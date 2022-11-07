{% macro gtfs_rt_stg_outcomes(step, source_table) %}

WITH raw_aggregation_outcomes AS (
    SELECT
        *,
        {{ to_url_safe_base64('`extract`.config.url') }} AS base64_url
    FROM {{ source_table }}
),

stg_gtfs_rt__agg_outcomes AS (
    SELECT
        dt,
        hour,
        `extract`.config.name AS name,
        `extract`.config.url AS url,
        `extract`.config.feed_type AS feed_type,
        `extract`.config.extracted_at AS _config_extract_ts,
        `extract`.config.schedule_url_for_validation AS schedule_url_for_validation,
        success AS {{ step }}_success,
        exception AS {{ step }}_exception,
        `extract`.response_code AS download_response_code,
        `extract`.response_headers AS download_response_headers,
        aggregation.step AS step,
        base64_url,
        `extract`.ts
    FROM raw_aggregation_outcomes
)

SELECT * FROM stg_gtfs_rt__agg_outcomes

{% endmacro %}
