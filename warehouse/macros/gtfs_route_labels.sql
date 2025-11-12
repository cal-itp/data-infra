{% macro parse_route_id(operator_name_column, route_id_column) %}
    CASE
        -- operators using hyphens
        WHEN (
            CONTAINS_SUBSTR({{ operator_name_column  }}, "Monterey Salinas") OR
            CONTAINS_SUBSTR({{ operator_name_column  }}, "LA Metro") OR
            CONTAINS_SUBSTR({{ operator_name_column  }}, "BART") OR
             CONTAINS_SUBSTR({{ operator_name_column  }}, "MVGO")
        ) THEN TRIM(SPLIT({{ route_id_column }}, "-")[SAFE_OFFSET(0)])
        -- operators using underscores
        WHEN CONTAINS_SUBSTR({{ operator_name_column  }}, "Roseville") THEN TRIM(SPLIT({{ route_id_column }}, "_")[SAFE_OFFSET(0)])
        ELSE TRIM( {{ route_id_column }} )

    END

{% endmacro %}

{% macro get_combined_route_name(operator_name_column, route_short_name_column, route_long_name_column) %}
-- base off of latest commit
-- https://github.com/cal-itp/data-analyses/blob/59dff810bc963de265709e803a166bc83d5aa3d7/rt_segment_speeds/segment_speed_utils/time_series_utils.py#L42-L105
    CASE
        -- operators where route_short_name adds duplicate info, just use route_long_name
        --Ex: route_short_name = 2; route_long_name = Route 2; combined name would be 2 Route 2
        WHEN (
            CONTAINS_SUBSTR({{ operator_name_column  }}, "Antelope Valley Transit Authority") OR
            CONTAINS_SUBSTR({{ operator_name_column  }}, "Bay Area 511 ACE") OR
            CONTAINS_SUBSTR({{ operator_name_column  }}, "Bay Area 511 Emery Go-Round") OR
            CONTAINS_SUBSTR({{ operator_name_column  }}, "Bay Area 511 Petaluma") OR
            CONTAINS_SUBSTR({{ operator_name_column  }}, "Beach Cities GMV") OR
            CONTAINS_SUBSTR({{ operator_name_column  }}, "Bear") OR
            CONTAINS_SUBSTR({{ operator_name_column  }}, "Commerce") OR
            CONTAINS_SUBSTR({{ operator_name_column  }}, "Humboldt") OR
            CONTAINS_SUBSTR({{ operator_name_column  }}, "LA DOT") OR
            CONTAINS_SUBSTR({{ operator_name_column  }}, "Lawndale Beat GMV") OR
            CONTAINS_SUBSTR({{ operator_name_column  }}, "Redding") OR
            CONTAINS_SUBSTR({{ operator_name_column  }}, "Redwood Coast") OR
            CONTAINS_SUBSTR({{ operator_name_column  }}, "Santa Maria") OR
            CONTAINS_SUBSTR({{ operator_name_column  }}, "StanRTA") OR
            CONTAINS_SUBSTR({{ operator_name_column  }}, "Victor Valley GMV") OR
            CONTAINS_SUBSTR({{ operator_name_column  }}, "Visalia") OR
            CONTAINS_SUBSTR({{ operator_name_column  }}, "Yolobus")
        ) THEN {{ route_long_name_column }}
        ELSE CONCAT( {{ route_short_name_column }}, " ", {{ route_long_name_column }} )

    END

{% endmacro %}
