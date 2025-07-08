WITH staging_stations_by_mode_and_age AS (
    SELECT *
    FROM {{ ref('stg_ntd__stations_by_mode_and_age') }}
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

fct_stations_by_mode_and_age AS (
    SELECT
        stg.key,
        stg.ntd_id,
        stg.report_year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        stg.modes,
        stg.mode_names,
        stg.facility_type,
        stg._1940s,
        stg._1950s,
        stg._1960s,
        stg._1970s,
        stg._1980s,
        stg._1990s,
        stg._2000s,
        stg._2010s,
        stg._2020s,
        stg.agency_voms,
        stg.organization_type,
        stg.pre1940,
        stg.primary_uza_population,
        stg.reporter_type,
        stg.total_facilities,
        stg.uace_code,
        stg.uza_name,
        stg.agency AS source_agency,
        stg.city AS source_city,
        stg.state AS source_state,
        stg.dt,
        stg.execution_ts
    FROM staging_stations_by_mode_and_age AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
    -- remove bad rows
    WHERE stg.key NOT IN ('e6ae8b4ab7edaeb5aacae6deb53f248a','49c35a4752024b8492cf0634630e035d','01ca19b045cc370b7b480a4ec88cfa5b',
        'ad4740b4f02762e86f43980ed897a17d','180192ab7473c2305cc0a7b23230e8f7','4946050b519fa2b2f5ad7926f95e8001',
        '50f3d0db10eeaf0d6aec3dfc8e2f129d','ee2f2322812feccb5686c302cc577013','fe2bd9f259fcbdb85c1177993382f2b5',
        '5d794e553a54c8fb4f964259ffc59230','716649ddb0ee63c910ba1043d1b86fe3','7bfe300355338e1f70c19976c756c2c7',
        '8e69c75b39b5f6d50fcf1b311e9f3d41','3392b1216af42b4cda868fba00c11f5a','20f28ea22694c3668fd188f3a197628b',
        'cac220eb2a51b3d9239f6f1ae2e35ab0','492cb87b59c8e61dae96f20193600535','8692a5ebd76c76b9226136348d47ae3e',
        '9e887e7ecc908b824b132c1ddaae6ab8','7cb10d28fde63c137be34741261ecd5a','ae152668899d7d61e61e7798a90f7cf5',
        '082462f81f2b67658fa6f99fee485fc3','6801945e97bd7193a2fea6910550c9f6','4796f8b2ce1197ddacd7352a5bc3c13f',
        '18fc9c5ac42802d1326093b06ccccb61','edf7b7a1601f7b2e68f091d3971eb8c6','f06fc43982dcd47c5974a3a08480557d',
        '1594dbd45a70e4bdc041e017b9e443b3','605fa149fd1b2edd7c511f89cb253777','855d71d69b2a11b8975bd8ac7388a57d')
)

SELECT * FROM fct_stations_by_mode_and_age
