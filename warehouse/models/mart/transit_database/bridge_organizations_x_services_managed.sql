{{ config(materialized='table') }}

WITH stg_transit_database__organizations AS (
    SELECT * FROM {{ ref('stg_transit_database__organizations') }}
),

stg_transit_database__services AS (
    SELECT * FROM {{ ref('stg_transit_database__services') }}
),

bridge_organizations_x_services_managed AS (
 {{ transit_database_many_to_many(
     table_a = 'stg_transit_database__organizations',
     table_a_key_col = 'key',
     table_a_key_col_name = 'organization_key',
     table_a_name_col = 'name',
     table_a_name_col_name = 'organization_name',
     table_a_join_col = 'mobility_services_managed',
     table_b = 'stg_transit_database__services',
     table_b_key_col = 'key',
     table_b_key_col_name = 'service_key',
     table_b_name_col = 'name',
     table_b_name_col_name = 'service_name',
     table_b_join_col = 'provider'
 ) }}
)

SELECT * FROM bridge_organizations_x_services_managed
