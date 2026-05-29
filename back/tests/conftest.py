import os
import tempfile
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

_TEST_DB_DIR = Path(tempfile.mkdtemp(prefix="cafemap-pytest-"))
_TEST_DB_PATH = _TEST_DB_DIR / "cafemap-test.db"

# 테스트는 실제 개발 DB를 건드리지 않도록 임시 SQLite 경로로 강제한다.
os.environ["cafemap_DB_URL"] = f"sqlite:///{_TEST_DB_PATH}"
os.environ["CAFEMAP_SEED_CATALOG_ON_STARTUP"] = "1"
os.environ["CAFEMAP_SEED_SAMPLE_DATA"] = "1"

from main import app
from cafemap.db.session import SessionLocal


@pytest.fixture(scope="session")
def client():
    # FastAPI 앱을 실제 lifespan(init_db 포함)과 함께 띄운 테스트 클라이언트다.
    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture()
def db_session():
    # 테스트가 직접 정리해야 하는 리뷰/지점/유저 레코드 삭제에 사용한다.
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()


@pytest.fixture()
def auth_header():
    # Firebase 없이도 인증 흐름을 흉내 낼 수 있는 테스트용 Authorization 헤더다.
    token = "test-user|test@example.com|Test User||codex"
    return {"Authorization": f"Bearer {token}"}
