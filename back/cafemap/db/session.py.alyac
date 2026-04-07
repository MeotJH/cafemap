from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, DeclarativeBase

from chickenmap.core.config import DB_URL


# SQLAlchemy 세션과 Base를 제공하는 모듈이다.


class Base(DeclarativeBase):
    # ORM 모델의 공통 Base 클래스다.
    pass


engine = create_engine(
    DB_URL,
    echo=False,
    connect_args={"check_same_thread": False},
)

SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)


def get_db():
    # FastAPI 의존성으로 사용할 DB 세션 생성기다.
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
