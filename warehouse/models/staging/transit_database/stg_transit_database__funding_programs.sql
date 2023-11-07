WITH

once_daily_funding_programs AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'california_transit__funding_programs'),
        order_by = 'ts DESC', partition_by = 'dt'
        ) }}
),

stg_transit_database__funding_programs AS (
    SELECT
        id,
        {{ trim_make_empty_string_null(column_name = "program") }} AS program,
        full_name,
        COALESCE(program_information, program_informatiom) AS program_information,
        services,
        organization,
        category,
        drmt_data,
        dt
    FROM once_daily_funding_programs
)

SELECT * FROM stg_transit_database__funding_programs
