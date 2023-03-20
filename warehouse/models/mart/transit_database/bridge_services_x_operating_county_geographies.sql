{{ config(materialized='table') }}

WITH services AS ( -- noqa
    SELECT *
    FROM {{ ref('int_transit_database__services_dim') }}
),

county_geography AS ( -- noqa
    SELECT *
    FROM {{ ref('int_transit_database__county_geography_dim') }}
),

bridge_services_x_operating_county_geographies AS (
 {{ transit_database_many_to_many_versioned(
    shared_start_date_name = '_valid_from',
    shared_end_date_name = '_valid_to',
    shared_current_name = '_is_current',
    table_a = {'name': 'services',
        'unversioned_key_col': 'source_record_id',
        'versioned_key_col': 'key',
        'key_col_name': 'service_key',
        'name_col': 'name',
        'name_col_name': 'service_name',
        'unversioned_join_col': 'operating_county_geographies',
        'start_date_col': '_valid_from',
        'end_date_col': '_valid_to'},

    table_b = {'name': 'county_geography',
        'unversioned_key_col': 'source_record_id',
        'versioned_key_col': 'key',
        'key_col_name': 'county_geography_key',
        'name_col': 'name',
        'name_col_name': 'county_geography_name',
        'unversioned_join_col': 'service_key',
        'start_date_col': '_valid_from',
        'end_date_col': '_valid_to'}
    ) }}
)

SELECT * FROM bridge_services_x_operating_county_geographies
