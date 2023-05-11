{{ config(materialized='table') }}

WITH orgs AS ( -- noqa
    SELECT *
    FROM {{ ref('int_transit_database__organizations_dim') }}
),

ntd AS ( -- noqa
    SELECT *
    FROM {{ ref('int_transit_database__ntd_agency_info_dim') }}
),

bridge_organizations_x_ntd_agency_info AS (
    SELECT
        orgs.key AS organization_key,
        orgs.name AS organization_name,
        ntd.key AS ntd_agency_info_key,
        ntd.ntd_id,
        (orgs._is_current AND ntd._is_current) AS _is_current,
        GREATEST(orgs._valid_from, ntd._valid_from) AS _valid_from,
        LEAST(orgs._valid_to, ntd._valid_to) AS _valid_to
    FROM orgs
    INNER JOIN ntd
        ON orgs.ntd_agency_info_key = ntd.source_record_id
        AND orgs._valid_from < ntd._valid_to
        AND orgs._valid_to > ntd._valid_from
)

SELECT * FROM bridge_organizations_x_ntd_agency_info
