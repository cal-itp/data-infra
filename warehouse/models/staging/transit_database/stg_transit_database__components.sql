WITH
source AS (
    SELECT * FROM {{ source('airtable_tts', 'transit_technology_stacks__components') }}
),

stg_transit_database__components AS (
    SELECT
        id AS record_id,
        {{ trim_make_empty_string_null(column_name = "name") }} AS name,
        aliases,
        description,
        function_group,
        system,
        location,
        organization_stack_components AS service_components,
        products,
        properties___features AS properties_and_features,
        contracts,
        ts
    FROM source
)

SELECT * FROM stg_transit_database__components
