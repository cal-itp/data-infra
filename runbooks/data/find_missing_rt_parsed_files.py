"""
Script that checks if an outcomes file exists for an RT parsing job.  If it exists, that means the job completed successfully.

If it doesn't exist, the job either failed midway or or never ran.  This only properly analyzes results from the parse_and_validate_v2 airflow job.  In the new airflow job parse_and_validate,
now each agency is parsed separately so it's possible some agencies were parsed and others were not.
"""
import time

import pandas as pd
from google.cloud import storage

client = storage.Client(project="cal-itp-data-infra")

# calitp-gtfs-rt-parsed/trip_updates_outcomes/dt=2025-08-25/hour=2025-08-25T00:00:00+00:00/trip_updates.jsonl
# calitp-gtfs-rt-parsed/service_alerts_outcomes/dt=2022-09-15/hour=2022-09-15T20:00:00+00:00
# vehicle_positions_outcomes/
hours = [
    f"{dt.strftime('%Y-%m-%dT%H:00:00+00:00')}"
    for dt in pd.date_range("2022-09-15", "2025-09-09", freq="H")[:-1]
]

generated_file_paths = []
paths = [
    "trip_updates_outcomes/",
    "service_alerts_outcomes/",
    "vehicle_positions_outcomes/",
]
for path in paths:
    for hour in hours:
        dt_str = hour[0:10]
        full_path = f"{path}dt={dt_str}/hour={hour}"
        generated_file_paths.append(full_path)
print(generated_file_paths[20])


bucket_name = "calitp-gtfs-rt-parsed"
# calitp-gtfs-rt-parsed/trip_updates_outcomes/dt=2025-08-25/hour=2025-08-25T04:00:00+00:00/trip_updates.jsonl
prefixes = [
    "trip_updates_outcomes/",
    "service_alerts_outcomes/",
    "vehicle_positions_outcomes/",
]
bucket = client.get_bucket(bucket_name)
seen_files_in_parsed_bucket = []
start = time.time()
for prefix in prefixes:
    blob_iterator = bucket.list_blobs(prefix=prefix)
    seen_files_in_parsed_bucket.extend([(blob.name) for blob in blob_iterator])
end = time.time()
print(f"Elapsed time: {end - start:.2f} seconds")


# Remove the filename from each path keeping only the directory portion
seen_dirs_in_parsed_bucket = [
    fp.rsplit("/", 1)[0] for fp in seen_files_in_parsed_bucket
]
print(seen_dirs_in_parsed_bucket[:5])


# Use sets to find the difference between expected and actual file paths
expected_set = set(generated_file_paths)
actual_set = set(seen_dirs_in_parsed_bucket)
missing_files = expected_set - actual_set
extra_files = actual_set - expected_set
print(f"Missing files: {len(missing_files)}")
print(f"Extra files: {len(extra_files)}")
print("Sample missing files:", list(missing_files)[:5])
print("Sample extra files:", list(extra_files)[:5])


# Write missing files to a text file
with open("missing_files_to_process.txt", "w") as f:
    for path in sorted(missing_files):
        f.write(path + "\n")
