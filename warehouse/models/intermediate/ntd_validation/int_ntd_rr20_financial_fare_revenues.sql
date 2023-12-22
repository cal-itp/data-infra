-- need fare rev and upt for each year.

WITH fare_rev_2023 AS (
  SELECT
    organization,
    api_report_period AS fiscal_year,
    item AS mode,
    operations_expended + capital_expended AS Fare_Revenues,
    MAX(api_report_last_modified_date) AS max_api_report_last_modified_date
     FROM {{ ref('stg_ntd_rr20_rural') }}
     WHERE type = "Fare Revenues"
     AND api_report_period = 2023
     GROUP BY organization, fiscal_year, mode, Fare_Revenues
),
upt_2023 AS (
  SELECT
    organization,
    api_report_period AS fiscal_year,
    item AS mode,
    annual_unlinked_pass_trips AS Annual_UPT,
    MAX(api_report_last_modified_date) AS max_api_report_last_modified_date
    FROM {{ ref('stg_ntd_rr20_rural') }}
     WHERE type = "Service Data"
     AND api_report_period = 2023
    GROUP BY organization, fiscal_year, mode, Annual_UPT
),
all_2023 AS (
  select fare_rev_2023.organization,
    fare_rev_2023.fiscal_year,
    fare_rev_2023.mode,
    fare_rev_2023.Fare_Revenues,
    upt_2023.Annual_UPT
  FROM fare_rev_2023
  FULL OUTER JOIN upt_2023
    ON fare_rev_2023.organization = upt_2023.organization
    AND fare_rev_2023.mode = upt_2023.mode
),
fare_rev_2022 AS (
  SELECT Organization_Legal_Name AS organization,
  Fiscal_Year AS fiscal_year,
  SUM(Fare_Revenues) AS Fare_Revenues
  FROM {{ ref('stg_ntd_2022_rr20_financial') }}
  GROUP BY organization, fiscal_year
),
upt_2022 AS (
  select
    Organization_Legal_Name AS organization,
    Fiscal_Year AS  fiscal_year,
    Mode AS mode,
    Annual_UPT
FROM {{ ref('stg_ntd_2022_rr20_service') }}
),
all_2022 AS (
  select fare_rev_2022.organization, fare_rev_2022.fiscal_year,
    upt_2022.Mode, fare_rev_2022.Fare_Revenues, upt_2022.Annual_UPT
  FROM fare_rev_2022
  FULL OUTER JOIN upt_2022
    ON fare_rev_2022.organization = upt_2022.organization
)

SELECT * FROM all_2023

UNION ALL

SELECT * FROM all_2022
