from datetime import datetime

from pydantic import BaseModel, Field


class BrandMenuRankingOut(BaseModel):
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
    id: str
    name: str
    brandName: str
    storeType: str
    isLocal: bool
    address: str
    link: str = ""
    rating: float
    displayScore: float = 0.0
    reviewCount: int
    distanceKm: float
    imageUrl: str
    lat: float
    lng: float
    coffeeQualityScore: float = 0.0
    workFriendlyScore: float = 0.0
    quietnessScore: float = 0.0
    dessertScore: float = 0.0
    topLabelA: str = ""
    topScoreA: float = 0.0
    topLabelB: str = ""
    topScoreB: float = 0.0


class StoreRankingOut(BaseModel):
    id: str
    storeId: str
    storeName: str
    brandName: str
    district: str = ""
    storeType: str
    isLocal: bool
    link: str = ""
    rating: float
    displayScore: float
    reviewCount: int
    distanceKm: float
    imageUrl: str
    thumbnailImageUrl: str = ""
    imageUrls: list[str] = Field(default_factory=list)
    thumbnailImageUrls: list[str] = Field(default_factory=list)
    lat: float
    lng: float
    coffeeQualityScore: float = 0.0
    topLabelA: str
    topScoreA: float
    topLabelB: str
    topScoreB: float
    workFriendlyScore: float = 0.0
    quietnessScore: float = 0.0
    dessertScore: float = 0.0
    coupleScore: float = 0.0
    wifeScore: float = 0.0
    husbandScore: float = 0.0
    userScore: float = 0.0
    revisitScore: float = 0.0
    summary: str = ""
    tags: list[str] = Field(default_factory=list)
    latestVisitedAt: datetime | None = None


class HomeRecommendedMenuOut(BaseModel):
    menuName: str
    storeName: str
    score: float


class HomeSummaryOut(BaseModel):
    featuredCafe: StoreRankingOut | None = None
    wifeTop: list[StoreRankingOut] = Field(default_factory=list)
    husbandTop: list[StoreRankingOut] = Field(default_factory=list)
    recentCafes: list[StoreRankingOut] = Field(default_factory=list)
    recommendedMenus: list[HomeRecommendedMenuOut] = Field(default_factory=list)


class RatingBreakdownOut(BaseModel):
    scores: dict[str, float] = Field(default_factory=dict)
    overall: float


class ReviewOut(BaseModel):
    id: str
    storeName: str
    address: str = ""
    placeId: str = ""
    link: str = ""
    lat: float | None = None
    lng: float | None = None
    temperatureOption: str = ""
    brandId: str = ""
    brandName: str
    menuName: str
    menuCategory: str
    reviewerType: str = "USER"
    scores: dict[str, float] = Field(default_factory=dict)
    overall: float
    comment: str
    userEmail: str = ""
    imageUrls: list[str] = Field(default_factory=list)
    createdAt: datetime


class PlaceSearchOut(BaseModel):
    name: str
    address: str
    roadAddress: str
    category: str
    phone: str
    link: str
    placeId: str
    brandId: str = ""
    brandName: str = ""
    mapx: int
    mapy: int
    lat: float | None = None
    lng: float | None = None
    distanceKm: float | None = None


class BrandOut(BaseModel):
    id: str
    name: str
    logoUrl: str


class MenuOut(BaseModel):
    id: str
    brandId: str
    name: str
    imageUrl: str
    category: str


class ReviewCreateIn(BaseModel):
    storeName: str
    address: str
    placeId: str = ""
    link: str = ""
    temperatureOption: str = ""
    lat: float | None = None
    lng: float | None = None
    brandId: str
    menuName: str
    scores: dict[str, float] = Field(default_factory=dict)
    storeScores: dict[str, float] = Field(default_factory=dict)
    overall: float = 0.0
    comment: str
    imageUrls: list[str] = Field(default_factory=list)


class ReviewImagePresignIn(BaseModel):
    fileName: str
    contentType: str = "image/jpeg"


class ReviewImagePresignOut(BaseModel):
    uploadUrl: str
    fileUrl: str


class AuthOut(BaseModel):
    uid: str
    email: str
    name: str
    picture: str
    provider: str
