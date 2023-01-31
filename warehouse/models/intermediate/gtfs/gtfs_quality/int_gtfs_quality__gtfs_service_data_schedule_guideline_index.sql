{{ config(materialized='ephemeral') }}

WITH int_gtfs_quality__gtfs_service_data_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__gtfs_service_data_guideline_index') }}
),

gtfs_datasets AS (
    SELECT * FROM {{ ref('dim_gtfs_datasets') }}
),

gtfs_service_data AS (
    SELECT * FROM {{ ref('dim_gtfs_service_data') }}
),

int_gtfs_quality__gtfs_service_data_schedule_guideline_index AS (
    SELECT idx.*
      FROM int_gtfs_quality__gtfs_service_data_guideline_index idx
    LEFT JOIN gtfs_service_data
        ON gtfs_service_data.key = idx.gtfs_service_data_key
      LEFT JOIN gtfs_datasets
        ON gtfs_datasets.key = gtfs_service_data.gtfs_dataset_key
     WHERE gtfs_datasets.type = "schedule"
)

SELECT * FROM int_gtfs_quality__gtfs_service_data_schedule_guideline_index
