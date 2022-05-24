Original definitions from https://gtfs.org/reference/static#attributionstxt

{% docs gtfs_attributions__attribution_id %}
Identifies an attribution for the dataset or a subset of it. This is mostly useful for translations.
{% enddocs %}

{% docs gtfs_attributions__agency_id %}
Agency to which the attribution applies.

If one agency_id, route_id, or trip_id attribution is defined, the other ones must be empty. If none of them is specified, the attribution will apply to the whole dataset.
{% enddocs %}

{% docs gtfs_attributions__route_id %}
Functions in the same way as agency_id except the attribution applies to a route. Multiple attributions can apply to the same route.
{% enddocs %}

{% docs gtfs_attributions__trip_id %}
Functions in the same way as agency_id except the attribution applies to a trip. Multiple attributions can apply to the same trip.
{% enddocs %}

{% docs gtfs_attributions__organization_name %}
Name of the organization that the dataset is attributed to.
{% enddocs %}

{% docs gtfs_attributions__is_producer %}
The role of the organization is producer. Valid options are:

0 or empty - Organization doesn’t have this role.
1 - Organization does have this role.

At least one of the fields is_producer, is_operator, or is_authority should be set at 1.
{% enddocs %}

{% docs gtfs_attributions__is_operator %}
Functions in the same way as is_producer except the role of the organization is operator.
{% enddocs %}

{% docs gtfs_attributions__is_authority %}
Functions in the same way as is_producer except the role of the organization is authority.
{% enddocs %}

{% docs gtfs_attributions__attribution_url %}
URL of the organization.
{% enddocs %}

{% docs gtfs_attributions__attribution_email %}
Email of the organization.
{% enddocs %}

{% docs gtfs_attributions__attribution_phone %}
Phone number of the organization.
{% enddocs %}
