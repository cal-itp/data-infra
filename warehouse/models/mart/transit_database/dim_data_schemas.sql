{{ config(materialized='table') }}

WITH stg_transit_database__data_schemas AS (
    SELECT * FROM {{ ref('stg_transit_database__data_schemas') }}
),

dim_data_schemas AS (
    SELECT
        id,
        name,
        status,
        calitp_extracted_at
    FROM stg_transit_database__data_schemas
)

SELECT * FROM dim_data_schemas
