{{ config(materialized='table') }}

WITH latest_data_schemas AS (
    {{ get_latest_dense_rank(
    external_table = ref('stg_transit_database__data_schemas'),
    order_by = 'calitp_extracted_at DESC'
    ) }}
),

latest_products AS (
    {{ get_latest_dense_rank(
    external_table = ref('stg_transit_database__products'),
    order_by = 'calitp_extracted_at DESC'
    ) }}
),

bridge_data_schemas_x_products_inputs AS (
 {{ transit_database_many_to_many(
     table_a = 'latest_data_schemas',
     table_a_key_col = 'key',
     table_a_key_col_name = 'data_schema_key',
     table_a_name_col = 'name',
     table_a_name_col_name = 'data_schema_name',
     table_a_join_col = 'input_products',
     table_b = 'latest_products',
     table_b_key_col = 'key',
     table_b_key_col_name = 'product_key',
     table_b_name_col = 'name',
     table_b_name_col_name = 'product_name',
     table_b_join_col = 'accepted_input_components'
 ) }}
)

SELECT * FROM bridge_data_schemas_x_products_inputs
