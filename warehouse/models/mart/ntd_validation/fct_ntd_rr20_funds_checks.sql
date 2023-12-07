--- We do identical CASE WHEN clauses in each CTE. The results determine 2 different column values but one can only specify 1 col/statement

WITH rr20f_070 as (
 select
    organization,
    "RR20F-070: 5311 Funds not reported" as name_of_check,
    CASE WHEN ROUND(FTA_Formula_Grants_for_Rural_Areas_5311_2023) = 0  OR FTA_Formula_Grants_for_Rural_Areas_5311_2023 IS NULL
        THEN "Fail"
        ELSE "Pass"
        END as check_status,
    CASE WHEN ROUND(FTA_Formula_Grants_for_Rural_Areas_5311_2023) = 0  OR FTA_Formula_Grants_for_Rural_Areas_5311_2023 IS NULL
        THEN "The §5311 program is not listed as a revenue source in your report, Please double check and provide a narrative justification."
        ELSE ""
        END AS description,
    CONCAT("2023 = ", CAST(ROUND(FTA_Formula_Grants_for_Rural_Areas_5311_2023,0) AS STRING)) as value_checked,
    CURRENT_TIMESTAMP() AS date_checked
    from {{ ref('int_ntd_rr20_financial_specific_funds') }}
),
rr20f_066  as (
    select
    organization,
    "RR20F-066: change from zero" as name_of_check,
    CASE WHEN ((FTA_Formula_Grants_for_Rural_Areas_5311_2023 = 0 OR FTA_Formula_Grants_for_Rural_Areas_5311_2023 IS NULL)
                    AND (FTA_Formula_Grants_for_Rural_Areas_5311_2022 != 0 OR FTA_Formula_Grants_for_Rural_Areas_5311_2022 IS NOT NULL))
                    OR
                ((FTA_Formula_Grants_for_Rural_Areas_5311_2023 != 0 OR FTA_Formula_Grants_for_Rural_Areas_5311_2023 IS NOT NULL)
                AND (FTA_Formula_Grants_for_Rural_Areas_5311_2022 = 0 OR FTA_Formula_Grants_for_Rural_Areas_5311_2022 IS NULL))
        THEN "Fail"
        ELSE "Pass"
        END as check_status,
    CASE WHEN ((FTA_Formula_Grants_for_Rural_Areas_5311_2023 = 0 OR FTA_Formula_Grants_for_Rural_Areas_5311_2023 IS NULL)
                    AND (FTA_Formula_Grants_for_Rural_Areas_5311_2022 != 0 OR FTA_Formula_Grants_for_Rural_Areas_5311_2022 IS NOT NULL))
                    OR
                ((FTA_Formula_Grants_for_Rural_Areas_5311_2023 != 0 OR FTA_Formula_Grants_for_Rural_Areas_5311_2023 IS NOT NULL)
                AND (FTA_Formula_Grants_for_Rural_Areas_5311_2022 = 0 OR FTA_Formula_Grants_for_Rural_Areas_5311_2022 IS NULL))
        THEN "FTA_Formula_Grants_for_Rural_Areas_5311 funding changed either from or to zero compared to last year. Please provide a narrative justification."
        ELSE ""
        END AS description,
    CONCAT("2022 = ", CAST(ROUND(FTA_Formula_Grants_for_Rural_Areas_5311_2022,0) AS STRING),
            "2023 = ", CAST(ROUND(FTA_Formula_Grants_for_Rural_Areas_5311_2023,0) AS STRING)) as value_checked,
    CURRENT_TIMESTAMP() AS date_checked
    from {{ ref('int_ntd_rr20_financial_specific_funds') }}
),
rr20f_065 as (
 select
    organization,
    "RR20F-065: 5311 Funds same value" as name_of_check,
    CASE WHEN (FTA_Formula_Grants_for_Rural_Areas_5311_2023 != 0 OR FTA_Formula_Grants_for_Rural_Areas_5311_2023 IS NOT NULL)
                AND (FTA_Formula_Grants_for_Rural_Areas_5311_2022 != 0 OR FTA_Formula_Grants_for_Rural_Areas_5311_2022 IS NOT NULL)
                AND (FTA_Formula_Grants_for_Rural_Areas_5311_2023 = FTA_Formula_Grants_for_Rural_Areas_5311_2022)
        THEN "Fail"
        ELSE "Pass"
        END as check_status,
    CASE WHEN (FTA_Formula_Grants_for_Rural_Areas_5311_2023 != 0 OR FTA_Formula_Grants_for_Rural_Areas_5311_2023 IS NOT NULL)
                AND (FTA_Formula_Grants_for_Rural_Areas_5311_2022 != 0 OR FTA_Formula_Grants_for_Rural_Areas_5311_2022 IS NOT NULL)
                AND (FTA_Formula_Grants_for_Rural_Areas_5311_2023 = FTA_Formula_Grants_for_Rural_Areas_5311_2022)
        THEN "You have identical values for FTA_Formula_Grants_for_Rural_Areas_5311 funding in 2022 and 2023, which is unusual. Please provide a narrative justification."
        ELSE ""
        END AS description,
    CONCAT("2022 = ", CAST(ROUND(FTA_Formula_Grants_for_Rural_Areas_5311_2022,0) AS STRING),
            "2023 = ", CAST(ROUND(FTA_Formula_Grants_for_Rural_Areas_5311_2023,0) AS STRING)) as value_checked,
    CURRENT_TIMESTAMP() AS date_checked
    from {{ ref('int_ntd_rr20_financial_specific_funds') }}
),
rr20f_013 as (
    select
    organization,
    "RR20F-013: Other Directly Generated Funds same value" as name_of_check,
    CASE WHEN (Other_Directly_Generated_Funds_2023 != 0 OR Other_Directly_Generated_Funds_2023 IS NOT NULL)
                AND (Other_Directly_Generated_Funds_2022 != 0 OR Other_Directly_Generated_Funds_2022 IS NOT NULL)
                AND (Other_Directly_Generated_Funds_2023 = Other_Directly_Generated_Funds_2022)
        THEN "Fail"
        ELSE "Pass"
        END as check_status,
    CASE WHEN (Other_Directly_Generated_Funds_2023 != 0 OR Other_Directly_Generated_Funds_2023 IS NOT NULL)
                AND (Other_Directly_Generated_Funds_2022 != 0 OR Other_Directly_Generated_Funds_2022 IS NOT NULL)
                AND (Other_Directly_Generated_Funds_2023 = Other_Directly_Generated_Funds_2022)
        THEN "You have identical values for Other_Directly_Generated_Funds funding in 2022 and 2023, which is unusual. Please provide a narrative justification."
        ELSE ""
        END AS description,
    CONCAT("2022 = ", CAST(ROUND(Other_Directly_Generated_Funds_2022,0) AS STRING),
            "2023 = ", CAST(ROUND(Other_Directly_Generated_Funds_2023,0) AS STRING)) as value_checked,
    CURRENT_TIMESTAMP() AS date_checked
    from {{ ref('int_ntd_rr20_financial_specific_funds') }}
),
rr20f_068 as (
 select
    organization,
    "RR20F-068: 5311 Funds rounded to thousand" as name_of_check,
    CASE WHEN MOD(CAST(ROUND(FTA_Formula_Grants_for_Rural_Areas_5311_2023,0) AS INT),1000) = 0  AND FTA_Formula_Grants_for_Rural_Areas_5311_2023 IS NOT NULL
        THEN "Fail"
        ELSE "Pass"
        END as check_status,
    CASE WHEN MOD(CAST(ROUND(FTA_Formula_Grants_for_Rural_Areas_5311_2023,0) AS INT),1000) = 0  AND FTA_Formula_Grants_for_Rural_Areas_5311_2023 IS NOT NULL
    THEN "FTA_Formula_Grants_for_Rural_Areas_5311 are rounded to the nearest thousand, but should be reported as exact values. Please double check and provide a narrative justification."
        ELSE ""
        END AS description,
    CONCAT("2023 = ", CAST(ROUND(FTA_Formula_Grants_for_Rural_Areas_5311_2023,0) AS STRING)) as value_checked,
    CURRENT_TIMESTAMP() AS date_checked
    from {{ ref('int_ntd_rr20_financial_specific_funds') }}
),
rr20f_024 as (
    select
    organization,
    "RR20F-024: Local Funds rounded to thousand" as name_of_check,
    CASE WHEN MOD(CAST(ROUND(Local_Funds_2023) AS INT),1000) = 0  AND Local_Funds_2023 IS NOT NULL
        THEN "Fail"
        ELSE "Pass"
        END as check_status,
    CASE WHEN MOD(CAST(ROUND(Local_Funds_2023) AS INT),1000) = 0 AND Local_Funds_2023 IS NOT NULL
        THEN "Local Funds are rounded to the nearest thousand, but should be reported as exact values. Please double check and provide a narrative justification."
        ELSE ""
        END AS description,
    CONCAT("2023 = ", CAST(ROUND(Local_Funds_2023) AS STRING)) as value_checked,
    CURRENT_TIMESTAMP() AS date_checked
    from {{ ref('int_ntd_rr20_financial_specific_funds') }}
)

SELECT * FROM rr20f_070
UNION ALL
SELECT * FROM rr20f_066
UNION ALL
SELECT * FROM rr20f_065
UNION ALL
SELECT * FROM rr20f_013
UNION ALL
SELECT * FROM rr20f_068
UNION ALL
SELECT * FROM rr20f_024
ORDER BY organization
