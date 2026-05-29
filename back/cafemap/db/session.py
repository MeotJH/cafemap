from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker

from cafemap.core.config import DB_URL

# Shared SQLAlchemy engine and declarative base.


class Base(DeclarativeBase):
    # Base class for all ORM models.
    pass


engine = create_engine(
    DB_URL,
    echo=False,
    connect_args={"check_same_thread": False},
)

SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)


def get_db():
    # Yield a request-scoped database session for FastAPI dependencies.
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
