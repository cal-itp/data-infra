{{ config(materialized='table') }}

WITH services AS ( --noqa
    SELECT *
    FROM {{ ref('int_transit_database__services_dim') }}
),
rider_requirements AS ( --noqa
    SELECT *
    FROM {{ ref('int_transit_database__rider_requirements_dim') }}
),
bridge_services_x_rider_requirements AS (
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
        'unversioned_join_col': 'rider_requirements',
        'start_date_col': '_valid_from',
        'end_date_col': '_valid_to'},

    table_b = {'name': 'rider_requirements',
        'unversioned_key_col': 'source_record_id',
        'versioned_key_col': 'key',
        'key_col_name': 'rider_requirement_key',
        'name_col': 'requirement',
        'name_col_name': 'rider_requirement',
        'unversioned_join_col': 'services',
        'start_date_col': '_valid_from',
        'end_date_col': '_valid_to'}
    ) }}
)

SELECT
    service_key,
    service_name,
    rider_requirement_key,
    rider_requirement,
    _valid_from,
    _valid_to,
    _is_current
FROM bridge_services_x_rider_requirements
