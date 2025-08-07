{% macro label_elavon_entities(input_model, date_col = 'payment_date') %}
WITH payments_entity_mapping AS (
    SELECT
        * EXCEPT(elavon_customer_name),
        elavon_customer_name AS customer_name
    FROM {{ ref('payments_entity_mapping') }}
),

orgs AS (
    SELECT * FROM {{ ref('dim_organizations') }}
)

SELECT
    input.*,
    orgs.name AS organization_name,
    orgs.source_record_id AS organization_source_record_id,
    littlepay_participant_id,
FROM {{ input_model }} AS input
LEFT JOIN payments_entity_mapping
    ON input.customer_name = payments_entity_mapping.customer_name
    AND CAST(input.payment_date AS TIMESTAMP)
        BETWEEN CAST(payments_entity_mapping._in_use_from AS TIMESTAMP)
        AND CAST(payments_entity_mapping._in_use_until AS TIMESTAMP)
LEFT JOIN orgs
    ON payments_entity_mapping.organization_source_record_id = orgs.source_record_id
    AND CAST(input.{{ date_col }} AS TIMESTAMP) BETWEEN orgs._valid_from AND orgs._valid_to
{% endmacro %}
