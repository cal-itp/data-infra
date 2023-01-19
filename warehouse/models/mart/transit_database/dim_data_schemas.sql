{{ config(materialized='table') }}

WITH int_transit_database__data_schemas_dim AS (
    SELECT *
    FROM {{ ref('int_transit_database__data_schemas_dim') }}
),

dim_data_schemas AS (
    SELECT
        key,
        name,
        status,
        original_record_id,
        _is_current,
        _valid_from,
        _valid_to
    FROM int_transit_database__data_schemas_dim
)

SELECT * FROM dim_data_schemas
