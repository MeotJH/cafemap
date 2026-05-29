from __future__ import annotations

import hashlib
import io
from pathlib import Path

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

from cafemap.core.config import DATA_DIR

THUMBNAIL_CACHE_DIR = DATA_DIR / "thumbnail_cache"
THUMBNAIL_CACHE_DIR.mkdir(parents=True, exist_ok=True)

_REQUEST_TIMEOUT_SECONDS = 10
_DEFAULT_QUALITY = 82


class ThumbnailError(RuntimeError):
    pass


def get_or_create_thumbnail(
    *,
    source_url: str,
    width: int,
    height: int,
) -> Path:
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
    cache_key = hashlib.sha256(
        f"{normalized_url}|{safe_width}|{safe_height}".encode("utf-8")
    ).hexdigest()
    cache_path = THUMBNAIL_CACHE_DIR / f"{cache_key}.jpg"
    if cache_path.exists():
        return cache_path

    try:
        response = requests.get(
            normalized_url,
            timeout=_REQUEST_TIMEOUT_SECONDS,
        )
        response.raise_for_status()
    except requests.RequestException as exc:
        raise ThumbnailError("Failed to fetch thumbnail source") from exc

    try:
        with Image.open(io.BytesIO(response.content)) as image:
            processed = _prepare_image(image, safe_width, safe_height)
            processed.save(
                cache_path,
                format="JPEG",
                quality=_DEFAULT_QUALITY,
                optimize=True,
            )
    except (UnidentifiedImageError, OSError) as exc:
        raise ThumbnailError("Failed to generate thumbnail image") from exc

    return cache_path


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
