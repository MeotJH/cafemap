from __future__ import annotations

from typing import TypedDict


class BrandCatalogEntry(TypedDict, total=False):
    id: str
    name: str
    source_url: str | None
    store_name: str
    address: str
    lat: float
    lng: float


BRAND_CATALOG: tuple[BrandCatalogEntry, ...] = (
    {
        "id": "brand-local",
        "name": "개인 카페",
        "source_url": None,
        "store_name": "홍대 로컬 카페",
        "address": "서울 마포구 와우산로 227-15",
        "lat": 37.5617,
        "lng": 126.9257,
    },
    {
        "id": "brand-starbucks",
        "name": "스타벅스",
        "source_url": "https://i.namu.wiki/i/7FcKGfq9aymli75CoBHEHUVaG_pD-3-Lth0ECJxf9YRGLqdXnZ_1yGfQHlCqV5c770pr35vxYGaoX1P_e7CFQAw_yMvCz2qJFPLgENvjMJY2Us8akCaprqkHX2KMn6PVDVbI9QF12bCJA4IrWRV8rw.svg",
        "store_name": "스타벅스 시청점",
        "address": "서울 중구 세종대로 110",
        "lat": 37.5663,
        "lng": 126.9779,
    },
    {
        "id": "brand-twosome",
        "name": "투썸플레이스",
        "source_url": "https://i.namu.wiki/i/fbtmb9Z3L01vrQhlwekvCeRXJDJKp0IJtgdaQyDzUvBOi-WLAaM-7H0K8ZaGPV8pM0q0pQ6F9_3PKi_RzdAEaA.svg",
        "store_name": "투썸플레이스 광화문점",
        "address": "서울 종로구 세종대로 172",
        "lat": 37.5720,
        "lng": 126.9769,
    },
    {
        "id": "brand-ediya",
        "name": "이디야커피",
        "source_url": "https://i.namu.wiki/i/RqpsK4GFyCTo0mcbbcYAwoA4XlJKG0lNG5MJPfwles7GTH5MbLeiIS_fW6KPuQL_F2ZtCLeYd8KWq9w10zKHLQ.svg",
        "store_name": "이디야커피 서울역점",
        "address": "서울 중구 한강대로 405",
        "lat": 37.5547,
        "lng": 126.9706,
    },
    {
        "id": "brand-mega",
        "name": "메가MGC커피",
        "source_url": "https://i.namu.wiki/i/te7-wMFAu0bI5YSfuBKWEptjc9YlKmXApR2BCwWbyFLNgueW7EedI_eNrTr-2PvcnJWcbE6WVPIPYtv6MQvkzTchvCDpKeuQEAs-AinaJ7KHZ9V3NauZuVe7u5pQCJn9pNwFxGGc9x1MbOREQ9niHQ.svg",
        "store_name": "메가MGC커피 강남역점",
        "address": "서울 강남구 강남대로 396",
        "lat": 37.4981,
        "lng": 127.0276,
    },
    {"id": "brand-gamsung", "name": "감성커피", "source_url": "https://i.namu.wiki/i/YGMZiLO4dvxqoGg8VmjiwlCa5fX27BxFRtaFYLmqZKf-vvIDXjWDqpMlOVmyeEDEJPDF0IujhENnPPEA0S2Ywg.png"},
    {"id": "brand-theliter", "name": "더리터", "source_url": "https://i.namu.wiki/i/0nUxUZzikR1M-TCPuZfjRHXjB_Tg8-I_ffIpGTsbNc44aEN7woTeiKPlkyHDS7S-bzqHUjKQpQ0hZ0U5euTEV_LpM-gUHedFLWB03H2IBDvlkQkqHuBl3MdHYLV-2P2HAlr3zq14dRYzjgEa5h5f5Q.svg"},
    {"id": "brand-theventi", "name": "더벤티", "source_url": "https://i.namu.wiki/i/pRBteTW4w6KRc-HljvIiqNb9U0nNqfavQi1qPFCsV00ey1GFOEHsxR5L2G8xU22Pn59o2OVUx4uL-Rt1espo8yu8W00Rz1tjZo9YPk8E1VzSHWETyNL8r2mHZz0VYZ0EWdviPn-MiHquUCKTBZeSCg.svg"},
    {"id": "brand-thecafe", "name": "더카페", "source_url": "https://i.namu.wiki/i/mT45DQT7Ai-vV3FZ4zD9VfDWkNq5IGcRKp17uCNx5hbhWHInb20httPkhiGFGgCwdnG4eBaYGjiu2TqXmwLLTAPaF_Wif92oCa_2OBfNfZUlkxQsKeAyfGbqgTW9YJONRm8Wirv8lhD2jdxOmv6_vA.svg"},
    {"id": "brand-dunkin", "name": "던킨", "source_url": "https://i.namu.wiki/i/mTbUaQTVzbHp5Vbp5YI2WH0X6bKoGPfwleYgJYT-gMCbl6wZ_KtnF3VWAq17m5uWrS65DNQCmBh0ZGEZZRB01qqzz701sMUNMFKmY-8nx0vWsL4C5XlitCl3uVUjqoEf0uoZ45TJrpOP7ICduTqAIA.svg"},
    {"id": "brand-droptop", "name": "드롭탑", "source_url": "https://i.namu.wiki/i/q4nKxFZHFte25SnB9XGiBPWEJx7BUYLZ-sqj633QsbGIzTo_3YzvYkXFgMJeCbmg3DmKUVgJz_bQaAOzMhqYcHIAT25fZ2qv0iub8tvI_T0sP7l0QSDlBXdjp2jtJRr0PGxzin4wwBcWLwUvtMNquw.svg"},
    {"id": "brand-dessert39", "name": "디저트39", "source_url": "https://i.namu.wiki/i/za4MB3fu_aLVARvEaenQcmC3FzmF8RXH_KuYWYOQF8ul-UgYqlOje9e3NSTQpMVHMY2XWW2OCblpGXfgsob59bC9vBnFcTlQo0Nr95k_7vvM-18HH5D2pcry9LQ_xc8NOKZ3jVxzXRSN3QpUd0nRoA.svg"},
    {"id": "brand-mammoth", "name": "매머드커피", "source_url": "https://i.namu.wiki/i/hByRhaXIfIG2EccNxcfWrYjKdgvulh-gz7S1QRHzFsHRb8d2SCX3bsSN0voQPVoLQpRnO68NgmknoqZHTlhHjxkVemKgep7Vt1wmtR-dKnkCJ86ZeA9KdtSgO0vKaeL7TC8aQ64oZgrGJm1axfbQrQ.svg"},
    {"id": "brand-mccafe", "name": "맥카페", "source_url": "https://i.namu.wiki/i/APs0SHRsaoTg4xT3vr8pM3rybq5gPT7YlQA1RVbrUvnA4STHbkbdLWVCQzO2Bj-Gs_Q73hdDS93hMs2vlj4KN7y1ENf2Xzo3q5GXAyluwqilVRpAo0pSb0wivOGqC7FFvW30zQF9JwYd5XZNSdXFhQ.svg"},
    {"id": "brand-bacha", "name": "바샤커피", "source_url": "https://i.namu.wiki/i/alzEkeLYWvfRYBgWGoy_QsU2WcU1FkWnZbyhluZs5zQl2iwLD40nZqn2Ue81nLapwzBB7dd8BlzYf7yo2kWf3c88IkwG7Z8yB2K8vWFS84_QT7VZckRnAGYO_usB3-vOJ0yO_SdU6VLs89QyqJ784A.svg"},
    {"id": "brand-bluebottle", "name": "블루보틀", "source_url": "https://i.namu.wiki/i/jXBfVZJgbpvOXxLxUBGdGSVvkNA-W-b2RZ4hq6AdeVev9Kk2dvXjKKui1dgaIpZf7YntM8Sx-PryT3LBHxh_kw.svg"},
    {"id": "brand-blueshaak", "name": "블루샥", "source_url": "https://i.namu.wiki/i/KzHKuVOSlSDEsKCAzicJ8rYL5YaKp-2neO0liA8V4TkogULGCImrtV6Ux36PDdetybbOZdb8cRZ61K5m5vzbTw.webp"},
    {"id": "brand-paik", "name": "빽다방", "source_url": "https://i.namu.wiki/i/-fqMxAFDNB8c9BxSyVxa-JKul1HC21PoSLf-NKDqcAClFPBAWE7CslIf7EAe69jKARf58eer28Xht8CUKppX9dElMmO0N_xq0RyJXMwXCXksGcv3CMtAKNxixa99LaVJ-QCxA0Ej1b61qhUByhRGXw.svg"},
    {"id": "brand-angelinus", "name": "엔제리너스", "source_url": "https://i.namu.wiki/i/1l4RaspprtB8szrrdbSGbOOjliyXvzjk9rLxDtZu2X0MKjR-Eic0LMnBYElK1BKavMIeCYqC2kADOHDZEhohj9e3tyhyj6CIvoOaP-5h-5agY9t5WtvY3o24LtmGhLgGsrMgZAZn11B3lZOD0WXBqQ.svg"},
    {"id": "brand-yogerpresso", "name": "요거프레소", "source_url": "https://i.namu.wiki/i/ykcSHCneK49z1cq1AX3_8wEjEzKM5NbBbSU0Y_2J7dAF_AxWUn4QIxZI2qQNMdCX9VJ8EjVdmDJsh4vG5OOQk_xF9yrz8yo_GEKvathY8R9sLRjfzdQKwIK8Ji0zKL2PJdqnzpDOXwtQd2-dZFPAdQ.svg"},
    {"id": "brand-illy", "name": "일리카페", "source_url": "https://i.namu.wiki/i/Abb2dy6Fxf3NcnoJeV52h50tcGyNtigBYOIzbP2IBhqTIqiDOAmJAJuLc3a6KtUQnZNdH1OBrJgR6f6Z-sRkaA.svg"},
    {"id": "brand-cafe051", "name": "카페051", "source_url": "https://i.namu.wiki/i/tL-N8hAYoEpfERqA8vCF9cMtBEvCheEricX9AK3xOusbmpmw1GMLSYBy1sG9e9C3TpaC46hmyP27nrW5uF7eMXWwT4kKybM_BnP4DDFwlUwZRIESvIJu_3p3UPXSB0i0uuqo8ydDuxr87n2OM84bgQ.webp"},
    {"id": "brand-caffebene", "name": "카페베네", "source_url": "https://i.namu.wiki/i/pen9i7Lil_oTJi_eKqkw-gJC5Ing9Bjd3qGMZTioLpsV0JE5cpuveQlolTMDcYX9P_ylwA_C2yG_mmdDVYja0L63KD2bhKw6Qqq1sG6B5UFz0inJF_J6RSlWH02mekQwL8IOq3vO9LBxE0AX6F21Uw.svg"},
    {"id": "brand-bombom", "name": "카페봄봄", "source_url": "https://i.namu.wiki/i/5zHj6A_3r-JeTJ8NeB2fTrlEJAT9o-nepKkoys7CTprk18Ftr3BBtgYnxVW1XLcvFkyWilw67i2RLK1CFHk49wMDFVKCpSiEtEVwk16641hPxQriv7mdTqXErlAfbK0MijEsi6nGOvygPIC2bf95PQ.svg"},
    {"id": "brand-coffeebean", "name": "커피빈", "source_url": "https://i.namu.wiki/i/dlhmB71tCjkDh3OdfYuBxm3x8e-VcxKW9bhW44WnPPx5U9nq7fA8K4_R37_ZQWG3nmWPxifRw24cuiMxXAn3tQ.svg"},
    {"id": "brand-coffeebay", "name": "커피베이", "source_url": "https://i.namu.wiki/i/CAWF2sMNjunCsh2vqX7bmhhgTi4gXuUpWCnqG4uSbXTx5X_Emjm1AS9iFRJO1A1k27f7sB4Ay5HhlmPkbQuo9NKSs9Y4BWW0_esPGtsqkyw9GVLwAeny_Fk-oAMbu_OJVI61JzHbNegSyuf2RK1v2Q.svg"},
    {"id": "brand-compose", "name": "컴포즈커피", "source_url": "https://i.namu.wiki/i/Jr-5ZnLbMR6fIuixgeBSO71hrfTzGi8SS6seGEnF_oZVbbBnkq6L-FCkBPMdCtTDGpj4zEKOdq11ZOmAN0tjTBqHoJXM8J6ZOmxjUenoeo-oksbstEkvX52ZLBtYGRenlEpgB9DYSFA3bOxo3w2BNA.svg"},
    {"id": "brand-congcafe", "name": "콩카페", "source_url": "https://i.namu.wiki/i/YJcXagtEEHJh3pcgIuUuVu6gg_UCIKqjy9qEUKOuS_osXv57000vNkaYcwlw-bPcV8tXT5Sk2YQfH5IveogiFnjuFeRgIFp1DGnweA20o0F0qmDbSgqFGRYOTjGuH0Ek9XqDtVhNh5nfXcrg2lFjHQ.svg"},
    {"id": "brand-tomntoms", "name": "탐앤탐스", "source_url": "https://i.namu.wiki/i/v-jsEMr_rmxXiDx0GoEVQtxU331GEI-fRGUEzmOpUBRAdDIDMjNL4litHZynbmUV3mzXW28ZXH9C-2n32iTi9Q.svg"},
    {"id": "brand-tenpercent", "name": "텐퍼센트커피", "source_url": "https://i.namu.wiki/i/HKQgtR98_vda0ai1SqFwp3G5DCVBDqnL-9fYzPNLUC6dsyNctR5ViCjD_ZMo6xYbAEcwD9aze1C8SGjkcxb-xg.svg"},
    {"id": "brand-timhortons", "name": "팀홀튼", "source_url": "https://i.namu.wiki/i/rwy4zndIzEuVZJrYufzSj9UCapBKMH0MuEm14FQDyoSMJnG5MRidRuVIqRgDMjSExHIltQ4G5Qoqm6CYgJiw-SyeKTYXd6BbrMFD2Car2ZN0gHxtSzK--2Ff_o699cee6brXzYtQiztC-JE2QO7cUg.svg"},
    {"id": "brand-pascucci", "name": "파스쿠찌", "source_url": "https://i.namu.wiki/i/p2AY9nfAabURg6DbVvADpd2F_ouDQu78wQWMx1rSFOfRpxxElcu6BYdVTklra3DYg_OqXvxgshJASuCgkAcQq8pqU74R5BvpZ0QGkkLkADXQah1KFBcpw7fpMZ_xaw915Jr3EDRpZFS1ercVHHYQ4Q.svg"},
    {"id": "brand-paulbassett", "name": "폴 바셋", "source_url": "https://i.namu.wiki/i/_FiO6udXmetbBam20RMDst2HLlC3Y_wuGXyEBd3EyLLtop_e87_jlOGBrNwgNJRUakcDzdXuLL9UPS_ajMBhst26bbs8Y5OjeVujLjJjoFfzhBd-B16qMgB5rhMKhJN1EXakPvm_CRhIlQhPPrp59g.svg"},
    {"id": "brand-fuglen", "name": "푸글렌", "source_url": "https://i.namu.wiki/i/LWSSmPI1mpppaWonCTf_YB48w6IL1rL7sShoZepiMW1kDzehsjhe7ftJHGFbpIA9v_HLLt7rbTotkdZijpew_m7xILBz0VmFNgAh1EgGowNYo6H8zrkqi8IbjQIs78h4xV_GVf4i6adQGVy5qwZc4g.svg"},
    {"id": "brand-hasamdong", "name": "하삼동커피", "source_url": "https://i.namu.wiki/i/5lh8l1yMODb7Lsdk7ku06OZK0_VJTxBH3JREQRO-97Wuy3zY5dUgwJZan3H6y13YzgSPefgPNU3XHfW3LUIMzwReik1Z8i9MsSSG1gbZ0o2XHypI-wAvZmf3EQUAVDMjPtcyOUzTWhyA8b9MWJWkmw.svg"},
    {"id": "brand-hio", "name": "하이오커피", "source_url": "https://i.namu.wiki/i/Z9I0EO_gQtn-8ek3-Ic8X-UiLW7RpziDofPTA-fk3vgDHvMQhlTQ-D7uVlFm_VoC0lkWNDoFaV4j6-mhgRzRYkkurR0M554gok608jAXYiZ8ezhqc46j1FHsOAMjvLjiJ7Y4uxldS7CzVcrHYYBrRA.webp"},
    {"id": "brand-hollys", "name": "할리스", "source_url": "https://i.namu.wiki/i/6jdSlv9aWti7Z8gAACB0HNDUYBt8FexgMSwVIFwOvz9HUcMHtFYrlD4Slyi3pHgwp_Eang5p8ojZM0K9VWd4EQ.svg"},
)
