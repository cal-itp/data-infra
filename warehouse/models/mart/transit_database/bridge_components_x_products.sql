{{ config(materialized='table') }}

WITH stg_transit_database__components AS (
    SELECT * FROM {{ ref('stg_transit_database__components') }}
),

stg_transit_database__products AS (
    SELECT * FROM {{ ref('stg_transit_database__products') }}
),

bridge_components_x_products AS (
 {{ transit_database_many_to_many(
     table_a = 'stg_transit_database__components',
     table_a_key_col = 'key',
     table_a_key_col_name = 'component_key',
     table_a_name_col = 'name',
     table_a_name_col_name = 'component_name',
     table_a_join_col = 'products',
     table_b = 'stg_transit_database__products',
     table_b_key_col = 'key',
     table_b_key_col_name = 'product_key',
     table_b_name_col = 'name',
     table_b_name_col_name = 'product_name',
     table_b_join_col = 'components'
 ) }}
)

SELECT * FROM bridge_components_x_products
