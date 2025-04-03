{{ config(materialized='table') }}

WITH int_littlepay__unioned_settlements AS (
    SELECT * FROM {{ ref('int_littlepay__unioned_settlements') }}
),


elavon_deposits AS (
    SELECT * FROM {{ ref('fct_elavon__transactions') }}
    WHERE batch_type = 'D'
),

elavon_littlepay__transaction_reconciliation AS (
    SELECT

        t1.settlement_id AS littlepay_settlement_id,
        t1.aggregation_id AS littlepay_aggregation_id,
        t1.retrieval_reference_number AS littlepay_retrieval_reference_number,
        t1.littlepay_reference_number AS littlepay_reference_number,
        t1.external_reference_number AS littlepay_external_reference_number,
        t1.record_updated_timestamp_utc AS littlepay_record_updated_timestamp_utc,
        t1.transaction_amount AS littlepay_transaction_amount,

        t2.amount AS elavon_amount,
        t2.surchg_amount AS elavon_surchg_amount,
        t2.convnce_amt AS elavon_convnce_amt,
        t2.transaction_date AS elavon_transaction_date,
        t2.purch_id AS elavon_purch_id,
        t2.payment_reference AS elavon_payment_reference,
        t2.settlement_date AS elavon_settlement_date,
        t2.payment_date AS elavon_payment_date,
        t2.authorization_code AS elavon_authorization_code,
        t2.chargeback_control_no AS elavon_chargeback_control_no,
        t2.roc_text AS elavon_roc_text,


        t1.participant_id AS littlepay_participant_id,
        t1.customer_id AS littlepay_customer_id,
        t1.funding_source_id AS littlepay_funding_source_id,
        t1.acquirer AS littlepay_acquirer,
        t1._line_number AS littlepay__line_number,
        t1.instance AS littlepay_instance,
        t1.extract_filename AS littlepay_extract_filename,
        t1.ts AS littlepay_ts,


        t2.account_number AS elavon_account_number,
        t2.routing_number AS elavon_routing_number,
        t2.card_type AS elavon_card_type,
        t2.charge_type AS elavon_charge_type,
        t2.charge_type_description AS elavon_charge_type_description,
        t2.card_plan AS elavon_card_plan,
        t2.card_no AS  elavon_card_no,
        t2.chk_num AS elavon_chk_num

    FROM int_littlepay__unioned_settlements AS t1
    INNER JOIN elavon_deposits AS t2
        ON t1.retrieval_reference_number = t2.PURCH_ID
)

SELECT * FROM elavon_littlepay__transaction_reconciliation
