import yaml
import sys

from jsonschema import validate, ValidationError

if len(sys.argv) < 3:
    raise Exception("2 arguments required: data file, schema file")
else:
    fname, schema_name = sys.argv[1:]

headers = yaml.safe_load(open(fname))
schema = yaml.safe_load(open(schema_name))

print(f"There are {len(headers)} headers")

print("Checking agency entries formatted correctly")

i = 0
for header in headers:
    try:
        validate(instance=header, schema=schema)
    except ValidationError as err:
        raise Exception(f"Error validating header #{i}: {str(err)}")
    i += 1

print("Running parse_headers on headers file to ensure ids are unique.")
used = {}
for header in headers:
    for url_set in header["URLs"]:
        itp_id = url_set["itp_id"]
        url_number = url_set["url_number"]
        for rt_url in url_set["rt_urls"]:
            key = f"{itp_id}/{url_number}/{rt_url}"
            if key in used:
                raise ValueError(f"Duplicate header data for url with key: {key}")
            used[key] = True
