{{ config(materialized='table') }}

WITH latest_fare_systems AS (
    {{ get_latest_dense_rank(
    external_table = ref('stg_transit_database__fare_systems'),
    order_by = 'dt DESC'
    ) }}
),

latest_services AS (
    {{ get_latest_dense_rank(
    external_table = ref('stg_transit_database__services'),
    order_by = 'dt DESC'
    ) }}
),

bridge_fare_systems_x_services AS (
 {{ transit_database_many_to_many(
     table_a = 'latest_fare_systems',
     table_a_key_col = 'key',
     table_a_key_col_name = 'fare_system_key',
     table_a_name_col = 'fare_system',
     table_a_name_col_name = 'fare_system_name',
     table_a_join_col = 'transit_services',
     table_a_date_col = 'dt',
     table_b = 'latest_services',
     table_b_key_col = 'key',
     table_b_key_col_name = 'service_key',
     table_b_name_col = 'name',
     table_b_name_col_name = 'service_name',
     table_b_join_col = 'fare_systems',
     table_b_date_col = 'dt',
     shared_date_name = 'dt'
 ) }}
)

SELECT * FROM bridge_fare_systems_x_services
