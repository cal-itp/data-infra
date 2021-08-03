import os
import requests
import tempfile
from calitp import get_table


#
API_ENDPOINT = "https://data.ca.gov/api/3/action/resource_update"
API_KEY = os.environ.get("some_key")

#

with tempfile.TemporaryDirectory() as tmp_dir:
    agency = get_table("gtfs_schedule.agency", as_df=True)
    agency.to_csv(f"{tmp_dir}/gtfs_schedule_agency.csv")

    r = requests.post(
        API_ENDPOINT,
        data={"id": "e8f9d49e-2bb6-400b-b01f-28bc2e0e7df2"},
        headers={"Authorization": API_KEY},
        files={"upload": "gtfs_schedule_agency.csv"},
    )

#
with tempfile.TemporaryDirectory() as tmp_dir:
    routes = get_table("gtfs_schedule.routes", as_df=True)
    routes.to_csv(f"{tmp_dir}/gtfs_schedule_routes.csv")

    r1 = requests.post(
        API_ENDPOINT,
        data={"id": "c6bbb637-988f-431c-8444-aef7277297f8"},
        headers={"Authorization": API_KEY},
        files={"upload": "gtfs_schedule_routes.csv"},
    )

#
with tempfile.TemporaryDirectory() as tmp_dir:
    stop_times = get_table("gtfs_schedule.stop_times", as_df=True)
    stop_times.to_csv(f"{tmp_dir}/gtfs_schedule_stop_times.csv")

    r2 = requests.post(
        API_ENDPOINT,
        data={"id": "d31eef2f-e223-4ca4-a86b-170acc6b2590"},
        headers={"Authorization": API_KEY},
        files={"upload": "gtfs_schedule_stop_times.csv"},
    )

#
with tempfile.TemporaryDirectory() as tmp_dir:
    stops = get_table("gtfs_schedule.stops", as_df=True)
    stops.to_csv(f"{tmp_dir}/gtfs_schedule_stops.csv")

    r3 = requests.post(
        API_ENDPOINT,
        data={"id": "8c876204-e12b-48a2-8299-10f6ae3d4f2b"},
        headers={"Authorization": API_KEY},
        files={"upload": "gtfs_schedule_stops.csv"},
    )


#
with tempfile.TemporaryDirectory() as tmp_dir:
    trips = get_table("gtfs_schedule.trips", as_df=True)
    trips.to_csv(f"{tmp_dir}/gtfs_schedule_trips.csv")

    r4 = requests.post(
        API_ENDPOINT,
        data={"id": "0e4da89e-9330-43f8-8de9-305cb7d4918f"},
        headers={"Authorization": API_KEY},
        files={"upload": "gtfs_schedule_trips.csv"},
    )
