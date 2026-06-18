from pathlib import Path
from types import SimpleNamespace


def test_review_image_presign_returns_upload_contract(client, auth_header, monkeypatch):
    # S3를 실제로 치지 않고도 presign route 계약과 인증 wiring이 유지되는지 본다.
    from cafemap.api.routes import uploads

    expected_upload_url = "https://upload.example.com/presigned"
    expected_file_url = "https://cdn.example.com/review-images/test.png"

    def fake_issue_review_image_upload_url(*, user_id, file_name, content_type):
        assert user_id == "test-user"
        assert file_name == "test.png"
        assert content_type == "image/png"
        return expected_upload_url, expected_file_url

    monkeypatch.setattr(
        uploads.upload_service,
        "issue_review_image_upload_url",
        fake_issue_review_image_upload_url,
    )

    response = client.post(
        "/api/cafemap/uploads/review-images/presign",
        json={"fileName": "test.png", "contentType": "image/png"},
        headers=auth_header,
    )

    assert response.status_code == 200
    assert response.json() == {
        "uploadUrl": expected_upload_url,
        "fileUrl": expected_file_url,
    }


def test_review_video_presign_returns_upload_contract(client, auth_header, monkeypatch):
    from cafemap.api.routes import uploads

    expected_upload_url = "https://upload.example.com/presigned-video"
    expected_file_url = "https://cdn.example.com/review-images/test.mp4"

    def fake_issue_review_image_upload_url(*, user_id, file_name, content_type):
        assert user_id == "test-user"
        assert file_name == "test.mp4"
        assert content_type == "video/mp4"
        return expected_upload_url, expected_file_url

    monkeypatch.setattr(
        uploads.upload_service,
        "issue_review_image_upload_url",
        fake_issue_review_image_upload_url,
    )

    response = client.post(
        "/api/cafemap/uploads/review-images/presign",
        json={"fileName": "test.mp4", "contentType": "video/mp4"},
        headers=auth_header,
    )

    assert response.status_code == 200
    assert response.json() == {
        "uploadUrl": expected_upload_url,
        "fileUrl": expected_file_url,
    }


def test_place_search_returns_mocked_results(client, monkeypatch):
    # 장소 검색 provider를 mock 해서 route 응답 shape와 파라미터 연결만 검증한다.
    from cafemap.api.routes import catalog

    expected = [
        {
            "name": "테스트 카페",
            "address": "서울 중구 세종대로 110",
            "roadAddress": "서울 중구 세종대로 110",
            "category": "카페",
            "phone": "02-000-0000",
            "link": "https://example.com/place",
            "placeId": "place-test-1",
            "brandId": "brand-local",
            "brandName": "개인 카페",
            "mapx": 0,
            "mapy": 0,
            "lat": 37.5665,
            "lng": 126.9780,
            "distanceKm": 0.1,
        }
    ]

    monkeypatch.setattr(
        catalog.place_search_service,
        "search_places",
        lambda **_: expected,
    )

    response = client.get("/api/cafemap/places/search", params={"query": "카페"})

    assert response.status_code == 200
    assert response.json() == expected


def test_store_detail_includes_visit_media_items(client, monkeypatch):
    from cafemap.api.presenters import media_presenter
    from cafemap.api.routes import stores

    fake_row = SimpleNamespace(
        store=SimpleNamespace(
            id="store-1",
            name="Test Store",
            store_type="local",
            brand_id="brand-local",
            address="Seoul",
            link="https://example.com/store",
            distance_km=0.1,
            lat=37.5,
            lng=127.0,
        ),
        aggregate=SimpleNamespace(
            rating=4.3,
            review_count=2,
            scores_json='{"coffee_quality": 4.2, "work_friendly": 4.1, "quietness": 3.9, "dessert": 3.7}',
        ),
        brand_name="Local Brand",
        brand_logo_url="https://cdn.example.com/logo.png",
        visit_media_items=[
            {"type": "image", "url": "https://cdn.example.com/review-images/a.jpg"},
            {"type": "video", "url": "https://cdn.example.com/review-images/b.mp4"},
        ],
        has_visit_media_more=True,
        visit_media_next_cursor="cursor-1",
    )

    monkeypatch.setattr(
        stores.store_service,
        "get_store_detail",
        lambda db, store_id: fake_row,
    )
    monkeypatch.setattr(
        media_presenter.upload_service,
        "is_review_image_public_url",
        lambda raw_url: True,
    )

    response = client.get("/api/cafemap/stores/store-1")

    assert response.status_code == 200
    payload = response.json()
    assert payload["name"] == "Test Store"
    assert len(payload["visitMediaItems"]) == 2
    assert payload["hasVisitMediaMore"] is True
    assert payload["visitMediaNextCursor"] == "cursor-1"
    assert (
        payload["visitMediaItems"][0]["url"]
        == "https://cdn.example.com/review-images/a.jpg"
    )
    assert (
        "/api/cafemap/assets/thumbnail?src="
        in payload["visitMediaItems"][1]["thumbnailUrl"]
    )


def test_store_visit_media_page_returns_cursor_page(client, monkeypatch):
    from cafemap.api.presenters import media_presenter
    from cafemap.api.routes import stores

    monkeypatch.setattr(
        stores.store_service,
        "get_store_visit_media_page",
        lambda db, store_id, limit, cursor: SimpleNamespace(
            items=[
                {
                    "type": "image",
                    "url": "https://cdn.example.com/review-images/a.jpg",
                    "thumbnailUrl": "",
                    "durationMs": None,
                },
                {
                    "type": "video",
                    "url": "https://cdn.example.com/review-images/b.mp4",
                },
            ],
            has_more=True,
            next_cursor="cursor-2",
        ),
    )
    monkeypatch.setattr(
        media_presenter.upload_service,
        "is_review_image_public_url",
        lambda raw_url: True,
    )

    response = client.get(
        "/api/cafemap/stores/store-1/visit-media",
        params={"limit": 10, "cursor": "cursor-1"},
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["hasMore"] is True
    assert payload["nextCursor"] == "cursor-2"
    assert len(payload["items"]) == 2


def test_thumbnail_asset_endpoint_supports_review_media(
    client,
    monkeypatch,
    tmp_path,
):
    from cafemap.api.routes import stores
    from PIL import Image

    thumbnail_path = tmp_path / "thumb.jpg"
    Image.new("RGB", (24, 24), (120, 80, 40)).save(thumbnail_path, format="JPEG")

    monkeypatch.setattr(
        stores.upload_service,
        "is_review_image_public_url",
        lambda raw_url: True,
    )
    monkeypatch.setattr(
        stores.thumbnail_service,
        "get_or_create_thumbnail",
        lambda **_: stores.thumbnail_service.ThumbnailAsset(
            local_path=Path(thumbnail_path)
        ),
    )

    response = client.get(
        "/api/cafemap/assets/thumbnail",
        params={
            "src": "https://cdn.example.com/review-images/test.mp4",
            "w": 160,
            "h": 160,
        },
    )

    assert response.status_code == 200
    assert response.headers["content-type"].startswith("image/jpeg")


def test_thumbnail_asset_endpoint_redirects_to_presigned_thumbnail(client, monkeypatch):
    from cafemap.api.routes import stores

    download_url = "https://download.example.com/presigned-thumb"
    storage_key = "review-thumbnails/test.jpg"

    monkeypatch.setattr(
        stores.upload_service,
        "is_review_image_public_url",
        lambda raw_url: True,
    )
    monkeypatch.setattr(
        stores.upload_service,
        "issue_public_download_url",
        lambda *, key: download_url if key == storage_key else "",
    )
    monkeypatch.setattr(
        stores.thumbnail_service,
        "get_or_create_thumbnail",
        lambda **_: stores.thumbnail_service.ThumbnailAsset(storage_key=storage_key),
    )

    response = client.get(
        "/api/cafemap/assets/thumbnail",
        params={
            "src": "https://cdn.example.com/review-images/test.mp4",
            "w": 160,
            "h": 160,
        },
        follow_redirects=False,
    )

    assert response.status_code in {302, 307}
    assert response.headers["location"] == download_url
