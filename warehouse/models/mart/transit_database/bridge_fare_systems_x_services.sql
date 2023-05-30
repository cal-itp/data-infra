{{ config(materialized='table') }}

WITH fare_systems AS ( --noqa
    SELECT *
    FROM {{ ref('int_transit_database__fare_systems_dim') }}
),

services AS ( -- noqa
    SELECT *
    FROM {{ ref('int_transit_database__services_dim') }}
),

naive_bridge AS (
 {{ transit_database_many_to_many_versioned(
    shared_start_date_name = '_valid_from',
    shared_end_date_name = '_valid_to',
    shared_current_name = '_is_current',
    table_a = {'name': 'fare_systems',
        'unversioned_key_col': 'source_record_id',
        'versioned_key_col': 'key',
        'key_col_name': 'fare_system_key',
        'name_col': 'fare_system',
        'name_col_name': 'fare_system_name',
        'unversioned_join_col': 'transit_services',
        'start_date_col': '_valid_from',
        'end_date_col': '_valid_to'},

    table_b = {'name': 'services',
        'unversioned_key_col': 'source_record_id',
        'versioned_key_col': 'key',
        'key_col_name': 'service_key',
        'name_col': 'name',
        'name_col_name': 'service_name',
        'unversioned_join_col': 'fare_systems',
        'start_date_col': '_valid_from',
        'end_date_col': '_valid_to'}
    ) }}
),

-- TODO: can remove this once fare systems is made historical
bridge_fare_systems_x_services AS (
    SELECT *
    FROM naive_bridge
    WHERE fare_system_key IS NOT NULL
)


SELECT * FROM bridge_fare_systems_x_services
