WITH source AS (
    SELECT * FROM {{ source('external_enghouse', 'taps') }}
),

clean_columns AS (
    SELECT
        CAST(operator_id AS STRING) AS operator_id,
        {{ trim_make_empty_string_null('tap_id') }} AS tap_id,
        {{ trim_make_empty_string_null('mapping_terminal_id') }} AS mapping_terminal_id,
        {{ trim_make_empty_string_null('mapping_merchant_id') }} AS mapping_merchant_id,
        SAFE_CAST(terminal AS INT64) AS terminal,
        {{ trim_make_empty_string_null('token') }} AS token,
        {{ trim_make_empty_string_null('masked_pan') }} AS masked_pan,
        SAFE_CAST(server_date AS TIMESTAMP) AS server_date,
        SAFE_CAST(terminal_date AS TIMESTAMP) AS terminal_date,
        SAFE_CAST(tx_number AS INT64) AS tx_number,
        SAFE_CAST(tx_status AS INT64) AS tx_status,
        {{ trim_make_empty_string_null('payment_reference') }} AS payment_reference,
        SAFE_CAST(terminal_spdh_code AS INT64) AS terminal_spdh_code,
        {{ trim_make_empty_string_null('denylist_version') }} AS denylist_version,
        {{ trim_make_empty_string_null('transit_data') }} AS transit_data,
        SAFE_CAST(currency AS INT64) AS currency,
        {{ trim_make_empty_string_null('par') }} AS par,
        {{ trim_make_empty_string_null('fare_mode') }} AS fare_mode,
        {{ trim_make_empty_string_null('fare_type') }} AS fare_type,
        SAFE_CAST(fare_value AS INT64) AS fare_value,
        {{ trim_make_empty_string_null('fare_description') }} AS fare_description,
        {{ trim_make_empty_string_null('fare_linked_id') }} AS fare_linked_id,
        {{ trim_make_empty_string_null('gps_longitude') }} AS gps_longitude,
        SAFE_CAST(gps_latitude AS NUMERIC) AS gps_latitude,
        SAFE_CAST(gps_altitude AS NUMERIC) AS gps_altitude,
        SAFE_CAST(vehicle_public_number AS INT64) AS vehicle_public_number,
        {{ trim_make_empty_string_null('vehicle_name') }} AS vehicle_name,
        SAFE_CAST(stop_id AS INT64) AS stop_id,
        {{ trim_make_empty_string_null('stop_name') }} AS stop_name,
        {{ trim_make_empty_string_null('platform_id') }} AS platform_id,
        {{ trim_make_empty_string_null('platform_name') }} AS platform_name,
        SAFE_CAST(zone_id AS INT64) AS zone_id,
        {{ trim_make_empty_string_null('zone_name') }} AS zone_name,
        CAST(line_public_number AS STRING) AS line_public_number,
        {{ trim_make_empty_string_null('line_name') }} AS line_name,
        {{ trim_make_empty_string_null('line_direction') }} AS line_direction,
        {{ trim_make_empty_string_null('trip_public_number') }} AS trip_public_number,
        {{ trim_make_empty_string_null('trip_name') }} AS trip_name,
        {{ trim_make_empty_string_null('service_public_number') }} AS service_public_number,
        {{ trim_make_empty_string_null('service_name') }} AS service_name,
        {{ trim_make_empty_string_null('driver_id') }} AS driver_id,
        agency,
        dt,
        {{ dbt_utils.generate_surrogate_key([ 'operator_id', 'tap_id', 'mapping_terminal_id', 'mapping_merchant_id', 'terminal', 'token',
            'masked_pan', 'server_date', 'terminal_date', 'tx_number', 'tx_status', 'payment_reference',
            'terminal_spdh_code', 'denylist_version', 'transit_data', 'currency', 'par', 'fare_mode', 'fare_type', 'fare_value',
            'fare_description', 'fare_linked_id', 'gps_longitude', 'gps_latitude', 'gps_altitude', 'vehicle_public_number', 'vehicle_name',
            'stop_id', 'stop_name', 'platform_id', 'platform_name', 'zone_id', 'zone_name', 'line_public_number', 'line_name',
            'line_direction', 'trip_public_number', 'trip_name', 'service_public_number', 'service_name', 'driver_id']) }} AS _content_hash
    FROM source
),

deduplicated AS (
    SELECT * FROM (
        SELECT
            *,
            ROW_NUMBER() OVER (PARTITION BY _content_hash ORDER BY dt ASC) AS row_num
        FROM clean_columns
    )
    WHERE row_num = 1
),

stg_enghouse__taps AS (
    SELECT
        operator_id,
        tap_id,
        mapping_terminal_id,
        mapping_merchant_id,
        terminal,
        token,
        masked_pan,
        server_date,
        terminal_date,
        tx_number,
        tx_status,
        payment_reference,
        terminal_spdh_code,
        denylist_version,
        transit_data,
        currency,
        par,
        fare_mode,
        fare_type,
        fare_value,
        fare_description,
        fare_linked_id,
        gps_longitude,
        gps_latitude,
        gps_altitude,
        vehicle_public_number,
        vehicle_name,
        stop_id,
        stop_name,
        platform_id,
        platform_name,
        zone_id,
        zone_name,
        line_public_number,
        line_name,
        line_direction,
        trip_public_number,
        trip_name,
        service_public_number,
        service_name,
        driver_id,
        agency,
        dt,
        _content_hash
    FROM deduplicated
)

SELECT * FROM stg_enghouse__taps
