{{ config(materialized='table') }}

WITH latest AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__organizations'),
        order_by = 'calitp_extracted_at DESC'
        ) }}
),

unnest_parents AS (
    SELECT
        key AS organization_key,
        name AS organization_name,
        parent AS parent_organization_key,
        calitp_extracted_at
    FROM latest,
        latest.parent_organization AS parent
),

bridge_parent_organizations AS (
    SELECT
        t1.*,
        t2.name AS parent_organization_name
    FROM unnest_parents AS t1
    LEFT JOIN latest AS t2
        ON t1.parent_organization_key = t2.key
        AND t1.calitp_extracted_at = t2.calitp_extracted_at
)

SELECT * FROM bridge_parent_organizations
