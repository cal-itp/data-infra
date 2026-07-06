-- was seed to map mode abbreviation to full name
-- expand this to macro to map more abbreviations to other column groupings we need
-- https://github.com/cal-itp/data-infra/commit/0c5c1348c36037306ec04f2584cbde3925f70bdc
{% macro generate_ntd_mode_full_name(mode_abbrev_column) %}
    CASE
        WHEN {{ mode_abbrev_column }} = "AG" THEN "Automated Guideway"
        WHEN {{ mode_abbrev_column }} = "AR" THEN "Alaska Railroad"
        WHEN {{ mode_abbrev_column }} = "CB" THEN "Commuter Bus"
        WHEN {{ mode_abbrev_column }} = "CC" THEN "Cable Car"
        WHEN {{ mode_abbrev_column }} = "CR" THEN "Commuter Rail"
        WHEN {{ mode_abbrev_column }} = "DR" THEN "Demand Response"
        WHEN {{ mode_abbrev_column }} = "DT" THEN "Demand Response Taxi"
        WHEN {{ mode_abbrev_column }} = "FB" THEN "Ferryboat"
        WHEN {{ mode_abbrev_column }} = "HR" THEN "Heavy Rail"
        WHEN {{ mode_abbrev_column }} = "IP" THEN "Inclined Plane"
        WHEN {{ mode_abbrev_column }} = "JT" THEN "Jitney"
        WHEN {{ mode_abbrev_column }} = "LR" THEN "Light Rail"
        WHEN {{ mode_abbrev_column }} = "MB" THEN "Bus" -- motor bus
        WHEN {{ mode_abbrev_column }} = "MG" THEN "Monorail / Automated Guideway" -- monorail/motorguideway
        WHEN {{ mode_abbrev_column }} = "MO" THEN "Monorail"
        WHEN {{ mode_abbrev_column }} = "PB" THEN "Publico"
        WHEN {{ mode_abbrev_column }} = "RB" THEN "Bus Rapid Transit"
        WHEN {{ mode_abbrev_column }} = "SR" THEN "Streetcar"
        WHEN {{ mode_abbrev_column }} = "TB" THEN "Trolleybus"
        WHEN {{ mode_abbrev_column }} = "TR" THEN "Aerial Tramway"
        WHEN {{ mode_abbrev_column }} = "VP" THEN "Vanpool"
        WHEN {{ mode_abbrev_column }} = "YR" THEN "Hybrid Rail"
        ELSE "unknown"
    END

{% endmacro %}

{% macro generate_ntd_type_of_service_full_name(type_of_service_column) %}
    CASE
        WHEN {{ type_of_service_column }} = "DO" THEN "Directly Operated"
        WHEN {{ type_of_service_column }} = "PT" THEN "Purchased Transportation"
        WHEN {{ type_of_service_column }} = "TN" THEN "Purchased Transportation - Transportation Network Company"
        WHEN {{ type_of_service_column }} = "TX" THEN "Purchased Transportation - Taxi"
    END

{% endmacro %}


{% macro generate_ntd_mode_service_type(mode_abbrev_column) %}
    CASE
        WHEN {{ mode_abbrev_column }} IN ('AG', 'AR', 'CB', 'CC', 'CR', 'FB', 'HR', 'IP', 'IP', 'LR', 'MB', 'MG', 'MO', 'RB', 'SR', 'TB', 'TR', 'YR')
            THEN "Fixed Route"
        WHEN {{ mode_abbrev_column }} IN ('DR', 'DT', 'VP', 'JT', 'PB') THEN 'Demand Response'
        ELSE "Unknown" -- mode is null sometimes
    END
{% endmacro %}
