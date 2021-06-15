# Agency GTFS Feeds

Feed information is stored in [airflow/data/agencies.yml](https://github.com/cal-itp/data-infra/blob/main/airflow/data/agencies.yml).
This file is then used by our Airflow data pipeline to download feeds, and load them into the warehouse.

Each agency feed entry includes these fields:

* `agency_name`: Human friendly name for the agency
* `itp_id`: The California Integrated Travel Project ID
* URLs such as `gtfs_schedule_url`, and those for realtime feeds.

## Finding the ITP ID

Entries must include the correct ITP ID for an agency.
These can be found on the [Primary List of California Transit Providers](https://docs.google.com/spreadsheets/d/105oar4q_Z3yihDeUlP-VnYpJ0N9Mfs7-q4TnribqYLU/edit?usp=sharing).

## Including API Keys

If the URL for a GTFS feed requires an API key, you can include using these steps:

* Add a unique name, and the key to [this private spreadsheet](https://docs.google.com/spreadsheets/d/1Fp7sesSMS6VOIndTLTKcyyN2qHj6najKAaN-I9_3SFo/edit?usp=sharing).
* Include the API key in your url by using `{{ MY_KEY_NAME }}`, where `MY_KEY_NAME`
  is the unique name used in the spreadsheet.

Below is an example entry.

```yaml
ac-transit:
  agency_name: AC Transit
  feeds:
    - gtfs_schedule_url: https://api.actransit.org/transit/gtfs/download?token={{ AC_TRANSIT_API_KEY }}
      gtfs_rt_vehicle_positions_url: https://api.actransit.org/gtfsrt/vehicles?token={{ AC_TRANSIT_API_KEY }}
      gtfs_rt_service_alerts_url: https://api.actransit.org/gtfsrt/alerts?token={{ AC_TRANSIT_API_KEY }}
      gtfs_rt_trip_updates_url: https://api.actransit.org/gtfsrt/tripupdates?token={{ AC_TRANSIT_API_KEY }}
  itp_id: 4
```


## Deploying to Pipeline

Every time the main branch of cal-itp/data-infra is updated on github,
[this github action][action] swaps in the API keys and pushes to our Cloud Composer's data bucket.

[action]: (https://github.com/cal-itp/data-infra/blob/main/.github/workflows/update_gcloud_requirements.yml)
