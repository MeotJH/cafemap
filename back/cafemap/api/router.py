from fastapi import APIRouter

from cafemap.api.routes.auth import router as auth_router
from cafemap.api.routes.catalog import router as catalog_router
from cafemap.api.routes.rankings import router as rankings_router
from cafemap.api.routes.reviews import router as reviews_router
from cafemap.api.routes.stores import router as stores_router
from cafemap.api.routes.uploads import router as uploads_router

router = APIRouter(prefix="/api/cafemap", tags=["cafemap"])
router.include_router(auth_router)
router.include_router(rankings_router)
router.include_router(stores_router)
router.include_router(reviews_router)
router.include_router(uploads_router)
router.include_router(catalog_router)
