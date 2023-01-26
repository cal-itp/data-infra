{{ config(materialized='ephemeral') }}

WITH int_gtfs_quality__gtfs_dataset_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__gtfs_dataset_guideline_index') }}
),

gtfs_datasets AS (
    SELECT * FROM {{ ref('dim_gtfs_datasets') }}
),

int_gtfs_quality__gtfs_dataset_schedule_guideline_index AS (
    SELECT idx.*
      FROM int_gtfs_quality__gtfs_dataset_guideline_index idx
      LEFT JOIN gtfs_datasets
        ON gtfs_datasets.key = idx.gtfs_dataset_key
     WHERE gtfs_datasets.type = "schedule"
)

SELECT * FROM int_gtfs_quality__gtfs_dataset_schedule_guideline_index