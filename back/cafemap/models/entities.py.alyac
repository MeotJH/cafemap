from datetime import datetime
from sqlalchemy import String, Float, Integer, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from chickenmap.db.session import Base


# 도메인 엔티티 ORM 모델을 정의하는 모듈이다.


class Brand(Base):
    # 치킨 브랜드 정보를 저장하는 테이블이다.
    __tablename__ = "brand"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    name: Mapped[str] = mapped_column(String(100), unique=True, index=True)
    logo_url: Mapped[str] = mapped_column(String(1000))

    menus = relationship("Menu", back_populates="brand")
    stores = relationship("Store", back_populates="brand")


class User(Base):
    # Firebase 로그인 사용자를 저장하는 테이블이다.
    __tablename__ = "user"

    id: Mapped[str] = mapped_column(String(128), primary_key=True)
    email: Mapped[str] = mapped_column(String(255), default="")
    display_name: Mapped[str] = mapped_column(String(120), default="")
    photo_url: Mapped[str] = mapped_column(String(1000), default="")
    provider: Mapped[str] = mapped_column(String(40), default="google")
    created_at: Mapped[datetime] = mapped_column(DateTime)
    updated_at: Mapped[datetime] = mapped_column(DateTime)


class Menu(Base):
    # 브랜드별 메뉴 정보를 저장하는 테이블이다.
    __tablename__ = "menu"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    brand_id: Mapped[str] = mapped_column(ForeignKey("brand.id"))
    name: Mapped[str] = mapped_column(String(120))
    image_url: Mapped[str] = mapped_column(String(1000))
    category: Mapped[str] = mapped_column(String(40))

    brand = relationship("Brand", back_populates="menus")


class Store(Base):
    # 지점 기본 정보를 저장하는 테이블이다.
    __tablename__ = "store"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    brand_id: Mapped[str] = mapped_column(ForeignKey("brand.id"))
    name: Mapped[str] = mapped_column(String(120))
    address: Mapped[str] = mapped_column(String(200))
    distance_km: Mapped[float] = mapped_column(Float)
    lat: Mapped[float] = mapped_column(Float, default=0.0)
    lng: Mapped[float] = mapped_column(Float, default=0.0)

    brand = relationship("Brand", back_populates="stores")


class BrandMenuAggregate(Base):
    # 브랜드-메뉴 단위 집계 데이터를 저장하는 테이블이다.
    __tablename__ = "brand_menu_aggregate"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    brand_id: Mapped[str] = mapped_column(ForeignKey("brand.id"), index=True)
    menu_id: Mapped[str] = mapped_column(ForeignKey("menu.id"), index=True)
    rating: Mapped[float] = mapped_column(Float)
    review_count: Mapped[int] = mapped_column(Integer)
    highlight_score_a: Mapped[float] = mapped_column(Float)
    highlight_label_a: Mapped[str] = mapped_column(String(40))
    highlight_score_b: Mapped[float] = mapped_column(Float)
    highlight_label_b: Mapped[str] = mapped_column(String(40))
    scores_json: Mapped[str] = mapped_column(String, default="{}")


class StoreAggregate(Base):
    # 지점 단위 집계 데이터를 저장하는 테이블이다.
    __tablename__ = "store_aggregate"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    store_id: Mapped[str] = mapped_column(ForeignKey("store.id"), index=True)
    rating: Mapped[float] = mapped_column(Float)
    review_count: Mapped[int] = mapped_column(Integer)
    scores_json: Mapped[str] = mapped_column(String, default="{}")
    counts_json: Mapped[str] = mapped_column(String, default="{}")


class Review(Base):
    # 리뷰 상세 데이터를 저장하는 테이블이다.
    __tablename__ = "review"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    user_id: Mapped[str] = mapped_column(ForeignKey("user.id"), index=True)
    store_id: Mapped[str] = mapped_column(ForeignKey("store.id"), index=True)
    brand_id: Mapped[str] = mapped_column(ForeignKey("brand.id"), index=True)
    menu_id: Mapped[str] = mapped_column(ForeignKey("menu.id"), index=True)
    scores_json: Mapped[str] = mapped_column(String, default="{}")
    image_urls_json: Mapped[str] = mapped_column(String, default="[]")
    overall: Mapped[float] = mapped_column(Float)
    comment: Mapped[str] = mapped_column(String(500))
    created_at: Mapped[datetime] = mapped_column(DateTime)
