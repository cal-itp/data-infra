{% macro create_row_access_policy(filter_column,filter_value, principals) %}
create or replace row access policy
    {{ this.schema }}_{{ this.identifier }}_{{ filter_column }}_{% if filter_value %}{{ dbt_utils.slugify(filter_value) }}{% endif %}
on
    {{ this }}
grant to (
  {% for principal in principals %}
  '{{ principal }}'
  {% if not loop.last %} , {% endif %}
  {% endfor %}
)
filter using (
  {% if not filter_column and not filter_value %}
  1 = 1
  {% else %}
  {{ filter_column }} = '{{ filter_value }}'
  {% endif %}
)
{% endmacro %}

{% macro payments_littlepay_row_access_policy() %}

{{ create_row_access_policy(
    filter_column = 'participant_id',
    filter_value = 'mst',
    principals = ['serviceAccount:mst-payments-user@cal-itp-data-infra.iam.gserviceaccount.com']
) }};

{{ create_row_access_policy(
    filter_column = 'participant_id',
    filter_value = 'sacrt',
    principals = ['serviceAccount:sacrt-payments-user@cal-itp-data-infra.iam.gserviceaccount.com']
) }};

{{ create_row_access_policy(
    filter_column = 'participant_id',
    filter_value = 'sbmtd',
    principals = ['serviceAccount:sbmtd-payments-user@cal-itp-data-infra.iam.gserviceaccount.com']
) }};

{{ create_row_access_policy(
    filter_column = 'participant_id',
    filter_value = 'clean-air-express',
    principals = ['serviceAccount:clean-air-payments-user@cal-itp-data-infra.iam.gserviceaccount.com']
) }}   ;

{{ create_row_access_policy(
    filter_column = 'participant_id',
    filter_value = 'ccjpa',
    principals = ['serviceAccount:ccjpa-payments-user@cal-itp-data-infra.iam.gserviceaccount.com']
) }};

{{ create_row_access_policy(
    filter_column = 'participant_id',
    filter_value = 'humboldt-transit-authority',
    principals = ['serviceAccount:humboldt-transit-authority@cal-itp-data-infra.iam.gserviceaccount.com']
) }};

{{ create_row_access_policy(
    filter_column = 'participant_id',
    filter_value = 'lake-transit-authority',
    principals = ['serviceAccount:lake-transit-authority@cal-itp-data-infra.iam.gserviceaccount.com']
) }};

{{ create_row_access_policy(
    filter_column = 'participant_id',
    filter_value = 'mendocino-transit-authority',
    principals = ['serviceAccount:mendocino-transit-authority@cal-itp-data-infra.iam.gserviceaccount.com']
) }};

{{ create_row_access_policy(
    filter_column = 'participant_id',
    filter_value = 'redwood-coast-transit',
    principals = ['serviceAccount:redwood-coast-transit@cal-itp-data-infra.iam.gserviceaccount.com']
) }};

{{ create_row_access_policy(
    filter_column = 'participant_id',
    filter_value = 'atn',
    principals = ['serviceAccount:atn-payments-user@cal-itp-data-infra.iam.gserviceaccount.com']
) }};

{{ create_row_access_policy(
    filter_column = 'participant_id',
    filter_value = 'nevada-county-connects',
    principals = ['serviceAccount:nevada-county-payments-user@cal-itp-data-infra.iam.gserviceaccount.com']
) }};

{{ create_row_access_policy(
    principals = ['serviceAccount:metabase@cal-itp-data-infra.iam.gserviceaccount.com',
                  'serviceAccount:metabase-payments-team@cal-itp-data-infra.iam.gserviceaccount.com',
                  'serviceAccount:bq-transform-svcacct@cal-itp-data-infra.iam.gserviceaccount.com',
                  'serviceAccount:github-actions-services-accoun@cal-itp-data-infra.iam.gserviceaccount.com',
                  'group:cal-itp@jarv.us',
                  'group:mov-project-team@jarv.us',
                  'domain:calitp.org',
                 ]
) }};
-- TODO: In the last policy of the macro call above, see if we can get the prod warehouse service account out of context
{% endmacro %}

{% macro payments_elavon_row_access_policy() %}

{{ create_row_access_policy(
    filter_column = 'organization_name',
    filter_value = 'Monterey-Salinas Transit',
    principals = ['serviceAccount:mst-payments-user@cal-itp-data-infra.iam.gserviceaccount.com']
) }};

{{ create_row_access_policy(
    filter_column = 'organization_name',
    filter_value = 'Sacramento Regional Transit District',
    principals = ['serviceAccount:sacrt-payments-user@cal-itp-data-infra.iam.gserviceaccount.com']
) }};

{{ create_row_access_policy(
    filter_column = 'organization_name',
    filter_value = 'Santa Barbara Metropolitan Transit District',
    principals = ['serviceAccount:sbmtd-payments-user@cal-itp-data-infra.iam.gserviceaccount.com']
) }};

{{ create_row_access_policy(
    filter_column = 'organization_name',
    filter_value = 'Santa Barbara County Association of Governments',
    principals = ['serviceAccount:clean-air-payments-user@cal-itp-data-infra.iam.gserviceaccount.com']
) }}   ;

{{ create_row_access_policy(
    filter_column = 'organization_name',
    filter_value = 'Capitol Corridor Joint Powers Authority',
    principals = ['serviceAccount:ccjpa-payments-user@cal-itp-data-infra.iam.gserviceaccount.com']
) }};

{{ create_row_access_policy(
    filter_column = 'organization_name',
    filter_value = 'Humboldt Transit Authority',
    principals = ['serviceAccount:humboldt-transit-authority@cal-itp-data-infra.iam.gserviceaccount.com']
) }};

{{ create_row_access_policy(
    filter_column = 'organization_name',
    filter_value = 'Lake Transit Authority',
    principals = ['serviceAccount:lake-transit-authority@cal-itp-data-infra.iam.gserviceaccount.com']
) }};

{{ create_row_access_policy(
    filter_column = 'organization_name',
    filter_value = 'Mendocino Transit Authority',
    principals = ['serviceAccount:mendocino-transit-authority@cal-itp-data-infra.iam.gserviceaccount.com']
) }};

{{ create_row_access_policy(
    filter_column = 'organization_name',
    filter_value = 'Redwood Coast Transit Authority',
    principals = ['serviceAccount:redwood-coast-transit@cal-itp-data-infra.iam.gserviceaccount.com']
) }};

{{ create_row_access_policy(
    filter_column = 'organization_name',
    filter_value = 'Anaheim Transportation Network',
    principals = ['serviceAccount:atn-payments-user@cal-itp-data-infra.iam.gserviceaccount.com']
) }};

{{ create_row_access_policy(
    principals = ['serviceAccount:metabase@cal-itp-data-infra.iam.gserviceaccount.com',
                  'serviceAccount:metabase-payments-team@cal-itp-data-infra.iam.gserviceaccount.com',
                  'serviceAccount:bq-transform-svcacct@cal-itp-data-infra.iam.gserviceaccount.com',
                  'serviceAccount:github-actions-services-accoun@cal-itp-data-infra.iam.gserviceaccount.com',
                  'group:cal-itp@jarv.us',
                  'group:mov-project-team@jarv.us',
                  'domain:calitp.org',
                 ]
) }};
-- TODO: In the last policy of the macro call above, see if we can get the prod warehouse service account out of context
{% endmacro %}
