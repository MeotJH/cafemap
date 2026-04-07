import uuid

from cafemap.core.config import S3_PUBLIC_BASE_URL


def issue_review_image_upload_url(*, user_id: str, file_name: str, content_type: str) -> tuple[str, str]:
    if not file_name.strip():
        raise ValueError("fileName is required")
    if not content_type.startswith("image/"):
        raise ValueError("Only image uploads are allowed")

    safe_name = file_name.strip().replace(" ", "-")
    object_key = f"review-images/{user_id}/{uuid.uuid4().hex}-{safe_name}"
    public_base = S3_PUBLIC_BASE_URL.rstrip("/") or "https://example.com/uploads"
    file_url = f"{public_base}/{object_key}"
    return file_url, file_url
