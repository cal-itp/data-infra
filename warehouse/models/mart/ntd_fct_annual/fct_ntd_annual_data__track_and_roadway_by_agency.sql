WITH staging_track_and_roadway_by_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd__track_and_roadway_by_agency') }}
),

fct_ntd_annual_data__track_and_roadway_by_agency AS (
    SELECT *
    FROM staging_track_and_roadway_by_agency
)

SELECT * FROM fct_ntd_annual_data__track_and_roadway_by_agency
