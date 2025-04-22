{{ config(materialized='table') }}

WITH latest_products AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__products'),
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
    FROM latest_products
),

int_transit_database__products_dim AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['id', '_valid_from']) }} AS key,
        id AS source_record_id,
        name,
        url,
        requirements,
        notes,
        components,
        connectivity,
        certifications,
        product_features,
        business_model_features,
        vendor_organization_source_record_id,
        accepted_input_components,
        output_components,
        start_date,
        end_date,
        status,
        cal_itp_product,
        _is_current,
        _valid_from,
        _valid_to
    FROM historical
)

SELECT * FROM int_transit_database__products_dim
