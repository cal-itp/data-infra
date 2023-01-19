{{ config(materialized='table') }}

WITH components AS ( --noqa
    SELECT *
    FROM {{ ref('int_transit_database__components_dim') }}
),

products AS ( -- noqa
    SELECT *
    FROM {{ ref('int_transit_database__products_dim') }}
),

bridge_components_x_products AS (
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
        'unversioned_join_col': 'products',
        'start_date_col': '_valid_from',
        'end_date_col': '_valid_to'},

    table_b = {'name': 'products',
        'unversioned_key_col': 'original_record_id',
        'versioned_key_col': 'key',
        'key_col_name': 'product_key',
        'name_col': 'name',
        'name_col_name': 'product_name',
        'unversioned_join_col': 'components',
        'start_date_col': '_valid_from',
        'end_date_col': '_valid_to'}
    ) }}
)

SELECT * FROM bridge_components_x_products
