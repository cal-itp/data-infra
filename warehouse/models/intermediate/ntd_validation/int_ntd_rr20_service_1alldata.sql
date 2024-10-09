------
--- Compiles data for RR-20 Service checks from all years into one table for future computation
------
{% set this_year = run_started_at.year %}
{% set last_year = this_year - 1 %}

WITH service_this_year AS (
    SELECT
    organization,
    api_report_period AS fiscal_year,
    item AS mode,
    annual_vehicle_rev_miles AS Annual_VRM,
    annual_vehicle_rev_hours AS Annual_VRH,
    annual_unlinked_pass_trips AS Annual_UPT,
    sponsored_service_upt AS Sponsored_UPT,
    annual_vehicle_max_service AS VOMX,
    MAX(api_report_last_modified_date) AS max_api_report_last_modified_date
    FROM {{ ref('stg_ntd_rr20_rural') }}
    WHERE type = "Service Data"
    AND api_report_period = {{this_year}}
    GROUP BY organization, fiscal_year, mode, Annual_VRM, Annual_VRH, Annual_UPT, Sponsored_UPT, VOMX
),

expenses_this_year AS (
    SELECT
    organization,
    api_report_period AS fiscal_year,
    item AS mode,
    operations_expended AS Total_Annual_Expenses_By_Mode,
    MAX(api_report_last_modified_date) AS max_api_report_last_modified_date
    FROM {{ ref('stg_ntd_rr20_rural') }}
    WHERE type = "Expenses by Mode"
    AND api_report_period = {{this_year}}
    GROUP BY organization, fiscal_year, mode, Total_Annual_Expenses_By_Mode
),

fare_rev_this_year AS (
    SELECT
    organization,
    api_report_period AS fiscal_year,
    SUM(operations_expended) AS Fare_Revenues,
    MAX(api_report_last_modified_date) AS max_api_report_last_modified_date
    from {{ ref('stg_ntd_rr20_rural') }}
    WHERE type = "Fare Revenues"
    AND api_report_period = {{this_year}}
    GROUP BY organization, fiscal_year
),

all_this_year as (
    SELECT DISTINCT
        service_this_year.organization,
        service_this_year.fiscal_year,
        service_this_year.mode,
        expenses_this_year.Total_Annual_Expenses_By_Mode,
        service_this_year.Annual_VRM,
        service_this_year.Annual_VRH,
        service_this_year.Annual_UPT,
        service_this_year.Sponsored_UPT,
        service_this_year.VOMX,
        fare_rev_this_year.Fare_Revenues
    FROM service_this_year
    FULL OUTER JOIN expenses_this_year
        ON service_this_year.organization = expenses_this_year.organization
        AND service_this_year.fiscal_year = expenses_this_year.fiscal_year
        AND service_this_year.mode = expenses_this_year.mode
    FULL OUTER JOIN fare_rev_this_year
        ON service_this_year.organization = fare_rev_this_year.organization
        AND service_this_year.fiscal_year = fare_rev_this_year.fiscal_year
),

service_last_year AS (
    SELECT
    organization,
    api_report_period AS fiscal_year,
    item AS mode,
    annual_vehicle_rev_miles AS Annual_VRM,
    annual_vehicle_rev_hours AS Annual_VRH,
    annual_unlinked_pass_trips AS Annual_UPT,
    sponsored_service_upt AS Sponsored_UPT,
    annual_vehicle_max_service AS VOMX,
    MAX(api_report_last_modified_date) AS max_api_report_last_modified_date
    FROM {{ ref('stg_ntd_rr20_rural') }}
    WHERE type = "Service Data"
    AND api_report_period = {{last_year}}
    GROUP BY organization, fiscal_year, mode, Annual_VRM, Annual_VRH, Annual_UPT, Sponsored_UPT, VOMX
),

expenses_last_year AS (
    SELECT
    organization,
    api_report_period AS fiscal_year,
    item AS mode,
    operations_expended AS Total_Annual_Expenses_By_Mode,
    MAX(api_report_last_modified_date) AS max_api_report_last_modified_date
    FROM {{ ref('stg_ntd_rr20_rural') }}
    WHERE type = "Expenses by Mode"
    AND api_report_period = {{last_year}}
    GROUP BY organization, fiscal_year, mode, Total_Annual_Expenses_By_Mode
),

fare_rev_last_year AS (
    SELECT
    organization,
    api_report_period AS fiscal_year,
    SUM(operations_expended) AS Fare_Revenues,
    MAX(api_report_last_modified_date) AS max_api_report_last_modified_date
    from {{ ref('stg_ntd_rr20_rural') }}
    WHERE type = "Fare Revenues"
    AND api_report_period = {{last_year}}
    GROUP BY organization, fiscal_year
),

all_last_year as (
    SELECT DISTINCT
        service_last_year.organization,
        service_last_year.fiscal_year,
        service_last_year.mode,
        expenses_last_year.Total_Annual_Expenses_By_Mode,
        service_last_year.Annual_VRM,
        service_last_year.Annual_VRH,
        service_last_year.Annual_UPT,
        service_last_year.Sponsored_UPT,
        service_last_year.VOMX,
        fare_rev_last_year.Fare_Revenues
    FROM service_last_year
    FULL OUTER JOIN expenses_last_year
        ON service_last_year.organization = expenses_last_year.organization
        AND service_last_year.fiscal_year = expenses_last_year.fiscal_year
        AND service_last_year.mode = expenses_last_year.mode
    FULL OUTER JOIN fare_rev_last_year
        ON service_last_year.organization = fare_rev_last_year.organization
        AND service_last_year.fiscal_year = fare_rev_last_year.fiscal_year
)

SELECT * FROM all_last_year

UNION ALL

SELECT * FROM all_this_year
