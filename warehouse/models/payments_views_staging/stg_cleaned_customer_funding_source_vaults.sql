WITH stg_cleaned_customer_funding_source_vaults AS (
    SELECT
        customer_id,
        funding_source_vault_id,
        principal_customer_id,
        bin,
        masked_pan,
        card_scheme,
        issuer,
        issuer_country,
        form_factor,

        -- If there is no record leading this one over the specified window, then
        -- assume that this record has been valid since the beginning of time. If
        -- there is a previous record, assume this record is valid since the time
        -- the file was exported.
        CASE
            WHEN LEAD(calitp_export_datetime) OVER unique_ids IS NULL
                THEN TIMESTAMP('1899-01-01 00:00:00+00:00')
            ELSE TIMESTAMP(calitp_export_datetime, 'UTC') END AS calitp_valid_at,

        -- If there is no record lagging this one over the specified window, then
        -- assume that this record will be valid forever. Otherwise assume it is
        -- invalid at the time that the next record was exported.
        COALESCE(
            TIMESTAMP(LAG(calitp_export_datetime) OVER unique_ids, 'UTC'),
            TIMESTAMP('2099-01-01 00:00:00+00:00')) AS calitp_invalid_at

    FROM {{ ref('stg_enriched_customer_funding_source') }}
    WHERE calitp_dupe_number = 1
    WINDOW unique_ids AS (
        PARTITION BY funding_source_vault_id
        ORDER BY calitp_customer_id_rank)
ORDER BY funding_source_vault_id, calitp_valid_at DESC
)

SELECT * FROM stg_cleaned_customer_funding_source_vaults
