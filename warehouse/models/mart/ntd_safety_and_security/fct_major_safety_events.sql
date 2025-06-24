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
WHERE _content_hash NOT IN ('aef081e5571ed628d8b1da5014b12bfd','b8c901e33bfa0813f576b19efea245e0','3935ba33642772b29684f4b727e89ee0',
    '1fb500a87ef27564084e981522044ab5','6e8a8f8f08c0dc3850e2d361ff7ae178','ba21902b2f734d0dbb8c36808d9346b9',
    '14415f48b6e7d7c3551c0499389460d2','36e823f201f5e440514f0540cf4f4d22','ca47ee3cdcf56bfec9906b138abd20bd',
    '443ae3deb9d556badc1fd679b16c27d0','7a7fbda968b534b36e85e1acecd73525','71bd8dc7b40a35203253f8e1457ec067',
    '91ed9a880d942b91a2c4ec075e94feb1','878785761833226abc92479473346956','36b8ab8d25900421feac77fdaedbdd12',
    '855bb7cd7dcaa89456ac9611e70c452f','f543803686f4b24cca4e4b2824739730','9e79b1243c2548f5fe43ab9d5fed291e',
    '593d1b98fe7f4baa907a52c72806c1ff','1114b70aee7dc5b6bebade5ca04f41a0','cee74507e6cb3e909f95682d23e59d97',
    '4a5109beabee0d228286e7ad6665514d','349922d4867c8847183701543e5813b0','f6fd9f9208987983d0b5b7e5c7cf3676',
    '3331d393c080eab5d6c63f6130051da5','230065a7e7de201005efc7f75c0ec118','00d22f547db42d953d9d92b76639d2b4',
    '4ab1d3db9ab27991bc40f5554c932f8b','2ee50617743f2b5bca93f33f0ebdd7d1','4f2dd24d0097c5f9a8edd3f818c45000',
    'c341feb37763dea5059ea4b0d4320a5f','3624ac6698dc12af9df77fb6b9e35695','5987a2b59af7cd025bec3e8b0855d649',
    'a79838463aed1394fedf6de3a2618923','caf18be9b912355a8be60c0585e63e0c','d5216be7daa3901f0ec8f1102dcaad12',
    '00e2b350d5bf3ab5f2251e135aca6b6a','c4d41154a15f355b4b9c3dff86948f24','2cc13a71aacb173314d519b907086815',
    'fdcd7df5489b33f7288bdbb1bd649672','a5493d9d64360b1166dfaab4a4518ec6','ababcc0af5a9c3764f0e86bbbf768c9b',
    '116c4875f7e8c9af1eb9e6a070e1efe9','14c12d091afea2f9b2d976b107a3ed37','45beecd829c1d3c42d66d6d5f0119d09',
    '77561f820d88bad3ad97133cf1c6b297','15f639b16dbaba6662435355d084a9f9','6ea34546846e32bff10fa2ad7961b7ca',
    '4a02736bf7d5fb22ad75635394883cc6','43a5190ac0da3f7bfe46f5c3dd9fceb3','12cd2924709a89154c3288c0a88f9953',
    '5f550abbe8dfeffff06660f0b1ee52cf','f0a83931b7cacc440ac87ed5f66cdeae','1a574c9174b94fea90318acc47cc7460',
    '53248077b512f5efe7592bd2245ab1e0','65dedbf7f6eaea331f7976a6e0fbdccf','01b3d1a775bc7931e4e84085c060e455',
    'ba94a7d57844db5316e069c7a2d444d9','585ec38955596ce06964b9a802fa8122','d484f3e08cdff07a651fe5e902bef2a6',
    'fc504c4d4f31fe042af617e6fe0a1cf5','9dd68cd75bd0c9a222ab4eda8350ff66','1cc6e2cb02f84710eedce185b6385256',
    'f90e2036b6d9672f65fba23ef70c1f35','3a794cb8b8ea03cd65493c6c760c6f5f','34d669d8a500b17bf14edcdff9a8c465',
    'c13c9ffe9d4dbc5b85cb7a2ed1c252b6','79411ed0957bcbfd5572f4e356097770','df82d8aea3f0caf7297399cfdf146f44',
    '21a94647c565dc24ac6906e73368a99e','c3edb802278e5b077a504836747687f6','b2a0964f555d0fbaf5f53e9df70961fe',
    'e671df959772c8584652b0e4b5242347','be54405321e6029d22e0ebcad66cc4a3','d67e016ec0d9fd816ce50db4bf15c377',
    '7ee7bb0b8f31036de360d812b558e2cb','0848b0f3f1a517be7e1175fbdf65625e','5452a5cf55397d9f87d982da8dd26dc2',
    '532a49a940d5df2dff1b6e893c95a0ca','ebbf32330597a91ef14b7d11ee1b715b','750f55974ce8e55c511711e80e6f4acc',
    '9441d20bf236feeebf9e775ce1a35bb8','8b6d4324bc2c3c4c96b0dec07d71a54e','a5e13fcf455f15ff019b19efb35dae7e',
    '95d2bf1dfff98f881b3392f32b6be93c','2f9bd7633dbd363c3a45caf3d183557d','219b55ced4e402e9f2318a5effb7ae68',
    '5547735563739a096111bfea72d0c99e','3f3a26631983c204fd15739ac91a620e','4bbc9df2b7ede52c2068b40ccf98d497',
    '32430975538cb3dcf74975697e2a0f68','3d7664be0790d54b4992d07f0f22a8ae','d225f685ab79b11172cb5e6c88f70616',
    '8cc8ad684213b8714fd53a3f2a61ed2a','47d1fa0ad27fe0134554de8d5fe6355c','781d5c1bc28ddb69f80a0c1c221b9dea',
    'e0d9e5b1b9680e2f8862a72def76e80e','a10e250bd8907ed5c713820a7fcf4abd','a450ad59c4fb84a56c1873b2a3204ef1',
    '9bb520acd612231f279de634c0e88230','4d0c7602e0ea856af6c6835a6e81541c')
