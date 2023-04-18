{{ config(materialized='table') }}

WITH contracts AS (
    SELECT *
    FROM {{ ref('int_transit_database__contracts_dim') }}
),

dim_contract_attachments AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['unnested_attachments.id', '_valid_from']) }} AS key,
        contracts.key AS contract_key,
        contracts.name AS contract_name,
        unnested_attachments.url AS attachment_url,
        id AS source_record_id,
        _is_current,
        _valid_from,
        _valid_to
    FROM contracts,
        contracts.attachments AS unnested_attachments
)

SELECT * FROM dim_contract_attachments
