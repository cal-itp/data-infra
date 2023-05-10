{{ config(materialized='table') }}

WITH orgs AS ( -- noqa
    SELECT *
    FROM {{ ref('int_transit_database__organizations_dim') }}
),

ntd AS ( -- noqa
    SELECT *
    FROM {{ ref('ntd_agency_to_organization') }}
),

bridge_organizations_x_ntd_agency_info AS (
    SELECT
        orgs.key AS organization_key,
        orgs.source_record_id,
        orgs.name AS organization_name,
        ntd.ntd_id,
        ntd.organization_record_id,
        orgs._is_current,
        orgs._valid_from,
        orgs._valid_to
    FROM orgs
    INNER JOIN ntd
        ON orgs.source_record_id = ntd.organization_record_id
)

SELECT * FROM bridge_organizations_x_ntd_agency_info
