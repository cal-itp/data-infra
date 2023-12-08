{{ config(materialized = 'table',) }}

WITH auth AS (
    SELECT *
    FROM {{ ref('int_payments__authorisations_deduped') }}
),

-- TODO: do we want to add any additional summary columns here?
-- for example: number of attempted authorisations over all?

-- get the payments key values of rows that are the final update for that aggregation ID
final_update AS (
    SELECT
        _payments_key,
        aggregation_id,
        status
    FROM auth
    QUALIFY ROW_NUMBER() OVER(PARTITION BY aggregation_id ORDER BY authorisation_date_time_utc DESC) = 1
),

-- get the payments key values of rows that are the final update with a null status for that
-- aggregation ID
final_update_without_status AS (
    SELECT
        _payments_key,
        aggregation_id
    FROM final_update
    WHERE status IS NULL
),

-- get the payments key values of rows that are the final update with a non-null status for that
-- aggregation ID
final_update_with_status AS (
    SELECT
        _payments_key,
        aggregation_id
    FROM auth
    -- We cannot glean useful information downstream from a null status, so we take the most recent
    -- authorisation with a non-null status.
    WHERE status IS NOT NULL
    QUALIFY ROW_NUMBER() OVER(PARTITION BY aggregation_id ORDER BY authorisation_date_time_utc DESC) = 1
),

-- Take the latest rows for each aggregation with a non-null status, but flag where a final
-- authorisation exists that has a null status
join_with_flag AS (
    SELECT
        final_update_with_status._payments_key,
        COALESCE(final_update_without_status.aggregation_id IS NOT NULL, False) AS final_authorisation_has_null_status
    FROM final_update_with_status
    LEFT OUTER JOIN final_update_without_status
        ON final_update_with_status.aggregation_id = final_update_without_status.aggregation_id
),

int_payments__latest_authorisations_by_aggregation AS (
    SELECT
        participant_id,
        aggregation_id,
        acquirer_id,
        request_type,
        transaction_amount,
        currency_code,
        retrieval_reference_number,
        littlepay_reference_number,
        external_reference_number,
        response_code,
        status,
        final_authorisation_has_null_status,
        authorisation_date_time_utc,
         _line_number,
        `instance`,
        extract_filename,
        littlepay_export_ts,
        littlepay_export_date,
        ts,
        _key,
        _payments_key,
        _content_hash,
    FROM join_with_flag
    LEFT JOIN auth USING(_payments_key)
)

SELECT * FROM int_payments__latest_authorisations_by_aggregation
