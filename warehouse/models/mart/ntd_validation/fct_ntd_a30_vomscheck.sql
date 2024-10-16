--- Since we don't have the Revenue Inventory table from Black Cat yet, we cannot do the other checks in the file voms_inventory_check.py.
--- When we do get that data, we can add them here in their own CTEs, one per check, and then UNION ALL the CTEs together.

WITH rr20f_180 as (
    SELECT organization,
    "RR20F-180: VOMS across forms" as name_of_check,
    fiscal_year as year_of_data,
    CASE WHEN ROUND(rr20_voms, 1) > ROUND(a30_vin_n, 1)
        THEN "Fail"
        ELSE "Pass"
    END as check_status,
    CONCAT("RR-20 VOMS = ", IF(rr20_voms IS NULL, ' ', CAST(ROUND(rr20_voms, 1) AS STRING)),
            ", A-30 VINs = ", IF(a30_vin_n IS NULL, ' ', CAST(ROUND(a30_vin_n, 1) AS STRING))
    ) AS value_checked,
    CASE WHEN ROUND(rr20_voms, 1) > ROUND(a30_vin_n, 1)
        THEN "Total VOMS is greater than total A-30 vehicles reported. Please clarify."
        ELSE "VOMS & A-30 vehicles reported are equal to and/or lower than active inventory."
    END as description,
    "" as Agency_Response,
    CURRENT_TIMESTAMP() AS date_checked
    FROM {{ ref('int_ntd_a30_voms_vins_totals') }}
)

SELECT * from rr20f_180
