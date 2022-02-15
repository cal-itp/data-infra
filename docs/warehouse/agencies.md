---
jupytext:
  cell_metadata_filter: -all
  formats: md:myst
  text_representation:
    extension: .md
    format_name: myst
    format_version: 0.13
    jupytext_version: 1.10.3
kernelspec:
  display_name: Python 3 (ipykernel)
  language: python
  name: python3
---
 (agency-gtfs-feeds)=
# Agency GTFS Feeds

Feed information is stored in [airflow/data/agencies.yml](https://github.com/cal-itp/data-infra/blob/main/airflow/data/agencies.yml).
This file is then used by our Airflow data pipeline to download feeds, and load them into the warehouse.

Each agency feed entry includes these fields:

* `agency_name`: Human friendly name for the agency
* `itp_id`: The California Integrated Travel Project ID
* URLs such as `gtfs_schedule_url`, and those for realtime feeds.

## Walkthrough of adding a feed

The screencast below walks through the process of adding a new feed.

<div style="position: relative; padding-bottom: 62.5%; height: 0;"><iframe src="https://www.loom.com/embed/39f0100b43c4457db81b62249f162128" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"></iframe></div>

## Finding the ITP ID

Entries must include the correct ITP ID for an agency.
These can be found on the [Primary List of California Transit Providers](https://docs.google.com/spreadsheets/d/105oar4q_Z3yihDeUlP-VnYpJ0N9Mfs7-q4TnribqYLU/edit?usp=sharing).

## Including API Keys

If the URL for a GTFS feed requires an API key or other sensitive information, you can include that using these steps:

1. Add a unique name, and the key or value to a private airtable. Ask on internal chat for access to this.
2. Include the API key in your url by using `{{ MY_KEY_NAME }}`, where `MY_KEY_NAME`
  is the unique name used in the airtable.
3. Export this table as a CSV file and copy the raw contents of the CSV file.
4. Paste the raw contents into the `AGENCY_SECRETS` GitHub secret.
5. Add the appropriate key name in the text of a URL entry in the [airflow/data/agencies.yml](https://github.com/cal-itp/data-infra/blob/main/airflow/data/agencies.yml) file.

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
the [push_to_gcloud](https://github.com/cal-itp/data-infra/blob/main/.github/workflows/push_to_gcloud.yml) github action swaps in the API keys and pushes to our Cloud Composer's data bucket.
