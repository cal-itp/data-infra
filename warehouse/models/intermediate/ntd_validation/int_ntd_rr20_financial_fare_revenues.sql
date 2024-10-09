-- need fare rev and upt for each year.
{% set this_year = run_started_at.year %}
{% set last_year = this_year - 1 %}

WITH fare_rev_this_year AS (
  SELECT
    organization,
    api_report_period AS fiscal_year,
    item AS mode,
    operations_expended + capital_expended AS Fare_Revenues,
    MAX(api_report_last_modified_date) AS max_api_report_last_modified_date
     FROM {{ ref('stg_ntd_rr20_rural') }}
     WHERE type = "Fare Revenues"
     AND api_report_period = {{this_year}}
     GROUP BY organization, fiscal_year, mode, Fare_Revenues
),

upt_this_year AS (
  SELECT
    organization,
    api_report_period AS fiscal_year,
    item AS mode,
    annual_unlinked_pass_trips AS Annual_UPT,
    MAX(api_report_last_modified_date) AS max_api_report_last_modified_date
    FROM {{ ref('stg_ntd_rr20_rural') }}
     WHERE type = "Service Data"
     AND api_report_period = {{this_year}}
    GROUP BY organization, fiscal_year, mode, Annual_UPT
),

all_this_year AS (
  select fare_rev_this_year.organization,
    fare_rev_this_year.fiscal_year,
    fare_rev_this_year.mode,
    fare_rev_this_year.Fare_Revenues,
    upt_this_year.Annual_UPT
  FROM fare_rev_this_year
  FULL OUTER JOIN upt_this_year
    ON fare_rev_this_year.organization = upt_this_year.organization
    AND fare_rev_this_year.mode = upt_this_year.mode
),

fare_rev_last_year AS (
  SELECT
    organization,
    api_report_period AS fiscal_year,
    item AS mode,
    operations_expended + capital_expended AS Fare_Revenues,
    MAX(api_report_last_modified_date) AS max_api_report_last_modified_date
     FROM {{ ref('stg_ntd_rr20_rural') }}
     WHERE type = "Fare Revenues"
     AND api_report_period = {{last_year}}
     GROUP BY organization, fiscal_year, mode, Fare_Revenues
),

upt_last_year AS (
  SELECT
    organization,
    api_report_period AS fiscal_year,
    item AS mode,
    annual_unlinked_pass_trips AS Annual_UPT,
    MAX(api_report_last_modified_date) AS max_api_report_last_modified_date
    FROM {{ ref('stg_ntd_rr20_rural') }}
     WHERE type = "Service Data"
     AND api_report_period = {{last_year}}
    GROUP BY organization, fiscal_year, mode, Annual_UPT
),

all_last_year AS (
  select fare_rev_last_year.organization,
    fare_rev_last_year.fiscal_year,
    fare_rev_last_year.mode,
    fare_rev_last_year.Fare_Revenues,
    upt_last_year.Annual_UPT
  FROM fare_rev_last_year
  FULL OUTER JOIN upt_last_year
    ON fare_rev_last_year.organization = upt_last_year.organization
    AND fare_rev_last_year.mode = upt_last_year.mode
)

SELECT * FROM all_this_year

UNION ALL

SELECT * FROM all_last_year
