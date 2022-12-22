{{ config(materialized='table') }}

WITH latest_organizations AS (
    {{ get_latest_dense_rank(
    external_table = ref('stg_transit_database__organizations'),
    order_by = 'dt DESC'
    ) }}
),

latest_gtfs_datasets AS (
    {{ get_latest_dense_rank(
    external_table = ref('stg_transit_database__gtfs_datasets'),
    order_by = 'dt DESC'
    ) }}
),

bridge_organizations_x_gtfs_datasets_managed AS (
 {{ transit_database_many_to_many(
     table_a = 'latest_organizations',
     table_a_key_col = 'key',
     table_a_key_col_name = 'organization_key',
     table_a_name_col = 'name',
     table_a_name_col_name = 'organization_name',
     table_a_join_col = 'gtfs_datasets_produced',
     table_a_date_col = 'dt',
     table_b = 'latest_gtfs_datasets',
     table_b_key_col = 'key',
     table_b_key_col_name = 'gtfs_dataset_key',
     table_b_name_col = 'name',
     table_b_name_col_name = 'gtfs_dataset_name',
     table_b_join_col = 'dataset_producers',
     table_b_date_col = 'dt',
     shared_date_name = 'dt'
 ) }}
)

SELECT * FROM bridge_organizations_x_gtfs_datasets_managed
