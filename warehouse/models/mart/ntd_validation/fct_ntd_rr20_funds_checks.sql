--- We do identical CASE WHEN clauses in each CTE. The results determine 2 different column values but one can only specify 1 col/statement
{% set this_year = run_started_at.year %}
{% set last_year = this_year - 1 %}

WITH rr20f_070 AS (
 SELECT
    organization,
    "RR20F-070: 5311 Funds not reported" AS name_of_check,
    CASE WHEN ROUND(FTA_Formula_Grants_for_Rural_Areas_5311_This_Year) = 0  OR FTA_Formula_Grants_for_Rural_Areas_5311_This_Year IS NULL
        THEN "Fail"
        ELSE "Pass"
        END AS check_status,
    CONCAT("{{this_year}} = ", CAST(ROUND(FTA_Formula_Grants_for_Rural_Areas_5311_This_Year,0) AS STRING)) AS value_checked,
    CASE WHEN ROUND(FTA_Formula_Grants_for_Rural_Areas_5311_This_Year) = 0  OR FTA_Formula_Grants_for_Rural_Areas_5311_This_Year IS NULL
        THEN "The §5311 program is not listed as a revenue source in your report, Please double check and provide a narrative justification."
        ELSE ""
        END AS description,
    "" AS Agency_Response,
    CURRENT_TIMESTAMP() AS date_checked
    FROM {{ ref('int_ntd_rr20_financial_specific_funds') }}
),
rr20f_066  AS (
    SELECT
    organization,
    "RR20F-066: change from zero" AS name_of_check,
    CASE WHEN ((FTA_Formula_Grants_for_Rural_Areas_5311_This_Year = 0 OR FTA_Formula_Grants_for_Rural_Areas_5311_This_Year IS NULL)
                    AND (FTA_Formula_Grants_for_Rural_Areas_5311_Last_Year != 0 OR FTA_Formula_Grants_for_Rural_Areas_5311_Last_Year IS NOT NULL))
                    OR
                ((FTA_Formula_Grants_for_Rural_Areas_5311_This_Year != 0 OR FTA_Formula_Grants_for_Rural_Areas_5311_This_Year IS NOT NULL)
                AND (FTA_Formula_Grants_for_Rural_Areas_5311_Last_Year = 0 OR FTA_Formula_Grants_for_Rural_Areas_5311_Last_Year IS NULL))
        THEN "Fail"
        ELSE "Pass"
        END AS check_status,
    CONCAT("{{last_year}} = ", CAST(ROUND(FTA_Formula_Grants_for_Rural_Areas_5311_Last_Year,0) AS STRING),
           ", {{this_year}} = ", CAST(ROUND(FTA_Formula_Grants_for_Rural_Areas_5311_This_Year,0) AS STRING)) AS value_checked,
    CASE WHEN ((FTA_Formula_Grants_for_Rural_Areas_5311_This_Year = 0 OR FTA_Formula_Grants_for_Rural_Areas_5311_This_Year IS NULL)
                    AND (FTA_Formula_Grants_for_Rural_Areas_5311_Last_Year != 0 OR FTA_Formula_Grants_for_Rural_Areas_5311_Last_Year IS NOT NULL))
                    OR
                ((FTA_Formula_Grants_for_Rural_Areas_5311_This_Year != 0 OR FTA_Formula_Grants_for_Rural_Areas_5311_This_Year IS NOT NULL)
                AND (FTA_Formula_Grants_for_Rural_Areas_5311_Last_Year = 0 OR FTA_Formula_Grants_for_Rural_Areas_5311_Last_Year IS NULL))
        THEN "FTA_Formula_Grants_for_Rural_Areas_5311 funding changed either from or to zero compared to last year. Please provide a narrative justification."
        ELSE ""
        END AS description,
    "" AS Agency_Response,
    CURRENT_TIMESTAMP() AS date_checked
    FROM {{ ref('int_ntd_rr20_financial_specific_funds') }}
),
rr20f_065 AS (
 SELECT
    organization,
    "RR20F-065: 5311 Funds same value" AS name_of_check,
    CASE WHEN (FTA_Formula_Grants_for_Rural_Areas_5311_This_Year != 0 OR FTA_Formula_Grants_for_Rural_Areas_5311_This_Year IS NOT NULL)
                AND (FTA_Formula_Grants_for_Rural_Areas_5311_Last_Year != 0 OR FTA_Formula_Grants_for_Rural_Areas_5311_Last_Year IS NOT NULL)
                AND (FTA_Formula_Grants_for_Rural_Areas_5311_This_Year = FTA_Formula_Grants_for_Rural_Areas_5311_Last_Year)
        THEN "Fail"
        ELSE "Pass"
        END AS check_status,
    CONCAT("{{last_year}} = ", CAST(ROUND(FTA_Formula_Grants_for_Rural_Areas_5311_Last_Year,0) AS STRING),
           ", {{this_year}} = ", CAST(ROUND(FTA_Formula_Grants_for_Rural_Areas_5311_This_Year,0) AS STRING)) AS value_checked,
    CASE WHEN (FTA_Formula_Grants_for_Rural_Areas_5311_This_Year != 0 OR FTA_Formula_Grants_for_Rural_Areas_5311_This_Year IS NOT NULL)
                AND (FTA_Formula_Grants_for_Rural_Areas_5311_Last_Year != 0 OR FTA_Formula_Grants_for_Rural_Areas_5311_Last_Year IS NOT NULL)
                AND (FTA_Formula_Grants_for_Rural_Areas_5311_This_Year = FTA_Formula_Grants_for_Rural_Areas_5311_Last_Year)
        THEN "You have identical values for FTA_Formula_Grants_for_Rural_Areas_5311 funding in {{last_year}} and {{this_year}}, which is unusual. Please provide a narrative justification."
        ELSE ""
        END AS description,
    "" AS Agency_Response,
    CURRENT_TIMESTAMP() AS date_checked
    FROM {{ ref('int_ntd_rr20_financial_specific_funds') }}
),
rr20f_013 AS (
    SELECT
    organization,
    "RR20F-013: Other Directly Generated Funds same value" AS name_of_check,
    CASE WHEN (Other_Directly_Generated_Funds_This_Year != 0 OR Other_Directly_Generated_Funds_This_Year IS NOT NULL)
                AND (Other_Directly_Generated_Funds_Last_Year != 0 OR Other_Directly_Generated_Funds_Last_Year IS NOT NULL)
                AND (Other_Directly_Generated_Funds_This_Year = Other_Directly_Generated_Funds_Last_Year)
        THEN "Fail"
        ELSE "Pass"
        END AS check_status,
    CONCAT("last_year = ", CAST(ROUND(Other_Directly_Generated_Funds_Last_Year,0) AS STRING),
           ", {{this_year}} = ", CAST(ROUND(Other_Directly_Generated_Funds_This_Year,0) AS STRING)) AS value_checked,
    CASE WHEN (Other_Directly_Generated_Funds_This_Year != 0 OR Other_Directly_Generated_Funds_This_Year IS NOT NULL)
                AND (Other_Directly_Generated_Funds_Last_Year != 0 OR Other_Directly_Generated_Funds_Last_Year IS NOT NULL)
                AND (Other_Directly_Generated_Funds_This_Year = Other_Directly_Generated_Funds_Last_Year)
        THEN "You have identical values for Other_Directly_Generated_Funds funding in {{last_year}} and {{this_year}}, which is unusual. Please provide a narrative justification."
        ELSE ""
        END AS description,
    "" AS Agency_Response,
    CURRENT_TIMESTAMP() AS date_checked
    FROM {{ ref('int_ntd_rr20_financial_specific_funds') }}
),
rr20f_068 AS (
 SELECT
    organization,
    "RR20F-068: 5311 Funds rounded to thousand" AS name_of_check,
    CASE WHEN MOD(CAST(ROUND(FTA_Formula_Grants_for_Rural_Areas_5311_This_Year,0) AS INT),1000) = 0  AND FTA_Formula_Grants_for_Rural_Areas_5311_This_Year IS NOT NULL
        THEN "Fail"
        ELSE "Pass"
        END AS check_status,
    CONCAT("{{this_year}} = ", CAST(ROUND(FTA_Formula_Grants_for_Rural_Areas_5311_This_Year,0) AS STRING)) AS value_checked,
    CASE WHEN MOD(CAST(ROUND(FTA_Formula_Grants_for_Rural_Areas_5311_This_Year,0) AS INT),1000) = 0  AND FTA_Formula_Grants_for_Rural_Areas_5311_This_Year IS NOT NULL
    THEN "FTA_Formula_Grants_for_Rural_Areas_5311 are rounded to the nearest thousand, but should be reported as exact values. Please double check and provide a narrative justification."
        ELSE ""
        END AS description,
    "" AS Agency_Response,
    CURRENT_TIMESTAMP() AS date_checked
    FROM {{ ref('int_ntd_rr20_financial_specific_funds') }}
),
rr20f_024 AS (
    SELECT
    organization,
    "RR20F-024: Local Funds rounded to thousand" AS name_of_check,
    CASE WHEN MOD(CAST(ROUND(Local_Funds_This_Year) AS INT),1000) = 0  AND Local_Funds_This_Year IS NOT NULL
        THEN "Fail"
        ELSE "Pass"
        END AS check_status,
    CONCAT("{{this_year}} = ", CAST(ROUND(Local_Funds_This_Year) AS STRING)) AS value_checked,
    CASE WHEN MOD(CAST(ROUND(Local_Funds_This_Year) AS INT),1000) = 0 AND Local_Funds_This_Year IS NOT NULL
        THEN "Local Funds are rounded to the nearest thousand, but should be reported as exact values. Please double check and provide a narrative justification."
        ELSE ""
        END AS description,
    "" AS Agency_Response,
    CURRENT_TIMESTAMP() AS date_checked
    FROM {{ ref('int_ntd_rr20_financial_specific_funds') }}
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
