WITH

once_daily_modes AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'california_transit__modes'),
        order_by = 'ts DESC', partition_by = 'dt'
        ) }}
),

stg_transit_database__modes AS (
    SELECT
        id,
        mode,
        super_mode,
        description,
        link_to_formal_definition,
        services,
        dt
    FROM once_daily_modes
)

SELECT * FROM stg_transit_database__modes
