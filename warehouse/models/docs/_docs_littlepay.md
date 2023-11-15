Documentation related to Littlepay data schema
In many cases, taken or adapted directly from Littlepay documentation: https://docs.littlepay.io/data/

-------------------------------- COMMON FIELD INCLUDING KEYS --------------------------------

{% docs lp_micropayment_id %}
Uniquely identifies a micropayment.
{% enddocs %}

{% docs lp_aggregation_id %}
Identifies an aggregation of one or more micropayments that can be authorised/settled.
{% enddocs %}

{% docs lp_participant_id %}
Littlepay identifier for the participant (transit agency) associated with this entity or event.
{% enddocs %}

{% docs lp_customer_id %}
Identifies the customer associated with this payment activity or entity.
A customer ID does not necessarily uniquely identify an individual person
or payment card.
{% enddocs %}

{% docs lp_funding_source_vault_id %}
Identifies the funding source (for example, card) that a micropayment will be charged to. This is always the card that was tapped.
A registered customer can have multiple funding sources linked to it.
{% enddocs %}

-------------------------------- AGGREGATIONS/SUMMARIES --------------------------------

{% docs lp_net_micropayment_amount_dollars %}
Sum of the `charge_amount` values for all micropayments in this aggregation.
If there are credit (pre-settlement refund) micropayments in the aggregation,
the value of those will have been subtracted from this total because they have
negative `charge_amount` values.
Post-settlement refunds will not be reflected since they are not recorded in the micropayments table.
{% enddocs %}

{% docs lp_total_nominal_amount_dollars %}
Sum of the `nominal_amount` (unadjusted) values for all micropayments in this aggregation.
This will not reflect pre-settlement refunds or micropayment adjustments.
{% enddocs %}

{% docs lp_mp_latest_transaction_time %}
Maximum (latest) transaction time for micropayments in this aggregation.
{% enddocs %}

{% docs lp_num_micropayments %}
Number of distinct micropayment ID values for micropayments in this aggregation.
{% enddocs %}

{% docs lp_contains_pre_settlement_refund %}
If "true", this aggregation contains a pre-settlement refund (i.e., contains a micropayment with `charge_type` "refund").
{% enddocs %}

{% docs lp_contains_variable_fare %}
If "true", this aggregation contains at least one micropayment with a variable fare charge type.
{% enddocs %}

{% docs lp_contains_flat_fare %}
If "true", this aggregation contains at least one micropayment with a `flat_fare` charge type.
{% enddocs %}

{% docs lp_contains_pending_charge %}
If "true", this aggregation contains at least one micropayment with a pending charge type.
{% enddocs %}

{% docs lp_contains_adjusted_micropayment %}
If "true", this aggregation contains at least one micropayment that had a micropayment adjustment applied. For example, micropayments that were reduced due to a fare cap being applied will have a "true" in this column.
{% enddocs %}

{% docs lp_settlement_contains_imputed_type %}
Some settlements are missing `settlement_type` (i.e., `DEBIT` vs. `CREDIT` designation).
We impute those missing values on the heuristic that first updates tend to be the debit
and any subsequent updates are credits (refunds).
Rows with "true" in this column indicate that at least one input row had its settlement type imputed.
These rows could potentially (though we believe it is unlikely) be sources of error if the imputation
assumptions were incorrect.
{% enddocs %}

{% docs lp_settlement_contains_refund %}
If `true`, this aggregation settlement included at least one row with settlement_type = `CREDIT`.
{% enddocs %}

{% docs lp_settlement_latest_update_timestamp %}
Most recent `record_updated_timestamp_utc` value for this aggregation settlement.
If a credit (refund) was issued after the initial debit, this will be the timestamp of the credit.
{% enddocs %}

{% docs lp_net_settled_amount_dollars %}
Net dollar amount of this aggregation settlement; if a refund (credit) has been issued,
that will be reflected. So for example if $20 was debited and then $8 was credited,
the value in this column will be `12` (= 20 - 8).
{% enddocs %}

{% docs lp_settlement_debit_amount %}
Total dollar amount associated with debit settlements in this aggregation.
Numbers in this column are positive because they represent amounts debited (charged) by the participant to the customer (rider);
i.e., these values represent income for the participant (agency).
{% enddocs %}

{% docs lp_settlement_credit_amount %}
Total dollar amount associated with credit (refund) settlements in this aggregation.
Numbers in this column are negative because they represent amounts credited (refunded) by the participant (agency) to the customer (rider);
i.e., these values represent costs for the participant (agency).
{% enddocs %}

{% docs lp_aggregation_is_settled %}
Boolean indicating whether all settlements in this aggregation have `settlement_status = SETTLED`.
`settlement_status` is only available for all agencies starting on November 28, 2023 so
this field does not account for activity before that date and aggregations that only contain activity before that date have nulls in this field. If `false`, there was a settlement present that has a `settlement_status` other than `SETTLED` (i.e., `PENDING`, `REJECTED`, or `FAILED`.)

When this column appears in models where not all aggregations have settlements at all, this field is also null for aggregations
that don't have any settlements. So, this field can be null if there are no settlements or if all settlement activity occurred before November 28, 2023.
{% enddocs %}

{% docs lp_debit_is_settled %}
Same as `aggregation_is_settled` but only includes the aggregation's debit (fare payment) settlements.
{% enddocs %}

{% docs lp_credit_is_settled %}
Same as `aggregation_is_settled` but only includes the aggregation's credit (refund) settlements.
If there is no credit activity for the aggregation, this field is null.
(So, a null in this field can mean either that there was no credit activity at all or that all credit
activity was prior to November 28, 2023.)
{% enddocs %}

-------------------------------- SETTLEMENTS TABLE --------------------------------

{% docs lp_settlement_id %}
A unique identifier for each settlement.
{% enddocs %}

{% docs lp_customer_id %}
Identifies the customer that the micropayment belongs to.
{% enddocs %}

{% docs lp_funding_source_id %}
Identifies the funding source (for example, card) that the micropayment will be charged to. This is always the card that was tapped.

A registered customer can have multiple funding sources linked to it. This field can be used to join to the `customer_funding_source` feed.
{% enddocs %}

{% docs lp_settlement_type %}
Type of settlement that occurred. Possible values are `DEBIT` or `CREDIT`.

If refunding a micropayment that has already been settled, the value will be `CREDIT`.
{% enddocs %}

{% docs lp_transaction_amount %}
The settlement amount.
{% enddocs %}

{% docs lp_retrieval_reference_number %}
Uniquely identifies a card transaction, based on the ISO 8583 standard.

If the acquirer is Elavon, this value will be split between `littlepay_reference_number` and `external_reference_number`.
{% enddocs %}

{% docs lp_littlepay_reference_number %}
Uniquely identifies a card transaction.

If the acquirer is Elavon, then this key will contain the first part of the string from `retrieval_reference_number`.
{% enddocs %}

{% docs lp_external_reference_number %}
Uniquely identifies a card transaction.

If the acquirer is Elavon, then this key will contain the second part of the string from `retrieval_reference_number`.
{% enddocs %}

{% docs lp_record_updated_timestamp_utc %}
Settlement last updated timestamp.
Formerly known as settlement_requested_date_time_utc.
{% enddocs %}

{% docs lp_acquirer %}
Identifies the acquirer used to settle the transaction.
{% enddocs %}

{% docs lp_acquirer_response_rrn %}
When returned by supported acquirers, uniquely identifies a card transaction as supplied by the acquirer in the settlement response, based on the ISO 8583 standard.

This field is supported for when the acquirer is Nets DK. When not supported or in use, this field will be empty.
{% enddocs %}

{% docs lp_settlement_status %}
The status of the settlement. Options are:
* `PENDING` - for settlements that have had a request but no response
* `REJECTED`
* `SETTLED`
* `FAILED` - an error occurred during processing
{% enddocs %}

{% docs lp_request_created_timestamp_utc %}
Time settlement request was created.
{% enddocs %}

{% docs lp_response_created_timestamp_utc %}
Time settlement response was created.
{% enddocs %}

{% docs lp_refund_id %}
Populated if the settlement is a refund; can be used when linking to the refunds table.
-------------------------------- MICROPAYMENTS TABLE --------------------------------

{% docs lp_transaction_time %}
The date and time when the micropayment was created.

For variable fare (tap on/tap off), the micropayment will not be created until the tap off occurs.

The date reflects the processing time by Littlepay, rather than the event time; that is, when the related taps occurred.
{% enddocs %}

{% docs lp_payment_liability %}
Indicates who would be liable to absorb the cost if the micropayment was declined by the issuer when an authorisation is attempted.

Possible values are `ISSUER` or `OPERATOR`.
{% enddocs %}

{% docs lp_charge_amount %}
Indicates who would be liable to absorb the cost if the micropayment was declined by the issuer when an authorisation is attempted.

Possible values are `ISSUER` or `OPERATOR`.
{% enddocs %}
