-------
--- Two checks on reported facilities. NTD error ID #s A10-032, A10-030
-------

WITH a10_032 as (
    SELECT organization,
    "A10-032: Whole Number Facilities" as name_of_check,
    CASE WHEN MOD(CAST(ROUND(total_facilities, 1) as numeric), 1) != 0
        THEN "Fail"
        ELSE "Pass"
    END as check_status,
    CONCAT("Total facilities = ", CAST(ROUND(total_facilities, 2) AS string)) AS value_checked,
    CASE WHEN MOD(CAST(ROUND(total_facilities, 1) as numeric), 1) != 0
        THEN "The reported total facilities do not add up to a whole number. Please explain."
        ELSE ""
    END as description,
    "" as Agency_Response,
    CURRENT_TIMESTAMP() AS date_checked
    FROM {{ ref('int_ntd_a10_facilitiesdata') }}
),

a10_030 as (
    SELECT organization,
    "A10-030: Zero Facilities Reported" as name_of_check,
    CASE WHEN ROUND(total_facilities, 1) = 0
        THEN "Fail"
        ELSE "Pass"
    END as check_status,
    CONCAT("Total facilities = ", CAST(ROUND(total_facilities, 2) AS string)) AS value_checked,
    CASE WHEN ROUND(total_facilities, 1) = 0
        THEN "There are no reported facilities. Please explain."
        ELSE ""
    END as description,
    "" as Agency_Response,
    CURRENT_TIMESTAMP() AS date_checked
    FROM {{ ref('int_ntd_a10_facilitiesdata') }}
)

SELECT * from a10_032

UNION ALL

SELECT * from a10_030
