WITH
once_daily_gtfs_service_data AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'california_transit__gtfs_service_data'),
        order_by = 'ts DESC', partition_by = 'dt'
        ) }}
),

stg_transit_database__gtfs_service_data AS (
    SELECT
        id,
        {{ trim_make_empty_string_null(column_name = "name") }} AS name,
        unnested_services AS service_key,
        unnested_gtfs_dataset AS gtfs_dataset_key,
        -- only coalesce to false after the field had been created (November 23, 2022)
        -- otherwise a null is genuinely a null
        CASE
            WHEN dt >= '2022-11-23' THEN COALESCE(customer_facing, FALSE)
        END AS customer_facing,
        category,
        agency_id,
        network_id,
        route_id,
        fares_v2_status,
        dt
    FROM once_daily_gtfs_service_data
    LEFT JOIN UNNEST(once_daily_gtfs_service_data.services) as unnested_services
    LEFT JOIN UNNEST(once_daily_gtfs_service_data.gtfs_dataset) as unnested_gtfs_dataset
    -- TODO: actually handle this -- there are historical records that were not 1:1
    -- either one service was entered with multiple datasets in a single record
    -- or vice versa
    -- this was not valid data entry at the time it was done, but we should see
    -- if we can find a way to preserve that data anyway
    -- we could see if we can generate a new key to keep all the entries
    QUALIFY ROW_NUMBER() OVER (PARTITION BY id, ts ORDER BY service_key) = 1
)

SELECT * FROM stg_transit_database__gtfs_service_data
