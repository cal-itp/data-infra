{{ config(materialized='table') }}

WITH latest_contracts AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__contracts'),
        order_by = 'dt DESC'
        ) }}
),

-- TODO: make this table actually historical
historical AS (
    SELECT
        *,
        TRUE AS _is_current,
        CAST((MIN(dt) OVER (ORDER BY dt)) AS TIMESTAMP) AS _valid_from,
        {{ make_end_of_valid_range('CAST("2099-01-01" AS TIMESTAMP)') }} AS _valid_to
    FROM latest_contracts
),


dim_contract_attachments AS (
    SELECT
        {{ dbt_utils.surrogate_key(['unnested_attachments.id', '_valid_from']) }} AS key,
        -- TODO: fix this -- this is not a valid foreign key
        historical.id AS contract_key,
        historical.name AS contract_name,
        unnested_attachments.url AS attachment_url,
        _is_current,
        _valid_from,
        _valid_to
    FROM historical,
        historical.attachments AS unnested_attachments
)

SELECT * FROM dim_contract_attachments
