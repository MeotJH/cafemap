import json
from urllib.parse import quote

import logging



from fastapi import APIRouter, Depends, Header, HTTPException, Query, Request
from fastapi.responses import FileResponse

from sqlalchemy.orm import Session



from cafemap.db.session import get_db

from cafemap.models.entities import Menu

from cafemap.core.rating_dimensions import (
    compute_overall,
    scores_json_loads,
    top_highlights,
    visible_scores_for_category,
)

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

  HomeRecommendedMenuOut,
  HomeSummaryOut,

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
    thumbnail_service,

)





# ??? API ????.



router = APIRouter(prefix="/api/cafemap", tags=["cafemap"])

logger = logging.getLogger(__name__)





def _public_base_url(request: Request) -> str:

    forwarded_proto = (request.headers.get("x-forwarded-proto") or "").split(",")[0].strip()
    forwarded_host = (request.headers.get("x-forwarded-host") or "").split(",")[0].strip()
    request_base_url = str(request.base_url).rstrip("/")
    if forwarded_proto and forwarded_host:
        return f"{forwarded_proto}://{forwarded_host}"
    return request_base_url


def _resolve_asset_url(request: Request, raw_url: str | None) -> str:

    value = (raw_url or "").strip()
    forwarded_proto = (request.headers.get("x-forwarded-proto") or "").split(",")[0].strip()
    base_url = _public_base_url(request)
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


def _resolve_thumbnail_url(
    request: Request,
    raw_url: str | None,
    *,
    width: int = 160,
    height: int = 160,
) -> str:
    resolved = _resolve_asset_url(request, raw_url)
    if not resolved:
        return ""
    lowered = resolved.lower()
    if lowered.endswith(".svg"):
        return resolved
    if not upload_service.is_review_image_public_url(resolved):
        return resolved

    encoded_src = quote(resolved, safe="")
    return (
        f"{_public_base_url(request)}/api/cafemap/assets/thumbnail"
        f"?src={encoded_src}&w={width}&h={height}"
    )


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


def _menu_highlights(category: str | None, raw_scores: str | None) -> list[tuple[str, float]]:

    scores = _scores_from_snapshot(raw_scores)
    visible_scores = visible_scores_for_category(category, scores)
    return top_highlights(visible_scores)


def _ranking_out(
    *,
    request: Request,
    aggregate,
    brand_name: str,
    brand_logo_url: str,
    menu_name: str,
    menu_category: str,
    menu_image_url: str,
) -> BrandMenuRankingOut:

    highlights = _menu_highlights(menu_category, aggregate.scores_json)
    return BrandMenuRankingOut(
        id=aggregate.id,
        brandId=aggregate.brand_id,
        menuId=aggregate.menu_id,
        brandName=brand_name,
        menuName=menu_name,
        category=menu_category,
        rating=aggregate.rating,
        reviewCount=aggregate.review_count,
        highlightScoreA=highlights[0][1],
        highlightLabelA=highlights[0][0],
        highlightScoreB=highlights[1][1],
        highlightLabelB=highlights[1][0],
        imageUrl=menu_image_url,
        brandLogoUrl=_resolve_asset_url(request, brand_logo_url),
    )





def _store_ranking_out(request: Request, item: dict) -> StoreRankingOut:
    image_url = _resolve_store_image_url(request, item["imageUrl"])
    image_urls = [
        _resolve_asset_url(request, url)
        for url in item.get("imageUrls", [])
        if isinstance(url, str) and url.strip()
    ]
    return StoreRankingOut(
        id=item["id"],
        storeId=item["storeId"],
        storeName=item["storeName"],
        brandName=item["brandName"],
        district=item.get("district", ""),
        storeType=item["storeType"],
        isLocal=bool(item["isLocal"]),
        link=item["link"],
        rating=float(item["rating"]),
        displayScore=float(item["displayScore"]),
        reviewCount=int(item["reviewCount"]),
        distanceKm=float(item["distanceKm"]),
        imageUrl=image_url,
        thumbnailImageUrl=_resolve_thumbnail_url(request, item["imageUrl"]),
        imageUrls=image_urls,
        thumbnailImageUrls=[
            _resolve_thumbnail_url(request, url)
            for url in item.get("imageUrls", [])
            if isinstance(url, str) and url.strip()
        ],
        lat=float(item["lat"]),
        lng=float(item["lng"]),
        coffeeQualityScore=float(item["coffeeQualityScore"]),
        topLabelA=item["topLabelA"],
        topScoreA=float(item["topScoreA"]),
        topLabelB=item["topLabelB"],
        topScoreB=float(item["topScoreB"]),
        workFriendlyScore=float(item["workFriendlyScore"]),
        quietnessScore=float(item["quietnessScore"]),
        dessertScore=float(item["dessertScore"]),
        coupleScore=float(item["coupleScore"]),
        wifeScore=float(item["wifeScore"]),
        husbandScore=float(item["husbandScore"]),
        userScore=float(item["userScore"]),
        revisitScore=float(item["revisitScore"]),
        summary=item["summary"],
        tags=list(item["tags"]),
        latestVisitedAt=item["latestVisitedAt"],
    )


def _review_out(
    *,
    review,
    store_name: str,
    store_address: str = "",
    place_id: str = "",
    store_link: str,
    lat: float | None = None,
    lng: float | None = None,
    brand_name: str,
    brand_id: str = "",
    menu_name: str,
    menu_category: str,
    user_email: str | None,
) -> ReviewOut:
    return ReviewOut(
        id=review.id,
        storeName=store_name,
        address=store_address,
        placeId=place_id,
        link=store_link,
        lat=lat,
        lng=lng,
        temperatureOption=review.temperature_option,
        brandId=brand_id,
        brandName=brand_name,
        menuName=menu_name,
        menuCategory=menu_category,
        reviewerType=(getattr(review, "reviewer_type", None) or "USER"),
        scores=_scores_from_snapshot(review.scores_json),
        overall=review.overall,
        comment=review.comment,
        userEmail=user_email or "",
        imageUrls=_image_urls_from_snapshot(review.image_urls_json),
        createdAt=review.created_at,
    )


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
        _ranking_out(
            request=request,
            aggregate=aggregate,
            brand_name=brand_name,
            brand_logo_url=brand_logo_url,
            menu_name=menu_name,
            menu_category=menu_category,
            menu_image_url=menu_image_url,
        )

        for aggregate, brand_name, brand_logo_url, menu_name, menu_category, menu_image_url in rows

    ]





@router.get("/rankings/{ranking_id}/breakdown", response_model=RatingBreakdownOut)

def get_ranking_breakdown(ranking_id: str, db: Session = Depends(get_db)):

    # ?? ?? ?? ?? ??? ????.

    aggregate = brand_menu_service.get_ranking_breakdown(db, ranking_id)

    if aggregate is None:

        raise HTTPException(status_code=404, detail="Ranking not found")

    menu = db.get(Menu, aggregate.menu_id)
    scores = visible_scores_for_category(
        menu.category if menu is not None else None,
        _scores_from_snapshot(aggregate.scores_json),
    )



    return RatingBreakdownOut(

        scores=scores,

        overall=aggregate.rating,

    )





@router.get("/rankings/{ranking_id}/reviews", response_model=list[ReviewOut])

def get_ranking_reviews(ranking_id: str, db: Session = Depends(get_db)):

    # ?? ?? ?? ??? ????.

    rows = brand_menu_service.get_ranking_reviews(db, ranking_id)

    return [

        _review_out(
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

            link=store.link,

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


@router.get("/home", response_model=HomeSummaryOut)
def get_home_summary(request: Request, db: Session = Depends(get_db)):
    payload = store_service.get_home_summary(db)
    return HomeSummaryOut(
        featuredCafe=_store_ranking_out(request, payload["featuredCafe"])
        if payload["featuredCafe"] is not None
        else None,
        wifeTop=[_store_ranking_out(request, item) for item in payload["wifeTop"]],
        husbandTop=[
            _store_ranking_out(request, item) for item in payload["husbandTop"]
        ],
        recentCafes=[
            _store_ranking_out(request, item) for item in payload["recentCafes"]
        ],
        recommendedMenus=[
            HomeRecommendedMenuOut(
                menuName=item.menu_name,
                storeName=item.store_name,
                score=item.average_score,
            )
            for item in payload["recommendedMenus"]
        ],
    )


@router.get("/store-rankings", response_model=list[StoreRankingOut])

def list_store_rankings(
    request: Request,
    type: str = "couple",
    db: Session = Depends(get_db),
):

    rows = store_service.get_store_rankings(db, ranking_type=type)

    return [

        _store_ranking_out(request, segmented_item)

        for _, _, _, _, _, _, _, _, _, _, segmented_item in rows

    ]


@router.get("/assets/thumbnail")
def get_thumbnail_asset(
    src: str = Query(..., min_length=1),
    w: int = Query(160, ge=32, le=512),
    h: int = Query(160, ge=32, le=512),
):
    if not upload_service.is_review_image_public_url(src):
        raise HTTPException(status_code=400, detail="Unsupported thumbnail source")

    try:
        thumbnail_path = thumbnail_service.get_or_create_thumbnail(
            source_url=src,
            width=w,
            height=h,
        )
    except thumbnail_service.ThumbnailError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc

    return FileResponse(
        thumbnail_path,
        media_type="image/jpeg",
        headers={"Cache-Control": "public, max-age=31536000, immutable"},
    )





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

        link=store.link,

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

        _review_out(
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

    auth_user: AuthUser = Depends(_require_auth_user),

    db: Session = Depends(get_db),

):

    # ? ?? ??? ????.

    rows = review_service.get_my_reviews(db, auth_user.uid)

    return [

        _review_out(
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

def get_review(review_id: str, db: Session = Depends(get_db)):

    # ?? ?? ??? ????.

    row = review_service.get_review(db, review_id)

    if row is None:

        raise HTTPException(status_code=404, detail="Review not found")

    review, store, brand_name, menu_name, menu_category, user_email = row

    return _review_out(
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

        review, store_name, store_link, brand_name, menu_name = review_service.create_review(

            db,

            payload,

            auth_user.uid,

        )

    except ValueError as exc:

        raise HTTPException(status_code=400, detail=str(exc)) from exc

    menu = db.get(Menu, review.menu_id)

    menu_category = menu.category if menu is not None else "?ë¼?´ë"



    return _review_out(
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
    payload: ReviewCreateIn,
    auth_user: AuthUser = Depends(_require_auth_user),
    db: Session = Depends(get_db),
):
    # 저장은 서비스에 위임하고, 응답은 수정 후 최신 상세 형태로 다시 조립해 내려준다.

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
    return _review_out(
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
