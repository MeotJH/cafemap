from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, DeclarativeBase

from cafemap.core.config import DB_URL


# SQLAlchemy ?몄뀡怨?Base瑜??쒓났?섎뒗 紐⑤뱢?대떎.


class Base(DeclarativeBase):
    # ORM 紐⑤뜽??怨듯넻 Base ?대옒?ㅻ떎.
    pass


engine = create_engine(
    DB_URL,
    echo=False,
    connect_args={"check_same_thread": False},
)

SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)


def get_db():
    # FastAPI ?섏〈?깆쑝濡??ъ슜??DB ?몄뀡 ?앹꽦湲곕떎.
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

