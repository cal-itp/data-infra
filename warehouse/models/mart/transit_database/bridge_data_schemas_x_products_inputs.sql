{{ config(materialized='table') }}

WITH data_schemas AS ( --noqa
    SELECT *
    FROM {{ ref('int_transit_database__data_schemas_dim') }}
),

products AS ( -- noqa
    SELECT *
    FROM {{ ref('int_transit_database__products_dim') }}
),


bridge_data_schemas_x_products_inputs AS (
 {{ transit_database_many_to_many2(
    shared_start_date_name = '_valid_from',
    shared_end_date_name = '_valid_to',
    shared_current_name = '_is_current',
    table_a = {'name': 'data_schemas',
        'unversioned_key_col': 'original_record_id',
        'versioned_key_col': 'key',
        'key_col_name': 'data_schema_key',
        'name_col': 'name',
        'name_col_name': 'data_schema_name',
        'unversioned_join_col': 'input_products',
        'start_date_col': '_valid_from',
        'end_date_col': '_valid_to'},

    table_b = {'name': 'products',
        'unversioned_key_col': 'original_record_id',
        'versioned_key_col': 'key',
        'key_col_name': 'product_key',
        'name_col': 'name',
        'name_col_name': 'product_name',
        'unversioned_join_col': 'accepted_input_components',
        'start_date_col': '_valid_from',
        'end_date_col': '_valid_to'}
    ) }}
)

SELECT * FROM bridge_data_schemas_x_products_inputs
