------
--- Compiles data for RR-20 Service checks from all years into one table for future computation
------

--- The 2022 data was *not* from the API and so formatted differently
--- We are *assuming* that data in 2024 and onwards will be the same format as 2023
--- If you get errors in 2024, check which columns may differ and read errors carefully.

---TO DO: insert parameter for loop, for each year, do what 2023 is doing, 
--- and at the end, add another union statement
with data_2023 as (
    select 
    organization,
    api_report_period as fiscal_year,
    item as mode,
    description as operating_capital,
    CASE
        WHEN description = "Operating Expenses" THEN operations_expended
        WHEN description = "Capital Expenses" THEN capital_expended
        ELSE Null
    END as Total_Annual_Expenses_By_Mode,
    annual_vehicle_rev_miles as Annual_VRM,
    annual_vehicle_rev_hours as Annual_VRH,
    annual_unlinked_pass_trips as Annual_UPT,
    sponsored_service_upt as Sponsored_UPT,
    annual_vehicle_max_service as VOMX
    from {{ ref('stg_ntd_2023_rr20_rural') }}
    WHERE type = "Expenses by Mode"
),

service2022 as (
    select 
    Organization_Legal_Name as organization,
    Fiscal_Year as  fiscal_year,
    Mode as mode,
    Annual_VRM,
    Annual_VRH,
    Annual_UPT,
    Sponsored_UPT,
    VOMX
    from {{ ref('stg_ntd_2022_rr20_service') }}
),

expenses2022 as (
    select 
    Organization_Legal_Name as organization,
    Fiscal_Year as  fiscal_year,
    Operating_Capital as operating_capital,
    Mode as mode,
    Total_Annual_Expenses_By_Mode
    FROM {{ ref('stg_ntd_2022_rr20_exp_by_mode') }}
),

all_2022 as (
    select service2022.organization,
        service2022.fiscal_year,
        service2022.mode,
        expenses2022.operating_capital,
        expenses2022.Total_Annual_Expenses_By_Mode,
        service2022.Annual_VRM,
        service2022.Annual_VRH,
        service2022.Annual_UPT,
        service2022.Sponsored_UPT,
        service2022.VOMX
from service2022
FULL OUTER JOIN expenses2022 
    ON service2022.organization = expenses2022.organization
    AND service2022.fiscal_year = expenses2022.fiscal_year
    AND service2022.mode = expenses2022.mode
)

select * FROM all_2022

UNION ALL

select * from data_2023

