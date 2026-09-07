Documentation related to Enghouse payments data schema.

These doc blocks are shared across the Enghouse transaction / settlement models in the staging,
intermediate, and mart layers so column descriptions stay consistent wherever a column is surfaced.

-------------------------------- TRANSACTION / SETTLEMENT FIELDS --------------------------------

{% docs enghouse_operator_id %}
Enghouse's internal identifier for the agency (referred to as "operator" by Enghouse).
{% enddocs %}

{% docs enghouse_id %}
Unique identifier for this transaction in the Enghouse system.
{% enddocs %}

{% docs enghouse_operation %}
Type of transaction.
{% enddocs %}

{% docs enghouse_terminal_id %}
Terminal identifier associated with the tap that triggered this transaction.
{% enddocs %}

{% docs enghouse_mapping_terminal_id %}
Not relevant for US projects.
{% enddocs %}

{% docs enghouse_mapping_merchant_id %}
Not relevant for US projects.
{% enddocs %}

{% docs enghouse_timestamp %}
Timestamp when the transaction occurred.
{% enddocs %}

{% docs enghouse_amount %}
Transaction amount in USD dollars (converted from cents at source).
{% enddocs %}

{% docs enghouse_settlement_amount %}
Transaction amount in USD dollars (converted from cents at source), negated for refunds
(settlement_type = 'CREDIT') so that SUM(amount) is the net amount requested for settlement by Enghouse.
{% enddocs %}

{% docs enghouse_payment_reference %}
Payment reference number (PRN / variable symbol) linking this transaction to its tap.
{% enddocs %}

{% docs enghouse_spdh_response %}
SPDH protocol response code. Not relevant for transactions.
{% enddocs %}

{% docs enghouse_response_type %}
Type of response received from the acquirer.
{% enddocs %}

{% docs enghouse_response_message %}
Response message received from the acquirer.
{% enddocs %}

{% docs enghouse_token %}
Tokenized card number.
{% enddocs %}

{% docs enghouse_issuer_response %}
Response code from the card issuer (bank), if provided. Enghouse sends transactions to the acquirer (Cybersource / Elavon) who forwards to the issuer.
{% enddocs %}

{% docs enghouse_core_response %}
Enghouse internal response code. Not meaningful for downstream analysis.
{% enddocs %}

{% docs enghouse_rrn %}
Retrieval Reference Number (RRN).
{% enddocs %}

{% docs enghouse_authorization_code %}
Authorization code received from the acquirer.
{% enddocs %}

{% docs enghouse_par %}
Payment Account Reference (PAR).
{% enddocs %}

{% docs enghouse_brand %}
Card scheme (e.g., VISA, MC, AMEX, DISCOVER).
{% enddocs %}

{% docs enghouse_agency %}
Agency identifier parsed from the GCS path partition (e.g., "ventura", "raba", "camarillo").
{% enddocs %}

{% docs enghouse_dt %}
Date partition parsed from the GCS path, corresponding to the date in the source filename.
{% enddocs %}

{% docs enghouse_payments_key %}
Surrogate key derived from id and operator_id. Uniquely identifies one transaction.
{% enddocs %}

{% docs enghouse_line_number %}
Line number of this record within its source delivery file. Retained for lineage and data quality inspection.
{% enddocs %}

{% docs enghouse_content_hash %}
Hash of all data columns. Retained for data quality inspection; deduplication uses _payments_key.
{% enddocs %}

{% docs enghouse_settlement_type %}
Type of settlement that occurred. `CREDIT` for refunds (operation = `REFUND`); `DEBIT` for all other operations.
{% enddocs %}

--------------------------------  AGGREGATION FIELDS --------------------------------

These describe columns used for fct_payments_aggregations_enghouse

{% docs eh_latest_settlement_update_timestamp %}
The timestamp of the latest settlement in the aggregation
{% enddocs %}

{% docs eh_num_settlements %}
The number of settlements in the aggregation. 
Note that there can also be multiple transaction entries per settlements, when this occurs, this will be the number of settlement IDs.
{% enddocs %}

{% docs eh_net_settlement_amount_dollars %}
The net amount of settlements in the aggregation (debit - credit)
{% enddocs %}

{% docs eh_contains_refund %}
`TRUE` if the aggregation contains a refund, `FALSE` otherwise
{% enddocs %}

{% docs eh_num_debit_settlements %}
The number of debit (sale) settlements in the aggregation
{% enddocs %}

{% docs eh_num_credit_settlements %}
The number of credit (refund) settlements in the aggregation
{% enddocs %}

{% docs eh_debit_amount %}
The total debit (sale) amount in the aggregation (in USD)
{% enddocs %}

{% docs eh_credit_amount %}
The total credit (refund) amount in the aggregation (in USD)
{% enddocs %}

{% docs eh_has_settlement %}
If "true", there is at least one settlement in `int_payments__settlements_to_aggregations_enghouse`
for this pay window's `operator_id` + `payment_reference`.
{% enddocs %}

{% docs eh_latest_settlement_update_datetime_pacific %}
`latest_settlement_update_datetime` in Pacific Time.
{% enddocs %}

{% docs eh_contains_nonzero_sales %}
Boolean flag for whether this pay window contains a debit (sales) amount greater than 0.
{% enddocs %}

{% docs eh_pay_window_id %}
Unique identifier for the pay window (Enghouse `id` from the pay_windows table).
{% enddocs %}

{% docs eh_aggregation_datetime %}
Datetime of pay window close if present, otherwise falls back to the latest settlement,
otherwise to the pay window open, otherwise to the latest terminal-recorded tap time.
{% enddocs %}

{% docs eh_end_of_month_date_pacific %}
The last day of the month of the `aggregation_datetime` in Pacific Time.
{% enddocs %}

{% docs eh_end_of_month_date_utc %}
The last day of the month of the `aggregation_datetime` in UTC.
{% enddocs %}

{% docs eh_stage %}
Current stage of the pay window lifecycle. Known values: Open, Closed, Debt, DebtFinal, NoAuthDone.
{% enddocs %}

{% docs eh_pay_window_terminal_id %}
Terminal ID where the pay window was initiated.
{% enddocs %}

{% docs eh_open_date %}
Timestamp when the pay window was opened (first tap).
{% enddocs %}

{% docs eh_close_date %}
Timestamp when the pay window was closed and settled.
{% enddocs %}

{% docs eh_amount_to_settle %}
Total fare amount that should be charged for this pay window.
{% enddocs %}

{% docs eh_amount_settled %}
Amount actually settled for this pay window.
{% enddocs %}

{% docs eh_debt_settled %}
Amount recovered through debt recovery for this pay window.
{% enddocs %}

{% docs eh_num_taps %}
Number of distinct taps associated with this pay window's `payment_reference`.
{% enddocs %}

{% docs eh_num_ticket_results %}
Number of ticket results associated with the taps in this pay window.
{% enddocs %}

{% docs eh_total_fare_amount %}
Sum of fare amounts across all ticket results for this pay window.
{% enddocs %}

{% docs eh_elavon_purch_id %}
Elavon purchase ID matched to this pay window via `payment_reference`. NULL if no Elavon match found.
{% enddocs %}

{% docs eh_elavon_settlement_date %}
Settlement date from Elavon deposit data for this pay window.
{% enddocs %}

{% docs eh_elavon_payment_date %}
Payment date from Elavon deposit data for this pay window.
{% enddocs %}

{% docs eh_elavon_net_amount %}
Net amount from Elavon deposit data (sum of all Elavon transactions for this `purch_id`).
{% enddocs %}

{% docs eh_elavon_sales %}
Total sales amount from Elavon deposit data for this pay window.
{% enddocs %}

{% docs eh_elavon_refunds %}
Total refund amount from Elavon deposit data for this pay window.
{% enddocs %}

{% docs eh_reconciliation_category %}
The state of the aggregation

Possible Values:
- `Zero-dollar value sales`: the pay window settled to 0 value, so no charge is expected
- `Settled non-zero sales (with Elavon match)`: stage is `Closed` and the pay window matched an Elavon deposit record
- `Settled non-zero sales (no Elavon match)`: stage is `Closed` but no corresponding Elavon deposit record was found
- `Unsettled non-zero sales`: stage is `Debt`, `DebtFinal`, `Open` or `NoAuthDone` — the pay window is not settled - stage has more context
- `Declined sales`: stage is `AuthDeclined` — the authorization attempt was declined
- `UNKNOWN`: none of these conditions are met
{% enddocs %}
