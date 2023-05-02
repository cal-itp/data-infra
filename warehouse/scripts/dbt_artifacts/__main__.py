# mainly just to test that these models work
import json

from . import Manifest, RunResults

paths = [
    ("./target/manifest.json", Manifest),
    ("./target/run_results.json", RunResults),
]

for path, model in paths:
    with open(path) as f:
        model(**json.load(f))
        print(f"{path} is a valid {model.__name__}!", flush=True)
