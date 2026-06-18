import os

from locust import HttpUser, between, task

STORE_ID = os.getenv("CAFEMAP_LOADTEST_STORE_ID", "").strip()
RANKING_ID = os.getenv("CAFEMAP_LOADTEST_RANKING_ID", "").strip()


class CafeMapReadUser(HttpUser):
    """
    CafeMap 공개 조회 API를 대상으로 하는 기본 Locust 사용자 시나리오.

    - 인증이 필요 없는 read endpoint 위주로만 호출한다.
    - store/ranking 세부 조회는 환경 변수가 있을 때만 활성화한다.
    - 처음에는 작은 동시성으로 병목 endpoint를 찾는 용도로 사용한다.
    """

    wait_time = between(1, 3)

    @task(4)
    def get_rankings(self):
        self.client.get("/api/cafemap/rankings", name="GET /rankings")

    @task(3)
    def get_home(self):
        self.client.get("/api/cafemap/home", name="GET /home")

    @task(3)
    def get_stores(self):
        self.client.get("/api/cafemap/stores", name="GET /stores")

    @task(2)
    def get_store_rankings(self):
        self.client.get(
            "/api/cafemap/store-rankings?type=couple",
            name="GET /store-rankings",
        )

    @task(2)
    def get_place_search(self):
        self.client.get(
            "/api/cafemap/places/search",
            params={"query": "카페", "display": 5},
            name="GET /places/search",
        )

    @task(1)
    def get_store_detail(self):
        if not STORE_ID:
            return
        self.client.get(
            f"/api/cafemap/stores/{STORE_ID}",
            name="GET /stores/:store_id",
        )

    @task(1)
    def get_store_reviews(self):
        if not STORE_ID:
            return
        self.client.get(
            f"/api/cafemap/stores/{STORE_ID}/reviews",
            name="GET /stores/:store_id/reviews",
        )

    @task(1)
    def get_store_visit_media(self):
        if not STORE_ID:
            return
        self.client.get(
            f"/api/cafemap/stores/{STORE_ID}/visit-media",
            params={"limit": 10},
            name="GET /stores/:store_id/visit-media",
        )

    @task(1)
    def get_ranking_breakdown(self):
        if not RANKING_ID:
            return
        self.client.get(
            f"/api/cafemap/rankings/{RANKING_ID}/breakdown",
            name="GET /rankings/:ranking_id/breakdown",
        )

    @task(1)
    def get_ranking_reviews(self):
        if not RANKING_ID:
            return
        self.client.get(
            f"/api/cafemap/rankings/{RANKING_ID}/reviews",
            name="GET /rankings/:ranking_id/reviews",
        )
