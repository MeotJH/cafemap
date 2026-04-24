import json

import logging



from fastapi import APIRouter, Depends, Header, HTTPException, Request

from sqlalchemy.orm import Session



from cafemap.db.session import get_db

from cafemap.models.entities import Menu

from cafemap.core.rating_dimensions import compute_overall, scores_json_loads, top_highlights

from cafemap.services.auth_service import (

    resolve_auth_user,

    upsert_user,

    get_user,

    AuthUser,

)

from cafemap.schemas.cafemap import (

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
  StoreRankingOut,

  PlaceSearchOut,

)

from cafemap.services import (

    brand_menu_service,

    store_service,

    review_service,

    place_search_service,

    brand_service,

    upload_service,

)





# ??? API ????.



router = APIRouter(prefix="/api/cafemap", tags=["cafemap"])

logger = logging.getLogger(__name__)





def _resolve_asset_url(request: Request, raw_url: str | None) -> str:

    value = (raw_url or "").strip()
    forwarded_proto = (request.headers.get("x-forwarded-proto") or "").split(",")[0].strip()
    forwarded_host = (request.headers.get("x-forwarded-host") or "").split(",")[0].strip()
    request_base_url = str(request.base_url).rstrip("/")
    if forwarded_proto and forwarded_host:
        base_url = f"{forwarded_proto}://{forwarded_host}"
    else:
        base_url = request_base_url
    if not value:
        return ""
    if value.startswith(("http://", "https://")):
        return value
    if value.startswith("//"):
        scheme = forwarded_proto or request.url.scheme
        return f"{scheme}:{value}"
    if value.startswith("/"):
        return f"{base_url}{value}"
    return f"{base_url}/{value.lstrip('/')}"


def _resolve_store_image_url(request: Request, brand_logo_url: str | None) -> str:

    # ??? ??? ??? ??? ?? ???? ??? ? ???? ????.

    return _resolve_asset_url(request, brand_logo_url)


def _store_type_for_response(store) -> str:
    return (getattr(store, "store_type", None) or "unknown").strip() or "unknown"


def _is_local_store(store) -> bool:
    store_type = _store_type_for_response(store)
    return store_type == "local" or getattr(store, "brand_id", "") == "brand-local"


def _store_signal(scores: dict[str, float], key: str) -> float:
    return float(scores.get(key, 0.0))


def _dessert_signal(scores: dict[str, float]) -> float:
    values = [
        scores.get("flavor_balance"),
        scores.get("sweetness"),
        scores.get("visuals"),
        scores.get("portion"),
    ]
    parsed = [float(value) for value in values if value is not None]
    if not parsed:
        return 0.0
    return sum(parsed) / len(parsed)


def _display_score_for_store(aggregate) -> float:
    return store_service.confidence_weighted_score(
        rating=aggregate.rating,
        review_count=aggregate.review_count,
    )





def _scores_from_snapshot(

    scores_json: str | None,

) -> dict[str, float]:

    # `scores_json` ???? ???? ??????.

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

    # ??? ???? ????? ????.

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

def list_rankings(request: Request, db: Session = Depends(get_db)):

    # ??? ?? ?? ???? ????.

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

            brandLogoUrl=_resolve_asset_url(request, brand_logo_url),

        )

        for aggregate, brand_name, brand_logo_url, menu_name, menu_category, menu_image_url in rows

    ]





@router.get("/rankings/{ranking_id}/breakdown", response_model=RatingBreakdownOut)

def get_ranking_breakdown(ranking_id: str, db: Session = Depends(get_db)):

    # ?? ?? ?? ?? ??? ????.

    aggregate = brand_menu_service.get_ranking_breakdown(db, ranking_id)

    if aggregate is None:

        raise HTTPException(status_code=404, detail="Ranking not found")

    scores = _scores_from_snapshot(aggregate.scores_json)



    return RatingBreakdownOut(

        scores=scores,

        overall=aggregate.rating,

    )





@router.get("/rankings/{ranking_id}/reviews", response_model=list[ReviewOut])

def get_ranking_reviews(ranking_id: str, db: Session = Depends(get_db)):

    # ?? ?? ?? ??? ????.

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

def list_stores(request: Request, db: Session = Depends(get_db)):

    # ?? ?? ???? ????.

    rows = store_service.get_nearby_stores(db)

    return [

        StoreSummaryOut(

            id=store.id,

            name=store.name,

            brandName=brand_name,

            storeType=_store_type_for_response(store),

            isLocal=_is_local_store(store),

            address=store.address,

            rating=aggregate.rating,

            displayScore=_display_score_for_store(aggregate),

            reviewCount=aggregate.review_count,

            distanceKm=store.distance_km,

            imageUrl=_resolve_store_image_url(request, brand_logo_url),

            lat=store.lat,

            lng=store.lng,

            coffeeQualityScore=_store_signal(_scores_from_snapshot(aggregate.scores_json), "coffee_quality"),

            workFriendlyScore=_store_signal(_scores_from_snapshot(aggregate.scores_json), "work_friendly"),

            quietnessScore=_store_signal(_scores_from_snapshot(aggregate.scores_json), "quietness"),

            dessertScore=_dessert_signal(_scores_from_snapshot(aggregate.scores_json)),

            topLabelA=top_highlights(_scores_from_snapshot(aggregate.scores_json))[0][0],

            topScoreA=top_highlights(_scores_from_snapshot(aggregate.scores_json))[0][1],

            topLabelB=top_highlights(_scores_from_snapshot(aggregate.scores_json))[1][0],

            topScoreB=top_highlights(_scores_from_snapshot(aggregate.scores_json))[1][1],

        )

        for store, aggregate, brand_name, brand_logo_url in rows

    ]


@router.get("/store-rankings", response_model=list[StoreRankingOut])

def list_store_rankings(request: Request, db: Session = Depends(get_db)):

    rows = store_service.get_store_rankings(db)

    return [

        StoreRankingOut(

            id=store.id,

            storeId=store.id,

            storeName=store.name,

            brandName=brand_name,

            storeType=_store_type_for_response(store),

            isLocal=_is_local_store(store),

            rating=aggregate.rating,

            displayScore=display_score,

            reviewCount=aggregate.review_count,

            distanceKm=store.distance_km,

            imageUrl=_resolve_store_image_url(request, brand_logo_url),

            lat=store.lat,

            lng=store.lng,

            topLabelA=highlights[0][0],

            topScoreA=highlights[0][1],

            topLabelB=highlights[1][0],

            topScoreB=highlights[1][1],

            coffeeQualityScore=_store_signal(_scores_from_snapshot(aggregate.scores_json), "coffee_quality"),

            workFriendlyScore=_store_signal(_scores_from_snapshot(aggregate.scores_json), "work_friendly"),

            quietnessScore=_store_signal(_scores_from_snapshot(aggregate.scores_json), "quietness"),

            dessertScore=_dessert_signal(_scores_from_snapshot(aggregate.scores_json)),

        )

        for display_score, _, store, aggregate, brand_name, brand_logo_url, highlights in rows

    ]





@router.get("/stores/{store_id}", response_model=StoreSummaryOut)

def get_store_detail(store_id: str, request: Request, db: Session = Depends(get_db)):

    # ?? ?? ??? ????.

    row = store_service.get_store_detail(db, store_id)

    if row is None:

        raise HTTPException(status_code=404, detail="Store not found")

    store, aggregate, brand_name, brand_logo_url = row

    return StoreSummaryOut(

        id=store.id,

        name=store.name,

        brandName=brand_name,

        storeType=_store_type_for_response(store),

        isLocal=_is_local_store(store),

        address=store.address,

        rating=aggregate.rating,

        displayScore=_display_score_for_store(aggregate),

        reviewCount=aggregate.review_count,

        distanceKm=store.distance_km,

        imageUrl=_resolve_store_image_url(request, brand_logo_url),

        lat=store.lat,

        lng=store.lng,

        coffeeQualityScore=_store_signal(_scores_from_snapshot(aggregate.scores_json), "coffee_quality"),

        workFriendlyScore=_store_signal(_scores_from_snapshot(aggregate.scores_json), "work_friendly"),

        quietnessScore=_store_signal(_scores_from_snapshot(aggregate.scores_json), "quietness"),

        dessertScore=_dessert_signal(_scores_from_snapshot(aggregate.scores_json)),

        topLabelA=top_highlights(_scores_from_snapshot(aggregate.scores_json))[0][0],

        topScoreA=top_highlights(_scores_from_snapshot(aggregate.scores_json))[0][1],

        topLabelB=top_highlights(_scores_from_snapshot(aggregate.scores_json))[1][0],

        topScoreB=top_highlights(_scores_from_snapshot(aggregate.scores_json))[1][1],

    )





@router.get("/stores/{store_id}/breakdown", response_model=RatingBreakdownOut)

def get_store_breakdown(store_id: str, db: Session = Depends(get_db)):

    # ?? ?? ?? ??? ????.

    aggregate = store_service.get_store_breakdown(db, store_id)

    if aggregate is None:

        raise HTTPException(status_code=404, detail="Store not found")

    scores = _scores_from_snapshot(aggregate.scores_json)



    return RatingBreakdownOut(

        scores=scores,

        overall=aggregate.rating,

    )





@router.get("/stores/{store_id}/reviews", response_model=list[ReviewOut])

def get_store_reviews(store_id: str, db: Session = Depends(get_db)):

    # ?? ?? ??? ????.

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

    # ? ?? ??? ????.

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

    # ?? ?? ??? ????.

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

    # ??? ???? ????.

    user = get_user(db, auth_user.uid)
    if user is None:
        user = upsert_user(db, auth_user)
        db.flush()

    try:

        review, store_name, brand_name, menu_name = review_service.create_review(

            db,

            payload,

            auth_user.uid,

        )

    except ValueError as exc:

        raise HTTPException(status_code=400, detail=str(exc)) from exc

    menu = db.get(Menu, review.menu_id)

    menu_category = menu.category if menu is not None else "?ë¼?´ë"



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

    # ?? ??? ???? presigned URL? ????.

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
def search_places(
    query: str,
    display: int = 5,
    lat: float | None = None,
    lng: float | None = None,
    radiusKm: float | None = None,
    pages: int | None = None,
    southLat: float | None = None,
    westLng: float | None = None,
    northLat: float | None = None,
    eastLng: float | None = None,
):

    # ??? ?? ?? API? ?? ??? ????.

    return place_search_service.search_places(
        query=query,
        display=display,
        lat=lat,
        lng=lng,
        radius_km=radiusKm,
        pages=pages,
        south_lat=southLat,
        west_lng=westLng,
        north_lat=northLat,
        east_lng=eastLng,
    )





@router.get("/brands", response_model=list[BrandOut])

def list_brands(request: Request, db: Session = Depends(get_db)):

    # ??? ??? ????.

    brands = brand_service.get_brands(db)

    return [

        BrandOut(
            id=brand.id,
            name=brand.name,
            logoUrl=_resolve_asset_url(request, brand.logo_url),
        )

        for brand in brands

    ]





@router.get("/brands/{brand_id}/menus", response_model=list[MenuOut])

def list_brand_menus(brand_id: str, query: str | None = None, db: Session = Depends(get_db)):

    # ???? ?? ??? ????.

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
