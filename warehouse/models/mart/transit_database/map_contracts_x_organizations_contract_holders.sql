{{ config(materialized='table') }}

WITH stg_transit_database__components AS (
    SELECT * FROM {{ ref('stg_transit_database__components') }}
),

stg_transit_database__service_components AS (
    SELECT * FROM {{ ref('stg_transit_database__service_components') }}
),

map_components_service_components_x_service_components AS (
 {{ transit_database_two_table_join(
     table_a = 'stg_transit_database__components',
     table_a_id_col = 'component_id',
     table_a_name_col = 'component_name',
     table_a_join_col = 'service_components',
     table_b = 'stg_transit_database__service_components',
     table_b_id_col = 'service_component_id',
     table_b_name_col = 'service_component_name',
     table_b_join_col = 'component'
 ) }}
)

SELECT * FROM map_components_service_components_x_service_components
