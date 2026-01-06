WITH source AS (
    SELECT * FROM {{ source('external_enghouse', 'ticket_results') }}
),

clean_columns AS (
    SELECT
        SAFE_CAST(operator_id AS INT64) AS operator_id,
        {{ trim_make_empty_string_null('id') }} AS id,
        {{ trim_make_empty_string_null('ticket_id') }} AS ticket_id,
        {{ trim_make_empty_string_null('station_name') }} AS station_name,
        SAFE_CAST(amount AS NUMERIC) AS amount,
        {{ trim_make_empty_string_null('clearing_id') }} AS clearing_id,
        {{ trim_make_empty_string_null('reason') }} AS reason,
        {{ trim_make_empty_string_null('tap_id') }} AS tap_id,
        {{ trim_make_empty_string_null('ticket_type') }} AS ticket_type,
        SAFE_CAST(created_dttm AS TIMESTAMP) AS created_dttm,
        {{ trim_make_empty_string_null('line') }} AS line,
        {{ trim_make_empty_string_null('start_station') }} AS start_station,
        {{ trim_make_empty_string_null('end_station') }} AS end_station,
        SAFE_CAST(start_dttm AS TIMESTAMP) AS start_dttm,
        SAFE_CAST(end_dttm AS TIMESTAMP) AS end_dttm,
        {{ trim_make_empty_string_null('ticket_code') }} AS ticket_code,
        {{ trim_make_empty_string_null('additional_infos') }} AS additional_infos,
        {{ dbt_utils.generate_surrogate_key(['operator_id', 'id', 'ticket_id', 'station_name', 'amount', 'clearing_id',
            'reason', 'tap_id', 'ticket_type', 'created_dttm', 'line', 'start_station', 'end_station', 'start_dttm',
            'end_dttm', 'ticket_code', 'additional_infos']) }} AS _content_hash
    FROM source
),

stg_enghouse__ticket_results AS (
    SELECT
        operator_id,
        id,
        ticket_id,
        station_name,
        amount,
        clearing_id,
        reason,
        tap_id,
        ticket_type,
        created_dttm,
        line,
        start_station,
        end_station,
        start_dttm,
        end_dttm,
        ticket_code,
        additional_infos,
        _content_hash
    FROM clean_columns
)

SELECT * FROM stg_enghouse__ticket_results
