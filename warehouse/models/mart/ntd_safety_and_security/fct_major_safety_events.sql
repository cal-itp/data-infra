WITH staging_major_safety_events AS (
    SELECT *
    FROM {{ ref('stg_ntd__major_safety_events') }}
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

fct_major_safety_events AS (
    SELECT
        stg.ntd_id,
        stg.year,
        stg.month,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        stg.mode,
        stg.type_of_service,
        stg.location_group,
        stg.location,
        stg.event_type,
        stg.customer,
        stg.other,
        stg.worker,
        stg.minor_nonphysical_assaults_on_other_transit_workers,
        stg.total_injuries,
        stg.non_physical_assaults_on_operators_security_events_only_,
        stg.total_incidents,
        stg.minor_physical_assaults_on_operators,
        stg.minor_physical_assaults_on_other_transit_workers,
        stg.additional_assault_information,
        stg.sftsecfl,
        stg.reportername,
        stg.dt,
        stg.execution_ts,
        {{ dbt_utils.generate_surrogate_key(['stg.ntd_id', 'stg.year', 'stg.month',
            'agency.agency_name', 'agency.city', 'agency.state', 'agency.caltrans_district_current',
            'agency.caltrans_district_name_current', 'stg.mode', 'stg.type_of_service', 'stg.location_group',
            'stg.location', 'stg.event_type', 'stg.customer', 'stg.other', 'stg.worker',
            'stg.minor_nonphysical_assaults_on_other_transit_workers', 'stg.total_injuries',
            'stg.non_physical_assaults_on_operators_security_events_only_', 'stg.total_incidents',
            'stg.minor_physical_assaults_on_operators', 'stg.minor_physical_assaults_on_other_transit_workers',
            'stg.additional_assault_information', 'stg.sftsecfl', 'stg.reportername']) }} AS _content_hash
    FROM staging_major_safety_events AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.year = agency.year
)

SELECT * FROM fct_major_safety_events
-- remove bad rows for 'Advance Transit, Inc. NH' and 'Southern Teton Area Rapid Transit'
WHERE _content_hash NOT IN (
    'a5eaf5c4ec897419f11586f94214a04a','37701074ac6981cf292b15d6c794d8a2','db29665789a160ce0c7609f230912131',
    'bbf9196852a817dac5eab0b96ae7a6d1','0708c383d5dbd0876c20f3ba374f7266','3c01813e7ab6cc7475d5b0ad3e720e99',
    '5de266afc22de90c875a3dd738025e2f','04d46158e46dccaed4728467ab51fe41','fb325dc1f8cb05c289bbb3233b1e3bf7',
    '1a4b4081211fc00c1da85682f86d1733','c166b861a46b9bd87f3f038ec124f0f6','71ad9b43ffd20eec1ba8dcde40dddcfa',
    'e942764ed0a041b60090a7a0da42ce00','6cfe6f6c9db155e381a39dfea1d1dfb4','8a04961877fe91cd0d893871adf9e2f6',
    '59ecf9772ef01d83a9df3423a88cac90','bcad1bdd40b8ac0b85702d875d797925','bc4f91319f65301a063e27f6b2b191c4',
    '1cf807628885249cfb00f6ad4c599d60','a0a68d1e7749f5462bdf813861e9c1b4','c3c571b7612ba7621616cc560e233411',
    'a9e4b845720746e64517c0bad904f17e','b61c9cb6ac8f9a8c0331d18ff6de950a','744015d6b745e7f1a6353ef06bfa2850',
    'f2d133e3c4dfa56ba89ed13df5365bee','0cb104576d313e5f3fb2bac9293844eb','b3b37e22b03bd8532acb1e718894f163',
    '3c567f6d52d37056ce54af46b1cd68f6','e372a97a4f0dd0838f218f5b90307d20','a87a1c5afc4456794ed9c2df5297ab2e',
    '25020be68ea0db233b9e605cfd3793cc','4313eb9fd7e02db4163706c333a07601','eaf70b5a478430982b3ec3aeb9efed29',
    'd7530c7c96f6535116b25191b1fac9a8','7b3f274e5ef5c35859a72f60ab1e3225','f67d7d3782309278384c4f0c35bc1a2e',
    '551cfa12bb294918fd6cf07b75be761e','46477b96a1ddc8c604645e74c2aa7689','ef765fd1bf1c602c46e3c736c743997c',
    '0b651b7148dd6fe36f7177fbaeb28440','1e82b52f0bf0cbbf2f8681913ba420aa','d9b55279af6e8fe4219710c2e1c59253',
    'bcb36082319cb011dee4da00155bd6f4','753a12aa2efd17486815d215c8b8bfe0','9f3b67b5fd10069baa105dca767d69e9',
    'f48edd4567258c4bb5e715a3ddce5300','09b3d9c071ce69270ec7276682bcf494','7d203cd4500a4bce45bdc014a86d0631',
    '192a36c3066ca8a87876dacf798464ae','b350d8b140e8446226a08eaa25b2ef64','6179336ffc49bd9de98f34b3be057ea2',
    'ae5572939c450ffff43f9e53d878922f','15d26e4889960a2bc0f4961c4583941c','89c662e8f4d4d8ddcfad5bce9af7f8d3',
    'a293edc7b3e95f485dfd2c8f3538a185','0aaecbf9d5b9ab9ddedc7a0f5fe99696','2faaedd897d82dd7a62d581c63e7e166',
    '1f05a48ec2434b1c07a9fabb8170a7d8','9b3104a9c73341f28127180b52ccd443','7bffb23ada802726fa70cd6b55f8a031',
    '005cf36636c6497ed2d0ce1175cea041','4e467e91841fad33c74f4fe74111a298','351de5df434615d4f0da52ab395537dc',
    'b9c99faa0490d4bf56025d6aec091b52','0a1e55a355ebf219081c4b206d2bc437','eaa99e247305dd0f6630ec345685e8e6',
    'f869e05305e98a8c71353c6bd766b6cf','80384a4df976241f56ba25a12141e22d','2b06b3f17d6be5181e2349c95ef78ba8',
    '3eb344ab864fab22e8a0d0f16821ac7a','d0de422064293d0e59976b97c21d2616','bdb39edabc380be5e80b8827155e829f',
    '4e83ae0fe7bda71c12a9da2d9295de7c','198108f2470df8d5e9eeb951e4ff525d','0d6645891ef597f1eee90863503c3075',
    'd701236f162e5a5e2789d07887724bb1','15d36233a0acce69623eef207b11e148','a25909dba23794fd86d1377cd18a39e3',
    '7467071d786830896a8b2e6e3ff1e6ac','4eb6d75b872b7ae53ec09419167a18a0','2e66d5be3210dd23208ba90d853a9a42',
    'de925ef45b227b8746ae01d041afa44d','196c8a64c30fe6c32f59fbdcedd4420e','49e545f9b65733b706532fbf6749e8e0',
    '76a212ed4eae1bc934214676f1d7cfca','b54d6c235556facbad1c4c3c662fad65','29c256da0c30373752e37d0bc45d7a29',
    '2682f4bc45b74947c3c516c074322290','a6ecdd3bcbf9d0f833382d73075b257d','12b22fd8cdad2c7a45acb10ece29f4a9',
    '6250fe71ed608766257ef2eb3047e94f','5dab904a2136c046826d5b38dae4fc4f','af16fbc238235abf768c102426a421a9',
    '433ac82fef0cb7514af346068eebcc7d','390103519d7bb4b55fe7bc26139ecb65','3624ac6698dc12af9df77fb6b9e35695',
    'c341feb37763dea5059ea4b0d4320a5f','5987a2b59af7cd025bec3e8b0855d649','c4d41154a15f355b4b9c3dff86948f24',
    'ababcc0af5a9c3764f0e86bbbf768c9b','585ec38955596ce06964b9a802fa8122')
