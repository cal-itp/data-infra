--- get the # of active VINS in the inventory - DON'T HAVE
--- get the # of VOMS in the rr-20
-- get the # of vins in the A30

with voms_rr20 as (
    select organization,
    fiscal_year,
    AVG(VOMX) as rr20_voms
    FROM {{ ref('int_ntd_rr20_service_alldata') }}
    GROUP BY organization, fiscal_year
),

vins_a30 as (
    SELECT organization,
    api_report_period as fiscal_year,
    COUNT(DISTINCT VIN) as a30_vin_n
    FROM {{ ref('stg_ntd_a30_assetandresourceinfo') }}
    GROUP BY organization, fiscal_year
)

select voms_rr20.*, vins_a30.a30_vin_n
FROM voms_rr20
FULL OUTER JOIN vins_a30
    ON voms_rr20.organization = vins_a30.organization
    AND voms_rr20.fiscal_year = vins_a30.fiscal_year
ORDER BY organization, fiscal_year
