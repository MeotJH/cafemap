from datetime import datetime

from sqlalchemy import String, Float, Integer, DateTime, ForeignKey

from sqlalchemy.orm import Mapped, mapped_column, relationship



from cafemap.db.session import Base





# ??? ??? ORM ??? ???? ????.





class Brand(Base):

    # ?? ??? ??? ???? ?????.

    __tablename__ = "brand"



    id: Mapped[str] = mapped_column(String(64), primary_key=True)

    name: Mapped[str] = mapped_column(String(100), unique=True, index=True)

    logo_url: Mapped[str] = mapped_column(String(1000))



    menus = relationship("Menu", back_populates="brand")

    stores = relationship("Store", back_populates="brand")





class User(Base):

    # Firebase ??? ???? ???? ?????.

    __tablename__ = "user"



    id: Mapped[str] = mapped_column(String(128), primary_key=True)

    email: Mapped[str] = mapped_column(String(255), default="")

    display_name: Mapped[str] = mapped_column(String(120), default="")

    photo_url: Mapped[str] = mapped_column(String(1000), default="")

    provider: Mapped[str] = mapped_column(String(40), default="google")

    created_at: Mapped[datetime] = mapped_column(DateTime)

    updated_at: Mapped[datetime] = mapped_column(DateTime)





class Menu(Base):

    # ???? ?? ??? ???? ?????.

    __tablename__ = "menu"



    id: Mapped[str] = mapped_column(String(64), primary_key=True)

    brand_id: Mapped[str] = mapped_column(ForeignKey("brand.id"))

    name: Mapped[str] = mapped_column(String(120))

    image_url: Mapped[str] = mapped_column(String(1000))

    category: Mapped[str] = mapped_column(String(40))



    brand = relationship("Brand", back_populates="menus")





class Store(Base):

    # ?? ?? ??? ???? ?????.

    __tablename__ = "store"



    id: Mapped[str] = mapped_column(String(64), primary_key=True)

    brand_id: Mapped[str] = mapped_column(ForeignKey("brand.id"))

    name: Mapped[str] = mapped_column(String(120))

    address: Mapped[str] = mapped_column(String(200))

    store_type: Mapped[str] = mapped_column(String(20), default="unknown")

    place_id: Mapped[str] = mapped_column(String(120), default="")

    link: Mapped[str] = mapped_column(String(1000), default="")

    distance_km: Mapped[float] = mapped_column(Float)

    lat: Mapped[float] = mapped_column(Float, default=0.0)

    lng: Mapped[float] = mapped_column(Float, default=0.0)



    brand = relationship("Brand", back_populates="stores")





class BrandMenuAggregate(Base):

    # ??? ?? ?? ?? ???? ???? ?????.

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

    # ?? ?? ?? ???? ???? ?????.

    __tablename__ = "store_aggregate"



    id: Mapped[str] = mapped_column(String(64), primary_key=True)

    store_id: Mapped[str] = mapped_column(ForeignKey("store.id"), index=True)

    rating: Mapped[float] = mapped_column(Float)

    review_count: Mapped[int] = mapped_column(Integer)

    scores_json: Mapped[str] = mapped_column(String, default="{}")

    counts_json: Mapped[str] = mapped_column(String, default="{}")





class Review(Base):

    # ?? ?? ???? ???? ?????.

    __tablename__ = "review"



    id: Mapped[str] = mapped_column(String(64), primary_key=True)

    user_id: Mapped[str] = mapped_column(ForeignKey("user.id"), index=True)

    store_id: Mapped[str] = mapped_column(ForeignKey("store.id"), index=True)

    brand_id: Mapped[str] = mapped_column(ForeignKey("brand.id"), index=True)

    menu_id: Mapped[str] = mapped_column(ForeignKey("menu.id"), index=True)

    scores_json: Mapped[str] = mapped_column(String, default="{}")

    image_urls_json: Mapped[str] = mapped_column(String, default="[]")

    temperature_option: Mapped[str] = mapped_column(String(20), default="")

    reviewer_type: Mapped[str] = mapped_column(String(20), default="USER")

    overall: Mapped[float] = mapped_column(Float)

    comment: Mapped[str] = mapped_column(String(500))

    created_at: Mapped[datetime] = mapped_column(DateTime)

