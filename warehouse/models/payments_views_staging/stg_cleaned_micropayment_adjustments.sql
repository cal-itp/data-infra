WITH stg_cleaned_micropayment_adjustments AS (

    SELECT DISTINCT * EXCEPT (
        calitp_file_name,
        calitp_n_dupes,
        calitp_n_dupe_ids,
        calitp_dupe_number)
    FROM {{ ref('stg_enriched_micropayment_adjustments') }}
    WHERE calitp_dupe_number = 1
)

SELECT * FROM stg_cleaned_micropayment_adjustments
