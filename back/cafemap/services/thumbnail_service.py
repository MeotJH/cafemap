from __future__ import annotations

import hashlib
import io
import logging
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import urlparse

import requests

try:
    from PIL import Image, ImageOps, UnidentifiedImageError
except ModuleNotFoundError as exc:
    Image = None
    ImageOps = None
    UnidentifiedImageError = OSError
    _PIL_IMPORT_ERROR = exc
else:
    _PIL_IMPORT_ERROR = None

try:
    import imageio_ffmpeg
except ModuleNotFoundError as exc:
    imageio_ffmpeg = None
    _FFMPEG_IMPORT_ERROR = exc
else:
    _FFMPEG_IMPORT_ERROR = None

from cafemap.core.config import DATA_DIR, S3_THUMBNAIL_PREFIX
from cafemap.services import upload_service

THUMBNAIL_CACHE_DIR = DATA_DIR / "thumbnail_cache"
THUMBNAIL_CACHE_DIR.mkdir(parents=True, exist_ok=True)

_REQUEST_TIMEOUT_SECONDS = 10
_DEFAULT_QUALITY = 82
_VIDEO_FRAME_OFFSET_SECONDS = 0.5
_VIDEO_RENDER_TIMEOUT_SECONDS = 20
_VIDEO_EXTENSIONS = {".mp4", ".mov", ".webm"}
_S3_CACHE_CONTROL = "public, max-age=31536000, immutable"

logger = logging.getLogger(__name__)


class ThumbnailError(RuntimeError):
    pass


@dataclass(frozen=True)
class ThumbnailAsset:
    local_path: Path | None = None
    storage_key: str = ""


def get_or_create_thumbnail(
    *,
    source_url: str,
    width: int,
    height: int,
) -> ThumbnailAsset:
    if _PIL_IMPORT_ERROR is not None:
        raise ThumbnailError(
            "Pillow is not installed. Run `python -m pip install -r requirements.txt` "
            "from the back directory."
        ) from _PIL_IMPORT_ERROR

    normalized_url = source_url.strip()
    if not normalized_url:
        raise ThumbnailError("Thumbnail source URL is empty")

    safe_width = max(32, min(int(width), 512))
    safe_height = max(32, min(int(height), 512))
    cache_key = _thumbnail_cache_key(normalized_url, safe_width, safe_height)

    if _should_store_in_s3():
        public_key = _thumbnail_object_key(cache_key)
        try:
            if upload_service.public_object_exists(public_key):
                return ThumbnailAsset(storage_key=public_key)
        except Exception:
            logger.exception("Failed to check S3 thumbnail cache for %s", public_key)

    cache_path = THUMBNAIL_CACHE_DIR / f"{cache_key}.jpg"
    if cache_path.exists():
        return ThumbnailAsset(local_path=cache_path)

    thumbnail_bytes = _render_thumbnail_bytes(
        source_url=normalized_url,
        width=safe_width,
        height=safe_height,
    )

    if _should_store_in_s3():
        public_key = _thumbnail_object_key(cache_key)
        try:
            storage_key = upload_service.upload_public_bytes(
                key=public_key,
                data=thumbnail_bytes,
                content_type="image/jpeg",
                cache_control=_S3_CACHE_CONTROL,
            )
            return ThumbnailAsset(storage_key=storage_key)
        except Exception:
            logger.exception("Failed to upload thumbnail to S3 for %s", public_key)

    cache_path.write_bytes(thumbnail_bytes)
    return ThumbnailAsset(local_path=cache_path)


def _thumbnail_cache_key(source_url: str, width: int, height: int) -> str:
    return hashlib.sha256(f"{source_url}|{width}|{height}".encode("utf-8")).hexdigest()


def _thumbnail_object_key(cache_key: str) -> str:
    prefix = S3_THUMBNAIL_PREFIX.strip("/")
    if not prefix:
        raise ThumbnailError("S3 thumbnail prefix is empty")
    return f"{prefix}/{cache_key}.jpg"


def _should_store_in_s3() -> bool:
    return upload_service.is_public_storage_configured() and bool(
        S3_THUMBNAIL_PREFIX.strip()
    )


def _render_thumbnail_bytes(*, source_url: str, width: int, height: int) -> bytes:
    if _is_video_source(source_url):
        return _render_video_thumbnail_bytes(
            source_url=source_url,
            width=width,
            height=height,
        )

    try:
        response = requests.get(
            source_url,
            timeout=_REQUEST_TIMEOUT_SECONDS,
        )
        response.raise_for_status()
    except requests.RequestException as exc:
        raise ThumbnailError("Failed to fetch thumbnail source") from exc

    try:
        with Image.open(io.BytesIO(response.content)) as image:
            processed = _prepare_image(image, width, height)
            output = io.BytesIO()
            processed.save(
                output,
                format="JPEG",
                quality=_DEFAULT_QUALITY,
                optimize=True,
            )
            return output.getvalue()
    except (UnidentifiedImageError, OSError) as exc:
        raise ThumbnailError("Failed to generate thumbnail image") from exc


def _is_video_source(source_url: str) -> bool:
    path = urlparse(source_url).path.lower()
    return any(path.endswith(ext) for ext in _VIDEO_EXTENSIONS)


def _render_video_thumbnail_bytes(
    *,
    source_url: str,
    width: int,
    height: int,
) -> bytes:
    if _FFMPEG_IMPORT_ERROR is not None or imageio_ffmpeg is None:
        raise ThumbnailError(
            "imageio-ffmpeg is not installed. Run `python -m pip install -r requirements.txt` "
            "from the back directory."
        ) from _FFMPEG_IMPORT_ERROR

    scale_filter = (
        f"scale={width}:{height}:force_original_aspect_ratio=increase,"
        f"crop={width}:{height}"
    )

    with tempfile.TemporaryDirectory(prefix="cafemap-thumb-") as temp_dir:
        cache_path = Path(temp_dir) / "thumbnail.jpg"
        command = [
            imageio_ffmpeg.get_ffmpeg_exe(),
            "-y",
            "-ss",
            str(_VIDEO_FRAME_OFFSET_SECONDS),
            "-i",
            source_url,
            "-frames:v",
            "1",
            "-vf",
            scale_filter,
            "-q:v",
            "3",
            str(cache_path),
        ]

        try:
            completed = subprocess.run(
                command,
                check=False,
                capture_output=True,
                text=True,
                timeout=_VIDEO_RENDER_TIMEOUT_SECONDS,
            )
        except (OSError, subprocess.SubprocessError) as exc:
            raise ThumbnailError("Failed to render video thumbnail") from exc

        if completed.returncode != 0 or not cache_path.exists():
            raise ThumbnailError("Failed to render video thumbnail")

        return cache_path.read_bytes()


def _prepare_image(image: Image.Image, width: int, height: int) -> Image.Image:
    normalized = ImageOps.exif_transpose(image)
    converted = normalized.convert("RGBA")
    fitted = ImageOps.fit(
        converted,
        (width, height),
        method=Image.Resampling.LANCZOS,
        centering=(0.5, 0.5),
    )

    background = Image.new("RGB", fitted.size, (255, 255, 255))
    background.paste(fitted, mask=fitted.getchannel("A"))
    return background
