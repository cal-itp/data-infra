{{ config(materialized='table') }}

WITH services AS ( --noqa
    SELECT *
    FROM {{ ref('int_transit_database__services') }}
),

gtfs_datasets AS ( -- noqa
    SELECT *
    FROM {{ ref('dim_gtfs_datasets') }}
),

bridge_services_x_gtfs_datasets AS (
 {{ transit_database_many_to_many_versioned(
    shared_start_date_name = '_valid_from',
    shared_end_date_name = '_valid_to',
    shared_current_name = '_is_current',
    table_a = {'name': 'services',
        'unversioned_key_col': 'source_record_id',
        'versioned_key_col': 'key',
        'key_col_name': 'service_key',
        'name_col': 'issue__',
        'name_col_name': 'service_issue__',
        'unversioned_join_col': 'gtfs_datasets',
        'start_date_col': '_valid_from',
        'end_date_col': '_valid_to'},

    table_b = {'name': 'gtfs_datasets',
        'unversioned_key_col': 'source_record_id',
        'versioned_key_col': 'key',
        'key_col_name': 'gtfs_dataset_key',
        'name_col': 'name',
        'name_col_name': 'gtfs_dataset_name',
        'unversioned_join_col': 'key',
        'start_date_col': '_valid_from',
        'end_date_col': '_valid_to'}
    ) }}
)

SELECT * FROM bridge_services_x_gtfs_datasets
