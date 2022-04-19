{{ config(materialized='table') }}

WITH gtfs_schedule_fact_daily_feeds as (
    select *
    from {{ ref('gtfs_schedule_fact_daily_feeds') }}
),
gtfs_schedule_dim_feeds as (
    select *
    from {{ ref('gtfs_schedule_dim_feeds') }}
),
gtfs_rt_fact_daily_feeds AS (
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
  FROM gtfs_schedule_fact_daily_feeds
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
  LEFT JOIN gtfs_schedule_dim_feeds
      USING(feed_key)
)

SELECT * FROM gtfs_rt_fact_daily_feeds
