{{ config(materialized='table') }}

WITH latest_contracts AS (
    {{ get_latest_dense_rank(
    external_table = ref('stg_transit_database__contracts'),
    order_by = 'calitp_extracted_at DESC'
    ) }}
),
latest_components AS (
    {{ get_latest_dense_rank(
    external_table = ref('stg_transit_database__components'),
    order_by = 'calitp_extracted_at DESC'
    ) }}
),

bridge_contracts_x_components AS (
 {{ transit_database_many_to_many(
     table_a = 'latest_contracts',
     table_a_key_col = 'key',
     table_a_key_col_name = 'contract_key',
     table_a_name_col = 'name',
     table_a_name_col_name = 'contract_name',
     table_a_join_col = 'covered_components',
     table_a_date_col = 'calitp_extracted_at',
     table_b = 'latest_components',
     table_b_key_col = 'key',
     table_b_key_col_name = 'component_key',
     table_b_name_col = 'name',
     table_b_name_col_name = 'component_name',
     table_b_join_col = 'contracts',
     table_b_date_col = 'calitp_extracted_at',
     shared_date_name = 'calitp_extracted_at'
 ) }}
)

SELECT * FROM bridge_contracts_x_components
