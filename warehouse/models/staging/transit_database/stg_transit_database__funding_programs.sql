

WITH
once_daily_funding_programs AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'california_transit__funding_programs'),
        order_by = 'ts DESC', partition_by = 'dt'
        ) }}
),

stg_transit_database__funding_programs AS (
    SELECT
        id AS key,
        {{ trim_make_empty_string_null(column_name = "program") }},
        full_name,
        program_informatiom,
        services,
        organization,
        category,
        drmt_data,
        ts,
        dt AS calitp_extracted_at
    FROM once_daily_funding_programs
)

SELECT * FROM stg_transit_database__funding_programs
