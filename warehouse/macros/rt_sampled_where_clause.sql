{# https://github.com/dbt-labs/dbt-core/discussions/6236#discussioncomment-4177272 #}
{% macro get_where_subquery(relation) -%}
    {% set where = config.get('where', '') %}
    {% if where == "__rt_sampled__" %}
        {% set today = modules.datetime.date.today() %}
        {% set yesterday = today - modules.datetime.timedelta(days=1) %}
        {% set zero_utc = modules.datetime.time(hour=0) %}
        {% set two_utc = modules.datetime.time(hour=2) %}
        {% set columns = adapter.get_columns_in_relation(relation) %}

        {# If we still have the hour, it means we are probably on top of raw data via views and should eliminate more #}
        {% if 'hour' in (columns | map(attribute='name')) %}
            {% set where %}
            dt in (
                '{{ today }}',
                '{{ yesterday }}'
                )
            {# test hour = 0 UTC because 5pm Pacific = PM peak, good sample of data
                and other test hour = 2 UTC because that is when the GTFS download config changeover occurs;
                want to confirm that there are no enduring bugs from config change #}
            AND hour in (
                '{{ modules.datetime.datetime.combine(today, zero_utc) }}',
                '{{ modules.datetime.datetime.combine(yesterday, two_utc) }}'
            )
            {% endset %}
        {% else %}
            {% set where %}
            dt in (
                '{{ today }}',
                '{{ yesterday }}'
                )
            {% endset %}
        {% endif %}
    {% endif %}
    {% if where %}
        {%- set filtered -%}
            (select * from {{ relation }} where {{ where }}) dbt_subquery
        {%- endset -%}
        {% do return(filtered) %}
    {%- else -%}
        {% do return(relation) %}
    {%- endif -%}
{%- endmacro %}
