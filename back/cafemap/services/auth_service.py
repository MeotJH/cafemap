import base64
import json
from dataclasses import dataclass
from datetime import datetime

from sqlalchemy.orm import Session

from cafemap.models.entities import User


@dataclass
class AuthUser:
    uid: str
    email: str
    name: str
    picture: str
    provider: str = "google"


def resolve_auth_user(authorization: str | None) -> AuthUser | None:
    if not authorization:
        return None
    token = authorization.removeprefix("Bearer").strip()
    if not token:
        return None
    if token.startswith("cafemap-auth:"):
        return _resolve_cafemap_auth_token(token.removeprefix("cafemap-auth:"))
    if "|" in token:
        parts = token.split("|")
        uid = parts[0].strip() or "guest-user"
        email = parts[1].strip() if len(parts) > 1 else ""
        name = parts[2].strip() if len(parts) > 2 else ""
        picture = parts[3].strip() if len(parts) > 3 else ""
        provider = parts[4].strip() if len(parts) > 4 else "google"
        return AuthUser(
            uid=uid,
            email=email,
            name=name,
            picture=picture,
            provider=provider,
        )
    return AuthUser(uid=token, email="", name="", picture="")


def _resolve_cafemap_auth_token(token: str) -> AuthUser | None:
    try:
        padding = "=" * (-len(token) % 4)
        decoded = base64.urlsafe_b64decode(f"{token}{padding}").decode()
        payload = json.loads(decoded)
    except (ValueError, json.JSONDecodeError):
        return None
    if not isinstance(payload, dict):
        return None

    uid = str(payload.get("uid") or "").strip()
    if not uid:
        return None
    return AuthUser(
        uid=uid,
        email=str(payload.get("email") or ""),
        name=str(payload.get("name") or ""),
        picture=str(payload.get("picture") or ""),
        provider=str(payload.get("provider") or "firebase"),
    )


def get_user(db: Session, user_id: str) -> User | None:
    return db.get(User, user_id)


def upsert_user(db: Session, auth_user: AuthUser) -> User:
    user = db.get(User, auth_user.uid)
    now = datetime.now()
    if user is None:
        user = User(
            id=auth_user.uid,
            email=auth_user.email,
            display_name=auth_user.name,
            photo_url=auth_user.picture,
            provider=auth_user.provider,
            created_at=now,
            updated_at=now,
        )
        db.add(user)
        return user

    user.email = auth_user.email
    user.display_name = auth_user.name
    user.photo_url = auth_user.picture
    user.provider = auth_user.provider
    user.updated_at = now
    return user
