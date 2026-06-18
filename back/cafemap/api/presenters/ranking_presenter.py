from fastapi import Request

from cafemap.schemas.cafemap import BrandMenuRankingOut

from .media_presenter import resolve_asset_url
from .scoring_presenter import menu_highlights


def to_brand_menu_ranking_out(
    *,
    request: Request,
    aggregate,
    brand_name: str,
    brand_logo_url: str,
    menu_name: str,
    menu_category: str,
    menu_image_url: str,
) -> BrandMenuRankingOut:
    highlights = menu_highlights(menu_category, aggregate.scores_json)
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
        brandLogoUrl=resolve_asset_url(request, brand_logo_url),
    )
