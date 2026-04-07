from sqlalchemy import select
from sqlalchemy.orm import Session

from cafemap.models.entities import Brand


# ??? ??? ?? ????.


def fetch_brands(db: Session):
    # ??? ?? ??? ????.
    stmt = select(Brand).order_by(Brand.name.asc())
    return db.execute(stmt).scalars().all()


