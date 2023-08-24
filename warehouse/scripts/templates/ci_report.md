Warehouse report 📦

{% if new_models or modified_or_downstream_incremental_models %}

### Checks/potential follow-ups

Checks indicate the following action items may be necessary.
{% if new_models -%}

- [ ] For new models, do they all have a surrogate primary key that is tested to be not-null and unique?
  {%- endif %}
  {% if modified_or_downstream_incremental_models -%}
- [ ] For modified incremental models (or incremental models whose parents are modified), does the PR description identify whether a full refresh is needed for these tables?
  {%- endif %}
  {% endif %}

{% if new_models %}

### New models 🌱

{% for model in new_models %}
{{ model }}
{% endfor %}
{% endif %}

{% if modified_or_downstream_incremental_models %}

### Changed incremental models 🔀

{% for model in modified_or_downstream_incremental_models %}
{{ model }}
{% endfor %}
{% endif %}

### DAG

![](./dag.png "New and changed models")

Legend (in order of precedence)

| Resource type                                  | Indicator   | Resolution                            |
| ---------------------------------------------- | ----------- | ------------------------------------- |
| Large table-materialized model                 | Orange      | Make the model incremental            |
| Large model without partitioning or clustering | Orange      | Add partitioning and/or clustering    |
| View with more than one child                  | Yellow      | Materialize as a table or incremental |
| Incremental                                    | Light green |                                       |
| Table                                          | Green       |                                       |
| View                                           | White       |                                       |
