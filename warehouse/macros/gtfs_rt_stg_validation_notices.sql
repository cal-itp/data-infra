{% macro gtfs_rt_stg_validation_notices(source_table) %}

WITH stg_gtfs_rt__validation_notices AS (
    SELECT
        -- this mainly exists so we can use WHERE in tests
        {{ dbt_utils.generate_surrogate_key(['metadata.extract_ts', 'base64_url', 'errorMessage.validationRule.errorId']) }} AS key,
        dt,
        hour,
        base64_url,
        metadata.gtfs_validator_version,
        metadata.extract_ts AS ts,
        metadata.extract_config.name AS name,
        metadata.extract_config.url AS url,
        metadata.extract_config.feed_type AS feed_type,
        metadata.extract_config.extracted_at AS _config_extract_ts,
        errorMessage.messageId AS error_message_message_id,
        errorMessage.gtfsRtFeedIterationModel AS error_message_gtfs_rt_feed_iteration_model,
        errorMessage.errorDetails AS error_message_error_details,
        errorMessage.validationRule.errorId AS error_message_validation_rule_error_id,
        errorMessage.validationRule.severity AS error_message_validation_rule_severity,
        errorMessage.validationRule.title AS error_message_validation_rule_title,
        errorMessage.validationRule.errorDescription AS error_message_validation_rule_error_description,
        errorMessage.validationRule.occurrenceSuffix AS error_message_validation_rule_occurrence_suffix,
        occurrenceList AS occurrence_list
    FROM {{ source_table }}
    WHERE dt >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH) -- last 6 months
)

SELECT * FROM stg_gtfs_rt__validation_notices

{% endmacro %}
