WITH debited_micropayments AS (

    SELECT *
    FROM {{ ref('stg_cleaned_micropayments') }}
    WHERE type = 'DEBIT'

)

SELECT * FROM debited_micropayments
