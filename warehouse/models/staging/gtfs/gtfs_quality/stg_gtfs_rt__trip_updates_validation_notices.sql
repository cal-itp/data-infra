WITH raw_validation_notices AS (
    SELECT * FROM {{ source('external_gtfs_rt', 'trip_updates_validation_notices') }}
),

stg_gtfs_rt__trip_updates_validation_notices AS (
    SELECT
        -- this mainly exists so we can use WHERE in tests
        {{ dbt_utils.surrogate_key(['metadata.extract_ts', 'base64_url', 'errorMessage.messageId']) }} AS key,
        dt,
        hour,
        base64_url,
        metadata.gtfs_validator_version,
        metadata.extract_ts AS ts,
        metadata.extract_config.name AS name,
        metadata.extract_config.url AS url,
        metadata.extract_config.feed_type AS feed_type,
        metadata.extract_config.extracted_at AS _config_extract_ts,
        errorMessage AS error_message,
        occurrenceList AS occurrence_list
    FROM raw_validation_notices
)

SELECT * FROM stg_gtfs_rt__trip_updates_validation_notices
