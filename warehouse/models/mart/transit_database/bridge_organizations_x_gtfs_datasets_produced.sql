{{ config(materialized='table') }}

WITH latest_organizations AS (
    {{ get_latest_dense_rank(
    external_table = ref('stg_transit_database__organizations'),
    order_by = 'calitp_extracted_at DESC'
    ) }}
),

latest_gtfs_datasets AS (
    {{ get_latest_dense_rank(
    external_table = ref('stg_transit_database__gtfs_datasets'),
    order_by = 'calitp_extracted_at DESC'
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
     table_a_date_col = 'calitp_extracted_at',
     table_b = 'latest_gtfs_datasets',
     table_b_key_col = 'key',
     table_b_key_col_name = 'gtfs_dataset_key',
     table_b_name_col = 'name',
     table_b_name_col_name = 'gtfs_dataset_name',
     table_b_join_col = 'dataset_producers',
     table_b_date_col = 'calitp_extracted_at',
     shared_date_name = 'calitp_extracted_at'
 ) }}
)

SELECT * FROM bridge_organizations_x_gtfs_datasets_managed
