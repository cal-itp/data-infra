WITH

gtfs_datasets AS (
    SELECT * FROM {{ ref('stg_transit_database__gtfs_datasets') }}
),

int_transit_database__urls_to_gtfs_datasets AS (
    SELECT
        base64_url,
        key AS gtfs_dataset_key -- this is defined in {{ ref('dim_gtfs_datasets') }}
    FROM gtfs_datasets
    WHERE base64_url IS NOT NULL
    -- NOTE: there could be more than 1 record per URL per ts if a given
    -- URL is set in more than one gtfs_dataset row; our general assertion
    -- is that we really should think of the underlying Airtable data
    -- as unique at the URL level and merge records if necessary to
    -- enforce that uniqueness constraint
    QUALIFY ROW_NUMBER() OVER (PARTITION BY base64_url ORDER BY ts DESC) = 1
)

SELECT * FROM int_transit_database__urls_to_gtfs_datasets
