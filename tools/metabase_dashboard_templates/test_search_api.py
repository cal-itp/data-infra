import requests
from metabase_flow import environments, gcp_secrets

# get staging key
api_key = gcp_secrets.fetch_secret_from_gcp(
    environments.ENVIRONMENTS["staging"]["gcp_secret"]
)

# run api key
dashboards: list[dict] = []
limit, offset = 200, 0
base_url = "https://metabase-staging.dds.dot.ca.gov"
r = requests.get(
    f"{base_url}/api/search",
    params={
        "models": "dashboard",
        "archived": "false",
        "limit": 200,
        "offset": 0,
    },
    headers={"X-API-Key": api_key},
    timeout=30,
)
print("url: ", r.url)
print([entry["name"] for entry in r.json()["data"]])
