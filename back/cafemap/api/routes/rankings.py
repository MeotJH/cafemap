from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session

from cafemap.api.presenters.ranking_presenter import to_brand_menu_ranking_out
from cafemap.api.presenters.review_presenter import to_review_out
from cafemap.api.presenters.scoring_presenter import scores_from_snapshot
from cafemap.core.rating_dimensions import visible_scores_for_category
from cafemap.db.session import get_db
from cafemap.models.entities import Menu
from cafemap.schemas.cafemap import BrandMenuRankingOut, RatingBreakdownOut, ReviewOut
from cafemap.services import brand_menu_service

router = APIRouter()


@router.get("/rankings", response_model=list[BrandMenuRankingOut])
def list_rankings(request: Request, db: Session = Depends(get_db)):
    rows = brand_menu_service.get_rankings(db)
    return [
        to_brand_menu_ranking_out(
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
    aggregate = brand_menu_service.get_ranking_breakdown(db, ranking_id)
    if aggregate is None:
        raise HTTPException(status_code=404, detail="Ranking not found")

    menu = db.get(Menu, aggregate.menu_id)
    scores = visible_scores_for_category(
        menu.category if menu is not None else None,
        scores_from_snapshot(aggregate.scores_json),
    )
    return RatingBreakdownOut(scores=scores, overall=aggregate.rating)


@router.get("/rankings/{ranking_id}/reviews", response_model=list[ReviewOut])
def get_ranking_reviews(
    ranking_id: str,
    request: Request,
    db: Session = Depends(get_db),
):
    rows = brand_menu_service.get_ranking_reviews(db, ranking_id)
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
