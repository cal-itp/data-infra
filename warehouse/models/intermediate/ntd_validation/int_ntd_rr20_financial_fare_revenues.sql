-- need fare rev and upt for each year. 

WITH fare_rev_2023 as (
  select 
    organization,
    api_report_period as fiscal_year,
    item as mode,
    operations_expended + capital_expended as Fare_Revenues,
     from {{ ref('stg_ntd_2023_rr20_rural') }}
     WHERE type = "Fare Revenues"
),
upt_2023 as (
  select 
    organization,
    api_report_period as fiscal_year,
    item as mode,
    annual_unlinked_pass_trips as Annual_UPT
    from {{ ref('stg_ntd_2023_rr20_rural') }}
     WHERE type = "Service Data"
),
all_2023 as (
  select fare_rev_2023.*, upt_2023.Annual_UPT
  FROM fare_rev_2023 
  FULL OUTER JOIN upt_2023
    ON fare_rev_2023.organization = upt_2023.organization
    AND fare_rev_2023.mode = upt_2023.mode
),
fare_rev_2022 as (
  SELECT Organization_Legal_Name as organization,
  Fiscal_Year as fiscal_year,
  sum(Fare_Revenues) as Fare_Revenues
  FROM {{ ref('stg_ntd_2022_rr20_financial') }}
  GROUP BY organization, fiscal_year
),
upt_2022 as (
  select 
    Organization_Legal_Name as organization,
    Fiscal_Year as  fiscal_year,
    Mode as mode,
    Annual_UPT
from {{ ref('stg_ntd_2022_rr20_service') }}
),
all_2022 as (
  select fare_rev_2022.organization, fare_rev_2022.fiscal_year,
    upt_2022.Mode, fare_rev_2022.Fare_Revenues, upt_2022.Annual_UPT
  FROM fare_rev_2022 
  FULL OUTER JOIN upt_2022
    ON fare_rev_2022.organization = upt_2022.organization
)

SELECT * from all_2023

UNION ALL

SELECT * from all_2022
