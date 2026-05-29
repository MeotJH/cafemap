import os
from pathlib import Path

BACK_DIR = Path(__file__).resolve().parents[2]
DATA_DIR = BACK_DIR / "data"
DATA_DIR.mkdir(parents=True, exist_ok=True)


def _default_sqlite_url() -> str:
    db_path = (DATA_DIR / "cafemap.db").resolve().as_posix()
    return f"sqlite:///{db_path}"


def _env_bool(name: str, default: bool) -> bool:
    raw = os.getenv(name)
    if raw is None:
        return default
    return raw.lower() in {"1", "true", "yes", "on"}


def _env_csv(name: str, default: str = "") -> tuple[str, ...]:
    raw = os.getenv(name, default)
    return tuple(item.strip() for item in raw.split(",") if item.strip())


DB_URL = os.getenv("cafemap_DB_URL", _default_sqlite_url())
SEED_CATALOG_ON_STARTUP = _env_bool("CAFEMAP_SEED_CATALOG_ON_STARTUP", True)
SEED_SAMPLE_DATA_ON_STARTUP = _env_bool(
    "CAFEMAP_SEED_SAMPLE_DATA",
    _env_bool("CAFEMAP_SEED_ON_STARTUP", True),
)

AWS_REGION = os.getenv("AWS_REGION", "ap-northeast-2")
S3_BUCKET = os.getenv("S3_BUCKET", "")
S3_REVIEW_IMAGE_PREFIX = os.getenv("S3_REVIEW_IMAGE_PREFIX", "review-images")
S3_PRESIGNED_EXPIRES_SECONDS = int(os.getenv("S3_PRESIGNED_EXPIRES_SECONDS", "600"))
S3_PUBLIC_BASE_URL = os.getenv("S3_PUBLIC_BASE_URL", "")
S3_ENDPOINT_URL = os.getenv("S3_ENDPOINT_URL", f"https://s3.{AWS_REGION}.amazonaws.com")
REVIEW_IMAGE_LIMIT = 5

OFFICIAL_WIFE_EMAILS = _env_csv(
    "CAFEMAP_OFFICIAL_WIFE_EMAILS",
    "sumdubu1234@gmail.com,sumin940104@gmail.com",
)
OFFICIAL_HUSBAND_EMAILS = _env_csv(
    "CAFEMAP_OFFICIAL_HUSBAND_EMAILS",
    "marionette934@gmail.com,businesskim93@gmail.com",
)
