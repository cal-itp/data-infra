
{% docs gtfs_shapes__shape_id %}
Identifies a shape.
{% enddocs %}

{% docs gtfs_shapes__shape_pt_lat %}
Latitude of a shape point. Each record in shapes.txt represents a shape point used to define the shape.
{% enddocs %}

{% docs gtfs_shapes__shape_pt_lon %}
Longitude of a shape point.
{% enddocs %}

{% docs gtfs_shapes__shape_pt_sequence %}
Sequence in which the shape points connect to form the shape. Values must increase along the trip but do not need to be consecutive.Example: If the shape "A_shp" has three points in its definition, the shapes.txt file might contain these records to define the shape:
 shape_id,shape_pt_lat,shape_pt_lon,shape_pt_sequence
 A_shp,37.61956,-122.48161,0
 A_shp,37.64430,-122.41070,6
 A_shp,37.65863,-122.30839,11
{% enddocs %}

{% docs gtfs_shapes__shape_dist_traveled %}
Actual distance traveled along the shape from the first shape point to the point specified in this record. Used by trip planners to show the correct portion of the shape on a map. Values must increase along with shape_pt_sequence; they cannot be used to show reverse travel along a route. Distance units must be consistent with those used in stop_times.txt.Example: If a bus travels along the three points defined above for A_shp, the additional shape_dist_traveled values (shown here in kilometers) would look like this:
 shape_id,shape_pt_lat,shape_pt_lon,shape_pt_sequence,shape_dist_traveled
 A_shp,37.61956,-122.48161,0,0
A_shp,37.64430,-122.41070,6,6.8310
 A_shp,37.65863,-122.30839,11,15.8765
{% enddocs %}
