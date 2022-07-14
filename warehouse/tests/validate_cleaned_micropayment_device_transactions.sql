with stg_cleaned_micropayment_device_transactions as (

    select * from {{ ref('stg_cleaned_micropayment_device_transactions') }}

),

stg_cleaned_micropayments as (

    select * from {{ ref('stg_cleaned_micropayments') }}

),

multiple_debit_transaction_ids as (

    select littlepay_transaction_id
    from stg_cleaned_micropayment_device_transactions
    inner join stg_cleaned_micropayments as m using (micropayment_id)
    where m.type = 'DEBIT'
    group by 1
    having count(*) > 1

),

validate_cleaned_micropayment_device_transactions as (

    select
        littlepay_transaction_id,
        m.*
    from stg_cleaned_micropayment_device_transactions
    inner join stg_cleaned_micropayments as m using (micropayment_id)
    inner join multiple_debit_transaction_ids using (littlepay_transaction_id)
 --   order by transaction_time desc, littlepay_transaction_id asc, charge_type desc

),

select * from validate_cleaned_micropayment_device_transactions
