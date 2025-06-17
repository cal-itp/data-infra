WITH staging_stations_and_facilities_by_agency_and_facility_type AS (
    SELECT *
    FROM {{ ref('stg_ntd__stations_and_facilities_by_agency_and_facility_type') }}
    -- remove bad rows
    WHERE key NOT IN ('889aa75ff154f55a32fa3afb74b6e236','345e37241f3883bfc08428a9a96faa97','6f507fa5717699c74202df80606a2557',
        '814b5dc32062eed9be2eb59a5e6bb140','abd981f1eeb176cd71024b38c0ce24e6','0610e7c75b67e0edd77f3ef3117b15ba',
        'd31729d3be4d8f0429dd102f94b77e7f','d65372e696a7bae859d00f3b10d42141','349183b4d6c1f92d3be13457ef8eea05',
        '11206b74a3f2f7fd453aa01b79a0a52c','429b2f3e22cd8c75d6fe245048244fd3','a942d417813164b78586bd1bf2a0855d',
        'ecd29c26452544cf60e3ebf40405fc65','10543c670a74cab09d939dbccfce5707','ab22087042cc49d054f00dd101797b84',
        '7a4d62bedf9b28ae9012db3224801bd5','5dad5c44a23b526d4d304cb84291ca15','e3d99595799db399728cb66adcc07290',
        '1bada0357021e156420bfab1ae31b3c1','6943d72da4b6ab0d8b2b8f1814d2dc0e','4afa0365bfdb0cc0883198fcd16ab293',
        '373fcc547a381745c12710bb272211a2','2be3887bd681c16ca015539b5abf8529','145cb44ced40bd2d593eb242c05fd6b7',
        'ef4dab4a487ec44305b459568f3fb3f6','9d4f1caeda82b63dcee955f1009b34d6')
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

fct_stations_and_facilities_by_agency_and_facility_type AS (
    SELECT
        key,
        stg.ntd_id,
        stg.report_year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        stg.administrative_and_other_non_passenger_facilities,
        stg.administrative_office_sales,
        stg.agency_voms,
        stg.at_grade_fixed_guideway,
        stg.bus_transfer_center,
        stg.combined_administrative_and,
        stg.elevated_fixed_guideway,
        stg.exclusive_grade_separated,
        stg.ferryboat_terminal,
        stg.general_purpose_maintenance,
        stg.heavy_maintenance_overhaul,
        stg.maintenance_facilities,
        stg.maintenance_facility_service,
        stg.organization_type,
        stg.other_administrative,
        stg.other_passenger_or_parking,
        stg.parking_and_other_passenger_facilities,
        stg.parking_structure,
        stg.passenger_stations_and_terminals,
        stg.primary_uza_population,
        stg.reporter_type,
        stg.revenue_collection_facility,
        stg.simple_at_grade_platform,
        stg.surface_parking_lot,
        stg.total_facilities,
        stg.uace_code,
        stg.underground_fixed_guideway,
        stg.uza_name,
        stg.vehicle_blow_down_facility,
        stg.vehicle_fueling_facility,
        stg.vehicle_testing_facility,
        stg.vehicle_washing_facility,
        stg.agency AS source_agency,
        stg.city AS source_city,
        stg.state AS source_state,
        stg.dt,
        stg.execution_ts
    FROM staging_stations_and_facilities_by_agency_and_facility_type AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
)

SELECT * FROM fct_stations_and_facilities_by_agency_and_facility_type
