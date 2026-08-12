with services as (
  select *
    from {{ ref('int_transit_database__services_dim') }}
),

-- unnest rixed-route service's linked complementary paratransit services 
-- (may add fixed-route filter later)
unnest_complementary_paratransit_services as (
  select key AS fixed_route_service_key,
        name AS fixed_route_service_name,
        complementary_paratransit_service AS complementary_paratransit_service_key,

        _is_current,
        _valid_from,
        _valid_to
    FROM services,
        services.complementary_paratransit_service AS complementary_paratransit_service
),

-- join fixed route service with its complementary service
bridge_service_x_paratransit as (
  select  unnested.fixed_route_service_key,
         unnested.fixed_route_service_name,

         services.key as paratransit_service_key,
         services.name as paratransit_service_name,

         (unnested._is_current AND services._is_current) AS _is_current,
         GREATEST(unnested._valid_from, services._valid_from) AS _valid_from,
         LEAST(unnested._valid_to, services._valid_to) AS _valid_to
  from unnest_complementary_paratransit_services unnested
  left join services
    on unnested.complementary_paratransit_service_key = services.source_record_id
   and unnested._valid_from < services._valid_to
   and unnested._valid_to > services._valid_from
)

select *
from bridge_service_x_paratransit