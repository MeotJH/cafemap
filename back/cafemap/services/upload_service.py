import re
import uuid
from urllib.parse import urlparse

import boto3
from botocore.client import BaseClient
from botocore.config import Config
from botocore.exceptions import ClientError

from cafemap.core.config import (
    AWS_REGION,
    S3_BUCKET,
    S3_ENDPOINT_URL,
    S3_PRESIGNED_EXPIRES_SECONDS,
    S3_PUBLIC_BASE_URL,
    S3_REVIEW_IMAGE_PREFIX,
)

_EXT_BY_CONTENT_TYPE = {
    "image/jpeg": "jpg",
    "image/jpg": "jpg",
    "image/png": "png",
    "image/webp": "webp",
    "image/heic": "heic",
    "image/heif": "heif",
    "image/gif": "gif",
    "video/mp4": "mp4",
    "video/quicktime": "mov",
    "video/webm": "webm",
}


def _s3_client() -> BaseClient:
    return boto3.client(
        "s3",
        region_name=AWS_REGION,
        endpoint_url=S3_ENDPOINT_URL,
        config=Config(
            signature_version="s3v4",
            s3={"addressing_style": "virtual"},
        ),
    )


def _sanitize_file_name(raw: str) -> str:
    safe = raw.strip().lower()
    safe = re.sub(r"[^a-z0-9._-]", "-", safe)
    return safe[:120] if safe else "media"


def _resolve_extension(file_name: str, content_type: str) -> str:
    if "." in file_name:
        ext = file_name.rsplit(".", 1)[1].lower()
        if ext in {
            "jpg",
            "jpeg",
            "png",
            "webp",
            "heic",
            "heif",
            "gif",
            "mp4",
            "mov",
            "webm",
        }:
            return "jpg" if ext == "jpeg" else ext
    return _EXT_BY_CONTENT_TYPE.get(content_type.lower(), "jpg")


def is_public_storage_configured() -> bool:
    return bool(S3_BUCKET.strip())


def build_public_file_url(key: str) -> str:
    if not is_public_storage_configured():
        raise ValueError("S3_BUCKET is not configured")

    if S3_PUBLIC_BASE_URL:
        return f"{S3_PUBLIC_BASE_URL.rstrip('/')}/{key}"
    return f"https://{S3_BUCKET}.s3.{AWS_REGION}.amazonaws.com/{key}"


def public_object_exists(key: str) -> bool:
    if not is_public_storage_configured():
        return False

    try:
        _s3_client().head_object(Bucket=S3_BUCKET, Key=key)
        return True
    except ClientError as exc:
        error_code = str(exc.response.get("Error", {}).get("Code", ""))
        if error_code in {"404", "NoSuchKey", "NotFound"}:
            return False
        raise


def issue_public_download_url(
    *,
    key: str,
    expires_seconds: int | None = None,
) -> str:
    if not is_public_storage_configured():
        raise ValueError("S3_BUCKET is not configured")

    return _s3_client().generate_presigned_url(
        ClientMethod="get_object",
        Params={
            "Bucket": S3_BUCKET,
            "Key": key,
        },
        ExpiresIn=expires_seconds or S3_PRESIGNED_EXPIRES_SECONDS,
    )


def upload_public_bytes(
    *,
    key: str,
    data: bytes,
    content_type: str,
    cache_control: str | None = None,
) -> str:
    if not is_public_storage_configured():
        raise ValueError("S3_BUCKET is not configured")

    params = {
        "Bucket": S3_BUCKET,
        "Key": key,
        "Body": data,
        "ContentType": content_type,
    }
    if cache_control:
        params["CacheControl"] = cache_control

    _s3_client().put_object(**params)
    return key


def is_review_image_public_url(raw_url: str | None) -> bool:
    value = (raw_url or "").strip()
    if not value:
        return False

    prefix = S3_REVIEW_IMAGE_PREFIX.strip("/")
    if not prefix:
        return False

    parsed = urlparse(value)
    path = (parsed.path or "").strip("/")
    if parsed.scheme in {"http", "https"} and f"/{prefix}/" in f"/{path}/":
        return True

    allowed_prefixes = []
    if S3_PUBLIC_BASE_URL:
        allowed_prefixes.append(f"{S3_PUBLIC_BASE_URL.rstrip('/')}/{prefix}/")
    if S3_BUCKET:
        allowed_prefixes.append(
            f"https://{S3_BUCKET}.s3.{AWS_REGION}.amazonaws.com/{prefix}/"
        )
    endpoint_host = urlparse(S3_ENDPOINT_URL).netloc.strip()
    if endpoint_host and S3_BUCKET:
        allowed_prefixes.append(f"https://{S3_BUCKET}.{endpoint_host}/{prefix}/")

    return any(value.startswith(item) for item in allowed_prefixes)


def issue_review_image_upload_url(
    *,
    user_id: str,
    file_name: str,
    content_type: str,
) -> tuple[str, str]:
    if not S3_BUCKET:
        raise ValueError("S3_BUCKET is not configured")

    normalized_content_type = (content_type or "").strip().lower()
    if normalized_content_type not in _EXT_BY_CONTENT_TYPE:
        raise ValueError("Unsupported review media type")

    safe_name = _sanitize_file_name(file_name)
    ext = _resolve_extension(safe_name, normalized_content_type)
    key = (
        f"{S3_REVIEW_IMAGE_PREFIX.strip('/')}/"
        f"{user_id}/"
        f"{uuid.uuid4().hex}.{ext}"
    )

    upload_url = _s3_client().generate_presigned_url(
        ClientMethod="put_object",
        Params={
            "Bucket": S3_BUCKET,
            "Key": key,
            "ContentType": normalized_content_type,
        },
        ExpiresIn=S3_PRESIGNED_EXPIRES_SECONDS,
    )
    return upload_url, build_public_file_url(key)
