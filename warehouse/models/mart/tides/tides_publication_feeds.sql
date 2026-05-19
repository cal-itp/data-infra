{{
    config(
        materialized='view',
        tags=['tides_product'],
    )
}}

-- Resolves the human-curated organization allowlist (the tides_publication_keys
-- seed) to the concrete set of current customer-facing vehicle-positions feeds
-- to publish. One row per (organization, feed) -- an organization with multiple
-- feeds (e.g. LA Metro: Bus + Rail) yields multiple rows. The TIDES export DAG
-- reads this view and fans out one parquet export per row.
--
-- base64_url is derived from recent fct_tides_vehicle_locations data rather than
-- carried in the seed, so a feed-URL rotation flows through automatically (a
-- stale seeded URL would silently export zero rows).
WITH current_feeds AS (
    SELECT DISTINCT
        k.organization_source_record_id,
        k.agency_name,
        d.vehicle_positions_source_record_id,
        d.vehicle_positions_gtfs_dataset_name,
        d.vehicle_positions_gtfs_dataset_key
    FROM {{ ref('tides_publication_keys') }} AS k
    INNER JOIN {{ ref('dim_provider_gtfs_data') }} AS d
        USING (organization_source_record_id)
    WHERE d._is_current = TRUE
      AND d.public_customer_facing_or_regional_subfeed_fixed_route = TRUE
),

-- Most-recent base64_url observed per feed key, over a short recent window.
feed_urls AS (
    SELECT
        gtfs_dataset_key,
        base64_url
    FROM {{ ref('fct_tides_vehicle_locations') }}
    WHERE dt >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY gtfs_dataset_key
        ORDER BY dt DESC
    ) = 1
)

SELECT
    cf.organization_source_record_id,
    cf.vehicle_positions_source_record_id,
    cf.agency_name,
    -- per-feed label so a multi-feed org's export tasks are distinguishable
    cf.vehicle_positions_gtfs_dataset_name AS feed_name,
    cf.vehicle_positions_gtfs_dataset_key AS gtfs_dataset_key,
    -- NULL when the feed has had no data in the recent window; the DAG skips
    -- (and should warn on) NULL-base64_url rows
    fu.base64_url
FROM current_feeds AS cf
LEFT JOIN feed_urls AS fu
    ON fu.gtfs_dataset_key = cf.vehicle_positions_gtfs_dataset_key
