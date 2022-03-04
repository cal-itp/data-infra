---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_rt_fact_daily_feeds"

description: |
  Each row represents a GTFS realtime feed (combination of ITP ID, URL number,
  and realtime data type) that was present in our extraction list on the given date.
  Note that a feed can be added to the  list at any point in the day
  and this table contains no information about extractions success or failure;
  i.e., a feed may be listed here even if no data was successfully pulled,
  or if only partial data was pulled.


fields:
  date: Date for which this feed was present in our extraction list
  calitp_itp_id: Feed ITP ID
  calitp_url_number: Feed URL number
  url: Feed URL
  type: GTFS realtime type (service_alerts, trip_updates, or vehicle_positions)

tests:
    check_null:
        - calitp_itp_id
        - calitp_url_number
        - date
        - type
        - url
    # do not include URL here in case we have duplicate labeling of different URLs
    check_composite_unique:
        - calitp_itp_id
        - calitp_url_number
        - date
        - type

external_dependencies:
  - gtfs_views: gtfs_schedule_fact_daily_feeds
---

-- note that for realtime we do not (yet) have a feed_key-type identifier
-- so use calitp_itp_id plus calitp_url_number as identifier

SELECT
    calitp_itp_id,
    calitp_url_number,
    date,
    url,
    -- turn type from a label like gtfs_rt_<file_type>_url
    -- to just file_type
    REGEXP_EXTRACT(type, r"gtfs_rt_(.*)_url") as type
FROM `cal-itp-data-infra.views.gtfs_schedule_fact_daily_feeds`
-- in fact_daily_feeds, there are columns for each RT type
-- UNPIVOT to transform this into one column with all types
-- UNPIVOT has EXCLUDE_NULL set to true by default so this returns only urls that are present
UNPIVOT(
    url for type in (
        raw_gtfs_rt_vehicle_positions_url,
        raw_gtfs_rt_trip_updates_url,
        raw_gtfs_rt_service_alerts_url)
    )
-- join so that we have calitp_itp_id and calitp_url_number
LEFT JOIN `cal-itp-data-infra.views.gtfs_schedule_dim_feeds`
    USING(feed_key)
