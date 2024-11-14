WITH staging_track_and_roadway_guideway_age_distribution AS (
    SELECT *
    FROM {{ ref('staging', 'stg_ntd_annual_data__track_and_roadway_guideway_age_distribution') }}
),

fct_ntd_annual_data__track_and_roadway_guideway_age_distribution AS (
    SELECT *
    FROM staging_track_and_roadway_guideway_age_distribution
)

SELECT * FROM fct_ntd_annual_data__track_and_roadway_guideway_age_distribution
