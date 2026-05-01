{% macro label_elavon_entities(input_model, date_col = 'payment_date') %}
WITH payments_entity_mapping AS (
    SELECT
        gtfs_dataset_source_record_id,
        organization_source_record_id,
        littlepay_participant_id,
        null as enghouse_operator_id,
        elavon_customer_name AS customer_name,
        _in_use_from,
        _in_use_until
    FROM {{ ref('payments_entity_mapping') }}

    UNION ALL

    SELECT
        gtfs_dataset_source_record_id,
        organization_source_record_id,
        null as littlepay_participant_id,
        enghouse_operator_id,
        elavon_customer_name AS customer_name,
        _in_use_from,
        _in_use_until
    FROM {{ ref('payments_entity_mapping_enghouse') }}
),

orgs AS (
    SELECT * FROM {{ ref('dim_organizations') }}
)

SELECT
    input.*,
    orgs.name AS organization_name,
    orgs.source_record_id AS organization_source_record_id,
    littlepay_participant_id,
    enghouse_operator_id
FROM {{ input_model }} AS input
LEFT JOIN payments_entity_mapping USING (customer_name)
LEFT JOIN orgs
    ON payments_entity_mapping.organization_source_record_id = orgs.source_record_id
    AND CAST(input.{{ date_col }} AS TIMESTAMP) BETWEEN orgs._valid_from AND orgs._valid_to
{% endmacro %}
