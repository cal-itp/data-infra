{{ config(materialized='table') }}

WITH organizations AS ( --noqa
    SELECT *
    FROM {{ ref('int_transit_database__organizations_dim') }}
),

services AS ( -- noqa
    SELECT *
    FROM {{ ref('int_transit_database__services_dim') }}
),


bridge_organizations_x_services_managed AS (
 {{ transit_database_many_to_many2(
    shared_start_date_name = '_valid_from',
    shared_end_date_name = '_valid_to',
    table_a = {'name': 'organizations',
        'key_col': 'original_record_id',
        'key_col_name': 'organization_key',
        'name_col': 'name',
        'name_col_name': 'organization_name',
        'join_col': 'mobility_services_managed',
        'start_date_col': '_valid_from',
        'end_date_col': '_valid_to'},

    table_b = {'name': 'services',
    'key_col': 'original_record_id',
    'key_col_name': 'service_key',
    'name_col': 'name',
    'name_col_name': 'service_name',
    'join_col': 'provider',
    'start_date_col': '_valid_from',
    'end_date_col': '_valid_to'}
 ) }}
)

SELECT * FROM bridge_organizations_x_services_managed
