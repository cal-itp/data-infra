{{ config(materialized='table') }}

WITH organizations AS ( -- noqa
    SELECT *
    FROM {{ ref('int_transit_database__organizations_dim') }}
),

unnest_parents AS (
    SELECT
        key AS organization_key,
        name AS organization_name,
        parent AS parent_organization_key,
        _is_current,
        _valid_from,
        _valid_to
    FROM organizations,
        organizations.parent_organization AS parent
),

bridge_parent_organizations AS (
    SELECT
        unnested.organization_key,
        unnested.organization_name,
        organizations.key AS parent_organization_key,
        organizations.name AS parent_organization_name,
        (unnested._is_current AND organizations._is_current) AS _is_current,
        GREATEST(unnested._valid_from, organizations._valid_from) AS _valid_from,
        LEAST(unnested._valid_to, organizations._valid_to) AS _valid_to
    FROM unnest_parents AS unnested
    LEFT JOIN organizations
        ON unnested.parent_organization_key = organizations.source_record_id
        AND unnested._valid_from < organizations._valid_to
        AND unnested._valid_to > organizations._valid_from
)

SELECT * FROM bridge_parent_organizations
