{{
    config(
        materialized='table'
    )
}}

WITH deduped_by_funding_source AS (
    SELECT *
    FROM {{ ref('stg_littlepay__customer_funding_source') }}
    QUALIFY ROW_NUMBER() OVER (PARTITION BY participant_id, funding_source_id ORDER BY littlepay_export_ts DESC) = 1
),

deduped_by_vault_and_extract AS (
    SELECT *
    FROM deduped_by_funding_source
    QUALIFY ROW_NUMBER() OVER (PARTITION BY participant_id, funding_source_vault_id, littlepay_export_ts ORDER BY funding_source_id) = 1
),

int_littlepay__customer_funding_source_vaults AS (
    SELECT
        participant_id,
        funding_source_id,
        customer_id,
        funding_source_vault_id,
        principal_customer_id,
        bin,
        masked_pan,
        card_scheme,
        issuer,
        issuer_country,
        form_factor,
        littlepay_export_ts,

        -- If there is no record leading this one over the specified window, then
        -- assume that this record has been valid since the beginning of time. If
        -- there is a previous record, assume this record is valid since the time
        -- the file was exported.
        CASE
            WHEN LAG(littlepay_export_ts) OVER unique_ids IS NULL
                THEN TIMESTAMP('1899-01-01 00:00:00')
            ELSE littlepay_export_ts END AS calitp_valid_at,

        -- If there is no record lagging this one over the specified window, then
        -- assume that this record will be valid forever. Otherwise assume it is
        -- invalid at the time that the next record was exported.
        COALESCE(
            LEAD(littlepay_export_ts) OVER unique_ids,
            TIMESTAMP('2099-01-01 00:00:00')) AS calitp_invalid_at

    FROM deduped_by_vault_and_extract
    WINDOW unique_ids AS (
        PARTITION BY participant_id, funding_source_vault_id
        ORDER BY littlepay_export_ts)
)

SELECT * FROM int_littlepay__customer_funding_source_vaults
