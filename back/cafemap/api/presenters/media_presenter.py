from urllib.parse import quote

from fastapi import Request

from cafemap.services import upload_service


def public_base_url(request: Request) -> str:
    forwarded_proto = (
        (request.headers.get("x-forwarded-proto") or "").split(",")[0].strip()
    )
    forwarded_host = (
        (request.headers.get("x-forwarded-host") or "").split(",")[0].strip()
    )
    request_base_url = str(request.base_url).rstrip("/")
    if forwarded_proto and forwarded_host:
        return f"{forwarded_proto}://{forwarded_host}"
    return request_base_url


def resolve_asset_url(request: Request, raw_url: str | None) -> str:
    value = (raw_url or "").strip()
    forwarded_proto = (
        (request.headers.get("x-forwarded-proto") or "").split(",")[0].strip()
    )
    base_url = public_base_url(request)
    if not value:
        return ""
    if value.startswith(("http://", "https://")):
        return value
    if value.startswith("//"):
        scheme = forwarded_proto or request.url.scheme
        return f"{scheme}:{value}"
    if value.startswith("/"):
        return f"{base_url}{value}"
    return f"{base_url}/{value.lstrip('/')}"


def resolve_store_image_url(request: Request, brand_logo_url: str | None) -> str:
    return resolve_asset_url(request, brand_logo_url)


def is_video_media_url(raw_url: str | None) -> bool:
    lowered = (raw_url or "").strip().lower()
    return (
        lowered.endswith(".mp4")
        or lowered.endswith(".mov")
        or lowered.endswith(".webm")
    )


def resolve_thumbnail_url(
    request: Request,
    raw_url: str | None,
    *,
    width: int = 160,
    height: int = 160,
) -> str:
    resolved = resolve_asset_url(request, raw_url)
    if not resolved:
        return ""
    lowered = resolved.lower()
    if lowered.endswith(".svg"):
        return resolved
    if not upload_service.is_review_image_public_url(resolved):
        return resolved

    encoded_src = quote(resolved, safe="")
    return (
        f"{public_base_url(request)}/api/cafemap/assets/thumbnail"
        f"?src={encoded_src}&w={width}&h={height}"
    )


def resolve_review_media_url(request: Request, raw_url: str | None) -> str:
    resolved = resolve_asset_url(request, raw_url)
    if not resolved:
        return ""
    if not upload_service.is_review_image_public_url(resolved):
        return resolved

    encoded_src = quote(resolved, safe="")
    return f"{public_base_url(request)}/api/cafemap/assets/media?src={encoded_src}"


def resolve_media_gallery_url(
    request: Request,
    raw_url: str | None,
    *,
    width: int = 160,
    height: int = 160,
) -> str:
    if is_video_media_url(raw_url):
        return resolve_thumbnail_url(request, raw_url, width=width, height=height)
    return resolve_review_media_url(request, raw_url)


def resolve_video_thumbnail_url(
    request: Request,
    raw_url: str | None,
    *,
    width: int = 160,
    height: int = 160,
) -> str:
    resolved = resolve_asset_url(request, raw_url)
    if not resolved or not is_video_media_url(resolved):
        return ""
    if not upload_service.is_review_image_public_url(resolved):
        return ""
    return resolve_thumbnail_url(request, resolved, width=width, height=height)
