WITH
latest AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'transit_data_quality_issues__transit_data_quality_issues'),
        order_by = 'ts DESC', partition_by = 'dt'
        ) }}
),

base_tdqi_gtfs_datasets_ct_gtfs_datasets_map AS (
    SELECT * FROM {{ ref('base_tdqi_gtfs_datasets_ct_gtfs_datasets_map') }}
),

base_tdqi_services_ct_services_map AS (
    SELECT * FROM {{ ref('base_tdqi_services_ct_services_map') }}
),

mapped_gtfs_datasets AS (
    SELECT
        id,
        ARRAY_AGG(map_gtfs_dataset.ct_key IGNORE NULLS) AS gtfs_datasets,
        dt
    FROM latest
    LEFT JOIN UNNEST(latest.gtfs_datasets) AS unnested_gtfs_dataset
    LEFT JOIN base_tdqi_gtfs_datasets_ct_gtfs_datasets_map AS map_gtfs_dataset
        ON unnested_gtfs_dataset = map_gtfs_dataset.tdqi_key
        AND dt = map_gtfs_dataset.tdqi_date
    GROUP BY id, dt
),

mapped_services AS (
    SELECT
        id,
        ARRAY_AGG(map_service.ct_key IGNORE NULLS) AS services,
        dt
    FROM latest
    LEFT JOIN UNNEST(latest.services) AS unnested_service
    LEFT JOIN base_tdqi_services_ct_services_map AS map_service
        ON unnested_service = map_service.tdqi_key
        AND dt = map_service.tdqi_date
    GROUP BY id, dt
),

base_tdqi_issues_idmap AS (
    SELECT
        r.* EXCEPT(gtfs_datasets, services),
        gtfs_datasets_map.gtfs_datasets,
        services_map.services
    FROM latest as r
    LEFT JOIN mapped_gtfs_datasets AS gtfs_datasets_map
        USING (id, dt)
    LEFT JOIN mapped_services AS services_map
        USING (id, dt)
)

SELECT * FROM base_tdqi_issues_idmap
