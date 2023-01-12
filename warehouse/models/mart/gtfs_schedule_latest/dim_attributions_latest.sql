WITH
dim_attributions_latest AS (
    {{ get_latest_schedule_data(
    table_name = ref('dim_attributions')
 ) }}
)

SELECT * FROM dim_attributions_latest
