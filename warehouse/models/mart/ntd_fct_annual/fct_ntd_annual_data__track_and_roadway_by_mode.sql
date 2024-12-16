WITH staging_track_and_roadway_by_mode AS (
    SELECT *
    FROM {{ ref('stg_ntd__track_and_roadway_by_mode') }}
),

fct_ntd_annual_data__track_and_roadway_by_mode AS (
    SELECT *
    FROM staging_track_and_roadway_by_mode
)

SELECT * FROM fct_ntd_annual_data__track_and_roadway_by_mode
