--- We do identical CASE WHEN clauses in each CTE.
-- The results determine 2 different column values but one can only specify 1 col/statement
{% set cph_threshold = 0.3 %}
{% set mpv_threshold = 0.2 %}
{% set vrm_threshold = 0.3 %}
{% set frpt_threshold = 0.25 %}
{% set rs_threshold = 0.15 %}
{% set tph_threshold = 0.3 %}
{% set start_date = run_started_at.strftime("%Y-%m-%d") %}
{% set this_year = run_started_at.year %}
{% set last_year = this_year - 1 %}

WITH rr20f_005 as (
 select
    organization,
    "RR20F-005: Cost per Hour change" as name_of_check,
    mode,
    {{this_year}} as year_of_data,
    CASE WHEN (cph_this_year IS NULL OR cph_this_year = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{this_year}}, "-10-31") AS DATE)
            THEN "Did Not Run"
        WHEN (cph_last_year IS NULL OR cph_last_year = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{last_year}}, "-10-31") AS DATE)
            THEN "Did Not Run"
        WHEN ABS(ROUND(cph_this_year) - ROUND(cph_last_year) / ROUND(cph_last_year)) >= {{cph_threshold}} THEN "Fail"
        ELSE "Pass"
        END as check_status,
    CONCAT({{this_year}}, " = ", CAST(ROUND(cph_this_year,1) AS STRING),
            ", ", {{last_year}}, " = ", CAST(ROUND(cph_last_year,1) AS STRING),
            "chg = ",
          CAST(ROUND((ROUND(cph_this_year,1) - ROUND(cph_last_year,1))/ABS(ROUND(cph_this_year,1)) * 100,1) AS STRING),
          "%"
    ) as value_checked,
    CASE WHEN (cph_this_year IS NULL OR cph_this_year = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{this_year}}, "-10-31") AS DATE)
            THEN CONCAT("No data but this check was run before the NTD submission due date in ",{{this_year}}, ". Did not yet check for cost per hr.")
        WHEN (cph_last_year IS NULL OR cph_last_year = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{last_year}}, "-10-31") AS DATE)
            THEN CONCAT("No data but this check was run before the NTD submission due date in ",{{last_year}}, ". Did not yet check for cost per hr.")
        WHEN ABS(ROUND(cph_this_year) - ROUND(cph_last_year) / ROUND(cph_last_year)) >= {{cph_threshold}}
            THEN CONCAT("The cost per hour for this mode has changed from last year by > = ",
                    {{cph_threshold}} * 100,
                    "%, please provide a narrative justification.")
        ELSE ""
        END AS description,
    "" as Agency_Response,
    CURRENT_TIMESTAMP() AS date_checked
    from {{ ref('int_ntd_rr20_service_3ratios_wide') }}
),

rr20f_146 as (
    select
    organization,
    "RR20F-146: Miles per Vehicle change" as name_of_check,
    mode,
    {{this_year}} as year_of_data,
    CASE WHEN (mpv_this_year IS NULL OR mpv_this_year = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{this_year}}, "-10-31") AS DATE)
            THEN "Did Not Run"
        WHEN (mpv_last_year IS NULL OR mpv_last_year = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{last_year}}, "-10-31") AS DATE)
            THEN "Did Not Run"
        WHEN ABS(ROUND(mpv_this_year) - ROUND(mpv_last_year) / ROUND(mpv_last_year)) >= {{mpv_threshold}} THEN "Fail"
        ELSE "Pass"
        END as check_status,
    CONCAT({{this_year}}, " = ", CAST(ROUND(mpv_this_year,1) AS STRING),
            ", ", {{last_year}}, " = ", CAST(ROUND(mpv_last_year,1) AS STRING),
            "chg = ",
          CAST(ROUND((ROUND(mpv_this_year,1) - ROUND(mpv_last_year,1))/ABS(ROUND(mpv_this_year,1)) * 100,1) AS STRING),
          "%"
    ) as value_checked,
    CASE WHEN (mpv_this_year IS NULL OR mpv_this_year = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{this_year}}, "-10-31") AS DATE)
            THEN CONCAT("No data but this check was run before the NTD submission due date in ",{{this_year}}, ". Did not yet check for miles per vehicle.")
        WHEN (mpv_last_year IS NULL OR mpv_last_year = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{last_year}}, "-10-31") AS DATE)
            THEN CONCAT("No data but this check was run before the NTD submission due date in ",{{last_year}}, ". Did not yet check for miles per vehicle.")
        WHEN ABS(ROUND(mpv_this_year) - ROUND(mpv_last_year) / ROUND(mpv_last_year)) >= {{mpv_threshold}}
            THEN CONCAT("The miles per vehicle for this mode has changed from last year by >= ",
                    {{mpv_threshold}} * 100,
                    "%, please provide a narrative justification.")
        ELSE ""
        END AS description,
    "" as Agency_Response,
    CURRENT_TIMESTAMP() AS date_checked
    from {{ ref('int_ntd_rr20_service_3ratios_wide') }}
),

rr20f_179 as (
    select
    organization,
    "RR20F-179: Missing Service Data check" as name_of_check,
    mode,
    {{this_year}} as year_of_data,
    CASE WHEN ((vrm_this_year IS NULL OR vrm_this_year = 0) OR (vrh_this_year IS NULL OR vrh_this_year = 0) OR
        (upt_this_year IS NULL OR upt_this_year = 0) OR (voms_this_year IS NULL OR voms_this_year = 0))
            AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) > CAST(CONCAT({{this_year}}, "-10-31") AS DATE) THEN "Fail"
        WHEN ((vrm_last_year IS NULL OR vrm_last_year = 0) OR (vrh_last_year IS NULL OR vrh_last_year = 0) OR
        (upt_last_year IS NULL OR upt_last_year = 0) OR (voms_last_year IS NULL OR voms_last_year = 0))
            AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) > CAST(CONCAT({{last_year}}, "-10-31") AS DATE) THEN "Fail"
        WHEN ((vrm_this_year IS NULL OR vrm_this_year = 0) OR (vrh_this_year IS NULL OR vrh_this_year = 0) OR
        (upt_this_year IS NULL OR upt_this_year = 0) OR (voms_this_year IS NULL OR voms_this_year = 0))
            AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{this_year}}, "-10-31") AS DATE)  THEN "Didn't run"
        WHEN ((vrm_last_year IS NULL OR vrm_last_year = 0) OR (vrh_last_year IS NULL OR vrh_last_year = 0) OR
        (upt_last_year IS NULL OR upt_last_year = 0) OR (voms_last_year IS NULL OR voms_last_year = 0))
            AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{last_year}}, "-10-31") AS DATE) THEN "Didn't run"
        ELSE "Pass"
     END as check_status,
     CONCAT({{this_year}}, " Service data: VRM=", vrm_this_year, " VRH=", vrh_this_year, " UPT=", upt_this_year,
        " VOMS=", voms_this_year) as value_checked,
    CASE WHEN ((vrm_this_year IS NULL OR vrm_this_year = 0) OR (vrh_this_year IS NULL OR vrh_this_year = 0) OR
        (upt_this_year IS NULL OR upt_this_year = 0) OR (voms_this_year IS NULL OR voms_this_year = 0))
            AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) > CAST(CONCAT({{this_year}}, "-10-31") AS DATE)
        THEN "One or more service data fields are are missing for Vehicle Revenue Miles, Vehicle Revenue Hours, Unlinked Passenger Trips, or VOMS. Please revise your submission to report it if the transit unit operated revenue service during the fiscal year."
        WHEN ((vrm_last_year IS NULL OR vrm_last_year = 0) OR (vrh_last_year IS NULL OR vrh_last_year = 0) OR
        (upt_last_year IS NULL OR upt_last_year = 0) OR (voms_last_year IS NULL OR voms_last_year = 0))
            AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) > CAST(CONCAT({{last_year}}, "-10-31") AS DATE)
        THEN "One or more service data fields are are missing for Vehicle Revenue Miles, Vehicle Revenue Hours, Unlinked Passenger Trips, or VOMS. Please revise your submission to report it if the transit unit operated revenue service during the fiscal year."
        WHEN ((vrm_this_year IS NULL OR vrm_this_year = 0) OR (vrh_this_year IS NULL OR vrh_this_year = 0) OR
        (upt_this_year IS NULL OR upt_this_year = 0) OR (voms_this_year IS NULL OR voms_this_year = 0))
            AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{this_year}}, "-10-31") AS DATE)
        THEN CONCAT("No data but this check was run before the NTD submission due date in ",{{this_year}}, ". Did not yet check for missing service data.")
        WHEN ((vrm_last_year IS NULL OR vrm_last_year = 0) OR (vrh_last_year IS NULL OR vrh_last_year = 0) OR
        (upt_last_year IS NULL OR upt_last_year = 0) OR (voms_last_year IS NULL OR voms_last_year = 0))
            AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{last_year}}, "-10-31") AS DATE)
        THEN CONCAT("No data but this check was run before the NTD submission due date in ",{{last_year}}, ". Did not yet check for missing service data.")
        ELSE "Pass"
     END as description,
     "" as Agency_Response,
    CURRENT_TIMESTAMP() AS date_checked
    from {{ ref('int_ntd_rr20_service_3ratios_wide') }}
),

rr20f_139 as (
    select
    organization,
    "RR20F-139: Vehicle Revenue Miles (VRM) % change" as name_of_check,
    mode,
    {{this_year}} as year_of_data,
    CASE WHEN (vrm_this_year IS NULL OR vrm_this_year = 0 ) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{this_year}}, "-10-31") AS DATE) THEN "Did Not Run"
        WHEN (vrm_last_year IS NULL OR vrm_last_year = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{last_year}}, "-10-31") AS DATE)  THEN "Did Not Run"
        WHEN ABS(ROUND(vrm_this_year) - ROUND(vrm_last_year) / ROUND(vrm_last_year)) >= {{vrm_threshold}} THEN "Fail"
        ELSE "Pass"
        END as check_status,
    CONCAT({{this_year}}, " = ", CAST(ROUND(vrm_this_year,1) AS STRING),
            ", ", {{last_year}}, " = ", CAST(ROUND(vrm_last_year,1) AS STRING),
            "chg = ",
          CAST(ROUND((ROUND(vrm_this_year,1) - ROUND(vrm_last_year,1))/ABS(ROUND(vrm_this_year,1)) * 100,1) AS STRING),
          "%"
    ) as value_checked,
    CASE WHEN (vrm_this_year IS NULL OR vrm_this_year = 0 ) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{this_year}}, "-10-31") AS DATE)
            THEN CONCAT("No data but this check was run before the NTD submission due date in ",{{this_year}}, ".")
        WHEN (vrm_last_year IS NULL OR vrm_last_year = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{last_year}}, "-10-31") AS DATE)
            THEN CONCAT("No data but this check was run before the NTD submission due date in ",{{last_year}}, ".")
        WHEN ABS(ROUND(vrm_this_year) - ROUND(vrm_last_year) / ROUND(vrm_last_year)) >= {{vrm_threshold}}
            THEN CONCAT("The annual vehicle revenue miles for this mode has changed from last year by >= ",
                    {{vrm_threshold}} * 100,
                    "%, please provide a narrative justification.")
        ELSE ""
        END AS description,
    "" as Agency_Response,
    CURRENT_TIMESTAMP() AS date_checked
    from {{ ref('int_ntd_rr20_service_3ratios_wide') }}
),

rr20f_008 as (
    select
    organization,
    "RR20F-139: Fare Revenue Per Trip change" as name_of_check,
    mode,
    {{this_year}} as year_of_data,
    CASE WHEN (frpt_this_year IS NULL OR frpt_this_year = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{this_year}}, "-10-31") AS DATE) THEN "Did Not Run"
        WHEN (frpt_last_year IS NULL OR frpt_last_year = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{last_year}}, "-10-31") AS DATE) THEN "Did Not Run"
        WHEN ABS(ROUND(frpt_this_year) - ROUND(frpt_last_year) / ROUND(frpt_last_year)) >= {{frpt_threshold}} THEN "Fail"
        ELSE "Pass"
        END as check_status,
    CONCAT({{this_year}}, " = ", CAST(ROUND(frpt_this_year,1) AS STRING),
            ", ", {{last_year}}, " = ", CAST(ROUND(frpt_last_year,1) AS STRING),
            "chg = ",
          CAST(ROUND((ROUND(frpt_this_year,1) - ROUND(frpt_last_year,1))/ABS(ROUND(frpt_this_year,1)) * 100,1) AS STRING),
          "%"
    ) as value_checked,
    CASE WHEN (frpt_this_year IS NULL OR frpt_this_year = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{this_year}}, "-10-31") AS DATE)
        THEN CONCAT("No data but this check was run before the NTD submission due date in ",{{this_year}}, ".")
        WHEN (frpt_last_year IS NULL OR frpt_last_year = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{last_year}}, "-10-31") AS DATE)
            THEN CONCAT("No data but this check was run before the NTD submission due date in ",{{last_year}}, ".")
        WHEN ABS(ROUND(frpt_this_year) - ROUND(frpt_last_year) / ROUND(frpt_last_year)) >= {{frpt_threshold}}
        THEN CONCAT("The fare revenues per unlinked passenger trip for this mode has changed from last year by >= ",
                    {{frpt_threshold}} * 100,
                    "%, please provide a narrative justification.")
        ELSE ""
        END AS description,
    "" as Agency_Response,
    CURRENT_TIMESTAMP() AS date_checked
    from {{ ref('int_ntd_rr20_service_3ratios_wide') }}
),

rr20f_137 as (
    select
    organization,
    "RR20F-139: Revenue Speed change" as name_of_check,
    mode,
    {{this_year}} as year_of_data,
    CASE WHEN (rev_speed_this_year IS NULL OR rev_speed_this_year = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{this_year}}, "-10-31") AS DATE)
            THEN "Did Not Run"
        WHEN (rev_speed_last_year IS NULL OR  rev_speed_last_year = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{last_year}}, "-10-31") AS DATE)
            THEN "Did Not Run"
        WHEN ABS(ROUND(rev_speed_this_year) - ROUND(rev_speed_last_year) / ROUND(rev_speed_last_year)) >= {{rs_threshold}} THEN "Fail"
        ELSE "Pass"
        END as check_status,
    CONCAT({{this_year}}, " = ", CAST(ROUND(rev_speed_this_year,1) AS STRING),
            ", ", {{last_year}}, " = ", CAST(ROUND(rev_speed_last_year,1) AS STRING),
            "chg = ",
          CAST(ROUND(ROUND(rev_speed_this_year) - ROUND(rev_speed_last_year) / ROUND(rev_speed_last_year)*100, 1) AS STRING),
          "%"
    ) as value_checked,
    CASE WHEN (rev_speed_this_year IS NULL OR rev_speed_this_year = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{this_year}}, "-10-31") AS DATE)
            THEN CONCAT("No data but this check was run before the NTD submission due date in ",{{this_year}}, ".")
        WHEN (rev_speed_last_year IS NULL OR rev_speed_last_year = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{last_year}}, "-10-31") AS DATE)
            THEN CONCAT("No data but this check was run before the NTD submission due date in ",{{last_year}}, ".")
        WHEN ABS(ROUND(rev_speed_this_year) - ROUND(rev_speed_last_year) / ROUND(rev_speed_last_year)) >= {{rs_threshold}}
            THEN CONCAT("The revenue speed, the avg speed of your vehicles while in revenue service, for this mode has changed from last year by >= ",
                    {{rs_threshold}} * 100,
                    "%, please provide a narrative justification.")
        ELSE ""
        END AS description,
    "" as Agency_Response,
    CURRENT_TIMESTAMP() AS date_checked
    from {{ ref('int_ntd_rr20_service_3ratios_wide') }}
),

rr20f_154 as (
    select
    organization,
    "RR20F-154: Trips per Hour change" as name_of_check,
    mode,
    {{this_year}} as year_of_data,
    CASE WHEN (tph_this_year IS NULL OR tph_this_year = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{this_year}}, "-10-31") AS DATE)
            THEN "Did Not Run"
        WHEN (tph_last_year IS NULL OR tph_last_year = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{last_year}}, "-10-31") AS DATE)
            THEN "Did Not Run"
        WHEN ABS(ROUND(tph_this_year) - ROUND(tph_last_year) / ROUND(tph_last_year)) >= {{tph_threshold}}
            THEN "Fail"
        ELSE "Pass"
        END as check_status,
    CONCAT({{this_year}}, " = ", CAST(ROUND(tph_this_year,1) AS STRING),
            ", ", {{last_year}}, " = ", CAST(ROUND(tph_last_year,1) AS STRING),
            "chg = ",
          CAST(ROUND((ROUND(tph_this_year,1) - ROUND(tph_last_year,1))/ABS(ROUND(tph_this_year,1)) * 100,1) AS STRING),
          "%"
    ) as value_checked,
    CASE WHEN (tph_this_year IS NULL OR tph_this_year = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{this_year}}, "-10-31") AS DATE)
            THEN CONCAT("No data but this check was run before the NTD submission due date in ",{{this_year}}, ".")
        WHEN (tph_last_year IS NULL OR tph_last_year = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{last_year}}, "-10-31") AS DATE)
                THEN CONCAT("No data but this check was run before the NTD submission due date in ",{{last_year}}, ".")
        WHEN ABS(ROUND(tph_this_year) - ROUND(tph_last_year) / ROUND(tph_last_year)) >= {{tph_threshold}}
            THEN CONCAT("The calculated trips per hour for this mode has changed from last year by >= ",
                    {{tph_threshold}} * 100,
                    "%, please provide a narrative justification.")
        ELSE ""
        END AS description,
    "" as Agency_Response,
    CURRENT_TIMESTAMP() AS date_checked
    from {{ ref('int_ntd_rr20_service_3ratios_wide') }}
),

rr20f_171 as (
    select
    organization,
    "RR20F-171: Vehicles of Maximum Service (VOMS) change" as name_of_check,
    mode,
    {{this_year}} as year_of_data,
    CASE WHEN (ROUND(voms_this_year) =0 AND ROUND(voms_last_year) != 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) > CAST(CONCAT({{this_year}}, "-10-31") AS DATE))
            OR (ROUND(voms_this_year) !=0 AND ROUND(voms_this_year) IS NOT NULL AND ROUND(voms_last_year) = 0)
            THEN "Fail"
        WHEN (voms_this_year IS NULL OR voms_this_year=0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{this_year}}, "-10-31") AS DATE)
            THEN "Did Not Run"
        WHEN (voms_last_year IS NULL OR voms_last_year=0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{last_year}}, "-10-31") AS DATE)
            THEN "Did Not Run"
        ELSE "Pass"
        END as check_status,
    CONCAT({{this_year}}, " = ", CAST(ROUND(voms_this_year) AS STRING),
            ", ", {{last_year}}, " = ", CAST(ROUND(voms_last_year) AS STRING),
            "chg = ",
          CAST(ROUND((ROUND(voms_this_year,1) - ROUND(voms_last_year,1))/ABS(ROUND(voms_this_year,1)) * 100,1) AS STRING),
          "%"
    ) as value_checked,
    CASE WHEN (ROUND(voms_this_year) =0 AND ROUND(voms_last_year) != 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) > CAST(CONCAT({{this_year}}, "-10-31") AS DATE))
            OR (ROUND(voms_this_year) !=0 AND ROUND(voms_this_year) IS NOT NULL AND ROUND(voms_last_year) = 0)
            THEN "The Vehicles of Maximum Service (VOMS) for this mode has changed either to or from 0 compared to last year, please provide a narrative justification."
        WHEN (voms_this_year IS NULL OR voms_this_year=0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{this_year}}, "-10-31") AS DATE)
            THEN CONCAT("No data but this check was run before the NTD submission due date in ",{{this_year}}, " for VOMS.")
        WHEN (voms_last_year IS NULL OR voms_last_year=0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{last_year}}, "-10-31") AS DATE)
            THEN CONCAT("No data but this check was run before the NTD submission due date in ",{{last_year}}, " for VOMS.")
        ELSE ""
        END AS description,
    "" as Agency_Response,
    CURRENT_TIMESTAMP() AS date_checked
    from {{ ref('int_ntd_rr20_service_3ratios_wide') }}
),

rr20f_143 as (
    select
    organization,
    "RR20F-143: Vehicle Revenue Miles (VRM) change from zero" as name_of_check,
    mode,
    {{this_year}} as year_of_data,
    CASE WHEN (ROUND(vrm_this_year) =0 AND ROUND(vrm_last_year) != 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) > CAST(CONCAT({{this_year}}, "-10-31") AS DATE))
            OR (ROUND(vrm_this_year) !=0 AND ROUND(vrm_this_year) IS NOT NULL AND ROUND(voms_last_year) = 0)
            THEN "Fail"
        WHEN (vrm_this_year IS NULL OR vrm_this_year=0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{this_year}}, "-10-31") AS DATE)
            THEN "Did Not Run"
        WHEN (vrm_last_year IS NULL OR vrm_last_year=0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{last_year}}, "-10-31") AS DATE)
            THEN "Did Not Run"
        ELSE "Pass"
        END as check_status,
    CONCAT({{this_year}}, " = ", CAST(ROUND(vrm_this_year) AS STRING),
            ", ", {{last_year}}, " = ", CAST(ROUND(vrm_last_year) AS STRING),
            "chg = ",
          CAST(ROUND((ROUND(vrm_this_year,1) - ROUND(vrm_last_year,1))/ABS(ROUND(vrm_this_year,1)) * 100,1) AS STRING),
          "%"
    ) as value_checked,
    CASE WHEN (ROUND(vrm_this_year) =0 AND ROUND(vrm_last_year) != 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) > CAST(CONCAT({{this_year}}, "-10-31") AS DATE))
            OR (ROUND(vrm_this_year) !=0 AND ROUND(vrm_this_year) IS NOT NULL AND ROUND(vrm_last_year) = 0)
            THEN "The Vehicle Revenue Miles (VRM) for this mode has changed either to or from 0 compared to last year, please provide a narrative justification."
        WHEN (vrm_this_year IS NULL OR vrm_this_year=0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{this_year}}, "-10-31") AS DATE)
            THEN CONCAT("No data but this check was run before the NTD submission due date in ",{{this_year}}, " for VOMS.")
        WHEN (vrm_last_year IS NULL OR vrm_last_year=0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{last_year}}, "-10-31") AS DATE)
            THEN CONCAT("No data but this check was run before the NTD submission due date in ",{{last_year}}, " for VOMS.")
        ELSE ""
        END AS description,
    "" as Agency_Response,
    CURRENT_TIMESTAMP() AS date_checked
    from {{ ref('int_ntd_rr20_service_3ratios_wide') }}
)


SELECT * FROM rr20f_005

UNION ALL

SELECT * FROM rr20f_146

UNION ALL

SELECT * FROM rr20f_139

UNION ALL

SELECT * FROM rr20f_008

UNION ALL

SELECT * FROM rr20f_137

UNION ALL

SELECT * FROM rr20f_154

UNION ALL

SELECT * FROM rr20f_179

UNION ALL

SELECT * FROM rr20f_171

UNION ALL

SELECT * FROM rr20f_143
