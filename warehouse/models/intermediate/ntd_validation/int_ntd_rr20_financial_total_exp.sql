------
--- Compiles data for RR-20 Financial checks on total amounts (operating and capital)
--- into one table for downstream validation checks. "Prior year" data not needed
--- NTD error ID #s RR20F-001OA, RR20F-001C, RR20F-182
------
{% set this_year = run_started_at.year %}

WITH total_operations_exp AS(
    SELECT organization,
    api_report_period AS fiscal_year,
    SUM(operations_expended) AS Total_Annual_Op_Expenses_by_Mode,
    MAX(api_report_last_modified_date) AS max_api_report_last_modified_date
    FROM {{ ref('stg_ntd_rr20_rural') }}
     WHERE css_class = "expense"
     AND api_report_period = {{this_year}}
     GROUP BY organization, api_report_period
),

total_capital_exp_bymode AS (
    SELECT organization,
    api_report_period AS fiscal_year,
    SUM(capital_expended) AS Total_Annual_Cap_Expenses_byMode,
    MAX(api_report_last_modified_date) AS max_api_report_last_modified_date
    FROM {{ ref('stg_ntd_rr20_rural') }}
     WHERE css_class = "expense"
     AND api_report_period = {{this_year}}
    GROUP BY organization, api_report_period
),

total_operations_rev AS (
    SELECT organization,
    api_report_period AS fiscal_year,
    SUM(operations_expended) AS Total_Annual_Op_Revenues_Expended,
    MAX(api_report_last_modified_date) AS max_api_report_last_modified_date
    FROM {{ ref('stg_ntd_rr20_rural') }}
     WHERE css_class = "revenue"
     AND api_report_period = {{this_year}}
    GROUP BY organization, api_report_period
),

total_cap_exp_byfunds AS (
    SELECT organization,
    api_report_period AS fiscal_year,
    SUM(capital_expended) AS Total_Annual_Cap_Expenses_byFunds,
    MAX(api_report_last_modified_date) AS max_api_report_last_modified_date
    FROM {{ ref('stg_ntd_rr20_rural') }}
    WHERE css_class = "revenue"
    AND api_report_period = {{this_year}}
    GROUP BY organization, api_report_period
)

SELECT
    total_operations_exp.organization,
    total_operations_exp.fiscal_year,
    total_operations_exp.Total_Annual_Op_Expenses_by_Mode,
    total_capital_exp_bymode.Total_Annual_Cap_Expenses_byMode,
    total_operations_rev.Total_Annual_Op_Revenues_Expended,
    total_cap_exp_byfunds.Total_Annual_Cap_Expenses_byFunds
FROM total_operations_exp
FULL OUTER JOIN total_capital_exp_bymode
    ON total_operations_exp.organization = total_capital_exp_bymode.organization
    AND total_operations_exp.fiscal_year = total_capital_exp_bymode.fiscal_year
FULL OUTER JOIN total_operations_rev
    ON total_operations_exp.organization = total_operations_rev.organization
    AND total_operations_exp.fiscal_year = total_operations_rev.fiscal_year
FULL OUTER JOIN total_cap_exp_byfunds
    ON total_operations_exp.organization = total_cap_exp_byfunds.organization
    AND total_operations_exp.fiscal_year = total_cap_exp_byfunds.fiscal_year
