{% macro gtfs_rt_stg_outcomes(step, source_table) %}

WITH raw_outcomes AS (
    SELECT
        *,
        {{ to_url_safe_base64('`extract`.config.url') }} AS base64_url
    FROM {{ source_table }}
    WHERE dt >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH) -- last 6 months
),

stg_gtfs_rt__agg_outcomes AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['`extract`.ts', 'base64_url']) }} AS key,
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
        {% if step == 'parse' %}
        header,
        JSON_VALUE(`extract`.response_headers, '$."last_modified"') AS last_modified_string,
        CASE WHEN JSON_VALUE(`extract`.response_headers, '$."last_modified"') like '%GMT' THEN PARSE_TIMESTAMP("%a, %d %b %Y %H:%M:%S GMT", JSON_VALUE(`extract`.response_headers, '$."last_modified"'))
             -- 1/28/2020 6:29:01 PM
             WHEN JSON_VALUE(`extract`.response_headers, '$."last_modified"') like '%PM' THEN PARSE_TIMESTAMP("%m/%d/%Y %I:%M:%S %p", JSON_VALUE(`extract`.response_headers, '$."last_modified"'))
        END AS last_modified_timestamp,
        {% else %}
        process_stderr,
        {% endif %}
        `extract`.ts AS extract_ts
    FROM raw_outcomes
)

SELECT * FROM stg_gtfs_rt__agg_outcomes

{% endmacro %}
