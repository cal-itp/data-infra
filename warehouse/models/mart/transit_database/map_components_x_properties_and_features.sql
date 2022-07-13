{{ config(materialized='table') }}

WITH stg_transit_database__components AS (
    SELECT * FROM {{ ref('stg_transit_database__components') }}
),

stg_transit_database__properties_and_features AS (
    SELECT * FROM {{ ref('stg_transit_database__properties_and_features') }}
),

map_components_properties_and_features_x_properties_and_features AS (
 {{ transit_database_many_to_many(
     table_a = 'stg_transit_database__components',
     table_a_key_col = 'key',
     table_a_key_col_name = 'component_key',
     table_a_name_col = 'name',
     table_a_name_col_name = 'component_name',
     table_a_join_col = 'properties_and_features',
     table_b = 'stg_transit_database__properties_and_features',
     table_b_key_col = 'key',
     table_b_key_col_name = 'property_feature_key',
     table_b_name_col = 'name',
     table_b_name_col_name = 'property_feature_name',
     table_b_join_col = 'available_in_components'
 ) }}
)

SELECT * FROM map_components_properties_and_features_x_properties_and_features
