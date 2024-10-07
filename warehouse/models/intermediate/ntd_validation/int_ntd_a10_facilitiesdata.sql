---------
---- For assessing A10-032: Check that sum of total facilities for each agency, across all modes, is a whole number.
---------
{% set this_year = run_started_at.year %}

WITH fac_by_mode as (
SELECT
    organization,
    api_report_period,
    service_mode,
    COALESCE(ROUND(pt_owned_by_service_provider,2) ,0)
    + COALESCE(ROUND(pt_owned_by_public_agency, 2),0)
    + COALESCE(ROUND(pt_leased_by_public_agency, 2), 0)
    + COALESCE(ROUND(pt_leased_by_service_provider, 2), 0)
    + COALESCE(ROUND(do_owned, 2), 0)
    + COALESCE(ROUND(do_leased_by_public_agency,2), 0)
    + COALESCE(ROUND(do_leased_from_private_entity, 2), 0)
    as total_facilities,
    MAX(api_report_last_modified_date) as max_api_report_last_modified_date
FROM {{ ref('stg_ntd_a10') }}
WHERE api_report_period = {{this_year}}
GROUP BY organization, api_report_period, service_mode, total_facilities
),

collapsed_fac as (
    SELECT
        organization,
        api_report_period,
        SUM(total_facilities) as total_facilities
    FROM fac_by_mode
    GROUP BY organization, api_report_period
)

select * from collapsed_fac
