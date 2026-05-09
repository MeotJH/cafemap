def test_review_image_presign_returns_upload_contract(client, auth_header, monkeypatch):
    # S3를 실제로 치지 않고도 presign route 계약과 인증 wiring이 유지되는지 본다.
    from cafemap.api import router

    expected_upload_url = "https://upload.example.com/presigned"
    expected_file_url = "https://cdn.example.com/review-images/test.png"

    def fake_issue_review_image_upload_url(*, user_id, file_name, content_type):
        assert user_id == "test-user"
        assert file_name == "test.png"
        assert content_type == "image/png"
        return expected_upload_url, expected_file_url

    monkeypatch.setattr(
        router.upload_service,
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


def test_place_search_returns_mocked_results(client, monkeypatch):
    # 장소 검색 provider를 mock 해서 route 응답 shape와 파라미터 연결만 검증한다.
    from cafemap.api import router

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
        router.place_search_service,
        "search_places",
        lambda **_: expected,
    )

    response = client.get("/api/cafemap/places/search", params={"query": "카페"})

    assert response.status_code == 200
    assert response.json() == expected
