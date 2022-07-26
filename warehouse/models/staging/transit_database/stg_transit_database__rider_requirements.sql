

WITH
once_daily_rider_requirements AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'california_transit__rider_requirements'),
        order_by = 'ts DESC', partition_by = 'dt'
        ) }}
),

stg_transit_database__rider_requirements AS (
    SELECT
        id AS key,
        {{ trim_make_empty_string_null(column_name = "requirement") }},
        category,
        description,
        services,
        unnested_eligibility_programs AS eligibility_program_key,
        ts,
        dt AS calitp_extracted_at
    FROM once_daily_rider_requirements
    LEFT JOIN UNNEST(once_daily_rider_requirements.eligibility_programs) AS unnested_eligibility_programs
)

SELECT * FROM stg_transit_database__rider_requirements
