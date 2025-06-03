WITH source AS (
    SELECT * FROM {{ ref("int_ntd__monthly_ridership_with_adjustments_joined") }}
),

ntd_modes AS (
    SELECT * FROM {{ ref("int_ntd__modes") }}
),

dim_agency_information AS (
    SELECT
        ntd_id,
        year,
        agency_name,
        city,
        state,
        caltrans_district_current,
        caltrans_district_name_current
    FROM {{ ref('dim_agency_information') }}
),

fct_monthly_ridership_with_adjustments AS (
    SELECT {{ dbt_utils.generate_surrogate_key(['src.ntd_id', 'src.mode', 'src.tos', 'src.period_month', 'src.period_year']) }} as key,
        src.ntd_id,
        src.period_year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        src.legacy_ntd_id,
        src.reporter_type,
        concat(src.period_year, '-',  lpad(src.period_month, 2, '0')) AS period_year_month,
        src.period_month,
        src.uza_name AS primary_uza_name,
        src.uace_cd AS primary_uza_code,
        src._3_mode,
        src.mode,

        modes.ntd_mode_full_name AS mode_name,

        CASE
            WHEN src.mode IN ('AG', 'AR', 'CB', 'CC', 'CR', 'FB', 'HR', 'IP', 'IP', 'LR', 'MB', 'MG', 'MO', 'RB', 'SR', 'TB', 'TR', 'YR')
            THEN 'Fixed Route'
            WHEN src.mode IN ('DR', 'DT', 'VP', 'JT', 'PB')
            THEN 'Demand Response'
            ELSE 'Unknown' -- mode is null sometimes
        END AS service_type,

        src.mode_type_of_service_status,
        src.tos,
        src.upt,
        src.vrm,
        src.vrh,
        src.voms,
        -- This has been kept as 'agency' temporarily to temporarily prevent downstream analysis issues,
        -- but the pattern would be to rename this 'source_agency'
        src.agency,
        src._dt,
        src.execution_ts
    FROM source AS src
    LEFT JOIN ntd_modes AS modes
        ON src.mode = modes.ntd_mode_abbreviation
    LEFT JOIN dim_agency_information AS agency
        ON src.ntd_id = agency.ntd_id
            AND src.period_year = agency.year
)

SELECT * FROM fct_monthly_ridership_with_adjustments
