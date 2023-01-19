{{ config(materialized='table') }}

WITH components AS ( --noqa
    SELECT *
    FROM {{ ref('int_transit_database__components_dim') }}
),

properties_and_features AS ( -- noqa
    SELECT *
    FROM {{ ref('int_transit_database__properties_and_features_dim') }}
),


bridge_components_x_properties_and_features AS (
 {{ transit_database_many_to_many_versioned(
    shared_start_date_name = '_valid_from',
    shared_end_date_name = '_valid_to',
    shared_current_name = '_is_current',
    table_a = {'name': 'components',
        'unversioned_key_col': 'original_record_id',
        'versioned_key_col': 'key',
        'key_col_name': 'component_key',
        'name_col': 'name',
        'name_col_name': 'component_name',
        'unversioned_join_col': 'properties_and_features',
        'start_date_col': '_valid_from',
        'end_date_col': '_valid_to'},

    table_b = {'name': 'properties_and_features',
        'unversioned_key_col': 'original_record_id',
        'versioned_key_col': 'key',
        'key_col_name': 'property_feature_key',
        'name_col': 'name',
        'name_col_name': 'property_feature_name',
        'unversioned_join_col': 'available_in_components',
        'start_date_col': '_valid_from',
        'end_date_col': '_valid_to'}
    ) }}
)

SELECT * FROM bridge_components_x_properties_and_features
