# mainly just to test that these models work
import json

from . import Catalog, Manifest, RunResults

with open("./target/manifest.json") as f:
    manifest = Manifest(**json.load(f))

with open("./target/run_results.json") as f:
    run_results = RunResults(**json.load(f))

with open("./target/catalog.json") as f:
    catalog = Catalog(**json.load(f))

manifest.set_catalog(c=catalog)
