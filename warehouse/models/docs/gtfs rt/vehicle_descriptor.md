Original definitions from https://gtfs.org/realtime/reference/#message-vehicledescriptor

{% docs gtfs_vehicle_descriptor__id %}
Internal system identification of the vehicle. Should be unique per vehicle, and is used for tracking the vehicle as it proceeds through the system. This id should not be made visible to the end-user; for that purpose use the label field.
{% enddocs %}

{% docs gtfs_vehicle_descriptor__label %}
User visible label, i.e., something that must be shown to the passenger to help identify the correct vehicle.
{% enddocs %}

{% docs gtfs_vehicle_descriptor__license_plate %}
The license plate of the vehicle.
{% enddocs %}

{% docs gtfs_vehicle_descriptor__wheelchair_accessible %}
If provided, can overwrite the wheelchair_accessible value from the static GTFS.
{% enddocs %}
