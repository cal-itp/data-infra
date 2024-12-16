WITH staging_track_and_roadway_guideway_age_distribution AS (
    SELECT *
    FROM {{ ref('stg_ntd__track_and_roadway_guideway_age_distribution') }}
),

fct_track_and_roadway_guideway_age_distribution AS (
    SELECT *
    FROM staging_track_and_roadway_guideway_age_distribution
)

SELECT * FROM fct_track_and_roadway_guideway_age_distribution
