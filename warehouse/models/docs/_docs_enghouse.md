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

{% docs enghouse_content_hash %}
Hash of all data columns. Retained for data quality inspection; deduplication uses _payments_key.
{% enddocs %}

{% docs enghouse_settlement_type %}
Type of settlement that occurred. `CREDIT` for refunds (operation = `REFUND`); `DEBIT` for all other operations.
{% enddocs %}
