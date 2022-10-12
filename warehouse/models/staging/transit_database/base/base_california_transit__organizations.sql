WITH

source AS (
    SELECT * FROM {{ source('airtable', 'california_transit__organizations') }}
),

base_california_transit__organizations AS (
    SELECT
        id AS key,
        {{ trim_make_empty_string_null(column_name = "name") }} AS name,
        organization_type,
        roles,
        itp_id,
        ntp_id,
        alias_ as alias,
        details,
        caltrans_district,
        mobility_services_managed,
        parent_organization,
        website,
        reporting_category,
        funding_programs,
        gtfs_datasets_produced,
        gtfs_static_status,
        gtfs_realtime_status,
        ts
    FROM source
    WHERE name IS NOT NULL
)

SELECT * FROM base_california_transit__organizations
