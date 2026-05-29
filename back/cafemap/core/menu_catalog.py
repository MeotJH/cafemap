COMMON_CAFE_MENU_SEEDS: tuple[tuple[str, str], ...] = (
    ("아메리카노", "coffee"),
    ("디카페인 아메리카노", "coffee"),
    ("에스프레소", "coffee"),
    ("롱블랙", "coffee"),
    ("카페오레", "latte"),
    ("카페라떼", "latte"),
    ("바닐라 라떼", "latte"),
    ("헤이즐넛 라떼", "latte"),
    ("연유 라떼", "latte"),
    ("돌체 라떼", "latte"),
    ("흑당 라떼", "latte"),
    ("카푸치노", "latte"),
    ("카라멜 마끼아또", "latte"),
    ("모카 라떼", "latte"),
    ("카페모카", "latte"),
    ("화이트 모카", "latte"),
    ("아인슈페너", "coffee"),
    ("콜드브루", "cold_brew"),
    ("콜드브루 라떼", "latte"),
    ("디카페인 콜드브루", "cold_brew"),
    ("핸드드립", "hand_drip"),
    ("드립커피", "hand_drip"),
    ("시그니처 라떼", "coffee"),
    ("크림 라떼", "coffee"),
    ("슈페너 라떼", "coffee"),
    ("초코 라떼", "dessert"),
    ("녹차 라떼", "dessert"),
    ("말차 라떼", "dessert"),
    ("고구마 라떼", "dessert"),
    ("곡물 라떼", "dessert"),
    ("밀크티", "tea"),
    ("얼그레이 밀크티", "tea"),
    ("차이 밀크티", "tea"),
    ("아이스티", "tea"),
    ("복숭아 아이스티", "tea"),
    ("레몬티", "tea"),
    ("자몽티", "tea"),
    ("유자차", "tea"),
    ("캐모마일 티", "tea"),
    ("페퍼민트 티", "tea"),
    ("얼그레이 티", "tea"),
    ("녹차", "tea"),
    ("레몬에이드", "dessert"),
    ("자몽에이드", "dessert"),
    ("청포도에이드", "dessert"),
    ("블루레몬에이드", "dessert"),
    ("딸기 스무디", "dessert"),
    ("망고 스무디", "dessert"),
    ("블루베리 스무디", "dessert"),
    ("플레인 요거트 스무디", "dessert"),
    ("프라페", "dessert"),
    ("초코 프라페", "dessert"),
    ("쿠키 프라페", "dessert"),
)

TEA_MENU_NAMES = frozenset(
    {
        "밀크티",
        "얼그레이 밀크티",
        "차이 밀크티",
        "아이스티",
        "복숭아 아이스티",
        "레몬티",
        "자몽티",
        "유자차",
        "캐모마일 티",
        "페퍼민트 티",
        "얼그레이 티",
        "녹차",
    }
)

MENU_CATEGORY_ORDER = {
    "coffee": 0,
    "latte": 1,
    "cold_brew": 2,
    "hand_drip": 3,
    "tea": 4,
    "dessert": 5,
}

STANDARD_MENU_ORDER = {
    name: index for index, (name, _) in enumerate(COMMON_CAFE_MENU_SEEDS)
}


def classify_menu_category(name: str, category: str) -> str:
    normalized_name = name.strip()
    if normalized_name == "콜드브루 라떼":
        return "latte"
    if normalized_name in TEA_MENU_NAMES:
        return "tea"
    return category


def menu_sort_key(*, name: str, category: str) -> tuple[int, int, str]:
    normalized_name = name.strip()
    return (
        MENU_CATEGORY_ORDER.get(category, len(MENU_CATEGORY_ORDER)),
        STANDARD_MENU_ORDER.get(normalized_name, len(STANDARD_MENU_ORDER)),
        normalized_name,
    )
