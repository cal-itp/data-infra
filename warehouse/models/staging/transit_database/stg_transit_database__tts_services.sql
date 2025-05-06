WITH

once_daily_services AS (
    SELECT *
    -- have to use base table to get the california transit base organization record ids
    FROM {{ ref('base_tts_services_idmap') }}
),

stg_transit_database__tts_services AS (
    SELECT
        id,
        {{ trim_make_empty_string_null(column_name = "name") }} AS name,
        contract_names AS contracts,
        dt
    FROM once_daily_services
)

SELECT * FROM stg_transit_database__tts_services
