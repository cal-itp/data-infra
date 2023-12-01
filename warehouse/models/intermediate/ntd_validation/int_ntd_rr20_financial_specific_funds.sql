-------
-- NTD validation errors about these 1 specific funding sources. 
--- ID #s RR20F-070, RR20F-065, RR20F-068, RR20F-066, RR20F-013. Sums the capital expenses across all funding sources
--- In 2022 the data is a different format than 2023 **and onwards**. 
--- Only needed for the 2023 error checking (to compare to "last year"). In 2024 you don't need 2022 data.
-------

WITH longform_2023 AS (
    SELECT
    organization,
    api_report_period AS fiscal_year,
    operations_expended + capital_expended AS total_expended,
    REPLACE(
      REPLACE(
        REPLACE(item, 'FTA Formula Grants for Rural Areas (§5311)', 'FTA_Formula_Grants_for_Rural_Areas_5311'),
        'Other Directly Generated Funds', 'Other_Directly_Generated_Funds'),
    'Local Funds', 'Local_Funds') as item
     FROM {{ ref('stg_ntd_2023_rr20_rural') }}
     WHERE item LIKE "%Directly Generated Funds%" OR
      item LIKE "%Formula Grants for Rural Areas%" OR
      item LIKE "Local Funds"
),
wide_2023 AS (
    SELECT * FROM
    (SELECT * FROM longform_2023)
    PIVOT(AVG(total_expended) FOR item IN ('FTA_Formula_Grants_for_Rural_Areas_5311', 'Other_Directly_Generated_Funds', 'Local_Funds'))
    ORDER BY organization
),
data_2022 AS (
    SELECT Organization_Legal_Name as organization,
        Fiscal_Year as fiscal_year,
        SUM(Other_Directly_Generated_Funds) as Other_Directly_Generated_Funds_2022,
        SUM(FTA_Formula_Grants_for_Rural_Areas_5311) as FTA_Formula_Grants_for_Rural_Areas_5311_2022,
        Null as Local_Funds_2022
    FROM {{ ref('stg_ntd_2022_rr20_financial') }}
    GROUP BY 1,2
    ORDER BY organization
)

select wide_2023.organization, 
    wide_2023.FTA_Formula_Grants_for_Rural_Areas_5311 as FTA_Formula_Grants_for_Rural_Areas_5311_2023,
    wide_2023.Other_Directly_Generated_Funds as Other_Directly_Generated_Funds_2023,
    wide_2023.Local_Funds as Local_Funds_2023,
    data_2022.FTA_Formula_Grants_for_Rural_Areas_5311_2022,
    data_2022.Other_Directly_Generated_Funds_2022,
    data_2022.Local_Funds_2022
from wide_2023
FULL OUTER JOIN data_2022
    ON wide_2023.organization = data_2022.organization
ORDER BY organization
