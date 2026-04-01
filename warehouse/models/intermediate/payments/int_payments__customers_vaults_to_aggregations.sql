with micropayment_aggregations_customer_map as (
    select
        participant_id,
        aggregation_id,
        customer_id,
        funding_source_vault_id,
        transaction_time
    from {{ ref('int_littlepay__unioned_micropayments') }}
),

settlement_aggregations_customer_map as (
    select
        participant_id,
        aggregation_id,
        customer_id,
        funding_source_id as funding_source_vault_id,
        record_updated_timestamp_utc
    from {{ ref('fct_payments_settlements') }}
),

customer_mapping as (
    select * from {{ ref('int_payments__customers') }}
),

vaults as (
    select * from {{ ref('int_payments__customer_funding_source_vaults') }}
),

aggregations_map_to_customers_vaults as (
    select
        participant_id,
        aggregation_id,
        customer_id,
        funding_source_vault_id,
        -- get latest activity from either micropayments or settlements on this aggregation
        -- need a timestamp for the join with funding sources
        max(coalesce(record_updated_timestamp_utc, transaction_time)) as max_time
    from micropayment_aggregations_customer_map
    full outer join settlement_aggregations_customer_map
    using(participant_id, aggregation_id, customer_id, funding_source_vault_id)
    group by participant_id, aggregation_id, customer_id, funding_source_vault_id
),

int_payments__customers_vaults_to_aggregations as (
    -- select distinct because multiple customers might map to same principal customer id
    select distinct
        aggregations.participant_id,
        aggregations.aggregation_id,
        customer_mapping.principal_customer_id,
        vaults.bin,
        vaults.card_scheme,
    from aggregations_map_to_customers_vaults as aggregations
    left join customer_mapping
        on aggregations.customer_id = customer_mapping.customer_id
        and aggregations.participant_id = customer_mapping.participant_id
    left join vaults
        on aggregations.funding_source_vault_id = vaults.funding_source_vault_id
        and aggregations.participant_id = vaults.participant_id
        and aggregations.max_time >= vaults.calitp_valid_at
        and aggregations.max_time < vaults.calitp_invalid_at
)

select * from int_payments__customers_vaults_to_aggregations
