{{ config(materialized='table') }}

WITH stg_transit_database__components AS (
    SELECT * FROM {{ ref('stg_transit_database__components') }}
),

stg_transit_database__products AS (
    SELECT * FROM {{ ref('stg_transit_database__products') }}
),

map_components_products_x_products_components AS (
 {{ transit_database_many_to_many(
     table_a = 'stg_transit_database__components',
     table_a_id_col = 'component_id',
     table_a_name_col = 'component_name',
     table_a_join_col = 'products',
     table_b = 'stg_transit_database__products',
     table_b_id_col = 'product_id',
     table_b_name_col = 'product_name',
     table_b_join_col = 'components'
 ) }}
)

SELECT * FROM map_components_products_x_products_components
