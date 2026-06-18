from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from cafemap.api.presenters.media_presenter import resolve_asset_url
from cafemap.db.session import get_db
from cafemap.schemas.cafemap import BrandOut, MenuOut, PlaceSearchOut
from cafemap.services import brand_menu_service, brand_service, place_search_service

router = APIRouter()


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
    brands = brand_service.get_brands(db)
    return [
        BrandOut(
            id=brand.id,
            name=brand.name,
            logoUrl=resolve_asset_url(request, brand.logo_url),
        )
        for brand in brands
    ]


@router.get("/brands/{brand_id}/menus", response_model=list[MenuOut])
def list_brand_menus(
    brand_id: str,
    query: str | None = None,
    db: Session = Depends(get_db),
):
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
