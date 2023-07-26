WITH

ct_gtfs_datasets AS ( -- noqa: L045
    SELECT *
    FROM {{ source('airtable', 'california_transit__gtfs_datasets') }}
    WHERE TRIM(name) != ""
),

tdqi_gtfs_datasets AS ( -- noqa: L045
    SELECT *
    FROM {{ source('airtable', 'transit_data_quality_issues__gtfs_datasets') }}
    WHERE TRIM(name) != ""
),

base_tdqi_gtfs_datasets_ct_gtfs_datasets_map AS (
    {{ transit_database_synced_table_id_mapping(
        table_a_dict = {'table_name': 'ct_gtfs_datasets',
            'base': 'ct',
            'id_col': 'id'
        },
        table_b_dict = {'table_name': 'tdqi_gtfs_datasets',
            'base': 'tdqi',
            'id_col': 'id'
        }) }}
)

SELECT * FROM base_tdqi_gtfs_datasets_ct_gtfs_datasets_map
