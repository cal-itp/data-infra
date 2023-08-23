Original definitions from https://gtfs.org/schedule/reference/#stop_areastxt

{% docs gtfs_stop_areas\_\_area_id %}
Identifies an area to which one or multiple stop_ids belong. The same stop_id may be defined in many area_ids.
{% enddocs %}

{% docs gtfs_stop_areas\_\_stop_id %}
Identifies a stop. If a station (i.e. a stop with stops.location_type=1) is defined in this field, it is assumed that all of its platforms (i.e. all stops with stops.location_type=0 that have this station defined as stops.parent_station) are part of the same area. This behavior can be overridden by assigning platforms to other areas.
{% enddocs %}
