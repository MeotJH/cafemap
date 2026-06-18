import logging

from fastapi import APIRouter, Depends, HTTPException

from cafemap.api.deps import require_auth_user
from cafemap.schemas.cafemap import ReviewImagePresignIn, ReviewImagePresignOut
from cafemap.services import upload_service

router = APIRouter()
logger = logging.getLogger(__name__)


@router.post("/uploads/review-images/presign", response_model=ReviewImagePresignOut)
def presign_review_image_upload(
    payload: ReviewImagePresignIn,
    auth_user=Depends(require_auth_user),
):
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
        raise HTTPException(
            status_code=500,
            detail="Failed to issue upload URL",
        ) from exc

    logger.info(
        "Presign success: user_id=%s file_name=%s file_url=%s",
        auth_user.uid,
        payload.fileName,
        file_url,
    )
    return ReviewImagePresignOut(uploadUrl=upload_url, fileUrl=file_url)
