from __future__ import annotations

import subprocess
import tempfile
import uuid
from pathlib import Path

import imageio_ffmpeg

from cafemap.core.config import S3_REVIEW_IMAGE_PREFIX
from cafemap.services import upload_service

_TRANSCODE_TIMEOUT_SECONDS = 180
_VIDEO_CACHE_CONTROL = "private, max-age=31536000, immutable"


class VideoProcessingError(RuntimeError):
    pass


def transcode_review_video(*, user_id: str, source_url: str) -> str:
    source_key = upload_service.extract_review_image_key(source_url)
    user_prefix = f"{S3_REVIEW_IMAGE_PREFIX.strip('/')}/{user_id}/"
    if not source_key.startswith(user_prefix):
        raise ValueError("Video does not belong to the authenticated user")
    if "/processed/" in source_key:
        return source_url

    output_key = f"{user_prefix}processed/media-job-{uuid.uuid4().hex}.mp4"
    with tempfile.TemporaryDirectory(prefix="cafemap-video-") as temp_dir:
        temp_path = Path(temp_dir)
        source_path = temp_path / f"source{Path(source_key).suffix or '.mp4'}"
        output_path = temp_path / "processed.mp4"
        upload_service.download_public_file(key=source_key, file_path=source_path)

        command = [
            imageio_ffmpeg.get_ffmpeg_exe(),
            "-y",
            "-i",
            str(source_path),
            "-map",
            "0:v:0",
            "-map",
            "0:a:0?",
            "-c:v",
            "libx264",
            "-preset",
            "veryfast",
            "-crf",
            "23",
            "-pix_fmt",
            "yuv420p",
            "-c:a",
            "aac",
            "-b:a",
            "128k",
            "-movflags",
            "+faststart",
            str(output_path),
        ]
        try:
            completed = subprocess.run(
                command,
                check=False,
                capture_output=True,
                text=True,
                timeout=_TRANSCODE_TIMEOUT_SECONDS,
            )
        except (OSError, subprocess.SubprocessError) as exc:
            raise VideoProcessingError("Failed to process video") from exc

        if completed.returncode != 0 or not output_path.exists():
            raise VideoProcessingError("Failed to process video")

        upload_service.upload_public_file(
            key=output_key,
            file_path=output_path,
            content_type="video/mp4",
            cache_control=_VIDEO_CACHE_CONTROL,
        )
    return upload_service.build_public_file_url(output_key)
