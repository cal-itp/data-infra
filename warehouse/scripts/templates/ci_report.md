Warehouse report 📦

{% if new_models %}
### New models 🌱

{% for model in new_models %}
{{ model }}
{% endfor %}
{% endif %}

{% if changed_incremental_models %}
### Changed incremental models 🔀

{% for model in changed_incremental_models %}
{{ model }}
{% endfor %}
{% endif %}

### DAG
Legend (in order of precedence)

| Resource type                                  | Indicator | Resolution                            |
|------------------------------------------------|-----------|---------------------------------------|
| Large table-materialized model                 | Red       | Make the model incremental            |
| Large model without partitioning or clustering | Orange    | Add partitioning and/or clustering    |
| View with more than one child                  | Yellow    | Materialize as a table or incremental |
| Incremental                                    | Blue      |                                       |
| Table                                          | Green     |                                       |
| View                                           | White     |                                       |

![](./dag.png "New and changed models")

### Checks/potential follow-ups
{% if new_models %}
* All new models have a surrogate primary key that is tested to be not-null and unique
{% endif %}
{% if changed_incremental_models %}
* Full refresh as a follow-up action item
{% endif %}
