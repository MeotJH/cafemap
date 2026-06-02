from fastapi import APIRouter, Depends, HTTPException, Query, Request
from fastapi.responses import FileResponse, RedirectResponse
from sqlalchemy.orm import Session

from cafemap.api.presenters.store_presenter import (
    to_home_summary_out,
    to_similar_store_out,
    to_store_ranking_out,
    to_store_summary_out,
    to_store_visit_media_page_out,
)
from cafemap.db.session import get_db
from cafemap.schemas.cafemap import (
    HomeSummaryOut,
    RatingBreakdownOut,
    SimilarStoreOut,
    StoreRankingOut,
    StoreSummaryOut,
    StoreVisitMediaPageOut,
)
from cafemap.services import store_service, thumbnail_service, upload_service

router = APIRouter()


@router.get("/stores", response_model=list[StoreSummaryOut])
def list_stores(request: Request, db: Session = Depends(get_db)):
    rows = store_service.get_nearby_stores(db)
    return [
        to_store_summary_out(
            request=request,
            store=store,
            aggregate=aggregate,
            brand_name=brand_name,
            brand_logo_url=brand_logo_url,
        )
        for store, aggregate, brand_name, brand_logo_url in rows
    ]


@router.get("/home", response_model=HomeSummaryOut)
def get_home_summary(request: Request, db: Session = Depends(get_db)):
    return to_home_summary_out(request, store_service.get_home_summary(db))


@router.get("/store-rankings", response_model=list[StoreRankingOut])
def list_store_rankings(
    request: Request,
    type: str = "couple",
    purpose: str | None = None,
    db: Session = Depends(get_db),
):
    rows = store_service.get_store_rankings(
        db,
        ranking_type=type,
        purpose=purpose,
    )
    return [
        to_store_ranking_out(request, segmented_item)
        for _, _, _, _, _, _, _, _, _, _, _, segmented_item in rows
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
        thumbnail_asset = thumbnail_service.get_or_create_thumbnail(
            source_url=src,
            width=w,
            height=h,
        )
    except thumbnail_service.ThumbnailError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc

    if thumbnail_asset.storage_key:
        try:
            download_url = upload_service.issue_public_download_url(
                key=thumbnail_asset.storage_key
            )
        except ValueError as exc:
            raise HTTPException(status_code=502, detail=str(exc)) from exc

        return RedirectResponse(
            download_url,
            headers={"Cache-Control": "public, max-age=31536000, immutable"},
        )

    return FileResponse(
        thumbnail_asset.local_path,
        media_type="image/jpeg",
        headers={"Cache-Control": "public, max-age=31536000, immutable"},
    )


@router.get("/stores/{store_id}", response_model=StoreSummaryOut)
def get_store_detail(store_id: str, request: Request, db: Session = Depends(get_db)):
    row = store_service.get_store_detail(db, store_id)
    if row is None:
        raise HTTPException(status_code=404, detail="Store not found")

    return to_store_summary_out(
        request=request,
        store=row.store,
        aggregate=row.aggregate,
        brand_name=row.brand_name,
        brand_logo_url=row.brand_logo_url,
        visit_media_items=row.visit_media_items,
        has_visit_media_more=row.has_visit_media_more,
        visit_media_next_cursor=row.visit_media_next_cursor,
    )


@router.get("/stores/{store_id}/breakdown", response_model=RatingBreakdownOut)
def get_store_breakdown(store_id: str, db: Session = Depends(get_db)):
    aggregate = store_service.get_store_breakdown(db, store_id)
    if aggregate is None:
        raise HTTPException(status_code=404, detail="Store not found")

    return RatingBreakdownOut(
        scores=aggregate.scores,
        overall=aggregate.overall,
        ratingSchemaVersion=aggregate.rating_schema_version,
        reviewCount=aggregate.review_count,
    )


@router.get("/stores/{store_id}/visit-media", response_model=StoreVisitMediaPageOut)
def get_store_visit_media(
    store_id: str,
    request: Request,
    cursor: str | None = Query(default=None),
    limit: int = Query(10, ge=1, le=50),
    db: Session = Depends(get_db),
):
    page = store_service.get_store_visit_media_page(
        db,
        store_id,
        limit=limit,
        cursor=cursor,
    )
    return to_store_visit_media_page_out(request, page)


@router.get("/stores/{store_id}/similar", response_model=list[SimilarStoreOut])
def get_similar_stores(store_id: str, db: Session = Depends(get_db)):
    rows = store_service.get_similar_stores(db, store_id)
    if rows is None:
        raise HTTPException(status_code=404, detail="Store not found")
    return [to_similar_store_out(item) for item in rows]
