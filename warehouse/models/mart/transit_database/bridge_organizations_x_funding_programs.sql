{{ config(materialized='table') }}

WITH latest_organizations AS (
    {{ get_latest_dense_rank(
    external_table = ref('stg_transit_database__organizations'),
    order_by = 'dt DESC'
    ) }}
),

latest_funding_programs AS (
    {{ get_latest_dense_rank(
    external_table = ref('stg_transit_database__funding_programs'),
    order_by = 'dt DESC'
    ) }}
),

bridge_organizations_x_funding_programs AS (
 {{ transit_database_many_to_many(
     table_a = 'latest_organizations',
     table_a_key_col = 'key',
     table_a_key_col_name = 'organization_key',
     table_a_name_col = 'name',
     table_a_name_col_name = 'organization_name',
     table_a_join_col = 'funding_programs',
     table_a_date_col = 'dt',
     table_b = 'latest_funding_programs',
     table_b_key_col = 'key',
     table_b_key_col_name = 'funding_program_key',
     table_b_name_col = 'program',
     table_b_name_col_name = 'funding_program',
     table_b_join_col = 'organization',
     table_b_date_col = 'dt',
     shared_date_name = 'dt'
 ) }}
)

SELECT * FROM bridge_organizations_x_funding_programs
