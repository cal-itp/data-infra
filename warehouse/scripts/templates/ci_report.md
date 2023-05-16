Warehouse report 📦

### New models 🌱

{% for model in new_models %}
{{ model }}
{% endfor %}

### Changed incremental models 🔀

{% for model in changed_incremental_models %}
{{ model }}
{% endfor %}

### DAG

![](./dag.png "Changed models")

### Checks/potential follow-ups
{% if changed_incremental_models %}
* Full refresh as a follow-up action item
{% endif %}
