from pathlib import Path
import os


# ???¤ì ??ëª¨ì?ë ëª¨ë?´ë¤.

BACK_DIR = Path(__file__).resolve().parents[2]
DATA_DIR = BACK_DIR / "data"
DATA_DIR.mkdir(parents=True, exist_ok=True)


def _default_sqlite_url() -> str:
    # ë¡ì»¬ SQLite ?ì¼ ê²½ë¡ë¥?SQLAlchemy URLë¡?ë³?í??
    db_path = (DATA_DIR / "cafemap.db").resolve().as_posix()
    return f"sqlite:///{db_path}"


DB_URL = os.getenv("cafemap_DB_URL", _default_sqlite_url())
SEED_ON_STARTUP = os.getenv("CAFEMAP_SEED_ON_STARTUP", "true").lower() in {
    "1",
    "true",
    "yes",
    "on",
}

AWS_REGION = os.getenv("AWS_REGION", "ap-northeast-2")
S3_BUCKET = os.getenv("S3_BUCKET", "")
S3_REVIEW_IMAGE_PREFIX = os.getenv("S3_REVIEW_IMAGE_PREFIX", "review-images")
S3_PRESIGNED_EXPIRES_SECONDS = int(os.getenv("S3_PRESIGNED_EXPIRES_SECONDS", "600"))
S3_PUBLIC_BASE_URL = os.getenv("S3_PUBLIC_BASE_URL", "")
S3_ENDPOINT_URL = os.getenv("S3_ENDPOINT_URL", f"https://s3.{AWS_REGION}.amazonaws.com")

