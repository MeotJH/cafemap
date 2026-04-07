import os

import requests





# NCP ???? API ??? ???? ??????.





GEOCODE_ENDPOINT = "https://maps.apigw.ntruss.com/map-geocode/v2/geocode"





def geocode_address(address: str):

    # ??? ??? ????.

    key_id = os.getenv("NCP_GEOCODE_API_KEY_ID")

    key = os.getenv("NCP_GEOCODE_API_KEY")

    if not key_id or not key:

        # ?? ??? ????? ???? ????? ?? ??? ????.

        return {"addresses": []}



    response = requests.get(

        GEOCODE_ENDPOINT,

        headers={

            "x-ncp-apigw-api-key-id": key_id,

            "x-ncp-apigw-api-key": key,

            "Accept": "application/json",

        },

        params={"query": address},

        timeout=5,

    )

    response.raise_for_status()

    return response.json()



