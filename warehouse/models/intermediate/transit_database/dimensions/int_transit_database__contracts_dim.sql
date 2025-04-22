{{ config(materialized='table') }}

WITH latest_contracts AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__contracts'),
        order_by = 'dt DESC'
        ) }}
),

-- TODO: make this table actually historical
historical AS (
    SELECT
        *,
        TRUE AS _is_current,
        CAST(universal_first_val AS TIMESTAMP) AS _valid_from,
        {{ make_end_of_valid_range('CAST("2099-01-01" AS TIMESTAMP)') }} AS _valid_to
    FROM latest_contracts
),

int_transit_database__contracts_dim AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['id', '_valid_from']) }} AS key,
        id AS source_record_id,
        name,
        contract_holder_organization_key,
        contract_vendor_organization_key,
        value,
        start_date,
        end_date,
        is_active,
        covered_services,
        renewal_option,
        notes,
        attachments,
        contract_name_notes,
        covered_components,
        _is_current,
        _valid_from,
        _valid_to
    FROM historical
)

SELECT * FROM int_transit_database__contracts_dim
