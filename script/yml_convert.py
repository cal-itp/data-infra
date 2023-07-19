import sys
from io import StringIO
from pathlib import Path

import pandas as pd
import yaml
from jinja2 import Environment, StrictUndefined, select_autoescape

if len(sys.argv) < 4:
    raise Exception(
        "3 arguments required: input file, output file, and spreadsheet url"
    )
else:
    FNAME_IN, FNAME_OUT, SPREADSHEET_URL = sys.argv[1:4]

api_key_df = pd.read_csv(SPREADSHEET_URL)
api_keys = dict(zip(api_key_df["name"], api_key_df["api_key"]))

agencies_path = Path(FNAME_IN)

env = Environment(autoescape=select_autoescape(), undefined=StrictUndefined)
template = env.from_string(agencies_path.read_text())

new_agencies = template.render(**api_keys)

try:
    if "--unsafe" not in sys.argv:
        yaml.safe_load(StringIO(new_agencies))
except yaml.ParserError:
    raise Exception("Filled out agencies.yml is not valid yaml")

print("Saving filled out %s to %s" % (FNAME_IN, FNAME_OUT))

Path(FNAME_OUT).write_text(new_agencies)