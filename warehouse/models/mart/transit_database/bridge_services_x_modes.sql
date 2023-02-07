{{ config(materialized='table') }}

WITH services AS ( --noqa
    SELECT *
    FROM {{ ref('int_transit_database__services_dim') }}
),

modes AS ( -- noqa
    SELECT *
    FROM {{ ref('int_transit_database__modes_dim') }}
),

bridge_services_x_modes AS (
 {{ transit_database_many_to_many_versioned(
    shared_start_date_name = '_valid_from',
    shared_end_date_name = '_valid_to',
    shared_current_name = '_is_current',
    table_a = {'name': 'services',
        'unversioned_key_col': 'source_record_id',
        'versioned_key_col': 'key',
        'key_col_name': 'service_key',
        'name_col': 'name',
        'name_col_name': 'services_name',
        'unversioned_join_col': 'primary_mode',
        'start_date_col': '_valid_from',
        'end_date_col': '_valid_to'},

    table_b = {'name': 'modes',
        'unversioned_key_col': 'source_record_id',
        'versioned_key_col': 'key',
        'key_col_name': 'mode_key',
        'name_col': 'mode',
        'name_col_name': 'mode',
        'unversioned_join_col': 'services',
        'start_date_col': '_valid_from',
        'end_date_col': '_valid_to'}
    ) }}
)

SELECT * FROM bridge_services_x_modes
