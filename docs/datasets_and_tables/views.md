# Views (WIP)

## Data

| dataset | description | examples |
| ------- | ----------- | -------- |
| `views.gtfs_agency_names` | One row per GTFS Static data feed, with `calitp_itp_id`, `calitp_url_number`, and `agency_name` | |
| `views.gtfs_schedule_service_daily` | `calendar.txt` data from GTFS Static unpacked and joined with `calendar_dates.txt` to reflect service schedules on a given day. Critically, it uses the data that was current on `service_date`. For `service_date` values in the future, uses most recent data in warehouse. | |
| `views.validation_notices` | One line per specific validation violation (e.g. each invalid phone number). See `validation_code_descriptions` for human friendly code labels, and `validation_notice_fields` for looking up what columns in `validation_notices` different codes have data for (e.g. the code `"invalid_phone_number"` sets the `fieldValue` column). | |

## DAGS Maintenance

Views are held in the [`gtfs_views`](https://github.com/cal-itp/data-infra/tree/main/airflow/dags/gtfs_views) DAG.

You can find further information on DAGs maintenance for Views [on this page](views-dags).
