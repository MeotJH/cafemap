def test_list_brands_returns_seeded_catalog(client):
    # 브랜드 카탈로그 seed가 살아 있고 /brands 응답 계약이 깨지지 않았는지 본다.
    response = client.get("/api/cafemap/brands")

    assert response.status_code == 200
    data = response.json()
    assert data
    assert any(item["id"] == "brand-local" for item in data)


def test_list_brand_menus_returns_seeded_menu_catalog(client):
    # 특정 브랜드 메뉴 목록이 seed 데이터 기준으로 정상 노출되는지 본다.
    response = client.get("/api/cafemap/brands/brand-local/menus")

    assert response.status_code == 200
    data = response.json()
    assert data
    assert any(item["name"] == "아메리카노" for item in data)


def test_rankings_endpoint_returns_items(client):
    # 메뉴 랭킹 API가 최소 1개 이상의 결과와 핵심 식별자를 유지하는지 본다.
    response = client.get("/api/cafemap/rankings")

    assert response.status_code == 200
    data = response.json()
    assert data
    first = data[0]
    assert first["id"]
    assert first["brandId"]
    assert first["menuId"]


def test_store_rankings_endpoint_returns_list_shape(client):
    # 지점 랭킹은 seed 상태에 따라 비어 있을 수 있으므로 200과 리스트 shape만 보장한다.
    response = client.get("/api/cafemap/store-rankings")

    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    if data:
        first = data[0]
        assert first["storeId"]
        assert "thumbnailImageUrls" in first


def test_home_endpoint_returns_summary_sections(client):
    # 홈 요약 API가 프런트가 기대하는 주요 섹션 키를 모두 포함하는지 본다.
    response = client.get("/api/cafemap/home")

    assert response.status_code == 200
    data = response.json()
    assert "wifeTop" in data
    assert "husbandTop" in data
    assert "recentCafes" in data
    assert "recommendedMenus" in data


def test_stores_endpoint_returns_seeded_store_items(client):
    # 지점 목록 API가 최소 1개 이상의 seed 지점을 반환하는지 본다.
    response = client.get("/api/cafemap/stores")

    assert response.status_code == 200
    data = response.json()
    assert data
    first = data[0]
    assert first["id"]
    assert first["name"]
