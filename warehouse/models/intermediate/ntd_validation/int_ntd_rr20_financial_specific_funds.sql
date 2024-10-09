-------
-- NTD validation errors about these 1 specific funding sources.
--- ID #s RR20F-070, RR20F-065, RR20F-068, RR20F-066, RR20F-013. Sums the capital expenses across all funding sources
-------
{% set this_year = run_started_at.year %}
{% set last_year = this_year - 1 %}

WITH longform_this_year AS (
    SELECT
    organization,
    api_report_period AS fiscal_year,
    operations_expended + capital_expended AS total_expended,
    REPLACE(
      REPLACE(
        REPLACE(item, 'FTA Formula Grants for Rural Areas (§5311)', 'FTA_Formula_Grants_for_Rural_Areas_5311'),
        'Other Directly Generated Funds', 'Other_Directly_Generated_Funds'),
      'Local Funds', 'Local_Funds') AS item,
    MAX(api_report_last_modified_date) AS max_api_report_last_modified_date
     FROM {{ ref('stg_ntd_rr20_rural') }}
    WHERE item LIKE ANY("%Directly Generated Funds%","%Formula Grants for Rural Areas%","Local Funds")
      AND api_report_period = {{ this_year }}
    GROUP BY organization, fiscal_year, total_expended, item
),

wide_this_year AS (
    SELECT * FROM
    (SELECT * FROM longform_this_year)
    PIVOT(AVG(total_expended) FOR item IN ('FTA_Formula_Grants_for_Rural_Areas_5311', 'Other_Directly_Generated_Funds', 'Local_Funds'))
),

longform_last_year AS (
    SELECT
    organization,
    api_report_period AS fiscal_year,
    operations_expended + capital_expended AS total_expended,
    REPLACE(
      REPLACE(
        REPLACE(item, 'FTA Formula Grants for Rural Areas (§5311)', 'FTA_Formula_Grants_for_Rural_Areas_5311'),
        'Other Directly Generated Funds', 'Other_Directly_Generated_Funds'),
      'Local Funds', 'Local_Funds') AS item,
    MAX(api_report_last_modified_date) AS max_api_report_last_modified_date
     FROM {{ ref('stg_ntd_rr20_rural') }}
    WHERE item LIKE ANY("%Directly Generated Funds%","%Formula Grants for Rural Areas%","Local Funds")
      AND api_report_period = {{ last_year }}
    GROUP BY organization, fiscal_year, total_expended, item
),

wide_last_year AS (
    SELECT * FROM
    (SELECT * FROM longform_last_year)
    PIVOT(AVG(total_expended) FOR item IN ('FTA_Formula_Grants_for_Rural_Areas_5311', 'Other_Directly_Generated_Funds', 'Local_Funds'))
)

SELECT COALESCE(wide_this_year.organization, wide_last_year.organization) AS organization,
       wide_this_year.FTA_Formula_Grants_for_Rural_Areas_5311 AS FTA_Formula_Grants_for_Rural_Areas_5311_This_Year,
       wide_this_year.Other_Directly_Generated_Funds AS Other_Directly_Generated_Funds_This_Year,
       wide_this_year.Local_Funds AS Local_Funds_This_Year,
       wide_last_year.FTA_Formula_Grants_for_Rural_Areas_5311 AS FTA_Formula_Grants_for_Rural_Areas_5311_Last_Year,
       wide_last_year.Other_Directly_Generated_Funds AS Other_Directly_Generated_Funds_Last_Year
  FROM wide_this_year
  FULL OUTER JOIN wide_last_year
    ON wide_this_year.organization = wide_last_year.organization
 ORDER BY organization
