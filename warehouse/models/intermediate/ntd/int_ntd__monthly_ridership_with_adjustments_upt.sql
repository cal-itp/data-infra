WITH source_pivoted AS(
    {{ dbt_utils.unpivot(
        cast_to = 'int',
        relation = ref('stg_ntd__monthly_ridership_with_adjustments_upt'),
        exclude = ["uza_name","uace_cd","dt","ts","year","ntd_id","reporter_type","agency","status","mode","_3_mode","tos","legacy_ntd_id"],
        field_name = 'period',
        value_name = 'value'
    ) }}
),
int_ntd__monthly_ridership_with_adjustments_upt AS (
    SELECT uza_name,
        uace_cd,
        dt,
        ts,
        year,
        ntd_id,
        reporter_type,
        agency,
        STATUS,
        MODE,
        _3_mode,
        tos,
        legacy_ntd_id,
        SPLIT(period, '_') [OFFSET(1)] AS period_month,
        SPLIT(period, '_') [OFFSET(2)] AS period_year,
        value
    FROM source_pivoted
)
SELECT *
FROM int_ntd__monthly_ridership_with_adjustments_upt
