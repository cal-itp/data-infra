{{ config(materialized='table') }}

WITH latest_components AS (
    {{ get_latest_dense_rank(
    external_table = ref('stg_transit_database__components'),
    order_by = 'dt DESC'
    ) }}
),

latest_properties_and_features AS (
    {{ get_latest_dense_rank(
    external_table = ref('stg_transit_database__properties_and_features'),
    order_by = 'dt DESC'
    ) }}
),

bridge_components_x_properties_and_features AS (
 {{ transit_database_many_to_many(
     table_a = 'latest_components',
     table_a_key_col = 'key',
     table_a_key_col_name = 'component_key',
     table_a_name_col = 'name',
     table_a_name_col_name = 'component_name',
     table_a_join_col = 'properties_and_features',
     table_a_date_col = 'dt',
     table_b = 'latest_properties_and_features',
     table_b_key_col = 'key',
     table_b_key_col_name = 'property_feature_key',
     table_b_name_col = 'name',
     table_b_name_col_name = 'property_feature_name',
     table_b_join_col = 'available_in_components',
     table_b_date_col = 'dt',
     shared_date_name = 'dt'
 ) }}
)

SELECT * FROM bridge_components_x_properties_and_features
