import os

from dotenv import load_dotenv

load_dotenv()

env_vars = ["TRANSITLAND_API_KEY"]

env = {}

for key in env_vars:
    try:
        env[key] = os.environ[key]
    except KeyError:
        print(f"WARNING: env var {key} not found")
