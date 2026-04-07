#!/usr/bin/env python3
"""
Generate menu CSV aligned with brands declared in back/chickenmap/db/init_db.py.

Output columns:
  menu_id, brand_id, menu_name, description, category, source_url

Behavior:
  1) Read all Brand(...) rows from init_db.py.
  2) Try scraping menus for brands with known sources.
  3) Fill missing brands with deterministic fallback menus.
"""

from __future__ import annotations

import csv
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Tuple

try:
    from unidecode import unidecode  # type: ignore
except Exception:  # pylint: disable=broad-except
    unidecode = None



INIT_DB_PATH = Path("chickenmap/db/init_db.py")
OUTPUT_CSV = Path("korea_chicken_menus.csv")


def slug(value: str) -> str:
    if unidecode is not None:
        normalized = unidecode(value).lower()
    else:
        normalized = (
            value.encode("ascii", errors="ignore").decode("ascii").lower()
        )
    normalized = re.sub(r"[^\w\s-]", " ", normalized)
    normalized = re.sub(r"[\s_-]+", "-", normalized).strip("-")
    normalized = re.sub(r"[^a-z0-9-]", "", normalized)
    return normalized or "item"


def classify(menu_name: str) -> str:
    n = menu_name
    if any(
        k in n
        for k in [
            "치즈볼",
            "감자",
            "샐러드",
            "떡볶",
            "어묵",
            "먹태",
            "츄러스",
            "팝콘",
            "코울슬로",
            "소스",
            "탕",
            "덮밥",
            "볶음밥",
        ]
    ):
        return "사이드"
    if "후라이드" in n:
        return "후라이드"
    if "간장" in n or "소이" in n:
        return "간장"
    if "양념" in n:
        return "양념"
    if "허니" in n:
        return "허니"
    if "레드" in n or "매운" in n or "맵" in n:
        return "매운"
    if "마요" in n:
        return "마요"
    if "깐풍" in n:
        return "깐풍"
    if "투움바" in n:
        return "투움바"
    if "윙" in n or "봉" in n:
        return "윙"
    if "숯불" in n or "바베큐" in n:
        return "구이"
    return "기타"


@dataclass
class MenuItem:
    name: str
    source_url: str = ""
    description: str = ""

    @property
    def category(self) -> str:
        return classify(self.name)


def parse_brands_from_init_db(path: Path) -> List[Tuple[str, str]]:
    text = path.read_text(encoding="utf-8")
    matches = re.finditer(
        r'Brand\(\s*.*?id="([^"]+)"\s*,\s*.*?name="([^"]+)"\s*,\s*.*?logo_url=',
        text,
        flags=re.S,
    )
    out = [(m.group(1), m.group(2)) for m in matches]
    # Preserve insertion order while removing accidental duplicates.
    seen: set[str] = set()
    unique: List[Tuple[str, str]] = []
    for brand_id, brand_name in out:
        if brand_id in seen:
            continue
        seen.add(brand_id)
        unique.append((brand_id, brand_name))
    return unique


def dedupe_by_name(items: Iterable[MenuItem]) -> List[MenuItem]:
    seen: set[str] = set()
    out: List[MenuItem] = []
    for item in items:
        key = item.name.strip()
        if not key or key in seen:
            continue
        seen.add(key)
        out.append(item)
    return out


# brand_id -> official menu page list
BRAND_SOURCES: Dict[str, List[str]] = {
    "brand-kyochon": [
        "https://kyochon.com/menu/chicken.asp?code=1",
        "https://kyochon.com/menu/chicken.asp?code=2",
        "https://kyochon.com/menu/chicken.asp?code=4",
        "https://kyochon.com/menu/chicken.asp?code=5",
        "https://kyochon.com/menu/chicken.asp?code=18",
        "https://kyochon.com/menu/side.asp",
    ],
    "brand-puradak": ["https://puradakchicken.com/menu/product.asp"],
    "brand-hosigi": ["https://www.9922.co.kr/menu"],
}


def fetch_html(url: str) -> str:
    import requests

    headers = {"User-Agent": "Mozilla/5.0"}
    response = requests.get(url, headers=headers, timeout=30)
    response.raise_for_status()
    response.encoding = response.apparent_encoding
    return response.text


def parse_kyochon(html: str, source_url: str) -> List[MenuItem]:
    from bs4 import BeautifulSoup

    soup = BeautifulSoup(html, "html.parser")
    items: List[MenuItem] = []
    for a in soup.select("a"):
        text = " ".join(a.get_text(" ", strip=True).split())
        if "권장소비자가격" not in text:
            continue
        name = text.split("권장소비자가격")[0].strip().split("  ")[0].strip()
        if len(name) >= 2:
            items.append(MenuItem(name=name, source_url=source_url))
    return dedupe_by_name(items)


def parse_puradak(html: str, source_url: str) -> List[MenuItem]:
    from bs4 import BeautifulSoup

    soup = BeautifulSoup(html, "html.parser")
    items: List[MenuItem] = []
    for a in soup.select("a"):
        text = " ".join(a.get_text(" ", strip=True).split())
        if not text:
            continue
        # "메뉴명 메뉴명 ..." shape
        matched = re.match(r"^([가-힣0-9\(\)\/\-\s&·]+?)\s+\1\b", text)
        if not matched:
            continue
        name = matched.group(1).strip()
        if len(name) >= 2:
            items.append(MenuItem(name=name, source_url=source_url))
    return dedupe_by_name(items)


def parse_hosigi(html: str, source_url: str) -> List[MenuItem]:
    from bs4 import BeautifulSoup

    soup = BeautifulSoup(html, "html.parser")
    items: List[MenuItem] = []
    for node in soup.find_all(["h3", "h4", "h5", "strong"]):
        text = " ".join(node.get_text(" ", strip=True).split())
        if not text:
            continue
        if any(
            keyword in text
            for keyword in [
                "치킨",
                "떡볶",
                "치즈",
                "감자",
                "샐러드",
                "탕",
                "닭발",
                "똥집",
                "텐더",
                "윙",
                "봉",
            ]
        ):
            items.append(MenuItem(name=text, source_url=source_url))
    return dedupe_by_name(items)


PARSERS = {
    "brand-kyochon": parse_kyochon,
    "brand-puradak": parse_puradak,
    "brand-hosigi": parse_hosigi,
}


def scrape_menus_for_brand(brand_id: str) -> List[MenuItem]:
    urls = BRAND_SOURCES.get(brand_id, [])
    parser = PARSERS.get(brand_id)
    if not urls or parser is None:
        return []

    all_items: List[MenuItem] = []
    for url in urls:
        try:
            html = fetch_html(url)
            all_items.extend(parser(html, url))
        except Exception as exc:  # pylint: disable=broad-except
            print(f"[WARN] scrape failed for {brand_id} @ {url}: {exc}")
    return dedupe_by_name(all_items)


def fallback_menus_for_brand(brand_name: str) -> List[MenuItem]:
    return [
        MenuItem(name=f"{brand_name} 후라이드치킨"),
        MenuItem(name=f"{brand_name} 양념치킨"),
        MenuItem(name=f"{brand_name} 간장치킨"),
    ]


def generate_rows(brands: List[Tuple[str, str]]) -> List[List[str]]:
    rows: List[List[str]] = []
    seen_menu_ids: set[str] = set()

    for brand_id, brand_name in brands:
        scraped = scrape_menus_for_brand(brand_id)
        menus = scraped if scraped else fallback_menus_for_brand(brand_name)

        for item in dedupe_by_name(menus):
            base_menu_id = f"menu-{brand_id.removeprefix('brand-')}-{slug(item.name)}"
            menu_id = base_menu_id
            suffix = 2
            while menu_id in seen_menu_ids:
                menu_id = f"{base_menu_id}-{suffix}"
                suffix += 1

            seen_menu_ids.add(menu_id)
            rows.append(
                [
                    menu_id,
                    brand_id,
                    item.name,
                    item.description,
                    item.category,
                    item.source_url,
                ]
            )
    return rows


def write_csv(path: Path, rows: List[List[str]]) -> None:
    with path.open("w", newline="", encoding="utf-8") as file:
        writer = csv.writer(file)
        writer.writerow(
            ["menu_id", "brand_id", "menu_name", "description", "category", "source_url"]
        )
        writer.writerows(rows)


def main() -> None:
    brands = parse_brands_from_init_db(INIT_DB_PATH)
    if not brands:
        raise RuntimeError(f"No brands found in {INIT_DB_PATH}")

    rows = generate_rows(brands)
    write_csv(OUTPUT_CSV, rows)
    print(f"Wrote {len(rows)} rows -> {OUTPUT_CSV}")
    print(f"Brands covered: {len(brands)}")


if __name__ == "__main__":
    main()
