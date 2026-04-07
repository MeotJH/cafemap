import html

import re



from cafemap.repositories import place_search_repository





# ??? ?? ?? ???? ?? ????.





_TAG_RE = re.compile(r"<[^>]+>")

_ALLOWED_CATEGORIES = {

    "음식점>치킨,닭강정",

    "한식>닭요리",

    "양식>햄버거",

    "술집>맥주,호프",

    "술집>요리주점",

}





def _clean_title(raw: str) -> str:

    # HTML ??? ???? ???? ????.

    return html.unescape(_TAG_RE.sub("", raw)).strip()





def _is_allowed_category(category: str) -> bool:

    # ??? ????? ?????.

    return (category or "").strip() in _ALLOWED_CATEGORIES





def search_places(query: str, display: int = 5) -> list[dict]:

    # ?? ??? ? ???? ?? ????.

    payload = place_search_repository.search_places(query=query, display=display)

    items = payload.get("items", [])



    results = []

    for item in items:

        name = _clean_title(item.get("title", ""))

        category = item.get("category", "")

        if not _is_allowed_category(category):

            continue

        results.append(

            {

                "name": name,

                "address": item.get("address", ""),

                "roadAddress": item.get("roadAddress", ""),

                "category": category,

                "phone": item.get("telephone", ""),

                "link": item.get("link", ""),

                "mapx": int(item.get("mapx", 0) or 0),

                "mapy": int(item.get("mapy", 0) or 0),

            }

        )

    return results

