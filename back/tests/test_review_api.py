from uuid import uuid4

from cafemap.models.entities import Review, Store, StoreAggregate, User


def test_review_create_and_read_lifecycle(client, db_session, auth_header):
    # 리뷰 생성 -> 상세 조회 -> 내 리뷰 조회 -> 지점 리뷰 노출까지 핵심 쓰기 흐름을 검증한다.
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
        matched_store = next((item for item in stores if item["name"] == store_name), None)
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
