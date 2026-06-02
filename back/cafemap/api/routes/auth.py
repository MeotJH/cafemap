from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from cafemap.api.deps import require_auth_user
from cafemap.db.session import get_db
from cafemap.schemas.cafemap import AuthOut
from cafemap.services.auth_service import upsert_user

router = APIRouter()


@router.post("/auth", response_model=AuthOut)
def sync_user(
    auth_user=Depends(require_auth_user),
    db: Session = Depends(get_db),
):
    user = upsert_user(db, auth_user)
    db.commit()
    return AuthOut(
        uid=user.id,
        email=user.email,
        name=user.display_name,
        picture=user.photo_url,
        provider=user.provider,
    )
