{{
    config(
        materialized='view',
        tags=['tides_product'],
    )
}}

-- Day-by-day record of which vehicle-positions feed to publish for which
-- organization on which service_date (Pacific Time) -- one row per (service_date, organization,
-- feed). The TIDES export DAG reads this filtered to a single service_date and fans out
-- one parquet export per row:
--     SELECT ... FROM fct_tides_vehicle_locations
--     WHERE service_date = <ds> AND base64_url = <row.base64_url>
--
-- service_date + base64_url are observed straight from fct_tides_vehicle_locations (which
-- is already restricted to the published organizations -- the denylist
-- anti-join lives there), so the URL recorded for a day is the URL that
-- actually served data that day: a feed-URL rotation flows through on its own,
-- and a backfill of any past service_date picks up the URL that was correct then.
-- Organization and feed names are attached from the current dim snapshot.
--
-- KNOWN LIMITATION (regional/combined feeds): a VP gtfs_dataset_key attached to
-- multiple organizations in dim_provider_gtfs_data (e.g. Bay Area 511, San
-- Diego) produces one feed-day row per org, and the DAG would export that
-- shared feed once per org. Not a concern for the LA-area MVP pilots; resolve
-- before onboarding agencies that publish through a shared regional feed.
WITH feed_days AS (
    SELECT DISTINCT
        service_date,
        organization_source_record_id,
        gtfs_dataset_key,
        base64_url
    FROM {{ ref('fct_tides_vehicle_locations') }}
),

-- One row per (organization, feed) carrying human-readable names. Collapsed
-- with ANY_VALUE so the join below cannot fan out feed_days.
feed_meta AS (
    SELECT
        organization_source_record_id,
        vehicle_positions_gtfs_dataset_key AS gtfs_dataset_key,
        ANY_VALUE(vehicle_positions_source_record_id) AS vehicle_positions_source_record_id,
        ANY_VALUE(vehicle_positions_gtfs_dataset_name) AS feed_name,
        ANY_VALUE(organization_name) AS agency_name
    FROM {{ ref('dim_provider_gtfs_data') }}
    WHERE _is_current = TRUE
      AND vehicle_positions_gtfs_dataset_key IS NOT NULL
    GROUP BY organization_source_record_id, vehicle_positions_gtfs_dataset_key
)

SELECT
    fd.service_date,
    fd.organization_source_record_id,
    fm.vehicle_positions_source_record_id,
    fm.agency_name,
    fm.feed_name,
    fd.gtfs_dataset_key,
    fd.base64_url
FROM feed_days AS fd
LEFT JOIN feed_meta AS fm
    USING (organization_source_record_id, gtfs_dataset_key)
