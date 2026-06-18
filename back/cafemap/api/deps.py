from fastapi import Header, HTTPException

from cafemap.services.auth_service import AuthUser, resolve_auth_user


def require_auth_user(
    authorization: str | None = Header(default=None),
) -> AuthUser:
    auth_user = resolve_auth_user(authorization=authorization)
    if auth_user is None:
        raise HTTPException(status_code=401, detail="Login required")
    return auth_user
