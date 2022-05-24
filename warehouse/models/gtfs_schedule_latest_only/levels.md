
{% docs gtfs_levels__level_id %}
Id of the level that can be referenced from stops.txt.
{% enddocs %}

{% docs gtfs_levels__level_index %}
Numeric index of the level that indicates relative position of this level in relation to other levels (levels with higher indices are assumed to be located above levels with lower indices).

Ground level should have index 0, with levels above ground indicated by positive indices and levels below ground by negative indices.
{% enddocs %}

{% docs gtfs_levels__level_name %}
Optional name of the level (that matches level lettering/numbering used inside the building or the station). Is useful for elevator routing (e.g. “take the elevator to level “Mezzanine” or “Platforms” or “-1”).
{% enddocs %}
