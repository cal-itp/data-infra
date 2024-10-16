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
 SELECT
    organization,
    "RR20F-005: Cost per Hour change" as name_of_check,
    mode,
    {{this_year}} as year_of_data,
    CASE WHEN COALESCE(cph_this_year, 0) = 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{this_year}}-10-31" AS DATE)
            THEN "Did Not Run"
        WHEN COALESCE(cph_last_year, 0) = 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{last_year}}-10-31" AS DATE)
            THEN "Did Not Run"
        WHEN COALESCE(cph_last_year, 0) = 0 OR COALESCE(cph_this_year, 0) = 0
            THEN "No Data"
        WHEN ROUND(ABS((cph_this_year - cph_last_year) / cph_last_year), 2) >= {{cph_threshold}}
           THEN "Fail"
        ELSE "Pass"
        END as check_status,
    CONCAT("{{this_year}} = ", IF(cph_this_year IS NULL, ' ', CAST(ROUND(cph_this_year, 2) AS STRING)),
           ", {{last_year}} = ", IF(cph_last_year IS NULL, ' ', CAST(ROUND(cph_last_year, 2) AS STRING)),
           IF(COALESCE(cph_this_year, 0) = 0 OR COALESCE(cph_last_year, 0) = 0,
              ' ',
              CONCAT(", chg = ", CAST(ROUND(ABS((cph_this_year - cph_last_year) / cph_last_year) * 100, 2) AS STRING), "%")
             )
    ) as value_checked,
    CASE WHEN COALESCE(cph_this_year, 0) = 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{this_year}}-10-31" AS DATE)
            THEN "No data but this check was run before the NTD submission due date in {{this_year}}. Did not yet check for cost per hr."
        WHEN COALESCE(cph_last_year, 0) = 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{last_year}}-10-31" AS DATE)
            THEN "No data but this check was run before the NTD submission due date in {{last_year}}. Did not yet check for cost per hr."
        WHEN COALESCE(cph_last_year, 0) = 0 AND COALESCE(cph_this_year, 0) = 0
            THEN "No data for {{last_year}} and {{this_year}}."
        WHEN COALESCE(cph_last_year, 0) = 0
            THEN "No data for {{last_year}}."
        WHEN COALESCE(cph_this_year, 0) = 0
            THEN "No data for {{this_year}}."
        WHEN ROUND(ABS((cph_this_year - cph_last_year) / cph_last_year), 2) >= {{cph_threshold}}
            THEN CONCAT("The cost per hour for this mode has changed from last year by > = ",
                        {{cph_threshold}} * 100,
                        "%, please provide a narrative justification.")
        ELSE ""
        END AS description,
    "" as Agency_Response,
    CURRENT_TIMESTAMP() AS date_checked
 FROM {{ ref('int_ntd_rr20_service_3ratios_wide') }}
),

rr20f_146 as (
 SELECT
    organization,
    "RR20F-146: Miles per Vehicle change" as name_of_check,
    mode,
    {{this_year}} as year_of_data,
    CASE WHEN COALESCE(mpv_this_year, 0) = 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{this_year}}-10-31" AS DATE)
            THEN "Did Not Run"
        WHEN COALESCE(mpv_last_year, 0) = 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{last_year}}-10-31" AS DATE)
            THEN "Did Not Run"
        WHEN COALESCE(mpv_last_year, 0) = 0 OR COALESCE(mpv_this_year, 0) = 0
            THEN "No Data"
        WHEN ROUND(ABS((mpv_this_year - mpv_last_year) / mpv_last_year), 2) >= {{mpv_threshold}}
            THEN "Fail"
        ELSE "Pass"
        END as check_status,
    CONCAT("{{this_year}} = ", IF(mpv_this_year IS NULL, ' ', CAST(ROUND(mpv_this_year, 2) AS STRING)),
           ", {{last_year}} = ", IF(mpv_last_year IS NULL, ' ', CAST(ROUND(mpv_last_year, 2) AS STRING)),
           IF(COALESCE(mpv_this_year, 0) = 0 OR COALESCE(mpv_last_year, 0) = 0,
              ' ',
              CONCAT(", chg = ", CAST(ROUND(ABS((mpv_this_year - mpv_last_year) / mpv_last_year) * 100, 2) AS STRING), "%")
             )
    ) as value_checked,
    CASE WHEN COALESCE(mpv_this_year, 0) = 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{this_year}}-10-31" AS DATE)
            THEN "No data but this check was run before the NTD submission due date in {{this_year}}. Did not yet check for miles per vehicle."
        WHEN COALESCE(mpv_last_year, 0) = 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{last_year}}-10-31" AS DATE)
            THEN "No data but this check was run before the NTD submission due date in {{last_year}}. Did not yet check for miles per vehicle."
        WHEN COALESCE(mpv_last_year, 0) = 0 AND COALESCE(mpv_this_year, 0) = 0
           THEN "No data for {{last_year}} and {{this_year}}."
        WHEN COALESCE(mpv_last_year, 0) = 0
            THEN "No data for {{last_year}}."
        WHEN COALESCE(mpv_this_year, 0) = 0
           THEN "No data for {{this_year}}."
        WHEN ROUND(ABS((mpv_this_year - mpv_last_year) / mpv_last_year), 2) >= {{mpv_threshold}}
            THEN CONCAT("The miles per vehicle for this mode has changed from last year by >= ",
                        {{mpv_threshold}} * 100,
                        "%, please provide a narrative justification.")
        ELSE ""
        END AS description,
    "" as Agency_Response,
    CURRENT_TIMESTAMP() AS date_checked
 FROM {{ ref('int_ntd_rr20_service_3ratios_wide') }}
),

rr20f_179 as (
 SELECT
    organization,
    "RR20F-179: Missing Service Data check" as name_of_check,
    mode,
    {{this_year}} as year_of_data,
    CASE WHEN (COALESCE(vrm_this_year, 0) = 0 OR COALESCE(vrh_this_year, 0) = 0 OR
               COALESCE(upt_this_year, 0) = 0 OR COALESCE(voms_this_year, 0) = 0)
              AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) > CAST("{{this_year}}-10-31" AS DATE)
         THEN "Fail"
         WHEN (COALESCE(vrm_last_year, 0) = 0 OR COALESCE(vrh_last_year, 0) = 0 OR
               COALESCE(upt_last_year, 0) = 0 OR COALESCE(voms_last_year, 0) = 0)
              AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) > CAST("{{last_year}}-10-31" AS DATE)
         THEN "Fail"
         WHEN (COALESCE(vrm_this_year, 0) = 0 OR COALESCE(vrh_this_year, 0) = 0 OR
               COALESCE(upt_this_year, 0) = 0 OR COALESCE(voms_this_year, 0) = 0)
              AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{this_year}}-10-31" AS DATE)
         THEN "Didn't run"
         WHEN (COALESCE(vrm_last_year, 0) = 0 OR COALESCE(vrh_last_year, 0) = 0 OR
               COALESCE(upt_last_year, 0) = 0 OR COALESCE(voms_last_year, 0) = 0)
              AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{last_year}}-10-31" AS DATE)
         THEN "Didn't run"
        ELSE "Pass"
     END as check_status,
    CONCAT("{{this_year}} Service data: VRM=", COALESCE(CAST(vrm_this_year AS STRING), ' '),
           " VRH=", COALESCE(CAST(vrh_this_year AS STRING), ' '),
           " UPT=", COALESCE(CAST(upt_this_year AS STRING), ' '),
           " VOMS=", COALESCE(CAST(voms_this_year AS STRING), ' ')) as value_checked,
    CASE WHEN (COALESCE(vrm_this_year, 0) = 0 OR COALESCE(vrh_this_year, 0) = 0 OR
               COALESCE(upt_this_year, 0) = 0 OR COALESCE(voms_this_year, 0) = 0)
              AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) > CAST("{{this_year}}-10-31" AS DATE)
        THEN "One or more service data fields are are missing for Vehicle Revenue Miles, Vehicle Revenue Hours, Unlinked Passenger Trips, or VOMS. Please revise your submission to report it if the transit unit operated revenue service during the fiscal year."
        WHEN (COALESCE(vrm_last_year, 0) = 0 OR COALESCE(vrh_last_year, 0) = 0 OR
              COALESCE(upt_last_year, 0) = 0 OR COALESCE(voms_last_year, 0) = 0)
             AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) > CAST("{{last_year}}-10-31" AS DATE)
        THEN "One or more service data fields are are missing for Vehicle Revenue Miles, Vehicle Revenue Hours, Unlinked Passenger Trips, or VOMS. Please revise your submission to report it if the transit unit operated revenue service during the fiscal year."
        WHEN (COALESCE(vrm_this_year, 0) = 0 OR COALESCE(vrh_this_year, 0) = 0 OR
              COALESCE(upt_this_year, 0) = 0 OR COALESCE(voms_this_year, 0) = 0)
             AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{this_year}}-10-31" AS DATE)
        THEN "No data but this check was run before the NTD submission due date in {{this_year}}. Did not yet check for missing service data."
        WHEN (COALESCE(vrm_last_year, 0) = 0 OR COALESCE(vrh_last_year, 0) = 0 OR
              COALESCE(upt_last_year, 0) = 0 OR COALESCE(voms_last_year, 0) = 0)
             AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{last_year}}-10-31" AS DATE)
        THEN "No data but this check was run before the NTD submission due date in {{last_year}}. Did not yet check for missing service data."
        ELSE "Pass"
     END as description,
     "" as Agency_Response,
    CURRENT_TIMESTAMP() AS date_checked
 FROM {{ ref('int_ntd_rr20_service_3ratios_wide') }}
),

rr20f_139 as (
 SELECT
    organization,
    "RR20F-139: Vehicle Revenue Miles (VRM) % change" as name_of_check,
    mode,
    {{this_year}} as year_of_data,
    CASE WHEN COALESCE(vrm_this_year, 0) = 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{this_year}}-10-31" AS DATE)
            THEN "Did Not Run"
        WHEN COALESCE(vrm_last_year, 0) = 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{last_year}}-10-31" AS DATE)
            THEN "Did Not Run"
        WHEN COALESCE(vrm_this_year, 0) = 0 OR COALESCE(vrm_last_year, 0) = 0
            THEN "No Data"
        WHEN ROUND(ABS((vrm_this_year - vrm_last_year) / vrm_last_year), 2) >= {{vrm_threshold}}
            THEN "Fail"
        ELSE "Pass"
        END as check_status,
    CONCAT("{{this_year}} = ", IF(vrm_this_year IS NULL, ' ', CAST(ROUND(vrm_this_year, 2) AS STRING)),
           ", {{last_year}} = ", IF(vrm_last_year IS NULL, ' ', CAST(ROUND(vrm_last_year, 2) AS STRING)),
           IF(COALESCE(vrm_this_year, 0) = 0 OR COALESCE(vrm_last_year, 0) = 0,
              ' ',
              CONCAT(", chg = ", CAST(ROUND(ABS((vrm_this_year - vrm_last_year) / vrm_last_year) * 100, 2) AS STRING), "%")
             )
    ) as value_checked,
    CASE WHEN COALESCE(vrm_this_year, 0) = 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{this_year}}-10-31" AS DATE)
            THEN "No data but this check was run before the NTD submission due date in {{this_year}}."
        WHEN COALESCE(vrm_last_year, 0) = 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{last_year}}-10-31" AS DATE)
            THEN "No data but this check was run before the NTD submission due date in {{last_year}}."
        WHEN COALESCE(vrm_last_year, 0) = 0 AND COALESCE(vrm_this_year, 0) = 0
           THEN "No data for {{last_year}} and {{this_year}}."
        WHEN COALESCE(vrm_last_year, 0) = 0
            THEN "No data for {{last_year}}."
        WHEN COALESCE(vrm_this_year, 0) = 0
           THEN "No data for {{this_year}}."
        WHEN ROUND(ABS((vrm_this_year - vrm_last_year) / vrm_last_year), 2) >= {{vrm_threshold}}
            THEN CONCAT("The annual vehicle revenue miles for this mode has changed from last year by >= ",
                        {{vrm_threshold}} * 100,
                        "%, please provide a narrative justification.")
        ELSE ""
        END AS description,
    "" as Agency_Response,
    CURRENT_TIMESTAMP() AS date_checked
 FROM {{ ref('int_ntd_rr20_service_3ratios_wide') }}
),

rr20f_008 as (
 SELECT
    organization,
    "RR20F-139: Fare Revenue Per Trip change" as name_of_check,
    mode,
    {{this_year}} as year_of_data,
    CASE WHEN COALESCE(frpt_this_year, 0) = 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{this_year}}-10-31" AS DATE)
            THEN "Did Not Run"
        WHEN COALESCE(frpt_last_year, 0) = 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{last_year}}-10-31" AS DATE)
            THEN "Did Not Run"
        WHEN COALESCE(frpt_this_year, 0) = 0 OR COALESCE(frpt_last_year, 0) = 0
            THEN "No Data"
        WHEN ROUND(ABS((frpt_this_year - frpt_last_year) / frpt_last_year), 2) >= {{frpt_threshold}}
            THEN "Fail"
        ELSE "Pass"
        END as check_status,
    CONCAT("{{this_year}} = ", IF(frpt_this_year IS NULL, ' ', CAST(ROUND(frpt_this_year, 2) AS STRING)),
           ", {{last_year}} = ", IF(frpt_last_year IS NULL, ' ', CAST(ROUND(frpt_last_year, 2) AS STRING)),
           IF(COALESCE(frpt_this_year, 0) = 0 OR COALESCE(frpt_last_year, 0) = 0,
              ' ',
              CONCAT(", chg = ", CAST(ROUND(ABS((frpt_this_year - frpt_last_year) / frpt_last_year) * 100, 2) AS STRING), "%")
             )
    ) as value_checked,
    CASE WHEN COALESCE(frpt_this_year, 0) = 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{this_year}}-10-31" AS DATE)
            THEN "No data but this check was run before the NTD submission due date in {{this_year}}."
        WHEN COALESCE(frpt_last_year, 0) = 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{last_year}}-10-31" AS DATE)
            THEN "No data but this check was run before the NTD submission due date in {{last_year}}."
        WHEN COALESCE(frpt_last_year, 0) = 0 AND COALESCE(frpt_this_year, 0) = 0
           THEN "No data for {{last_year}} and {{this_year}}."
        WHEN COALESCE(frpt_last_year, 0) = 0
            THEN "No data for {{last_year}}."
        WHEN COALESCE(frpt_this_year, 0) = 0
           THEN "No data for {{this_year}}."
        WHEN ROUND(ABS((frpt_this_year - frpt_last_year) / frpt_last_year), 2) >= {{frpt_threshold}}
            THEN CONCAT("The fare revenues per unlinked passenger trip for this mode has changed from last year by >= ",
                        {{frpt_threshold}} * 100,
                        "%, please provide a narrative justification.")
        ELSE ""
        END AS description,
    "" as Agency_Response,
    CURRENT_TIMESTAMP() AS date_checked
 FROM {{ ref('int_ntd_rr20_service_3ratios_wide') }}
),

rr20f_137 as (
 SELECT
    organization,
    "RR20F-139: Revenue Speed change" as name_of_check,
    mode,
    {{this_year}} as year_of_data,
    CASE WHEN COALESCE(rev_speed_this_year, 0) = 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{this_year}}-10-31" AS DATE)
            THEN "Did Not Run"
        WHEN COALESCE(rev_speed_last_year, 0) = 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{last_year}}-10-31" AS DATE)
            THEN "Did Not Run"
        WHEN ROUND(ABS((rev_speed_this_year - rev_speed_last_year) / rev_speed_last_year), 2) >= {{rs_threshold}}
            THEN "Fail"
        ELSE "Pass"
        END as check_status,
    CONCAT("{{this_year}} = ", IF(rev_speed_this_year IS NULL, ' ', CAST(ROUND(rev_speed_this_year, 2) AS STRING)),
           ", {{last_year}} = ", IF(rev_speed_last_year IS NULL, ' ', CAST(ROUND(rev_speed_last_year, 2) AS STRING)),
           IF(COALESCE(rev_speed_this_year, 0) = 0 OR COALESCE(rev_speed_last_year, 0) = 0,
              ' ',
              CONCAT(", chg = ", CAST(ROUND(ABS((rev_speed_this_year - rev_speed_last_year) / rev_speed_last_year) * 100, 2) AS STRING), "%")
             )
    ) as value_checked,
    CASE WHEN COALESCE(rev_speed_this_year, 0) = 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{this_year}}-10-31" AS DATE)
            THEN "No data but this check was run before the NTD submission due date in {{this_year}}."
        WHEN COALESCE(rev_speed_last_year, 0) = 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{last_year}}-10-31" AS DATE)
            THEN "No data but this check was run before the NTD submission due date in {{last_year}}."
        WHEN COALESCE(rev_speed_last_year, 0) = 0 AND COALESCE(rev_speed_this_year, 0) = 0
            THEN "No data for {{last_year}} and {{this_year}}."
        WHEN COALESCE(rev_speed_last_year, 0) = 0
            THEN "No data for {{last_year}}."
        WHEN COALESCE(rev_speed_this_year, 0) = 0
            THEN "No data for {{this_year}}."
        WHEN ROUND(ABS((rev_speed_this_year - rev_speed_last_year) / rev_speed_last_year), 2) >= {{rs_threshold}}
            THEN CONCAT("The revenue speed, the avg speed of your vehicles while in revenue service, for this mode has changed from last year by >= ",
                        {{rs_threshold}} * 100,
                        "%, please provide a narrative justification.")
        ELSE ""
        END AS description,
    "" as Agency_Response,
    CURRENT_TIMESTAMP() AS date_checked
 FROM {{ ref('int_ntd_rr20_service_3ratios_wide') }}
),

rr20f_154 as (
 SELECT
    organization,
    "RR20F-154: Trips per Hour change" as name_of_check,
    mode,
    {{this_year}} as year_of_data,
    CASE WHEN COALESCE(tph_this_year, 0) = 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{this_year}}-10-31" AS DATE)
            THEN "Did Not Run"
        WHEN COALESCE(tph_last_year, 0) = 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{last_year}}-10-31" AS DATE)
            THEN "Did Not Run"
        WHEN COALESCE(tph_this_year, 0) = 0 OR COALESCE(tph_last_year, 0) = 0
            THEN "No Data"
        WHEN ROUND(ABS((tph_this_year - tph_last_year) / tph_last_year), 2) >= {{tph_threshold}}
            THEN "Fail"
        ELSE "Pass"
        END as check_status,
    CONCAT("{{this_year}} = ", IF(tph_this_year IS NULL, ' ', CAST(ROUND(tph_this_year, 2) AS STRING)),
           ", {{last_year}} = ", IF(tph_last_year IS NULL, ' ', CAST(ROUND(tph_last_year, 2) AS STRING)),
           IF(COALESCE(tph_this_year, 0) = 0 OR COALESCE(tph_last_year, 0) = 0,
              ' ',
              CONCAT(", chg = ", CAST(ROUND(ABS((tph_this_year - tph_last_year) / tph_last_year) * 100, 2) AS STRING), "%")
             )
    ) as value_checked,
    CASE WHEN COALESCE(tph_this_year, 0) = 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{this_year}}-10-31" AS DATE)
            THEN "No data but this check ran before the NTD submission due date in {{this_year}}."
        WHEN COALESCE(tph_last_year, 0) = 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{last_year}}-10-31" AS DATE)
            THEN "No data but this check ran before the NTD submission due date in {{last_year}}."
        WHEN tph_last_year IS NULL OR tph_last_year = 0
            THEN "No data for {{last_year}}."
        WHEN tph_this_year IS NULL OR tph_this_year = 0
            THEN "No data for {{this_year}}."
        WHEN ROUND(ABS((tph_this_year - tph_last_year) / tph_last_year), 2) >= {{tph_threshold}}
            THEN CONCAT("The calculated trips per hour for this mode has changed from last year by >= ",
                        {{tph_threshold}} * 100,
                        "%, please provide a narrative justification.")
        ELSE ""
        END AS description,
    "" as Agency_Response,
    CURRENT_TIMESTAMP() AS date_checked
 FROM {{ ref('int_ntd_rr20_service_3ratios_wide') }}
),

rr20f_171 as (
 SELECT
    organization,
    "RR20F-171: Vehicles of Maximum Service (VOMS) change" as name_of_check,
    mode,
    {{this_year}} as year_of_data,
    CASE WHEN (ROUND(voms_this_year) =0 AND ROUND(voms_last_year) != 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) > CAST("{{this_year}}-10-31" AS DATE))
            OR (ROUND(voms_this_year) !=0 AND ROUND(voms_this_year) IS NOT NULL AND ROUND(voms_last_year) = 0)
            THEN "Fail"
        WHEN COALESCE(voms_this_year, 0) = 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{this_year}}-10-31" AS DATE)
            THEN "Did Not Run"
        WHEN COALESCE(voms_last_year, 0) = 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{last_year}}-10-31" AS DATE)
            THEN "Did Not Run"
        ELSE "Pass"
        END as check_status,
    CONCAT("{{this_year}} = ", IF(voms_this_year IS NULL, ' ', CAST(ROUND(voms_this_year, 2) AS STRING)),
           ", {{last_year}} = ", IF(voms_last_year IS NULL, ' ', CAST(ROUND(voms_last_year, 2) AS STRING))
    ) as value_checked,
    CASE WHEN (ROUND(voms_this_year) =0 AND ROUND(voms_last_year) != 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) > CAST("{{this_year}}-10-31" AS DATE))
            OR (ROUND(voms_this_year) !=0 AND ROUND(voms_this_year) IS NOT NULL AND ROUND(voms_last_year) = 0)
            THEN "The Vehicles of Maximum Service (VOMS) for this mode has changed either to or from 0 compared to last year, please provide a narrative justification."
        WHEN COALESCE(voms_this_year, 0) = 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{this_year}}-10-31" AS DATE)
            THEN "No data but this check was run before the NTD submission due date in {{this_year}} for VOMS."
        WHEN COALESCE(voms_last_year, 0) = 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{last_year}}-10-31" AS DATE)
            THEN "No data but this check was run before the NTD submission due date in {{last_year}} for VOMS."
        ELSE ""
        END AS description,
    "" as Agency_Response,
    CURRENT_TIMESTAMP() AS date_checked
 FROM {{ ref('int_ntd_rr20_service_3ratios_wide') }}
),

rr20f_143 as (
 SELECT
    organization,
    "RR20F-143: Vehicle Revenue Miles (VRM) change from zero" as name_of_check,
    mode,
    {{this_year}} as year_of_data,
    CASE WHEN (ROUND(vrm_this_year) =0 AND ROUND(vrm_last_year) != 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) > CAST("{{this_year}}-10-31" AS DATE))
            OR (ROUND(vrm_this_year) !=0 AND ROUND(vrm_this_year) IS NOT NULL AND ROUND(voms_last_year) = 0)
            THEN "Fail"
        WHEN COALESCE(vrm_this_year, 0) = 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{this_year}}-10-31" AS DATE)
            THEN "Did Not Run"
        WHEN COALESCE(vrm_last_year, 0) = 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{last_year}}-10-31" AS DATE)
            THEN "Did Not Run"
        ELSE "Pass"
        END as check_status,
    CONCAT("{{this_year}} = ", IF(vrm_this_year IS NULL, ' ', CAST(ROUND(vrm_this_year, 2) AS STRING)),
           ", {{last_year}} = ", IF(vrm_last_year IS NULL, ' ', CAST(ROUND(vrm_last_year, 2) AS STRING))
    ) as value_checked,
    CASE WHEN (ROUND(vrm_this_year) =0 AND ROUND(vrm_last_year) != 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) > CAST("{{this_year}}-10-31" AS DATE))
            OR (ROUND(vrm_this_year) !=0 AND ROUND(vrm_this_year) IS NOT NULL AND ROUND(vrm_last_year) = 0)
            THEN "The Vehicle Revenue Miles (VRM) for this mode has changed either to or from 0 compared to last year, please provide a narrative justification."
        WHEN COALESCE(vrm_this_year, 0) = 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{this_year}}-10-31" AS DATE)
            THEN "No data but this check was run before the NTD submission due date in {{this_year}} for VOMS."
        WHEN COALESCE(vrm_last_year, 0) = 0 AND PARSE_DATE('%Y', CAST({{start_date}} AS STRING)) < CAST("{{last_year}}-10-31" AS DATE)
            THEN "No data but this check was run before the NTD submission due date in {{last_year}} for VOMS."
        ELSE ""
        END AS description,
    "" as Agency_Response,
    CURRENT_TIMESTAMP() AS date_checked
 FROM {{ ref('int_ntd_rr20_service_3ratios_wide') }}
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
