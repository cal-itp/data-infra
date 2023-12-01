------
--- Compiles data for RR-20 Financial checks on total amounts (operating and capital)
--- into one table for downstream validation checks. "Prior year" data not needed
--- NTD error ID #s RR20F-001OA, RR20F-001C, RR20F-182
------

WITH total_operations_exp_2023 as(
    select organization,
    api_report_period as fiscal_year,
    sum(operations_expended) as Total_Annual_Op_Expenses_by_Mode
    from {{ ref('stg_ntd_2023_rr20_rural') }}
     WHERE css_class = "expense"
     group by organization, api_report_period
),
total_capital_exp_bymode_2023 as (
    select organization,
    api_report_period as fiscal_year,
    sum(capital_expended) as Total_Annual_Cap_Expenses_byMode
    from {{ ref('stg_ntd_2023_rr20_rural') }}
     WHERE css_class = "expense"
     group by organization, api_report_period
),
total_operations_rev_2023 as (
    select organization,
    api_report_period as fiscal_year,
    sum(operations_expended) as Total_Annual_Op_Revenues_Expended
    from {{ ref('stg_ntd_2023_rr20_rural') }}
     WHERE css_class = "revenue"
     group by organization, api_report_period
),
total_cap_exp_byfunds_2023 as (
    select organization,
    api_report_period as fiscal_year,
    sum(capital_expended) as Total_Annual_Cap_Expenses_byFunds
    from {{ ref('stg_ntd_2023_rr20_rural') }}
    WHERE css_class = "revenue"
     group by organization, api_report_period
)

SELECT 
    total_operations_exp_2023.*,
    total_capital_exp_bymode_2023.Total_Annual_Cap_Expenses_byMode,
    total_operations_rev_2023.Total_Annual_Op_Revenues_Expended,
    total_cap_exp_byfunds_2023.Total_Annual_Cap_Expenses_byFunds
FROM total_operations_exp_2023
FULL OUTER JOIN total_capital_exp_bymode_2023
    ON total_operations_exp_2023.organization = total_capital_exp_bymode_2023.organization
    AND total_operations_exp_2023.fiscal_year = total_capital_exp_bymode_2023.fiscal_year
FULL OUTER JOIN total_operations_rev_2023
    ON total_operations_exp_2023.organization = total_operations_rev_2023.organization
    AND total_operations_exp_2023.fiscal_year = total_operations_rev_2023.fiscal_year
FULL OUTER JOIN total_cap_exp_byfunds_2023
    ON total_operations_exp_2023.organization = total_cap_exp_byfunds_2023.organization
    AND total_operations_exp_2023.fiscal_year = total_cap_exp_byfunds_2023.fiscal_year
