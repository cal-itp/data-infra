Docs for NTD models;

{% docs ntd_id %}
A five-digit identifying number for each agency used in the current NTD system.
{% enddocs %}

{% docs ntd_legacy_id %}
The Transit Property’s NTD identification number in the Legacy NTD Database.
{% enddocs %}

{% docs ntd_agency %}
The transit agency's name.
{% enddocs %}

{% docs ntd_report_year %}
The year for which the data was reported.
{% enddocs %}

{% docs ntd_reporter_type %}
The type of NTD report that the agency completed this year.
Valid values are: `Full Reporter`, `Reduced Reporter`, `Rural Reporter`.
{% enddocs %}

{% docs ntd_organization_type %}
Description of the agency's legal entity.
Valid values are: `Area Agency on Aging`, `University`, `MPO, COG, or Other Planning Agency`, `Private-Non-Profit Corporation`, `State Government Unit or Department of Transportation`, `City, County, or Local Government Unit or Department of Transportation`, `Independent Public Agency or Authority of Transit Service`, `Private Provider Reporting on Behalf of a Public Entity`, `Private-For-Profit Corporation`, or `Tribe`. 
{% enddocs %}

{% docs ntd_type_of_service %}
Describes how public transportation services are provided by the transit agency.
Valid values are: `directly operated (DO)` or `purchased transportation (PT)` services.
{% enddocs %}

{% docs ntd_city %}
The city in which the agency is headquartered.
{% enddocs %}

{% docs ntd_state %}
The state in which the agency is headquartered.
{% enddocs %}

{% docs ntd_primary_uza_code %}
UACE Code remains consistent across census years.
{% enddocs %}

{% docs ntd_primary_uza_name %}
The name of the agency's Urbanized Area.
{% enddocs %}

{% docs ntd_primary_uza_area_sq_miles %}
The agency's Urbanized Area's size in square miles.
{% enddocs %}

{% docs ntd_primary_uza_population %}
The population of the urbanized area primarily served by the agency.
{% enddocs %}

{% docs ntd_mode %}
A system for carrying transit passengers described by specific right-of-way (ROW), technology and operational features.
    - Rail modes (heavy rail (HR), light rail (LR), commuter rail (CR), inclined plane (IP), cable car (CC) and Monorail/Automated guideway (MG))
    - Ferryboats (FB)
    - Aerial tramways (TR)
    - Bus (MB)
    - Trolleybus (TB)
    - Commuter Bus (CB)
    - Bus Rapid Transit (RB)
    - Publico (PB)
    - Jitney (JT)    
{% enddocs %}

{% docs ntd_mode_name %}
A system for carrying transit passengers described by specific right-of-way (ROW), technology and operational features.
    - Rail modes: heavy rail (HR), light rail (LR), commuter rail (CR), inclined plane (IP), cable car (CC), monorail/automated guideway (MG), streetcar (SR), hybrid rail (YR), Alaska railroad (AR).
    - Ferryboats (FB)
    - Aerial tramways (TR)
    - Bus (MB)
    - Trolleybus (TB)
    - Commuter Bus (CB)
    - Bus Rapid Transit (RB)
    - Publico (PB)
    - Jitney (JT)    
{% enddocs %}

{% docs ntd_time_period %}
The time period for which data was collected.
Valid values are: 
    - Annual Total (excluded in mart_ntd mode-tos grain),
    - Average Weekday - AM Peak
    - Average Weekday - Midday
    - Average Weekday - PM Peak
    - Average Weekday - Other
    - Average Typical Weekday
    - Average Typical Saturday
    - Average Typical Sunday
{% enddocs %}

{% docs ntd_service_area_population %}
The population of the service area served by the agency.
{% enddocs %}
    
{% docs ntd_service_area_sq_miles %}
The agency's service area's size in square miles.
{% enddocs %}

{% docs ntd_questionable_data %}
Indicates whether there was questionable data for the given given record.        FTA marks a data point as Questionable when there is reason to believe it is incorrect,but the reporting agency has been unable to correct the data or offer an explanation for its anomalous appearance.
{% enddocs %}

{% docs ntd_agency_voms %}
The number of revenue vehicles operated across the whole agency to meet the annual maximum service requirement.
This is the revenue vehicle count during the peak season of the year; on the week and day that maximum service is provided.
Vehicles operated in maximum service (VOMS) exclude atypical days and one-time special events.
{% enddocs %}

{% docs ntd_actual_vehicle_hours %}
The hours that vehicles/passenger cars travel while in revenue service plus deadhead hours.
Actual vehicle hours include:
    - Revenue service,
    - Deadhead,
    - Layover/recovery time.
Actual vehicle hours exclude:
    - Hours for charter service,
    - School bus service,
    - Operator training,
    - Vehicle maintenance testing.
{% enddocs %}
