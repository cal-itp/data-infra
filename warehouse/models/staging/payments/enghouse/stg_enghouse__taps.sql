WITH source AS (
    SELECT * FROM {{ source('external_enghouse', 'taps') }}
),

clean_columns AS (
    SELECT
        CAST(Operator_Id AS STRING) AS operator_id,
        {{ trim_make_empty_string_null('tap_id') }} AS tap_id,
        {{ trim_make_empty_string_null('mapping_terminal_id') }} AS mapping_terminal_id,
        {{ trim_make_empty_string_null('mapping_merchant_id') }} AS mapping_merchant_id,
        SAFE_CAST(terminal AS INT64) AS terminal,
        {{ trim_make_empty_string_null('token') }} AS token,
        {{ trim_make_empty_string_null('masked_pan') }} AS masked_pan,
        SAFE_CAST(expiry AS INT64) AS expiry,
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
        {{ trim_make_empty_string_null('Fare_Mode') }} AS fare_mode,
        {{ trim_make_empty_string_null('Fare_Type') }} AS fare_type,
        SAFE_CAST(Fare_Value AS INT64) AS fare_value,
        {{ trim_make_empty_string_null('Fare_Description') }} AS fare_description,
        {{ trim_make_empty_string_null('Fare_Linked_Id') }} AS fare_linked_id,
        {{ trim_make_empty_string_null('ID') }} AS gps_longitude,
        SAFE_CAST(Gps_Latitude AS NUMERIC) AS gps_latitude,
        SAFE_CAST(Gps_Altitude AS NUMERIC) AS gps_altitude,
        SAFE_CAST(Vehicle_Public_Number AS INT64) AS vehicle_public_number,
        {{ trim_make_empty_string_null('Vehicle_Name') }} AS vehicle_name,
        SAFE_CAST(Stop_Id AS INT64) AS stop_id,
        {{ trim_make_empty_string_null('Stop_Name') }} AS stop_name,
        {{ trim_make_empty_string_null('Platform_Id') }} AS platform_id,
        {{ trim_make_empty_string_null('Platform_Name') }} AS platform_name,
        SAFE_CAST(Zone_Id AS INT64) AS zone_id,
        {{ trim_make_empty_string_null('Zone_Name') }} AS zone_name,
        CAST(Line_Public_Number AS STRING) AS line_public_number,
        {{ trim_make_empty_string_null('Line_Name') }} AS line_name,
        {{ trim_make_empty_string_null('Line_Direction') }} AS line_direction,
        {{ trim_make_empty_string_null('Trip_Public_Number') }} AS trip_public_number,
        {{ trim_make_empty_string_null('Trip_Name') }} AS trip_name,
        {{ trim_make_empty_string_null('Service_Public_Number') }} AS service_public_number,
        {{ trim_make_empty_string_null('Service_Name') }} AS service_name,
        {{ trim_make_empty_string_null('Driver_ID') }} AS driver_id,
        {{ dbt_utils.generate_surrogate_key([ 'Operator_Id', 'tap_id', 'mapping_terminal_id', 'mapping_merchant_id', 'terminal', 'token',
            'masked_pan', 'expiry', 'server_date', 'terminal_date', 'tx_number', 'tx_status', 'payment_reference',
            'terminal_spdh_code', 'denylist_version', 'transit_data', 'currency', 'par', 'Fare_Mode', 'Fare_Type', 'Fare_Value',
            'Fare_Description', 'Fare_Linked_Id', 'ID', 'Gps_Latitude', 'Gps_Altitude', 'Vehicle_Public_Number', 'Vehicle_Name',
            'Stop_Id', 'Stop_Name', 'Platform_Id', 'Platform_Name', 'Zone_Id', 'Zone_Name', 'Line_Public_Number', 'Line_Name',
            'Line_Direction', 'Trip_Public_Number', 'Trip_Name', 'Service_Public_Number', 'Service_Name', 'Driver_ID']) }} AS _content_hash
    FROM source
),

deduplicated AS (
    SELECT * FROM (
        SELECT
            *,
            ROW_NUMBER() OVER (PARTITION BY _content_hash ORDER BY (SELECT NULL)) AS row_num
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
        expiry,
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
        _content_hash
    FROM deduplicated
)

SELECT * FROM stg_enghouse__taps
