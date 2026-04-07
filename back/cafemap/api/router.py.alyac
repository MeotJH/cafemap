import json
import logging

from fastapi import APIRouter, Depends, Header, HTTPException
from sqlalchemy.orm import Session

from chickenmap.db.session import get_db
from chickenmap.models.entities import Menu
from chickenmap.core.rating_dimensions import compute_overall, scores_json_loads
from chickenmap.services.auth_service import (
    resolve_auth_user,
    upsert_user,
    get_user,
    AuthUser,
)
from chickenmap.schemas.chickenmap import (
  AuthOut,
  BrandMenuRankingOut,
  BrandOut,
  MenuOut,
  RatingBreakdownOut,
  ReviewImagePresignIn,
  ReviewImagePresignOut,
  ReviewOut,
  ReviewCreateIn,
  StoreSummaryOut,
  PlaceSearchOut,
)
from chickenmap.services import (
    brand_menu_service,
    store_service,
    review_service,
    place_search_service,
    brand_service,
    upload_service,
)


# 치킨맵 도메인 API 라우터다.

router = APIRouter(prefix="/api/chickenmap", tags=["chickenmap"])
logger = logging.getLogger(__name__)


def _resolve_store_image_url(brand_logo_url: str | None) -> str:
    # 브랜드 로고가 없으면 프론트 기본 이미지 폴백이 동작하도록 빈 문자열을 반환한다.
    return (brand_logo_url or "").strip()


def _scores_from_snapshot(
    scores_json: str | None,
) -> dict[str, float]:
    # scores_json 스냅샷을 안전하게 역직렬화한다.
    return scores_json_loads(scores_json)


def _image_urls_from_snapshot(
    image_urls_json: str | None,
) -> list[str]:
    if not image_urls_json:
        return []
    try:
        parsed = json.loads(image_urls_json)
    except (TypeError, ValueError):
        return []
    if not isinstance(parsed, list):
        return []
    return [item.strip() for item in parsed if isinstance(item, str) and item.strip()]


def _require_auth_user(
    authorization: str | None = Header(default=None),
) -> AuthUser:
    auth_user = resolve_auth_user(
        authorization=authorization,
    )
    if auth_user is None:
        raise HTTPException(status_code=401, detail="Login required")
    return auth_user


@router.post("/auth", response_model=AuthOut)
def sync_user(
    auth_user: AuthUser = Depends(_require_auth_user),
    db: Session = Depends(get_db),
):
    # 로그인 사용자를 동기화하고 반환한다.
    user = upsert_user(db, auth_user)
    db.commit()
    return AuthOut(
        uid=user.id,
        email=user.email,
        name=user.display_name,
        picture=user.photo_url,
        provider=user.provider,
    )


@router.get("/rankings", response_model=list[BrandMenuRankingOut])
def list_rankings(db: Session = Depends(get_db)):
    # 브랜드-메뉴 랭킹 리스트를 반환한다.
    rows = brand_menu_service.get_rankings(db)
    return [
        BrandMenuRankingOut(
            id=aggregate.id,
            brandId=aggregate.brand_id,
            menuId=aggregate.menu_id,
            brandName=brand_name,
            menuName=menu_name,
            category=menu_category,
            rating=aggregate.rating,
            reviewCount=aggregate.review_count,
            highlightScoreA=aggregate.highlight_score_a,
            highlightLabelA=aggregate.highlight_label_a,
            highlightScoreB=aggregate.highlight_score_b,
            highlightLabelB=aggregate.highlight_label_b,
            imageUrl=menu_image_url,
            brandLogoUrl=brand_logo_url,
        )
        for aggregate, brand_name, brand_logo_url, menu_name, menu_category, menu_image_url in rows
    ]


@router.get("/rankings/{ranking_id}/breakdown", response_model=RatingBreakdownOut)
def get_ranking_breakdown(ranking_id: str, db: Session = Depends(get_db)):
    # 랭킹 상세 점수 분해 정보를 반환한다.
    aggregate = brand_menu_service.get_ranking_breakdown(db, ranking_id)
    if aggregate is None:
        raise HTTPException(status_code=404, detail="Ranking not found")
    scores = _scores_from_snapshot(aggregate.scores_json)

    return RatingBreakdownOut(
        scores=scores,
        overall=compute_overall(scores, fallback=aggregate.rating),
    )


@router.get("/rankings/{ranking_id}/reviews", response_model=list[ReviewOut])
def get_ranking_reviews(ranking_id: str, db: Session = Depends(get_db)):
    # 랭킹 상세 리뷰 리스트를 반환한다.
    rows = brand_menu_service.get_ranking_reviews(db, ranking_id)
    return [
        ReviewOut(
            id=review.id,
            storeName=store_name,
            brandName=brand_name,
            menuName=menu_name,
            menuCategory=menu_category,
            scores=_scores_from_snapshot(review.scores_json),
            overall=review.overall,
            comment=review.comment,
            userEmail=user_email or "",
            imageUrls=_image_urls_from_snapshot(review.image_urls_json),
            createdAt=review.created_at,
        )
        for review, store_name, brand_name, menu_name, menu_category, user_email in rows
    ]


@router.get("/stores", response_model=list[StoreSummaryOut])
def list_stores(db: Session = Depends(get_db)):
    # 지점 요약 리스트를 반환한다.
    rows = store_service.get_nearby_stores(db)
    return [
        StoreSummaryOut(
            id=store.id,
            name=store.name,
            brandName=brand_name,
            address=store.address,
            rating=aggregate.rating,
            reviewCount=aggregate.review_count,
            distanceKm=store.distance_km,
            imageUrl=_resolve_store_image_url(brand_logo_url),
            lat=store.lat,
            lng=store.lng,
        )
        for store, aggregate, brand_name, brand_logo_url in rows
    ]


@router.get("/stores/{store_id}", response_model=StoreSummaryOut)
def get_store_detail(store_id: str, db: Session = Depends(get_db)):
    # 지점 상세 정보를 반환한다.
    row = store_service.get_store_detail(db, store_id)
    if row is None:
        raise HTTPException(status_code=404, detail="Store not found")
    store, aggregate, brand_name, brand_logo_url = row
    return StoreSummaryOut(
        id=store.id,
        name=store.name,
        brandName=brand_name,
        address=store.address,
        rating=aggregate.rating,
        reviewCount=aggregate.review_count,
        distanceKm=store.distance_km,
        imageUrl=_resolve_store_image_url(brand_logo_url),
        lat=store.lat,
        lng=store.lng,
    )


@router.get("/stores/{store_id}/breakdown", response_model=RatingBreakdownOut)
def get_store_breakdown(store_id: str, db: Session = Depends(get_db)):
    # 지점 점수 분해 정보를 반환한다.
    aggregate = store_service.get_store_breakdown(db, store_id)
    if aggregate is None:
        raise HTTPException(status_code=404, detail="Store not found")
    scores = _scores_from_snapshot(aggregate.scores_json)

    return RatingBreakdownOut(
        scores=scores,
        overall=compute_overall(scores, fallback=aggregate.rating),
    )


@router.get("/stores/{store_id}/reviews", response_model=list[ReviewOut])
def get_store_reviews(store_id: str, db: Session = Depends(get_db)):
    # 지점 리뷰 리스트를 반환한다.
    rows = store_service.get_store_reviews(db, store_id)
    return [
        ReviewOut(
            id=review.id,
            storeName=store_name,
            brandName=brand_name,
            menuName=menu_name,
            menuCategory=menu_category,
            scores=_scores_from_snapshot(review.scores_json),
            overall=review.overall,
            comment=review.comment,
            userEmail=user_email or "",
            imageUrls=_image_urls_from_snapshot(review.image_urls_json),
            createdAt=review.created_at,
        )
        for review, store_name, brand_name, menu_name, menu_category, user_email in rows
    ]


@router.get("/reviews/me", response_model=list[ReviewOut])
def get_my_reviews(
    auth_user: AuthUser = Depends(_require_auth_user),
    db: Session = Depends(get_db),
):
    # 내 리뷰 리스트를 반환한다.
    rows = review_service.get_my_reviews(db, auth_user.uid)
    return [
        ReviewOut(
            id=review.id,
            storeName=store_name,
            brandName=brand_name,
            menuName=menu_name,
            menuCategory=menu_category,
            scores=_scores_from_snapshot(review.scores_json),
            overall=review.overall,
            comment=review.comment,
            userEmail=user_email or "",
            imageUrls=_image_urls_from_snapshot(review.image_urls_json),
            createdAt=review.created_at,
        )
        for review, store_name, brand_name, menu_name, menu_category, user_email in rows
    ]


@router.get("/reviews/{review_id}", response_model=ReviewOut)
def get_review(review_id: str, db: Session = Depends(get_db)):
    # 리뷰 상세 정보를 반환한다.
    row = review_service.get_review(db, review_id)
    if row is None:
        raise HTTPException(status_code=404, detail="Review not found")
    review, store_name, brand_name, menu_name, menu_category, user_email = row
    return ReviewOut(
        id=review.id,
        storeName=store_name,
        brandName=brand_name,
        menuName=menu_name,
        menuCategory=menu_category,
        scores=_scores_from_snapshot(review.scores_json),
        overall=review.overall,
        comment=review.comment,
        userEmail=user_email or "",
        imageUrls=_image_urls_from_snapshot(review.image_urls_json),
        createdAt=review.created_at,
    )


@router.post("/reviews", response_model=ReviewOut)
def create_review(
    payload: ReviewCreateIn,
    auth_user: AuthUser = Depends(_require_auth_user),
    db: Session = Depends(get_db),
):
    # 리뷰를 생성하고 반환한다.
    user = get_user(db, auth_user.uid)
    if user is None:
        raise HTTPException(status_code=401, detail="User session not initialized")
    try:
        review, store_name, brand_name, menu_name = review_service.create_review(
            db,
            payload,
            auth_user.uid,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    menu = db.get(Menu, review.menu_id)
    menu_category = menu.category if menu is not None else "후라이드"

    return ReviewOut(
        id=review.id,
        storeName=store_name,
        brandName=brand_name,
        menuName=menu_name,
        menuCategory=menu_category,
        scores=_scores_from_snapshot(review.scores_json),
        overall=review.overall,
        comment=review.comment,
        userEmail=user.email or "",
        imageUrls=_image_urls_from_snapshot(review.image_urls_json),
        createdAt=review.created_at,
    )


@router.post("/uploads/review-images/presign", response_model=ReviewImagePresignOut)
def presign_review_image_upload(
    payload: ReviewImagePresignIn,
    auth_user: AuthUser = Depends(_require_auth_user),
):
    # 리뷰 이미지 업로드용 presigned URL을 발급한다.
    logger.info(
        "Presign request: user_id=%s file_name=%s content_type=%s",
        auth_user.uid,
        payload.fileName,
        payload.contentType,
    )
    try:
        upload_url, file_url = upload_service.issue_review_image_upload_url(
            user_id=auth_user.uid,
            file_name=payload.fileName,
            content_type=payload.contentType,
        )
    except ValueError as exc:
        logger.warning(
            "Presign rejected: user_id=%s file_name=%s content_type=%s error=%s",
            auth_user.uid,
            payload.fileName,
            payload.contentType,
            str(exc),
        )
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        logger.exception(
            "Presign failed: user_id=%s file_name=%s content_type=%s error=%s",
            auth_user.uid,
            payload.fileName,
            payload.contentType,
            str(exc),
        )
        raise HTTPException(status_code=500, detail="Failed to issue upload URL") from exc
    logger.info(
        "Presign success: user_id=%s file_name=%s file_url=%s",
        auth_user.uid,
        payload.fileName,
        file_url,
    )
    return ReviewImagePresignOut(uploadUrl=upload_url, fileUrl=file_url)


@router.get("/places/search", response_model=list[PlaceSearchOut])
def search_places(query: str, display: int = 5):
    # 네이버 지역 검색 API를 통해 치킨집을 조회한다.
    return place_search_service.search_places(query=query, display=display)


@router.get("/brands", response_model=list[BrandOut])
def list_brands(db: Session = Depends(get_db)):
    # 브랜드 목록을 반환한다.
    brands = brand_service.get_brands(db)
    return [
        BrandOut(id=brand.id, name=brand.name, logoUrl=brand.logo_url)
        for brand in brands
    ]


@router.get("/brands/{brand_id}/menus", response_model=list[MenuOut])
def list_brand_menus(brand_id: str, query: str | None = None, db: Session = Depends(get_db)):
    # 브랜드별 메뉴 목록을 반환한다.
    menus = brand_menu_service.get_menus_by_brand(db, brand_id, query)
    return [
        MenuOut(
            id=menu.id,
            brandId=menu.brand_id,
            name=menu.name,
            imageUrl=menu.image_url,
            category=menu.category,
        )
        for menu in menus
    ]
