from __future__ import annotations

import base64
import html
import imghdr
from pathlib import Path
import sys
from urllib.error import URLError
from urllib.request import Request, urlopen

ROOT_DIR = Path(__file__).resolve().parents[1]
if str(ROOT_DIR) not in sys.path:
    sys.path.insert(0, str(ROOT_DIR))

from cafemap.db.brand_catalog import BRAND_CATALOG

ASSET_DIR = ROOT_DIR / "static" / "brand-logos"
CANVAS_SIZE = 256


def _asset_name(brand_id: str) -> str:
    return f"{brand_id.removeprefix('brand-')}.svg"


def _looks_like_blocked_response(payload: bytes) -> bool:
    head = payload[:256].strip().lower()
    return head.startswith(b"code:") or head.startswith(b"<!doctype html") or head.startswith(b"<html")


def _fetch_logo(url: str) -> bytes | None:
    request = Request(
        url,
        headers={
            "User-Agent": "Mozilla/5.0",
            "Referer": "https://namu.wiki/",
            "Accept": "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8",
        },
    )
    try:
        with urlopen(request, timeout=20) as response:
            payload = response.read()
    except URLError:
        return None
    if not payload or _looks_like_blocked_response(payload):
        return None
    return payload


def _mime_type(payload: bytes) -> str | None:
    head = payload[:512].lstrip()
    if head.startswith(b"<?xml") or b"<svg" in head.lower():
        return "image/svg+xml"
    detected = imghdr.what(None, payload)
    if detected == "png":
        return "image/png"
    if detected == "gif":
        return "image/gif"
    if detected == "jpeg":
        return "image/jpeg"
    if payload.startswith(b"RIFF") and b"WEBP" in payload[:16]:
        return "image/webp"
    return None


def _svg_wrapper(brand_name: str, mime_type: str, payload: bytes) -> str:
    encoded = base64.b64encode(payload).decode("ascii")
    escaped_name = html.escape(brand_name)
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{CANVAS_SIZE}" height="{CANVAS_SIZE}" viewBox="0 0 {CANVAS_SIZE} {CANVAS_SIZE}">
  <rect width="{CANVAS_SIZE}" height="{CANVAS_SIZE}" rx="32" fill="#ffffff"/>
  <image href="data:{mime_type};base64,{encoded}" x="16" y="16" width="224" height="224" preserveAspectRatio="xMidYMid meet"/>
  <title>{escaped_name}</title>
</svg>
"""


def _placeholder_svg(brand_name: str) -> str:
    escaped_name = html.escape(brand_name)
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{CANVAS_SIZE}" height="{CANVAS_SIZE}" viewBox="0 0 {CANVAS_SIZE} {CANVAS_SIZE}">
  <rect width="{CANVAS_SIZE}" height="{CANVAS_SIZE}" rx="32" fill="#6f4e37"/>
  <circle cx="128" cy="96" r="48" fill="#ffffff" opacity="0.96"/>
  <text x="128" y="110" text-anchor="middle" font-family="Arial, sans-serif" font-size="44" font-weight="700" fill="#6f4e37">☕</text>
  <text x="128" y="188" text-anchor="middle" font-family="Arial, sans-serif" font-size="24" font-weight="700" fill="#ffffff">{escaped_name}</text>
  <title>{escaped_name}</title>
</svg>
"""


def main() -> None:
    ASSET_DIR.mkdir(parents=True, exist_ok=True)
    expected_names = {_asset_name(entry["id"]) for entry in BRAND_CATALOG}
    for existing in ASSET_DIR.iterdir():
        if existing.is_file() and existing.name not in expected_names:
            existing.unlink()

    for entry in BRAND_CATALOG:
        target = ASSET_DIR / _asset_name(entry["id"])
        source_url = entry.get("source_url")
        if not source_url:
            target.write_text(_placeholder_svg(entry["name"]), encoding="utf-8")
            continue

        payload = _fetch_logo(source_url)
        if payload is None:
            target.write_text(_placeholder_svg(entry["name"]), encoding="utf-8")
            continue

        mime_type = _mime_type(payload)
        if mime_type == "image/svg+xml":
            target.write_bytes(payload)
            continue

        if mime_type:
            target.write_text(
                _svg_wrapper(entry["name"], mime_type, payload),
                encoding="utf-8",
            )
            continue

        target.write_text(_placeholder_svg(entry["name"]), encoding="utf-8")


if __name__ == "__main__":
    main()
