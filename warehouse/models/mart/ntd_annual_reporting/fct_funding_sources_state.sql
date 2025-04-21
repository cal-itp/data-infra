WITH staging_funding_sources_state AS (
    SELECT *
    FROM {{ ref('stg_ntd__funding_sources_state') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_funding_sources_state AS (
    SELECT
        stg.agency,
        stg.agency_voms,
        stg.city,
        stg.general_funds,
        stg.ntd_id,
        stg.organization_type,
        stg.primary_uza_population,
        stg.reduced_reporter_funds,
        stg.report_year,
        stg.reporter_type,
        stg.state,
        stg.total,
        stg.total_questionable,
        stg.transportation_funds,
        stg.uace_code,
        stg.uza_name,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_funding_sources_state AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
    WHERE stg.state = 'CA'
)

SELECT * FROM fct_funding_sources_state
