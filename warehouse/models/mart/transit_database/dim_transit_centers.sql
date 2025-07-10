{{ config(materialized='table') }}
with dim_transit_centers as (
    SELECT
        id,
        agency_name,
        facility_id,
        facility_name,
        facility_type,
        ntd_id,
        geometry
    FROM {{ ref('stg_transit_database__transit_facilities') }}
    where facility_type IN ("Ferryboat Terminal", "Bus Transfer Center", "Simple At-Grade Platform Station")
)
SELECT * FROM dim_transit_centers
