------
--- Compiles data for RR-20 Service checks from all years into one table for future computation
------

--- The 2022 data was *not* from the API and so formatted differently
--- We are *assuming* that data in 2024 and onwards will be the same format as 2023
--- If you get errors in 2024, check which columns may differ and read errors carefully.

---TO DO: insert parameter for loop, for each year, do what 2023 is doing,
--- and at the end, add another union statement
WITH service_2023 AS (
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
    AND api_report_period = 2023
    GROUP BY organization, fiscal_year, mode, Annual_VRM, Annual_VRH, Annual_UPT, Sponsored_UPT, VOMX
),

expenses_2023 AS (
    SELECT
    organization,
    api_report_period AS fiscal_year,
    item AS mode,
    operations_expended AS Total_Annual_Expenses_By_Mode,
    MAX(api_report_last_modified_date) AS max_api_report_last_modified_date
    FROM {{ ref('stg_ntd_rr20_rural') }}
    WHERE type = "Expenses by Mode"
    AND api_report_period = 2023
    GROUP BY organization, fiscal_year, mode, Total_Annual_Expenses_By_Mode
),

fare_rev_2023 AS (
    SELECT
    organization,
    api_report_period AS fiscal_year,
    SUM(operations_expended) AS Fare_Revenues,
    MAX(api_report_last_modified_date) AS max_api_report_last_modified_date
    from {{ ref('stg_ntd_rr20_rural') }}
    WHERE type = "Fare Revenues"
    AND api_report_period = 2023
    GROUP BY organization, fiscal_year
),

all_2023 as (
    SELECT DISTINCT
        service_2023.organization,
        service_2023.fiscal_year,
        service_2023.mode,
        expenses_2023.Total_Annual_Expenses_By_Mode,
        service_2023.Annual_VRM,
        service_2023.Annual_VRH,
        service_2023.Annual_UPT,
        service_2023.Sponsored_UPT,
        service_2023.VOMX,
        fare_rev_2023.Fare_Revenues
    FROM service_2023
    FULL OUTER JOIN expenses_2023
        ON service_2023.organization = expenses_2023.organization
        AND service_2023.fiscal_year = expenses_2023.fiscal_year
        AND service_2023.mode = expenses_2023.mode
    FULL OUTER JOIN fare_rev_2023
        ON service_2023.organization = fare_rev_2023.organization
        AND service_2023.fiscal_year = fare_rev_2023.fiscal_year
),

service2022 AS (
    SELECT
    Organization_Legal_Name AS organization,
    Fiscal_Year AS fiscal_year,
    Mode AS mode,
    Annual_VRM,
    Annual_VRH,
    Annual_UPT,
    Sponsored_UPT,
    VOMX
    FROM {{ ref('stg_ntd_2022_rr20_service') }}
),

expenses2022 AS (
    SELECT
    Organization_Legal_Name AS organization,
    Fiscal_Year AS fiscal_year,
    Mode AS mode,
    Total_Annual_Expenses_By_Mode
    FROM {{ ref('stg_ntd_2022_rr20_exp_by_mode') }}
    WHERE Operating_Capital = "Operating"
),

fare_rev_2022 AS (
    SELECT
    Organization_Legal_Name AS organization,
    Fiscal_Year AS fiscal_year,
    Fare_Revenues
    FROM {{ ref('stg_ntd_2022_rr20_financial') }}
    WHERE Operating_Capital = "Operating"
),

all_2022 AS (
    SELECT DISTINCT
     service2022.organization,
        service2022.fiscal_year,
        service2022.mode,
        expenses2022.Total_Annual_Expenses_By_Mode,
        service2022.Annual_VRM,
        service2022.Annual_VRH,
        service2022.Annual_UPT,
        service2022.Sponsored_UPT,
        service2022.VOMX,
        fare_rev_2022.Fare_Revenues
FROM service2022
FULL OUTER JOIN expenses2022
    ON service2022.organization = expenses2022.organization
    AND service2022.fiscal_year = expenses2022.fiscal_year
    AND service2022.mode = expenses2022.mode
INNER JOIN fare_rev_2022
    ON service2022.organization = fare_rev_2022.organization
    AND service2022.fiscal_year = fare_rev_2022.fiscal_year
)

SELECT * FROM all_2022

UNION ALL

SELECT * FROM all_2023
