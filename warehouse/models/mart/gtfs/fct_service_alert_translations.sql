WITH messages AS (
    SELECT *
    FROM {{ ref('fct_service_alerts_messages') }}
),

fct_service_alert_translations AS (
    SELECT
        messages.* EXCEPT(
            key,
            header_text,
            description_text,
            tts_header_text,
            tts_description_text,
            url
        ),
        key AS service_alert_message_key,

        {{ dbt_utils.surrogate_key(['key',
            'unnested_header_text_translation.text',
            'unnested_header_text_translation.language']) }} AS key,

        unnested_header_text_translation.text AS header_text_text,
        unnested_header_text_translation.language AS header_text_language,

        unnested_description_text_translation.text AS description_text_text,
        unnested_description_text_translation.language AS description_text_language,

        unnested_tts_header_text_translation.text AS tts_header_text_text,
        unnested_tts_header_text_translation.language AS tts_header_text_language,

        unnested_tts_description_text_translation.text AS tts_description_text_text,
        unnested_tts_description_text_translation.language AS tts_description_text_language,

        unnested_url_translation.text AS url_text,
        unnested_url_translation.language AS url_language,

        CASE
            WHEN unnested_header_text_translation.language LIKE "%en%" THEN 100
            WHEN unnested_header_text_translation.language IS NULL THEN 1
            ELSE 0
        END AS english_likelihood
    FROM messages
    -- https://stackoverflow.com/questions/44918108/google-bigquery-i-lost-null-row-when-using-unnest-function
    -- these arrays may have nulls
    LEFT JOIN UNNEST(messages.header_text.translation) AS unnested_header_text_translation
    LEFT JOIN UNNEST(messages.description_text.translation) AS unnested_description_text_translation
    LEFT JOIN UNNEST(messages.tts_header_text.translation) AS unnested_tts_header_text_translation
    LEFT JOIN UNNEST(messages.tts_description_text.translation) AS unnested_tts_description_text_translation
    LEFT JOIN UNNEST(messages.url.translation) AS unnested_url_translation
    -- filter where languages match, otherwise we get cartesian product of language combinations
    WHERE COALESCE(unnested_description_text_translation.language, unnested_header_text_translation.language, 'language') = COALESCE(unnested_header_text_translation.language, 'language')
       AND COALESCE(unnested_tts_header_text_translation.language, unnested_header_text_translation.language, 'language') = COALESCE(unnested_header_text_translation.language, 'language')
       AND COALESCE(unnested_tts_description_text_translation.language, unnested_header_text_translation.language, 'language') = COALESCE(unnested_header_text_translation.language, 'language')
       AND COALESCE(unnested_url_translation.language, unnested_header_text_translation.language, 'language') = COALESCE(unnested_header_text_translation.language, 'language')
)

SELECT * FROM fct_service_alert_translations
