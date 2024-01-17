WITH unioned AS (
    {{ dbt_utils.union_relations(
        relations=[
            ref('gtfs_schedule_validator_rule_details_v2_0_0'),
            ref('gtfs_schedule_validator_rule_details_v3_1_1'),
            ref('gtfs_schedule_validator_rule_details_v4_0_0'),
            ref('gtfs_schedule_validator_rule_details_v4_1_0'),
            ref('gtfs_schedule_validator_rule_details_v4_2_0'),
        ],
    ) }}
),

int_gtfs_quality__schedule_validator_rule_details_unioned AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['code', 'version']) }} AS key,
        * EXCEPT(_dbt_source_relation)
    FROM unioned
)

SELECT * FROM int_gtfs_quality__schedule_validator_rule_details_unioned
