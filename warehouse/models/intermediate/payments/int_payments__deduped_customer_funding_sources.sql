{{ config(materialized = "table") }}

WITH int_littlepay__unioned_customer_funding_source AS (
    SELECT *
    FROM {{ ref('int_littlepay__unioned_customer_funding_source') }}
),

drop_full_dupes AS (
    SELECT *
    FROM int_littlepay__unioned_customer_funding_source
    {{ qualify_dedupe_full_duplicate_lp_rows() }}
),

add_ranks AS (
    SELECT
        *,
        -- flag in reverse order, since we usually want the latest
        DENSE_RANK() OVER (
            PARTITION BY participant_id, funding_source_id
            ORDER BY littlepay_export_ts DESC, record_updated_timestamp_utc DESC) AS calitp_funding_source_id_rank,
        DENSE_RANK() OVER (
            PARTITION BY participant_id, funding_source_vault_id
            ORDER BY littlepay_export_ts DESC, record_updated_timestamp_utc DESC, funding_source_id ASC) AS calitp_funding_source_vault_id_rank,
        DENSE_RANK() OVER (
            PARTITION BY participant_id, customer_id
            ORDER BY littlepay_export_ts DESC, record_updated_timestamp_utc DESC, funding_source_id ASC ) AS calitp_customer_id_rank,
    FROM drop_full_dupes
),

int_payments__deduped_customer_funding_sources AS (
    SELECT
        funding_source_id,
        funding_source_vault_id,
        customer_id,
        bin,
        masked_pan,
        card_scheme,
        issuer,
        issuer_country,
        form_factor,
        principal_customer_id,
        participant_id,
        _line_number,
        `instance`,
        feed_version,
        extract_filename,
        ts,
        littlepay_export_ts,
        littlepay_export_date,
        calitp_funding_source_id_rank,
        calitp_funding_source_vault_id_rank,
        calitp_customer_id_rank,
        _key,
        _payments_key,
        _content_hash,
    FROM add_ranks
    -- Some funding sources have incomplete information when first present in data, like missing
    -- values for form_factor or issuer_country that are filled in during later exports.
    -- Additionally, sometimes a filled column value is updated in newer exports for a given entry.
    WHERE calitp_funding_source_id_rank = 1
)

SELECT * FROM int_payments__deduped_customer_funding_sources
