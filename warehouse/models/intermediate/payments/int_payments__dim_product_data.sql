{%- set timestamps = dbt_utils.get_column_values(
        table = ref('int_littlepay__unioned_product_data'),
        column = 'littlepay_export_ts',
        order_by = 'littlepay_export_ts DESC') -%}
{%- set latest_processed_timestamp = timestamps[0] -%}

WITH unioned_products AS (
    SELECT * FROM {{ ref('int_littlepay__unioned_product_data') }}
),

distinct_data AS (
    SELECT
        participant_id,
        product_id,
        _content_hash,
        -- same content hash and product_id can be seen across v1 and v3 feeds, summarize to latest instance across either
        MAX(littlepay_export_ts) AS last_seen,
    FROM unioned_products
    GROUP BY participant_id, product_id, _content_hash
),

version_data AS (
    SELECT
        participant_id,
        product_id,
        _content_hash,
        last_seen,
        COALESCE(LAG(last_seen) OVER(PARTITION BY participant_id, product_id ORDER BY last_seen ASC), TIMESTAMP('2020-01-01')) as _valid_from,
        CASE
            -- if product was in latest extract, then it should be considered still active into the future
            WHEN last_seen = '{{ latest_processed_timestamp }}'
                THEN {{ make_end_of_valid_range("'2099-01-01'") }}
            ELSE {{ make_end_of_valid_range('last_seen') }}
        END AS _valid_to
    FROM distinct_data
),


int_payments__dim_product_data AS (
    SELECT
        version_data.participant_id,
        version_data.product_id,
        previous_version_id,
        original_version_id,
        product_code,
        product_description,
        product_type,
        activation_type,
        product_status,
        superseded,
        created_date,
        capping_type,
        multi_operator,
        capping_start_time,
        capping_end_time,
        rules_transaction_types,
        rules_default_limit,
        rules_max_fare_value,
        scheduled_start_date_time,
        scheduled_end_date_time,
        all_day,
        weekly_cap_start_day,
        weekly_cap_end_day,
        number_of_days_in_cap_window,
        capping_duration,
        number_of_transfer,
        capping_time_zone,
        capping_overlap_time,
        capping_application_level,
        route_capping_enabled,
        routes,
        zoned_capping_enabled,
        zoned_capping_mode,
        zoned_capping_pricing_type,
        on_peak_zones,
        off_peak_zones,
        incentive_enabled,
        incentive_type,
        discount_qualifier,
        configuration,
        _line_number,
        `instance`,
        feed_version,
        extract_filename,
        littlepay_export_ts,
        littlepay_export_date,
        ts,
        _key,
        _payments_key,
        version_data._content_hash,
        _valid_from,
        _valid_to
    FROM version_data
    LEFT JOIN unioned_products
        ON version_data.participant_id = unioned_products.participant_id
        AND version_data.product_id = unioned_products.product_id
        AND version_data._content_hash = unioned_products._content_hash
        AND version_data.last_seen = unioned_products.littlepay_export_ts
)

SELECT * FROM int_payments__dim_product_data
