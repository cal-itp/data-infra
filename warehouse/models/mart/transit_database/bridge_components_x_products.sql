{{ config(materialized='table') }}

WITH latest_components AS (
    {{ get_latest_dense_rank(
    external_table = ref('stg_transit_database__components'),
    order_by = 'calitp_extracted_at DESC'
    ) }}
),

latest_products AS (
    {{ get_latest_dense_rank(
    external_table = ref('stg_transit_database__products'),
    order_by = 'calitp_extracted_at DESC'
    ) }}
),

bridge_components_x_products AS (
 {{ transit_database_many_to_many(
     table_a = 'latest_components',
     table_a_key_col = 'key',
     table_a_key_col_name = 'component_key',
     table_a_name_col = 'name',
     table_a_name_col_name = 'component_name',
     table_a_join_col = 'products',
     table_b = 'latest_products',
     table_b_key_col = 'key',
     table_b_key_col_name = 'product_key',
     table_b_name_col = 'name',
     table_b_name_col_name = 'product_name',
     table_b_join_col = 'components'
 ) }}
)

SELECT * FROM bridge_components_x_products
