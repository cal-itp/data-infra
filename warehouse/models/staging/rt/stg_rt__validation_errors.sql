WITH validation_service_alerts AS (
    SELECT *, 'service_alerts' as rt_feed_type
    FROM {{ source('gtfs_rt_external_tables', 'service_alerts_validations') }}
),

validation_trip_updates AS (
    SELECT *, 'trip_updates' as rt_feed_type
    FROM {{ source('gtfs_rt_external_tables', 'trip_updates_validations') }}
),

validation_vehicle_positions AS (
    SELECT *, 'vehicle_positions' as rt_feed_type
    FROM {{ source('gtfs_rt_external_tables', 'vehicle_positions_validations') }}
),

unioned AS (
    SELECT *
    FROM validation_service_alerts
    UNION ALL
    SELECT *
    FROM validation_trip_updates
    UNION ALL
    SELECT *
    FROM validation_vehicle_positions
),

stg_rt__validation_errors as (
    SELECT
        metadata.itp_id as calitp_itp_id,
        metadata.url as calitp_url_number,
        metadata.path as original_file_path,
        rt_feed_type,
        dt as date,

        errorMessage.validationRule.title as rule_title,
        errorMessage.validationRule.errorDescription as error_description,
        errorMessage.validationRule.occurrenceSuffix as occurrence_suffix,
        errorMessage.validationRule.errorId as error_id,

        occurrence.prefix as occurrence_prefix,
        offset as nth_occurrence,

        {{ dbt_utils.surrogate_key(['metadata.path', 'errorMessage.validationRule.errorId', 'offset']) }} as key
    FROM unioned, unnest(occurrenceList) as occurrence WITH OFFSET
)

SELECT * FROM stg_rt__validation_errors
