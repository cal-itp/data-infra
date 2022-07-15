{{ config(materialized='table') }}

WITH latest_organizations AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__organizations'),
        order_by = 'calitp_extracted_at DESC'
        ) }}
),

dim_organizations AS (
    SELECT
        key,
        name,
        organization_type,
        roles,
        itp_id,
        details,
        caltrans_district,
        website,
        calitp_extracted_at
    FROM latest_organizations
)

SELECT * FROM dim_organizations
