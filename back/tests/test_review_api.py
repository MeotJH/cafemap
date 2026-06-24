from uuid import uuid4

from cafemap.core.config import REVIEW_IMAGE_LIMIT, REVIEW_VIDEO_MAX_DURATION_MS
from cafemap.models.entities import Review, Store, StoreAggregate, User


def _image_media(url: str) -> dict[str, object]:
    return {
        "type": "image",
        "url": url,
        "thumbnailUrl": "",
        "durationMs": None,
    }


def _video_media(url: str, *, duration_ms: int = 12000) -> dict[str, object]:
    return {
        "type": "video",
        "url": url,
        "thumbnailUrl": "",
        "durationMs": duration_ms,
    }


def test_review_create_and_read_lifecycle(client, db_session, auth_header):
    # 리뷰 생성부터 상세 조회, 내 리뷰 조회, 지도 리뷰 호출까지 흐름을 검증한다.
    suffix = uuid4().hex[:8]
    payload = {
        "storeName": f"Pytest 리뷰 카페 {suffix}",
        "address": "서울특별시 중구 세종대로 110",
        "placeId": "",
        "link": "",
        "temperatureOption": "ice",
        "lat": 37.5665,
        "lng": 126.9780,
        "brandId": "brand-local",
        "menuName": "아메리카노",
        "scores": {
            "coffee_quality": 4.0,
            "acidity_balance": 4.0,
            "body": 4.0,
            "aftertaste": 4.0,
            "temperature": 4.5,
            "value": 4.5,
        },
        "storeScores": {
            "atmosphere": 3.5,
            "work_friendly": 3.0,
            "quietness": 3.0,
            "seat_comfort": 3.5,
            "outlet_access": 3.0,
            "wifi_quality": 3.0,
            "service": 4.0,
            "revisit_intent": 4.0,
        },
        "overall": 4.2,
        "comment": f"pytest lifecycle {suffix}",
        "imageUrls": ["https://example.com/test-image.png"],
        "mediaItems": [_image_media("https://example.com/test-image.png")],
    }

    create_response = client.post(
        "/api/cafemap/reviews",
        json=payload,
        headers=auth_header,
    )

    assert create_response.status_code == 200
    created = create_response.json()
    review_id = created["id"]
    store_name = created["storeName"]

    try:
        assert created["comment"] == payload["comment"]
        assert created["temperatureOption"] == "ice"
        assert created["imageUrls"] == payload["imageUrls"]
        assert created["mediaItems"] == payload["mediaItems"]

        detail_response = client.get(f"/api/cafemap/reviews/{review_id}")
        assert detail_response.status_code == 200
        detail = detail_response.json()
        assert detail["id"] == review_id
        assert detail["comment"] == payload["comment"]
        assert detail["brandId"] == payload["brandId"]
        assert detail["address"] == payload["address"]
        assert detail["lat"] == payload["lat"]
        assert detail["lng"] == payload["lng"]

        my_reviews_response = client.get(
            "/api/cafemap/reviews/me",
            headers=auth_header,
        )
        assert my_reviews_response.status_code == 200
        my_reviews = my_reviews_response.json()
        assert any(item["id"] == review_id for item in my_reviews)

        stores_response = client.get("/api/cafemap/stores")
        assert stores_response.status_code == 200
        stores = stores_response.json()
        matched_store = next(
            (item for item in stores if item["name"] == store_name), None
        )
        assert matched_store is not None

        store_reviews_response = client.get(
            f"/api/cafemap/stores/{matched_store['id']}/reviews"
        )
        assert store_reviews_response.status_code == 200
        store_reviews = store_reviews_response.json()
        assert any(item["id"] == review_id for item in store_reviews)

        updated_payload = {
            **payload,
            "temperatureOption": "hot",
            "overall": 3.4,
            "comment": f"pytest edited {suffix}",
            "imageUrls": ["https://example.com/test-image-2.png"],
            "mediaItems": [
                _image_media("https://example.com/test-image-2.png"),
                _video_media("https://example.com/test-video.mp4"),
            ],
        }
        update_response = client.put(
            f"/api/cafemap/reviews/{review_id}",
            json=updated_payload,
            headers=auth_header,
        )
        assert update_response.status_code == 200
        updated = update_response.json()
        assert updated["comment"] == updated_payload["comment"]
        assert updated["temperatureOption"] == "hot"
        assert updated["imageUrls"] == updated_payload["imageUrls"]
        assert updated["mediaItems"] == updated_payload["mediaItems"]
        assert updated["address"] == payload["address"]

        updated_detail_response = client.get(f"/api/cafemap/reviews/{review_id}")
        assert updated_detail_response.status_code == 200
        updated_detail = updated_detail_response.json()
        assert updated_detail["comment"] == updated_payload["comment"]
        assert updated_detail["temperatureOption"] == "hot"

        store_breakdown_response = client.get(
            f"/api/cafemap/stores/{matched_store['id']}/breakdown"
        )
        assert store_breakdown_response.status_code == 200
        store_breakdown = store_breakdown_response.json()
        assert store_breakdown["overall"] == updated_payload["overall"]

        delete_response = client.delete(
            f"/api/cafemap/reviews/{review_id}",
            headers=auth_header,
        )
        assert delete_response.status_code == 204

        deleted_detail_response = client.get(f"/api/cafemap/reviews/{review_id}")
        assert deleted_detail_response.status_code == 404

        my_reviews_after_delete_response = client.get(
            "/api/cafemap/reviews/me",
            headers=auth_header,
        )
        assert my_reviews_after_delete_response.status_code == 200
        my_reviews_after_delete = my_reviews_after_delete_response.json()
        assert all(item["id"] != review_id for item in my_reviews_after_delete)

        deleted_store_breakdown_response = client.get(
            f"/api/cafemap/stores/{matched_store['id']}/breakdown"
        )
        assert deleted_store_breakdown_response.status_code == 404
    finally:
        review = db_session.get(Review, review_id)
        if review is None:
            return
        store_id = review.store_id
        user_id = review.user_id
        db_session.delete(review)
        aggregate = (
            db_session.query(StoreAggregate)
            .filter(StoreAggregate.store_id == store_id)
            .one_or_none()
        )
        if aggregate is not None:
            db_session.delete(aggregate)
        store = db_session.get(Store, store_id)
        if store is not None:
            db_session.delete(store)
        user = db_session.get(User, user_id)
        if user is not None:
            db_session.delete(user)
        db_session.commit()


def test_store_rankings_supports_purpose_sorting(client, db_session, auth_header):
    suffix = uuid4().hex[:8]
    payloads = [
        {
            "storeName": f"Pytest 데이트 카페 상 {suffix}",
            "address": "서울특별시 마포구 양화로 45",
            "placeId": "",
            "link": "",
            "temperatureOption": "ice",
            "lat": 37.5509,
            "lng": 126.9216,
            "brandId": "brand-local",
            "menuName": "아메리카노",
            "ratingSchemaVersion": 2,
            "scores": {
                "taste_satisfaction": 4.8,
                "aroma": 4.4,
                "body": 4.6,
                "clean_finish": 4.7,
                "aftertaste": 4.5,
                "value": 4.2,
            },
            "storeScores": {
                "atmosphere": 4.9,
                "quietness": 4.4,
                "seat_comfort": 4.0,
                "restroom_cleanliness": 4.1,
                "service": 4.3,
                "revisit_intent": 4.8,
            },
            "attributes": {
                "flavor_profile": "balanced",
                "roast_level": "medium",
                "temperature_option": "ice",
                "outlet_available": "yes",
                "wifi_usable": "good",
            },
            "overall": 4.7,
            "comment": f"purpose high {suffix}",
            "imageUrls": ["https://example.com/date-high.png"],
            "mediaItems": [_image_media("https://example.com/date-high.png")],
        },
        {
            "storeName": f"Pytest 데이트 카페 하 {suffix}",
            "address": "서울특별시 성동구 연무장길 35",
            "placeId": "",
            "link": "",
            "temperatureOption": "ice",
            "lat": 37.5447,
            "lng": 127.0557,
            "brandId": "brand-local",
            "menuName": "아메리카노",
            "ratingSchemaVersion": 2,
            "scores": {
                "taste_satisfaction": 3.1,
                "aroma": 3.0,
                "body": 3.2,
                "clean_finish": 3.0,
                "aftertaste": 3.4,
                "value": 3.3,
            },
            "storeScores": {
                "atmosphere": 2.8,
                "quietness": 2.9,
                "seat_comfort": 3.0,
                "restroom_cleanliness": 2.7,
                "service": 3.2,
                "revisit_intent": 2.9,
            },
            "attributes": {
                "flavor_profile": "nutty",
                "roast_level": "dark",
                "temperature_option": "ice",
                "outlet_available": "no",
                "wifi_usable": "bad",
            },
            "overall": 3.1,
            "comment": f"purpose low {suffix}",
            "imageUrls": ["https://example.com/date-low.png"],
            "mediaItems": [_image_media("https://example.com/date-low.png")],
        },
        {
            "storeName": f"Pytest 데이트 카페 구버전 {suffix}",
            "address": "서울특별시 강남구 테헤란로 212",
            "placeId": "",
            "link": "",
            "temperatureOption": "ice",
            "lat": 37.5012,
            "lng": 127.0396,
            "brandId": "brand-local",
            "menuName": "아메리카노",
            "scores": {
                "coffee_quality": 5.0,
                "acidity_balance": 4.8,
                "body": 4.9,
                "aftertaste": 4.8,
                "temperature": 4.9,
                "value": 4.7,
            },
            "storeScores": {
                "atmosphere": 5.0,
                "work_friendly": 4.7,
                "quietness": 4.8,
                "seat_comfort": 4.8,
                "outlet_access": 4.9,
                "wifi_quality": 4.8,
                "service": 4.9,
                "revisit_intent": 5.0,
            },
            "overall": 4.9,
            "comment": f"purpose legacy {suffix}",
            "imageUrls": ["https://example.com/date-legacy.png"],
            "mediaItems": [_image_media("https://example.com/date-legacy.png")],
        },
    ]

    created_review_ids: list[str] = []
    created_store_ids: set[str] = set()
    user_id: str | None = None

    try:
        for payload in payloads:
            response = client.post(
                "/api/cafemap/reviews",
                json=payload,
                headers=auth_header,
            )
            assert response.status_code == 200
            created = response.json()
            created_review_ids.append(created["id"])

            detail_response = client.get(f"/api/cafemap/reviews/{created['id']}")
            assert detail_response.status_code == 200
            detail = detail_response.json()
            user_id = user_id or db_session.get(Review, created["id"]).user_id

            stores_response = client.get("/api/cafemap/stores")
            assert stores_response.status_code == 200
            stores = stores_response.json()
            matched_store = next(
                (item for item in stores if item["name"] == detail["storeName"]),
                None,
            )
            assert matched_store is not None
            created_store_ids.add(matched_store["id"])

        ranking_response = client.get(
            "/api/cafemap/store-rankings?type=user&purpose=date"
        )
        assert ranking_response.status_code == 200
        rankings = ranking_response.json()

        names = [item["storeName"] for item in rankings]
        high_name = payloads[0]["storeName"]
        low_name = payloads[1]["storeName"]
        legacy_name = payloads[2]["storeName"]
        assert high_name in names
        assert low_name in names
        assert legacy_name not in names
        assert names.index(high_name) < names.index(low_name)

        all_ranking_response = client.get("/api/cafemap/store-rankings?type=user")
        assert all_ranking_response.status_code == 200
        all_rankings = all_ranking_response.json()
        legacy_ranking = next(
            (item for item in all_rankings if item["storeName"] == legacy_name),
            None,
        )
        assert legacy_ranking is not None
        assert legacy_ranking["topLabelA"] != "평가 없음"
        assert legacy_ranking["topScoreA"] > 0
    finally:
        for review_id in created_review_ids:
            review = db_session.get(Review, review_id)
            if review is not None:
                db_session.delete(review)
        db_session.flush()

        for store_id in created_store_ids:
            aggregate = (
                db_session.query(StoreAggregate)
                .filter(StoreAggregate.store_id == store_id)
                .one_or_none()
            )
            if aggregate is not None:
                db_session.delete(aggregate)
            store = db_session.get(Store, store_id)
            if store is not None:
                db_session.delete(store)

        if user_id is not None:
            user = db_session.get(User, user_id)
            if user is not None:
                db_session.delete(user)

        db_session.commit()


def test_review_image_limit_allows_five_and_rejects_more(
    client,
    db_session,
    auth_header,
):
    suffix = uuid4().hex[:8]
    base_payload = {
        "storeName": f"Pytest image limit cafe {suffix}",
        "address": "서울시 중구 테스트로 5",
        "placeId": "",
        "link": "",
        "temperatureOption": "ice",
        "lat": 37.5665,
        "lng": 126.9780,
        "brandId": "brand-local",
        "menuName": "아메리카노",
        "scores": {
            "coffee_quality": 4.0,
            "acidity_balance": 4.0,
            "body": 4.0,
            "aftertaste": 4.0,
            "temperature": 4.0,
            "value": 4.0,
        },
        "storeScores": {
            "atmosphere": 4.0,
            "work_friendly": 4.0,
            "quietness": 4.0,
            "seat_comfort": 4.0,
            "outlet_access": 4.0,
            "wifi_quality": 4.0,
            "service": 4.0,
            "revisit_intent": 4.0,
        },
        "overall": 4.0,
        "comment": f"pytest image limit {suffix}",
    }
    allowed_payload = {
        **base_payload,
        "imageUrls": [
            f"https://example.com/review-image-{index}.png"
            for index in range(REVIEW_IMAGE_LIMIT)
        ],
        "mediaItems": [
            _image_media(f"https://example.com/review-image-{index}.png")
            for index in range(REVIEW_IMAGE_LIMIT)
        ],
    }
    created_review_id: str | None = None
    created_store_id: str | None = None
    created_user_id: str | None = None

    try:
        allowed_response = client.post(
            "/api/cafemap/reviews",
            json=allowed_payload,
            headers=auth_header,
        )

        assert allowed_response.status_code == 200
        created = allowed_response.json()
        assert created["imageUrls"] == allowed_payload["imageUrls"]
        assert created["mediaItems"] == allowed_payload["mediaItems"]

        created_review_id = created["id"]
        review = db_session.get(Review, created_review_id)
        assert review is not None
        created_store_id = review.store_id
        created_user_id = review.user_id

        rejected_payload = {
            **base_payload,
            "storeName": f"Pytest image over limit cafe {suffix}",
            "comment": f"pytest image over limit {suffix}",
            "imageUrls": [
                f"https://example.com/review-image-{index}.png"
                for index in range(REVIEW_IMAGE_LIMIT + 1)
            ],
            "mediaItems": [
                _image_media(f"https://example.com/review-image-{index}.png")
                for index in range(REVIEW_IMAGE_LIMIT + 1)
            ],
        }
        rejected_response = client.post(
            "/api/cafemap/reviews",
            json=rejected_payload,
            headers=auth_header,
        )

        assert rejected_response.status_code == 400
        assert (
            rejected_response.json()["detail"]
            == f"At most {REVIEW_IMAGE_LIMIT} media items can be attached"
        )
    finally:
        if created_review_id is not None:
            review = db_session.get(Review, created_review_id)
            if review is not None:
                db_session.delete(review)
        if created_store_id is not None:
            aggregate = (
                db_session.query(StoreAggregate)
                .filter(StoreAggregate.store_id == created_store_id)
                .one_or_none()
            )
            if aggregate is not None:
                db_session.delete(aggregate)
            store = db_session.get(Store, created_store_id)
            if store is not None:
                db_session.delete(store)
        if created_user_id is not None:
            user = db_session.get(User, created_user_id)
            if user is not None:
                db_session.delete(user)
        db_session.commit()


def test_review_create_accepts_mixed_media_items(client, db_session, auth_header):
    suffix = uuid4().hex[:8]
    payload = {
        "storeName": f"Pytest mixed media cafe {suffix}",
        "address": "서울시 중구 테스트로 6",
        "placeId": "",
        "link": "",
        "temperatureOption": "ice",
        "lat": 37.5665,
        "lng": 126.9780,
        "brandId": "brand-local",
        "menuName": "아메리카노",
        "scores": {
            "coffee_quality": 4.1,
            "acidity_balance": 4.0,
            "body": 4.1,
            "aftertaste": 4.0,
            "temperature": 4.2,
            "value": 4.0,
        },
        "storeScores": {
            "atmosphere": 4.2,
            "work_friendly": 4.0,
            "quietness": 4.1,
            "seat_comfort": 4.0,
            "outlet_access": 4.0,
            "wifi_quality": 4.1,
            "service": 4.0,
            "revisit_intent": 4.2,
        },
        "overall": 4.1,
        "comment": f"pytest mixed media {suffix}",
        "mediaItems": [
            _image_media("https://example.com/mixed-image.png"),
            _video_media("https://example.com/mixed-video.mp4", duration_ms=9000),
        ],
    }
    created_review_id: str | None = None
    created_store_id: str | None = None
    created_user_id: str | None = None

    try:
        response = client.post(
            "/api/cafemap/reviews",
            json=payload,
            headers=auth_header,
        )

        assert response.status_code == 200
        created = response.json()
        assert created["mediaItems"] == payload["mediaItems"]
        assert created["imageUrls"] == ["https://example.com/mixed-image.png"]

        created_review_id = created["id"]
        review = db_session.get(Review, created_review_id)
        assert review is not None
        created_store_id = review.store_id
        created_user_id = review.user_id
    finally:
        if created_review_id is not None:
            review = db_session.get(Review, created_review_id)
            if review is not None:
                db_session.delete(review)
        if created_store_id is not None:
            aggregate = (
                db_session.query(StoreAggregate)
                .filter(StoreAggregate.store_id == created_store_id)
                .one_or_none()
            )
            if aggregate is not None:
                db_session.delete(aggregate)
            store = db_session.get(Store, created_store_id)
            if store is not None:
                db_session.delete(store)
        if created_user_id is not None:
            user = db_session.get(User, created_user_id)
            if user is not None:
                db_session.delete(user)
        db_session.commit()


def test_review_rejects_video_longer_than_thirty_seconds(
    client,
    auth_header,
):
    suffix = uuid4().hex[:8]
    payload = {
        "storeName": f"Pytest long video cafe {suffix}",
        "address": "Seoul Jung-gu Test-ro 7",
        "placeId": "",
        "link": "",
        "temperatureOption": "ice",
        "lat": 37.5665,
        "lng": 126.9780,
        "brandId": "brand-local",
        "menuName": "아메리카노",
        "scores": {
            "coffee_quality": 4.1,
            "acidity_balance": 4.0,
            "body": 4.1,
            "aftertaste": 4.0,
            "temperature": 4.2,
            "value": 4.0,
        },
        "storeScores": {
            "atmosphere": 4.2,
            "work_friendly": 4.0,
            "quietness": 4.1,
            "seat_comfort": 4.0,
            "outlet_access": 4.0,
            "wifi_quality": 4.1,
            "service": 4.0,
            "revisit_intent": 4.2,
        },
        "overall": 4.1,
        "comment": f"pytest long video {suffix}",
        "mediaItems": [
            _video_media(
                "https://example.com/too-long-video.mp4",
                duration_ms=REVIEW_VIDEO_MAX_DURATION_MS + 1,
            ),
        ],
    }

    response = client.post(
        "/api/cafemap/reviews",
        json=payload,
        headers=auth_header,
    )

    assert response.status_code == 400
    assert (
        response.json()["detail"]
        == f"Video duration must be {REVIEW_VIDEO_MAX_DURATION_MS // 1000} seconds or less"
    )


def test_review_video_thumbnail_url_is_derived_for_public_media(
    client,
    db_session,
    auth_header,
    monkeypatch,
):
    from cafemap.api.presenters import media_presenter

    monkeypatch.setattr(
        media_presenter.upload_service,
        "is_review_image_public_url",
        lambda raw_url: True,
    )
    monkeypatch.setattr(
        media_presenter.upload_service,
        "extract_review_image_key",
        lambda raw_url: "review-images/test-video.mp4",
    )
    monkeypatch.setattr(
        media_presenter.upload_service,
        "issue_public_download_url",
        lambda *, key: "https://download.example.com/presigned-video",
    )

    suffix = uuid4().hex[:8]
    payload = {
        "storeName": f"Pytest thumbnail media cafe {suffix}",
        "address": "Seoul Jung-gu Test-ro 8",
        "placeId": "",
        "link": "",
        "temperatureOption": "ice",
        "lat": 37.5665,
        "lng": 126.9780,
        "brandId": "brand-local",
        "menuName": "아메리카노",
        "scores": {
            "coffee_quality": 4.1,
            "acidity_balance": 4.0,
            "body": 4.1,
            "aftertaste": 4.0,
            "temperature": 4.2,
            "value": 4.0,
        },
        "storeScores": {
            "atmosphere": 4.2,
            "work_friendly": 4.0,
            "quietness": 4.1,
            "seat_comfort": 4.0,
            "outlet_access": 4.0,
            "wifi_quality": 4.1,
            "service": 4.0,
            "revisit_intent": 4.2,
        },
        "overall": 4.1,
        "comment": f"pytest thumbnail media {suffix}",
        "mediaItems": [
            _video_media(
                "https://cdn.example.com/review-images/test-video.mp4",
                duration_ms=9000,
            ),
        ],
    }
    created_review_id: str | None = None
    created_store_id: str | None = None
    created_user_id: str | None = None

    try:
        response = client.post(
            "/api/cafemap/reviews",
            json=payload,
            headers=auth_header,
        )

        assert response.status_code == 200
        created = response.json()
        assert created["mediaItems"][0]["type"] == "video"
        assert (
            created["mediaItems"][0]["url"]
            == "https://download.example.com/presigned-video"
        )
        assert (
            "/api/cafemap/assets/thumbnail?src="
            in created["mediaItems"][0]["thumbnailUrl"]
        )
        rankings_response = client.get("/api/cafemap/store-rankings?type=user")
        assert rankings_response.status_code == 200
        rankings = rankings_response.json()
        matched_store = next(
            (item for item in rankings if item["storeName"] == payload["storeName"]),
            None,
        )
        assert matched_store is not None
        assert matched_store["imageUrls"]
        assert matched_store["thumbnailImageUrls"]
        assert (
            "/api/cafemap/assets/thumbnail?src="
            in matched_store["thumbnailImageUrls"][0]
        )

        created_review_id = created["id"]
        review = db_session.get(Review, created_review_id)
        assert review is not None
        created_store_id = review.store_id
        created_user_id = review.user_id
    finally:
        if created_review_id is not None:
            review = db_session.get(Review, created_review_id)
            if review is not None:
                db_session.delete(review)
        if created_store_id is not None:
            aggregate = (
                db_session.query(StoreAggregate)
                .filter(StoreAggregate.store_id == created_store_id)
                .one_or_none()
            )
            if aggregate is not None:
                db_session.delete(aggregate)
            store = db_session.get(Store, created_store_id)
            if store is not None:
                db_session.delete(store)
        if created_user_id is not None:
            user = db_session.get(User, created_user_id)
            if user is not None:
                db_session.delete(user)
        db_session.commit()
