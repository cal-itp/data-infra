{% macro farm_surrogate_key(columns) %}
FARM_FINGERPRINT(CONCAT(
{% for column in columns %}
CAST({{ column }} AS STRING)
{% if not loop.last %}
, "___",
{% endif %}
{% endfor %}
))
{% endmacro %}
