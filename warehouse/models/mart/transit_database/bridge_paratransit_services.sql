{{ config(materialized='table') }}

WITH services AS ( -- noqa
    SELECT *
    FROM {{ ref('int_transit_database__services_dim') }}
),

unnest_paratransit AS (
    SELECT
        key AS service_key,
        name AS service_name,
        paratransit_for AS paratransit_for_service_key,
        _is_current,
        _valid_from,
        _valid_to
    FROM services,
        services.paratransit_for AS paratransit_for
),

bridge_paratransit_services AS (
    SELECT
        unnested.service_key,
        unnested.service_name,
        services.key AS paratransit_for_service_key,
        services.name AS paratransit_for_service_name,
        (unnested._is_current AND services._is_current) AS _is_current,
        GREATEST(unnested._valid_from, services._valid_from) AS _valid_from,
        LEAST(unnested._valid_to, services._valid_to) AS _valid_to
    FROM unnest_paratransit AS unnested
    LEFT JOIN services
        ON unnested.paratransit_for_service_key = services.source_record_id
        AND unnested._valid_from < services._valid_to
        AND unnested._valid_to > services._valid_from
)

SELECT * FROM bridge_paratransit_services
