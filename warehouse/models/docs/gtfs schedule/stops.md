Original definitions from https://gtfs.org/reference/static#stopstxt

{% docs gtfs_stops__stop_id %}
Identifies a stop, station, or station entrance.

 The term "station entrance" refers to both station entrances and station exits. Stops, stations or station entrances are collectively referred to as locations. Multiple routes may use the same stop.
{% enddocs %}

{% docs gtfs_stops__stop_code %}
Short text or a number that identifies the location for riders. These codes are often used in phone-based transit information systems or printed on signage to make it easier for riders to get information for a particular location. The stop_code can be the same as stop_id if it is public facing. This field should be left empty for locations without a code presented to riders.
{% enddocs %}

{% docs gtfs_stops__stop_name %}
Name of the location. Use a name that people will understand in the local and tourist vernacular.

When the location is a boarding area (location_type=4), the stop_name should contains the name of the boarding area as displayed by the agency. It could be just one letter (like on some European intercity railway stations), or text like “Wheelchair boarding area” (NYC’s Subway) or “Head of short trains” (Paris’ RER).

Conditionally Required:
• Required for locations which are stops (location_type=0), stations (location_type=1) or entrances/exits (location_type=2).
• Optional for locations which are generic nodes (location_type=3) or boarding areas (location_type=4).
{% enddocs %}

{% docs gtfs_stops__tts_stop_name %}
Readable version of the stop_name. See "Text-to-speech field" in the Term Definitions for more.
{% enddocs %}

{% docs gtfs_stops__stop_desc %}
Description of the location that provides useful, quality information. Do not simply duplicate the name of the location.
{% enddocs %}

{% docs gtfs_stops__stop_lat %}
Latitude of the location.

For stops/platforms (location_type=0) and boarding area (location_type=4), the coordinates must be the ones of the bus pole — if exists — and otherwise of where the travelers are boarding the vehicle (on the sidewalk or the platform, and not on the roadway or the track where the vehicle stops).

Conditionally Required:
• Required for locations which are stops (location_type=0), stations (location_type=1) or entrances/exits (location_type=2).
• Optional for locations which are generic nodes (location_type=3) or boarding areas (location_type=4).
{% enddocs %}

{% docs gtfs_stops__stop_lon %}
Longitude of the location.

For stops/platforms (location_type=0) and boarding area (location_type=4), the coordinates must be the ones of the bus pole — if exists — and otherwise of where the travelers are boarding the vehicle (on the sidewalk or the platform, and not on the roadway or the track where the vehicle stops).

Conditionally Required:
• Required for locations which are stops (location_type=0), stations (location_type=1) or entrances/exits (location_type=2).
• Optional for locations which are generic nodes (location_type=3) or boarding areas (location_type=4).
{% enddocs %}

{% docs gtfs_stops__zone_id %}
Identifies the fare zone for a stop. This field is required if providing fare information using fare_rules.txt, otherwise it is optional. If this record represents a station or station entrance, the zone_id is ignored.
{% enddocs %}

{% docs gtfs_stops__stop_url %}
URL of a web page about the location. This should be different from the agency.agency_url and the routes.route_url field values.
{% enddocs %}

{% docs gtfs_stops__location_type %}
Type of the location:
• 0 (or blank): Stop (or Platform). A location where passengers board or disembark from a transit vehicle. Is called a platform when defined within a parent_station.
• 1: Station. A physical structure or area that contains one or more platform.
• 2: Entrance/Exit. A location where passengers can enter or exit a station from the street. If an entrance/exit belongs to multiple stations, it can be linked by pathways to both, but the data provider must pick one of them as parent.
• 3: Generic Node. A location within a station, not matching any other location_type, which can be used to link together pathways define in pathways.txt.
• 4: Boarding Area. A specific location on a platform, where passengers can board and/or alight vehicles.
{% enddocs %}

{% docs gtfs_stops__parent_station %}
Defines hierarchy between the different locations defined in stops.txt. It contains the ID of the parent location, as followed:
• Stop/platform (location_type=0): the parent_station field contains the ID of a station.
• Station (location_type=1): this field must be empty.
• Entrance/exit (location_type=2) or generic node (location_type=3): the parent_station field contains the ID of a station (location_type=1)
• Boarding Area (location_type=4): the parent_station field contains ID of a platform.

Conditionally Required:
• Required for locations which are entrances (location_type=2), generic nodes (location_type=3) or boarding areas (location_type=4).
• Optional for stops/platforms (location_type=0).
• Forbidden for stations (location_type=1).
{% enddocs %}

{% docs gtfs_stops__stop_timezone %}
Timezone of the location. If the location has a parent station, it inherits the parent station’s timezone instead of applying its own. Stations and parentless stops with empty stop_timezone inherit the timezone specified by agency.agency_timezone. If stop_timezone values are provided, the times in stop_times.txt should be entered as the time since midnight in the timezone specified by agency.agency_timezone. This ensures that the time values in a trip always increase over the course of a trip, regardless of which timezones the trip crosses.
{% enddocs %}

{% docs gtfs_stops__wheelchair_boarding %}
Indicates whether wheelchair boardings are possible from the location. Valid options are:

For parentless stops:
0 or empty - No accessibility information for the stop.
1 - Some vehicles at this stop can be boarded by a rider in a wheelchair.
2 - Wheelchair boarding is not possible at this stop.

For child stops:
0 or empty - Stop will inherit its wheelchair_boarding behavior from the parent station, if specified in the parent.
1 - There exists some accessible path from outside the station to the specific stop/platform.
2 - There exists no accessible path from outside the station to the specific stop/platform.

 For station entrances/exits:
0 or empty - Station entrance will inherit its wheelchair_boarding behavior from the parent station, if specified for the parent.
1 - Station entrance is wheelchair accessible.
2 - No accessible path from station entrance to stops/platforms.
{% enddocs %}

{% docs gtfs_stops__level_id %}
Level of the location. The same level can be used by multiple unlinked stations.
{% enddocs %}

{% docs gtfs_stops__platform_code %}
Platform identifier for a platform stop (a stop belonging to a station). This should be just the platform identifier (eg. "G" or "3"). Words like “platform” or "track" (or the feed’s language-specific equivalent) should not be included. This allows feed consumers to more easily internationalize and localize the platform identifier into other languages.
{% enddocs %}
