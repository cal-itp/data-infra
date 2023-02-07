{{ config(materialized='table') }}

WITH dim AS (
    SELECT *
    FROM {{ ref('int_transit_database__modes_dim') }}
),

dim_modes AS (
    SELECT
        key,
        source_record_id,
        name,
        mode,
        super_mode,
        link_to_formal_definition,
        _is_current,
        _valid_from,
        _valid_to
    FROM dim
)

SELECT * FROM dim_modes
