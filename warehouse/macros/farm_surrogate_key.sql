{% macro farm_surrogate_key(columns) %}
FARM_FINGERPRINT(CONCAT(
{% for column in columns %}
COALESCE(CAST({{ column }} AS STRING),"_")
{% if not loop.last %}
, "___",
{% endif %}
{% endfor %}
))
{% endmacro %}
