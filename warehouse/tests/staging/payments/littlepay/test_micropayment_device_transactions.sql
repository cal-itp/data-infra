{{ config(store_failures = true) }}

-- dst_table_name: "payments.invalid_cleaned_micropayment_device_transactions"
-- A device transaction should only ever be associated with a single debit
-- micropayment. This table contains micropayment information where that
-- invariant does not hold true.

-- tests:
-- check_empty:
--  - "*"

with int_payments__cleaned_micropayment_device_transactions as (

    select * from {{ ref('int_payments__cleaned_micropayment_device_transactions') }}

),

stg_littlepay__micropayments as (

    select * from {{ ref('stg_littlepay__micropayments') }}

),

multiple_debit_transaction_ids as (

    select littlepay_transaction_id
    from int_payments__cleaned_micropayment_device_transactions
    inner join stg_littlepay__micropayments as m using (micropayment_id)
    where m.type = 'DEBIT'
    group by 1
    having count(*) > 1

),

validate_cleaned_micropayment_device_transactions as (

    select
        littlepay_transaction_id,
        m.*
    from int_payments__cleaned_micropayment_device_transactions
    inner join stg_littlepay__micropayments as m using (micropayment_id)
    inner join multiple_debit_transaction_ids using (littlepay_transaction_id)
    -- commented out the line below because I could not get rid of sqlfluff error L054
    -- order by transaction_time desc, littlepay_transaction_id asc, charge_type desc

)

select * from validate_cleaned_micropayment_device_transactions
