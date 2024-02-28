--- We do identical CASE WHEN clauses in each CTE.
-- The results determine 2 different column values but one can only specify 1 col/statement
{% set cph_threshold = 0.3 %}
{% set mpv_threshold = 0.2 %}
{% set vrm_threshold = 0.3 %}
{% set frpt_threshold = 0.25 %}
{% set rs_threshold = 0.15 %}
{% set tph_threshold = 0.3 %}
{% set start_datetime = run_started_at %}
{% set start_date = start_datetime.strftime("%Y-%m-%d") %}
{% set this_year = start_datetime.strftime("%Y") %}
{% set last_year1 = start_datetime - modules.datetime.timedelta(days=365) %}
{% set last_year = last_year1.strftime("%Y") %}



WITH
rr20f_005 as (
 select
    organization,
    "RR20F-005: Cost per Hour change" as name_of_check,
    mode,
    {{this_year}} as year_of_data,
    CASE WHEN (cph_{{this_year}} IS NULL OR cph_{{this_year}} = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{this_year}}, "-10-31") AS DATE)
            THEN "Did Not Run"
        WHEN (cph_{{last_year}} IS NULL OR cph_{{last_year}} = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{last_year}}, "-10-31") AS DATE)
            THEN "Did Not Run"
        WHEN ABS(ROUND(cph_{{this_year}}) - ROUND(cph_{{last_year}}) / ROUND(cph_{{last_year}})) >= {{cph_threshold}} THEN "Fail"
        ELSE "Pass"
        END as check_status,
    CONCAT({{this_year}}, " = ", CAST(ROUND(cph_{{this_year}},1) AS STRING),
            ", ", {{last_year}}, " = ", CAST(ROUND(cph_{{last_year}},1) AS STRING),
            "chg = ",
          CAST(ROUND((ROUND(cph_{{this_year}},1) - ROUND(cph_{{last_year}},1))/ABS(ROUND(cph_{{this_year}},1)) * 100,1) AS STRING),
          "%"
    ) as value_checked,
    CASE WHEN (cph_{{this_year}} IS NULL OR cph_{{this_year}} = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{this_year}}, "-10-31") AS DATE)
            THEN CONCAT("No data but this check was run before the NTD submission due date in ",{{this_year}}, ". Did not yet check for cost per hr.")
        WHEN (cph_{{last_year}} IS NULL OR cph_{{last_year}} = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{last_year}}, "-10-31") AS DATE)
            THEN CONCAT("No data but this check was run before the NTD submission due date in ",{{last_year}}, ". Did not yet check for cost per hr.")
        WHEN ABS(ROUND(cph_{{this_year}}) - ROUND(cph_{{last_year}}) / ROUND(cph_{{last_year}})) >= {{cph_threshold}}
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
    CASE WHEN (mpv_{{this_year}} IS NULL OR mpv_{{this_year}} = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{this_year}}, "-10-31") AS DATE)
            THEN "Did Not Run"
        WHEN (mpv_{{last_year}} IS NULL OR mpv_{{last_year}} = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{last_year}}, "-10-31") AS DATE)
            THEN "Did Not Run"
        WHEN ABS(ROUND(mpv_{{this_year}}) - ROUND(mpv_{{last_year}}) / ROUND(mpv_{{last_year}})) >= {{mpv_threshold}} THEN "Fail"
        ELSE "Pass"
        END as check_status,
    CONCAT({{this_year}}, " = ", CAST(ROUND(mpv_{{this_year}},1) AS STRING),
            ", ", {{last_year}}, " = ", CAST(ROUND(mpv_{{last_year}},1) AS STRING),
            "chg = ",
          CAST(ROUND((ROUND(mpv_{{this_year}},1) - ROUND(mpv_{{last_year}},1))/ABS(ROUND(mpv_{{this_year}},1)) * 100,1) AS STRING),
          "%"
    ) as value_checked,
    CASE WHEN (mpv_{{this_year}} IS NULL OR mpv_{{this_year}} = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{this_year}}, "-10-31") AS DATE)
            THEN CONCAT("No data but this check was run before the NTD submission due date in ",{{this_year}}, ". Did not yet check for miles per vehicle.")
        WHEN (mpv_{{last_year}} IS NULL OR mpv_{{last_year}} = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{last_year}}, "-10-31") AS DATE)
            THEN CONCAT("No data but this check was run before the NTD submission due date in ",{{last_year}}, ". Did not yet check for miles per vehicle.")
        WHEN ABS(ROUND(mpv_{{this_year}}) - ROUND(mpv_{{last_year}}) / ROUND(mpv_{{last_year}})) >= {{mpv_threshold}}
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
    CASE WHEN ((vrm_{{this_year}} IS NULL OR vrm_{{this_year}} = 0) OR (vrh_{{this_year}} IS NULL OR vrh_{{this_year}} = 0) OR
        (upt_{{this_year}} IS NULL OR upt_{{this_year}} = 0) OR (voms_{{this_year}} IS NULL OR voms_{{this_year}} = 0))
            AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) > CAST(CONCAT({{this_year}}, "-10-31") AS DATE) THEN "Fail"
        WHEN ((vrm_{{last_year}} IS NULL OR vrm_{{last_year}} = 0) OR (vrh_{{last_year}} IS NULL OR vrh_{{last_year}} = 0) OR
        (upt_{{last_year}} IS NULL OR upt_{{last_year}} = 0) OR (voms_{{last_year}} IS NULL OR voms_{{last_year}} = 0))
            AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) > CAST(CONCAT({{last_year}}, "-10-31") AS DATE) THEN "Fail"
        WHEN ((vrm_{{this_year}} IS NULL OR vrm_{{this_year}} = 0) OR (vrh_{{this_year}} IS NULL OR vrh_{{this_year}} = 0) OR
        (upt_{{this_year}} IS NULL OR upt_{{this_year}} = 0) OR (voms_{{this_year}} IS NULL OR voms_{{this_year}} = 0))
            AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{this_year}}, "-10-31") AS DATE)  THEN "Didn't run"
        WHEN ((vrm_{{last_year}} IS NULL OR vrm_{{last_year}} = 0) OR (vrh_{{last_year}} IS NULL OR vrh_{{last_year}} = 0) OR
        (upt_{{last_year}} IS NULL OR upt_{{last_year}} = 0) OR (voms_{{last_year}} IS NULL OR voms_{{last_year}} = 0))
            AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{last_year}}, "-10-31") AS DATE) THEN "Didn't run"
        ELSE "Pass"
     END as check_status,
     CONCAT({{this_year}}, " Service data: VRM=", vrm_{{this_year}}, " VRH=", vrh_{{this_year}}, " UPT=", upt_{{this_year}},
        " VOMS=", voms_{{this_year}}) as value_checked,
    CASE WHEN ((vrm_{{this_year}} IS NULL OR vrm_{{this_year}} = 0) OR (vrh_{{this_year}} IS NULL OR vrh_{{this_year}} = 0) OR
        (upt_{{this_year}} IS NULL OR upt_{{this_year}} = 0) OR (voms_{{this_year}} IS NULL OR voms_{{this_year}} = 0))
            AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) > CAST(CONCAT({{this_year}}, "-10-31") AS DATE)
        THEN "One or more service data fields are are missing for Vehicle Revenue Miles, Vehicle Revenue Hours, Unlinked Passenger Trips, or VOMS. Please revise your submission to report it if the transit unit operated revenue service during the fiscal year."
        WHEN ((vrm_{{last_year}} IS NULL OR vrm_{{last_year}} = 0) OR (vrh_{{last_year}} IS NULL OR vrh_{{last_year}} = 0) OR
        (upt_{{last_year}} IS NULL OR upt_{{last_year}} = 0) OR (voms_{{last_year}} IS NULL OR voms_{{last_year}} = 0))
            AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) > CAST(CONCAT({{last_year}}, "-10-31") AS DATE)
        THEN "One or more service data fields are are missing for Vehicle Revenue Miles, Vehicle Revenue Hours, Unlinked Passenger Trips, or VOMS. Please revise your submission to report it if the transit unit operated revenue service during the fiscal year."
        WHEN ((vrm_{{this_year}} IS NULL OR vrm_{{this_year}} = 0) OR (vrh_{{this_year}} IS NULL OR vrh_{{this_year}} = 0) OR
        (upt_{{this_year}} IS NULL OR upt_{{this_year}} = 0) OR (voms_{{this_year}} IS NULL OR voms_{{this_year}} = 0))
            AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{this_year}}, "-10-31") AS DATE)
        THEN CONCAT("No data but this check was run before the NTD submission due date in ",{{this_year}}, ". Did not yet check for missing service data.")
        WHEN ((vrm_{{last_year}} IS NULL OR vrm_{{last_year}} = 0) OR (vrh_{{last_year}} IS NULL OR vrh_{{last_year}} = 0) OR
        (upt_{{last_year}} IS NULL OR upt_{{last_year}} = 0) OR (voms_{{last_year}} IS NULL OR voms_{{last_year}} = 0))
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
    "RR20F-139: Vehicle Revenue Miles change" as name_of_check,
    mode,
    {{this_year}} as year_of_data,
    CASE WHEN (vrm_{{this_year}} IS NULL OR vrm_{{this_year}} = 0 ) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{this_year}}, "-10-31") AS DATE) THEN "Did Not Run"
        WHEN (vrm_{{last_year}} IS NULL OR vrm_{{last_year}} = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{last_year}}, "-10-31") AS DATE)  THEN "Did Not Run"
        WHEN ABS(ROUND(vrm_{{this_year}}) - ROUND(vrm_{{last_year}}) / ROUND(vrm_{{last_year}})) >= {{vrm_threshold}} THEN "Fail"
        ELSE "Pass"
        END as check_status,
    CONCAT({{this_year}}, " = ", CAST(ROUND(vrm_{{this_year}},1) AS STRING),
            ", ", {{last_year}}, " = ", CAST(ROUND(vrm_{{last_year}},1) AS STRING),
            "chg = ",
          CAST(ROUND((ROUND(vrm_{{this_year}},1) - ROUND(vrm_{{last_year}},1))/ABS(ROUND(vrm_{{this_year}},1)) * 100,1) AS STRING),
          "%"
    ) as value_checked,
    CASE WHEN (vrm_{{this_year}} IS NULL OR vrm_{{this_year}} = 0 ) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{this_year}}, "-10-31") AS DATE)
            THEN CONCAT("No data but this check was run before the NTD submission due date in ",{{this_year}}, ".")
        WHEN (vrm_{{last_year}} IS NULL OR vrm_{{last_year}} = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{last_year}}, "-10-31") AS DATE)
            THEN CONCAT("No data but this check was run before the NTD submission due date in ",{{last_year}}, ".")
        WHEN ABS(ROUND(vrm_{{this_year}}) - ROUND(vrm_{{last_year}}) / ROUND(vrm_{{last_year}})) >= {{vrm_threshold}}
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
    CASE WHEN (frpt_{{this_year}} IS NULL OR frpt_{{this_year}} = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{this_year}}, "-10-31") AS DATE) THEN "Did Not Run"
        WHEN (frpt_{{last_year}} IS NULL OR frpt_{{last_year}} = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{last_year}}, "-10-31") AS DATE) THEN "Did Not Run"
        WHEN ABS(ROUND(frpt_{{this_year}}) - ROUND(frpt_{{last_year}}) / ROUND(frpt_{{last_year}})) >= {{frpt_threshold}} THEN "Fail"
        ELSE "Pass"
        END as check_status,
    CONCAT({{this_year}}, " = ", CAST(ROUND(frpt_{{this_year}},1) AS STRING),
            ", ", {{last_year}}, " = ", CAST(ROUND(frpt_{{last_year}},1) AS STRING),
            "chg = ",
          CAST(ROUND((ROUND(frpt_{{this_year}},1) - ROUND(frpt_{{last_year}},1))/ABS(ROUND(frpt_{{this_year}},1)) * 100,1) AS STRING),
          "%"
    ) as value_checked,
    CASE WHEN (frpt_{{this_year}} IS NULL OR frpt_{{this_year}} = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{this_year}}, "-10-31") AS DATE)
        THEN CONCAT("No data but this check was run before the NTD submission due date in ",{{this_year}}, ".")
        WHEN (frpt_{{last_year}} IS NULL OR frpt_{{last_year}} = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{last_year}}, "-10-31") AS DATE)
            THEN CONCAT("No data but this check was run before the NTD submission due date in ",{{last_year}}, ".")
        WHEN ABS(ROUND(frpt_{{this_year}}) - ROUND(frpt_{{last_year}}) / ROUND(frpt_{{last_year}})) >= {{frpt_threshold}}
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
    CASE WHEN (rev_speed_{{this_year}} IS NULL OR rev_speed_{{this_year}} = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{this_year}}, "-10-31") AS DATE)
            THEN "Did Not Run"
        WHEN (rev_speed_{{last_year}} IS NULL OR  rev_speed_{{last_year}} = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{last_year}}, "-10-31") AS DATE)
            THEN "Did Not Run"
        WHEN ABS(ROUND(rev_speed_{{this_year}}) - ROUND(rev_speed_{{last_year}}) / ROUND(rev_speed_{{last_year}})) >= {{rs_threshold}} THEN "Fail"
        ELSE "Pass"
        END as check_status,
    CONCAT({{this_year}}, " = ", CAST(ROUND(rev_speed_{{this_year}},1) AS STRING),
            ", ", {{last_year}}, " = ", CAST(ROUND(rev_speed_{{last_year}},1) AS STRING),
            "chg = ",
          CAST(ROUND(ROUND(rev_speed_{{this_year}}) - ROUND(rev_speed_{{last_year}}) / ROUND(rev_speed_{{last_year}})*100, 1) AS STRING),
          "%"
    ) as value_checked,
    CASE WHEN (rev_speed_{{this_year}} IS NULL OR rev_speed_{{this_year}} = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{this_year}}, "-10-31") AS DATE)
            THEN CONCAT("No data but this check was run before the NTD submission due date in ",{{this_year}}, ".")
        WHEN (rev_speed_{{last_year}} IS NULL OR rev_speed_{{last_year}} = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{last_year}}, "-10-31") AS DATE)
            THEN CONCAT("No data but this check was run before the NTD submission due date in ",{{last_year}}, ".")
        WHEN ABS(ROUND(rev_speed_{{this_year}}) - ROUND(rev_speed_{{last_year}}) / ROUND(rev_speed_{{last_year}})) >= {{rs_threshold}}
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
    CASE WHEN (tph_{{this_year}} IS NULL OR tph_{{this_year}} = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{this_year}}, "-10-31") AS DATE)
            THEN "Did Not Run"
        WHEN (tph_{{last_year}} IS NULL OR tph_{{last_year}} = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{last_year}}, "-10-31") AS DATE)
            THEN "Did Not Run"
        WHEN ABS(ROUND(tph_{{this_year}}) - ROUND(tph_{{last_year}}) / ROUND(tph_{{last_year}})) >= {{tph_threshold}}
            THEN "Fail"
        ELSE "Pass"
        END as check_status,
    CONCAT({{this_year}}, " = ", CAST(ROUND(tph_{{this_year}},1) AS STRING),
            ", ", {{last_year}}, " = ", CAST(ROUND(tph_{{last_year}},1) AS STRING),
            "chg = ",
          CAST(ROUND((ROUND(tph_{{this_year}},1) - ROUND(tph_{{last_year}},1))/ABS(ROUND(tph_{{this_year}},1)) * 100,1) AS STRING),
          "%"
    ) as value_checked,
    CASE WHEN (tph_{{this_year}} IS NULL OR tph_{{this_year}} = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{this_year}}, "-10-31") AS DATE)
            THEN CONCAT("No data but this check was run before the NTD submission due date in ",{{this_year}}, ".")
        WHEN (tph_{{last_year}} IS NULL OR tph_{{last_year}} = 0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{last_year}}, "-10-31") AS DATE)
                THEN CONCAT("No data but this check was run before the NTD submission due date in ",{{last_year}}, ".")
        WHEN ABS(ROUND(tph_{{this_year}}) - ROUND(tph_{{last_year}}) / ROUND(tph_{{last_year}})) >= {{tph_threshold}}
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
    CASE WHEN (ROUND(voms_{{this_year}}) =0 AND ROUND(voms_{{last_year}}) != 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) > CAST(CONCAT({{this_year}}, "-10-31") AS DATE))
            OR (ROUND(voms_{{this_year}}) !=0 AND ROUND(voms_{{this_year}}) IS NOT NULL AND ROUND(voms_{{last_year}}) = 0)
            THEN "Fail"
        WHEN (voms_{{this_year}} IS NULL OR voms_{{this_year}}=0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{this_year}}, "-10-31") AS DATE)
            THEN "Did Not Run"
        WHEN (voms_{{last_year}} IS NULL OR voms_{{last_year}}=0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{last_year}}, "-10-31") AS DATE)
            THEN "Did Not Run"
        ELSE "Pass"
        END as check_status,
    CONCAT({{this_year}}, " = ", CAST(ROUND(voms_{{this_year}}) AS STRING),
            ", ", {{last_year}}, " = ", CAST(ROUND(voms_{{last_year}}) AS STRING),
            "chg = ",
          CAST(ROUND((ROUND(voms_{{this_year}},1) - ROUND(voms_{{last_year}},1))/ABS(ROUND(voms_{{this_year}},1)) * 100,1) AS STRING),
          "%"
    ) as value_checked,
    CASE WHEN (ROUND(voms_{{this_year}}) =0 AND ROUND(voms_{{last_year}}) != 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) > CAST(CONCAT({{this_year}}, "-10-31") AS DATE))
            OR (ROUND(voms_{{this_year}}) !=0 AND ROUND(voms_{{this_year}}) IS NOT NULL AND ROUND(voms_{{last_year}}) = 0)
            THEN "The Vehicles of Maximum Service (VOMS) for this mode has changed either to or from 0 compared to last year, please provide a narrative justification."
        WHEN (voms_{{this_year}} IS NULL OR voms_{{this_year}}=0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{this_year}}, "-10-31") AS DATE)
            THEN CONCAT("No data but this check was run before the NTD submission due date in ",{{this_year}}, " for VOMS.")
        WHEN (voms_{{last_year}} IS NULL OR voms_{{last_year}}=0) AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST(CONCAT({{last_year}}, "-10-31") AS DATE)
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
