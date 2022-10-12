WITH

source AS (
    SELECT * FROM {{ source('airtable_tts', 'transit_technology_stacks__services') }}
),

base_transit_technology_stacks__services AS (
    SELECT
        id AS key,
        {{ trim_make_empty_string_null(column_name = "name") }} AS name,
        ts
    FROM source
    QUALIFY ROW_NUMBER() OVER (PARTITION BY name, ts ORDER BY null) = 1
)

SELECT * FROM base_transit_technology_stacks__services
