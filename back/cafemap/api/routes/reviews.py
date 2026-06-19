from fastapi import APIRouter, Depends, HTTPException, Request, Response, status
from sqlalchemy.orm import Session

from cafemap.api.deps import require_auth_user
from cafemap.api.presenters.review_presenter import to_review_out
from cafemap.db.session import get_db
from cafemap.models.entities import Menu
from cafemap.schemas.cafemap import ReviewCreateIn, ReviewOut
from cafemap.services import review_service, store_service
from cafemap.services.auth_service import get_user, upsert_user

router = APIRouter()


@router.get("/stores/{store_id}/reviews", response_model=list[ReviewOut])
def get_store_reviews(store_id: str, request: Request, db: Session = Depends(get_db)):
    rows = store_service.get_store_reviews(db, store_id)
    return [
        to_review_out(
            request=request,
            review=review,
            store_name=store_name,
            store_link=store_link,
            brand_name=brand_name,
            menu_name=menu_name,
            menu_category=menu_category,
            user_email=user_email,
        )
        for review, store_name, store_link, brand_name, menu_name, menu_category, user_email in rows
    ]


@router.get("/reviews/me", response_model=list[ReviewOut])
def get_my_reviews(
    request: Request,
    auth_user=Depends(require_auth_user),
    db: Session = Depends(get_db),
):
    rows = review_service.get_my_reviews(db, auth_user.uid)
    return [
        to_review_out(
            request=request,
            review=review,
            store_name=store_name,
            store_link=store_link,
            brand_name=brand_name,
            menu_name=menu_name,
            menu_category=menu_category,
            user_email=user_email,
        )
        for review, store_name, store_link, brand_name, menu_name, menu_category, user_email in rows
    ]


@router.get("/reviews/{review_id}", response_model=ReviewOut)
def get_review(review_id: str, request: Request, db: Session = Depends(get_db)):
    row = review_service.get_review(db, review_id)
    if row is None:
        raise HTTPException(status_code=404, detail="Review not found")

    review, store, brand_name, menu_name, menu_category, user_email = row
    return to_review_out(
        request=request,
        review=review,
        store_name=store.name,
        store_address=store.address,
        place_id=store.place_id,
        store_link=store.link,
        lat=store.lat,
        lng=store.lng,
        brand_name=brand_name,
        brand_id=review.brand_id,
        menu_name=menu_name,
        menu_category=menu_category,
        user_email=user_email,
    )


@router.post("/reviews", response_model=ReviewOut)
def create_review(
    request: Request,
    payload: ReviewCreateIn,
    auth_user=Depends(require_auth_user),
    db: Session = Depends(get_db),
):
    user = get_user(db, auth_user.uid)
    if user is None:
        user = upsert_user(db, auth_user)
        db.flush()

    try:
        review, store_name, store_link, brand_name, menu_name = (
            review_service.create_review(
                db,
                payload,
                auth_user.uid,
            )
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    menu = db.get(Menu, review.menu_id)
    menu_category = menu.category if menu is not None else "unknown"
    return to_review_out(
        request=request,
        review=review,
        store_name=store_name,
        store_link=store_link,
        brand_name=brand_name,
        menu_name=menu_name,
        menu_category=menu_category,
        user_email=user.email or "",
    )


@router.put("/reviews/{review_id}", response_model=ReviewOut)
def update_review(
    review_id: str,
    request: Request,
    payload: ReviewCreateIn,
    auth_user=Depends(require_auth_user),
    db: Session = Depends(get_db),
):
    user = get_user(db, auth_user.uid)
    if user is None:
        user = upsert_user(db, auth_user)
        db.flush()

    try:
        updated_review = review_service.update_review(
            db,
            review_id,
            payload,
            auth_user.uid,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except PermissionError as exc:
        raise HTTPException(status_code=403, detail=str(exc)) from exc

    if updated_review is None:
        raise HTTPException(status_code=404, detail="Review not found")

    row = review_service.get_review(db, updated_review.id)
    if row is None:
        raise HTTPException(status_code=404, detail="Review not found")

    review, store, brand_name, menu_name, menu_category, user_email = row
    return to_review_out(
        request=request,
        review=review,
        store_name=store.name,
        store_address=store.address,
        place_id=store.place_id,
        store_link=store.link,
        lat=store.lat,
        lng=store.lng,
        brand_name=brand_name,
        brand_id=review.brand_id,
        menu_name=menu_name,
        menu_category=menu_category,
        user_email=user_email or user.email or "",
    )


@router.delete("/reviews/{review_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_review(
    review_id: str,
    auth_user=Depends(require_auth_user),
    db: Session = Depends(get_db),
):
    try:
        deleted = review_service.delete_review(db, review_id, auth_user.uid)
    except PermissionError as exc:
        raise HTTPException(status_code=403, detail=str(exc)) from exc

    if not deleted:
        raise HTTPException(status_code=404, detail="Review not found")

    return Response(status_code=status.HTTP_204_NO_CONTENT)
