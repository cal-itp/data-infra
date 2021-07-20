import yaml
import pandas as pd
import sys

from pathlib import Path
from jinja2 import Environment, select_autoescape, StrictUndefined
from io import StringIO

if len(sys.argv) < 4:
    raise Exception(
        "3 arguments required: input file, output file, and spreadsheet url"
    )
else:
    FNAME_IN, FNAME_OUT, SPREADSHEET_URL = sys.argv[1:]

api_key_df = pd.read_csv(SPREADSHEET_URL)
api_keys = dict(zip(api_key_df["name"], api_key_df["api_key"]))

agencies_path = Path(FNAME_IN)

env = Environment(autoescape=select_autoescape(), undefined=StrictUndefined)
template = env.from_string(agencies_path.read_text())

new_agencies = template.render(**api_keys)

try:
    yaml.safe_load(StringIO(new_agencies))
except yaml.ParserError:
    raise Exception("Filled out agencies.yml is not valid yaml")

print("Saving filled out agencies.yml to %s" % FNAME_OUT)

Path(FNAME_OUT).write_text(new_agencies)
