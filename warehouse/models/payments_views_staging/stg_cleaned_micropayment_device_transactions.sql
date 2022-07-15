with deduped_micropayment_device_transaction_ids as (

    select distinct
        littlepay_transaction_id,
        micropayment_id
    from {{ ref('stg_enriched_micropayment_device_transactions') }}
    where calitp_dupe_number = 1

),

-- Some transactions are associated with more than one DEBIT micropayment. This
-- should not happen. In the query below, we identify the micropayment_id of the
-- pending micropayment records that are no longer valid because they've been
-- superceded by a completed micropayment.
--
-- See https://github.com/cal-itp/data-infra/issues/647 for the explanation.
invalid_micropayment_device_transaction_ids as (

    select
        littlepay_transaction_id,
        m1.micropayment_id

    from deduped_micropayment_device_transaction_ids as mdt1
    inner join {{ ref('stg_cleaned_micropayments') }} as m1
        on mdt1.micropayment_id = m1.micropayment_id

    inner join deduped_micropayment_device_transaction_ids as mdt2 using (littlepay_transaction_id)
    inner join {{ ref('stg_cleaned_micropayments') }} as m2
        on mdt2.micropayment_id = m2.micropayment_id

    where m1.micropayment_id != m2.micropayment_id
        and m1.charge_type = 'pending_charge_fare'
        and m2.charge_type = 'complete_variable_fare'

),

cleaned_micropayment_device_transaction_ids as (

    select
        littlepay_transaction_id,
        micropayment_id
    from deduped_micropayment_device_transaction_ids
    left join invalid_micropayment_device_transaction_ids as invalid
        using (littlepay_transaction_id, micropayment_id)
    where invalid.littlepay_transaction_id is null

),

stg_cleaned_micropayment_device_transactions as (

    select distinct * except (
        calitp_file_name,
        calitp_n_dupes,
        calitp_n_dupe_ids,
        calitp_dupe_number)
    from {{ ref('stg_enriched_micropayment_device_transactions') }}
    inner join cleaned_micropayment_device_transaction_ids
        using (littlepay_transaction_id, micropayment_id)
    where calitp_dupe_number = 1
)

select * from stg_cleaned_micropayment_device_transactions
