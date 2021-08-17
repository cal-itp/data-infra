# ---
# python_callable: validation_notice_fields
# external_dependencies:
#   - gtfs_schedule_history2: all
# ---

# Note that in theory we could use a SQL query (maybe with a js UDF), but it
# looks kind of crazy: https://stackoverflow.com/q/34890339/1144523
# instead, just loop over the bucket of validation reports
import gcsfs
import json
import pandas as pd

from calitp import write_table
from calitp.config import get_bucket, get_project_id
from collections import defaultdict


# note that if we upgrade gusty, we don't need to wrap this in a function
def validation_notice_fields():
    bucket = get_bucket()

    print(f"{bucket}/schedule/processed/*/validation_report.json")

    fs = gcsfs.GCSFileSystem(project=get_project_id())
    reports = fs.glob(f"{bucket}/schedule/processed/*/validation_report.json")
    reports_json = [json.load(fs.open(fname)) for fname in reports]

    code_fields = defaultdict(lambda: set())
    for report in reports_json:
        # one entry per code (e.g. the code: invalid phone number)
        for notice in report["notices"]:
            # one entry per specific code violation (e.g. each invalid phone number)
            for entry in notice["notices"]:
                # map each code to the fields in its notice
                # (e.g. duplicate_route_name has a duplicatedField field
                for field_name, value in entry.items():
                    if isinstance(value, dict):
                        # handle the few cases where there's one level of nesting
                        sub_fields = [field_name + "." + v for v in value]
                        code_fields[notice["code"]].update(sub_fields)
                    else:
                        # handle the common case of no sub-objects
                        code_fields[notice["code"]].update(entry.keys())

    validation_json_fields = pd.DataFrame(
        {"code": code_fields.keys(), "field": list(map(list, code_fields.values()))}
    ).explode("field")

    write_table(validation_json_fields, "views.validation_notice_fields")
