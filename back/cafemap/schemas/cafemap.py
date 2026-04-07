from datetime import datetime
from pydantic import BaseModel, Field


# API 응답 스키마를 정의하는 모듈이다.


class BrandMenuRankingOut(BaseModel):
    # 랭킹 리스트 응답 모델이다.
    id: str
    brandId: str
    menuId: str
    brandName: str
    menuName: str
    category: str
    rating: float
    reviewCount: int
    highlightScoreA: float
    highlightLabelA: str
    highlightScoreB: float
    highlightLabelB: str
    imageUrl: str
    brandLogoUrl: str


class StoreSummaryOut(BaseModel):
    # 지점 요약 응답 모델이다.
    id: str
    name: str
    brandName: str
    address: str
    rating: float
    reviewCount: int
    distanceKm: float
    imageUrl: str
    lat: float
    lng: float


class RatingBreakdownOut(BaseModel):
    # 점수 분해 응답 모델이다.
    scores: dict[str, float] = Field(default_factory=dict)
    overall: float


class ReviewOut(BaseModel):
    # 리뷰 응답 모델이다.
    id: str
    storeName: str
    brandName: str
    menuName: str
    menuCategory: str
    scores: dict[str, float] = Field(default_factory=dict)
    overall: float
    comment: str
    userEmail: str = ""
    imageUrls: list[str] = Field(default_factory=list)
    createdAt: datetime


class PlaceSearchOut(BaseModel):
    # 네이버 지역 검색 결과 응답 모델이다.
    name: str
    address: str
    roadAddress: str
    category: str
    phone: str
    link: str
    mapx: int
    mapy: int


class BrandOut(BaseModel):
    # 브랜드 응답 모델이다.
    id: str
    name: str
    logoUrl: str


class MenuOut(BaseModel):
    # 메뉴 응답 모델이다.
    id: str
    brandId: str
    name: str
    imageUrl: str
    category: str


class ReviewCreateIn(BaseModel):
    # 리뷰 생성 요청 모델이다.
    storeName: str
    address: str
    brandId: str
    menuName: str
    scores: dict[str, float] = Field(default_factory=dict)
    overall: float = 0.0
    comment: str
    imageUrls: list[str] = Field(default_factory=list)


class ReviewImagePresignIn(BaseModel):
    # 리뷰 이미지 업로드용 presigned URL 요청 모델이다.
    fileName: str
    contentType: str = "image/jpeg"


class ReviewImagePresignOut(BaseModel):
    # 리뷰 이미지 업로드용 presigned URL 응답 모델이다.
    uploadUrl: str
    fileUrl: str


class AuthOut(BaseModel):
    # 인증 사용자 응답 모델이다.
    uid: str
    email: str
    name: str
    picture: str
    provider: str
