import yaml
import sys

from jsonschema import validate, ValidationError
from collections import Counter

if len(sys.argv) < 3:
    raise Exception("2 arguments required: data file, schema file")
else:
    fname, schema_name = sys.argv[1:]

agencies = yaml.safe_load(open(fname))
schema = yaml.safe_load(open(schema_name))

print(f"There are {len(agencies)} agencies")

print("Checking agency entries formatted correctly")

for k, entry in agencies.items():
    try:
        validate(instance=entry, schema=schema)
    except ValidationError as err:
        raise Exception(f"Error validating agency {k}: {str(err)}")

print("Checking that they have unique itp_ids")

id_counts = Counter([entry["itp_id"] for entry in agencies.values()])
duplicates = {k: v for k, v in id_counts.items() if v > 1}

if duplicates:
    raise Exception(f"Duplicate itp_ids. {list(duplicates.values())}")
