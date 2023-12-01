--- We do identical CASE WHEN clauses in each CTE. The results determine 2 different column values but one can only specify 1 col/statement

WITH rr20f_0010a as (
    select 
    organization,
    "RR20F-001OA: equal totalsfor operating expenses" as name_of_check,
    CASE WHEN (ROUND(Total_Annual_Op_Revenues_Expended,0) != ROUND(Total_Annual_Op_Expenses_by_Mode,0)) 
        THEN "Fail"
        ELSE "Pass"
        END as check_status,
    CASE WHEN (ROUND(Total_Annual_Op_Revenues_Expended,0) != ROUND(Total_Annual_Op_Expenses_by_Mode,0)) 
        THEN "Total_Annual_Revenues_Expended should, but does not, equal Total_Annual_Expenses_by_Mode. Please provide a narrative justification."
        ELSE ""
        END as description,
    CONCAT("Total_Annual_Revenues_Expended = $", CAST(ROUND(Total_Annual_Op_Revenues_Expended,0) AS STRING), 
            ",Total_Annual_Expenses_by_Mode = $", CAST(ROUND(Total_Annual_Op_Expenses_by_Mode,0) AS STRING)) as value_checked,
    CURRENT_TIMESTAMP() AS date_checked
    FROM {{ ref('int_ntd_rr20_financial_total_exp') }}
), 
rr20f_001c as(
    select 
    organization,
    "RR20F-001C: equal totals for capital expenses by mode and funding source expenditures" as name_of_check,
    CASE WHEN (ROUND(Total_Annual_Cap_Expenses_byMode,0) != ROUND(Total_Annual_Cap_Expenses_byFunds,0)) 
        THEN "Fail"
        ELSE "Pass"
        END as check_status,
    CASE WHEN (ROUND(Total_Annual_Cap_Expenses_byMode,0) != ROUND(Total_Annual_Cap_Expenses_byFunds,0)) 
        THEN "The sum of Total Expenses for all modes for Uses of Capital does not equal the sum of all values entered for Directly Generated, Non-Federal and Federal Government Funds for Uses of Capital. Please revise or explain."
        ELSE ""
        END as description,
    CONCAT("Total_Annual_Cap_Expenses_byMode = $", CAST(ROUND(Total_Annual_Cap_Expenses_byMode,0) AS STRING), 
            ",Total_Annual_Cap_Expenses_byFunds = $", CAST(ROUND(Total_Annual_Cap_Expenses_byFunds,0) AS STRING)) as value_checked,
    CURRENT_TIMESTAMP() AS date_checked
    FROM {{ ref('int_ntd_rr20_financial_total_exp') }}
)

SELECT * FROM rr20f_0010a

UNION ALL

SELECT * FROM rr20f_001c
