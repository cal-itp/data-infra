
WITH rr20f_0010a as (
    select 
    organization,
    "RR20F-001OA: equal totalsfor operating expenses" as name_of_check,
    CASE WHEN (ROUND(Total_Annual_Op_Revenues_Expended,0) != ROUND(Total_Annual_Op_Expenses_byMode,0)) THEN "Fail"
        ELSE "Pass"
        END as check_status,
    CASE WHEN check_status = "Fail" THEN "Total_Annual_Revenues_Expended should, but does not, equal Total_Annual_Expenses_by_Mode. Please provide a narrative justification."
        WHEN check_status = "Pass" THEN ""
        ELSE NULL
        END as description,
    COALESCE("Total_Annual_Revenues_Expended = $", ROUND(Total_Annual_Op_Revenues_Expended,0), 
            ",Total_Annual_Expenses_by_Mode = $", ROUND(Total_Annual_Op_Expenses_byMode,0)) as value_checked,
    CURRENT_TIMESTAMP() AS date_checked
    FROM {{ ref('int_ntd_rr20_financial_total_exp') }}
), 
rr20f_001c as(
    select 
    organization,
    "RR20F-001C: equal totals for capital expenses by mode and funding source expenditures" as name_of_check,
    CASE WHEN (ROUND(Total_Annual_Cap_Expenses_byMode,0) != ROUND(Total_Annual_Cap_Expenses_byFunds,0)) THEN "Fail"
        ELSE "Pass"
        END as check_status,
    CASE WHEN check_status = "Fail" THEN "The sum of Total Expenses for all modes for Uses of Capital does not equal the sum of all values entered for Directly Generated, Non-Federal and Federal Government Funds for Uses of Capital. Please revise or explain."
        WHEN check_status = "Pass" THEN ""
        ELSE NULL
        END as description,
    COALESCE("Total_Annual_Cap_Expenses_byMode = $", ROUND(Total_Annual_Cap_Expenses_byMode,0), 
            ",Total_Annual_Cap_Expenses_byFunds = $", ROUND(Total_Annual_Cap_Expenses_byFunds,0)) as value_checked,
    CURRENT_TIMESTAMP() AS date_checked
    FROM {{ ref('int_ntd_rr20_financial_total_exp') }}
)

SELECT * FROM rr20f_0010a

UNION ALL

SELECT * FROM rr20f_001c