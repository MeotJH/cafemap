from contextlib import asynccontextmanager
from pathlib import Path

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

load_dotenv(dotenv_path=Path(__file__).with_name(".env"))

from cafemap.api.router import router as cafemap_router
from cafemap.db.init_db import init_db


@asynccontextmanager
async def lifespan(app: FastAPI):
    # 앱 시작 시 카페맵 SQLite와 목업 데이터를 초기화한다.
    init_db()
    yield


app = FastAPI(title="Qwen Text2Image API", version="1.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["POST", "GET", "OPTIONS", "PATCH", "DELETE", "PUT"],
    allow_headers=["*"],
)

# /api prefix 아래에 실제 라우트 등록
app.include_router(router=cafemap_router)
static_dir = Path(__file__).with_name("static")
static_dir.mkdir(parents=True, exist_ok=True)
app.mount("/static", StaticFiles(directory=static_dir), name="static")

# if __name__ == "__main__" and os.getenv("ENV") != "lambda":
#     import uvicorn
#     uvicorn.run("main:app", host="0.0.0.0", port=8080, reload=True)
