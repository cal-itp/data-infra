{{ config(materialized='table') }}

WITH organizations AS ( --noqa
    SELECT *
    FROM {{ ref('int_transit_database__organizations_dim') }}
),

gtfs_datasets AS ( -- noqa
    SELECT *
    FROM {{ ref('int_transit_database__gtfs_datasets_dim') }}
),

bridge_organizations_x_gtfs_datasets_produced AS (
 {{ transit_database_many_to_many_versioned(
    shared_start_date_name = '_valid_from',
    shared_end_date_name = '_valid_to',
    shared_current_name = '_is_current',
    table_a = {'name': 'organizations',
        'unversioned_key_col': 'original_record_id',
        'versioned_key_col': 'key',
        'key_col_name': 'organization_key',
        'name_col': 'name',
        'name_col_name': 'organization_name',
        'unversioned_join_col': 'gtfs_datasets_produced',
        'start_date_col': '_valid_from',
        'end_date_col': '_valid_to'},

    table_b = {'name': 'gtfs_datasets',
        'unversioned_key_col': 'original_record_id',
        'versioned_key_col': 'key',
        'key_col_name': 'gtfs_dataset_key',
        'name_col': 'name',
        'name_col_name': 'gtfs_dataset_name',
        'unversioned_join_col': 'dataset_producers',
        'start_date_col': '_valid_from',
        'end_date_col': '_valid_to'}
    ) }}
)

SELECT * FROM bridge_organizations_x_gtfs_datasets_produced
