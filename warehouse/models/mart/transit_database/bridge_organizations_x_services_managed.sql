{{ config(materialized='table') }}

WITH latest_organizations AS (
    {{ get_latest_dense_rank(
    external_table = ref('stg_transit_database__organizations'),
    order_by = 'dt DESC'
    ) }}
),

latest_services AS (
    {{ get_latest_dense_rank(
    external_table = ref('stg_transit_database__services'),
    order_by = 'dt DESC'
    ) }}
),

bridge_organizations_x_services_managed AS (
 {{ transit_database_many_to_many2(
    shared_date_name = 'dt',
    table_a = {'name': 'latest_organizations',
        'key_col': 'id',
        'key_col_name': 'organization_key',
        'name_col': 'name',
        'name_col_name': 'organization_name',
        'join_col': 'mobility_services_managed',
        'date_col': 'dt'},

    table_b = {'name': 'latest_services',
    'key_col': 'id',
    'key_col_name': 'service_key',
    'name_col': 'name',
    'name_col_name': 'service_name',
    'join_col': 'provider',
    'date_col': 'dt'}
 ) }}
)

SELECT * FROM bridge_organizations_x_services_managed
