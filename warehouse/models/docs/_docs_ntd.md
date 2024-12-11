Docs for NTD models;

{% docs ntd_id %}
A five-digit identifying number for each agency used in the current NTD system.
FTA assigns each reporter a unique five-digit NTD Identification Number.
The first digit of the NTD ID corresponds to the FTA Region where the reporter is located (e.g., 9#### indicates Region IX).
The code will have a four-to-five digit prefix for any entity submitting the report on behalf of the reporter.
For example, State Departments of Transportation (usually indicated as #R##) submit on behalf of their subrecipients.
{% enddocs %}

{% docs ntd_legacy_id %}
The Transit Property’s NTD identification number in the Legacy NTD Database.
{% enddocs %}

{% docs ntd_state_parent_ntd_id %}
Indicates the ID number of the transit agency reporting to the database on behalf of the transit agency.
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
The primary urbanized area served by the transit agency.
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

{% docs ntd_3_mode %}
A grouping of modes based upon whether the mode operates on rail, is a bus mode, is ferry boat service or other.
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
Indicates whether there was questionable data for the given given record.
FTA marks a data point as Questionable when there is reason to believe it is incorrect,but the reporting agency has been unable to correct the data or offer an explanation for its anomalous appearance.
{% enddocs %}

{% docs ntd_agency_voms %}
The number of revenue vehicles operated across the whole agency to meet the annual maximum service requirement.
This is the revenue vehicle count during the peak season of the year; on the week and day that maximum service is provided.
Vehicles operated in maximum service (VOMS) exclude atypical days and one-time special events.
{% enddocs %}

{% docs ntd_actual_vehicles_passenger_car_hours %}
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

{% docs ntd_actual_vehicles_passenger_car_deadhead_hours %}
The hours that a vehicle/passenger car travels when out of revenue service.
Deadhead includes:
    - Leaving or returning to the garage or yard facility,
    - Changing routes,
    - When there is no expectation of carrying revenue passengers.
However, deadhead does not include:
    - Charter service,
    - School bus service,
    - Travel to fueling facilities,
    - Travel to maintenance facilities,
    - Operator training,
    - Maintenance testing.
{% enddocs %}

{% docs ntd_actual_vehicles_passenger_car_revenue_hours %}
The hours that vehicles/passenger cars travel while in revenue service.
Vehicle revenue hours (VRH) include:
    - Revenue service,
    - Layover/recovery time.
Actual vehicle revenue hours exclude:
    - Deadhead,
    - Operator training,
    - Maintenance testing,
    - School bus and charter services.
{% enddocs %}

{% docs ntd_charter_service_hours %}
Hours run in charter service.
{% enddocs %}

{% docs ntd_school_bus_hours %}
Hours run in school bus service.
{% enddocs %}

{% docs ntd_train_hours %}
The hours that trains travel while in revenue service plus deadhead hours.
Train hours include:
    - Revenue service,
    - Deadhead,
    - Layover/recovery time,
Train hours exclude:
    - Hours for charter service,
    - Operator training,
    - Vehicle maintenance testing.
{% enddocs %}

{% docs ntd_train_revenue_hours %}
The hours that trains travel while in revenue service. Train revenue hours include:
    - Revenue service,
    - Layover/recovery time.
Train revenue hours exclude:
    - Deadhead,
    - Operator training,
    - Maintenance testing,
    - Charter services.
{% enddocs %}

{% docs ntd_train_deadhead_hours %}
The hours that a train travels when out of revenue service. Deadhead includes:
    - Leaving or returning to the garage or yard facility,
    - Changing routes,
    - When there is no expectation of carrying revenue passengers.
However, deadhead does not include:
    - Charter service,
    - School bus service,
    - Travel to fueling facilities,
    - Travel to maintenance facilities,
    - Operator training,
    - Maintenance testing.
{% enddocs %}

{% docs ntd_passengers_per_hour %}
The average number of passengers to board a vehicle/passenger car in one hour of service.
For trains, this applies to passengers per hour on a single train car.
{% enddocs %}

{% docs ntd_actual_vehicles_passenger_car_miles %}
The miles that vehicles/passenger cars travel while in revenue service (actual vehicle revenue miles (VRM)) plus deadhead miles.
Actual vehicle miles include:
    - Revenue service,
    - Deadhead.
Actual vehicle miles exclude:
    - Miles for charter services,
    - School bus service,
    - Operator training,
    - Vehicle maintenance testing.
{% enddocs %}

{% docs ntd_actual_vehicles_passenger_car_revenue_miles %}
The miles that vehicles/passenger cars travel while in revenue service.
Vehicle revenue miles (VRM) include:
    - Revenue service.
Actual vehicle revenue miles exclude:
    - Deadhead,
    - Operator training,
    - Maintenance testing,
    - School bus and charter services.
{% enddocs %}

{% docs ntd_actual_vehicles_passenger_deadhead_miles %}
The miles that a vehicle/passenger car travels when out of revenue service.
Deadhead includes:
    - Leaving or returning to the garage or yard facility,
    - Changing routes,
    - When there is no expectation of carrying revenue passengers.
However, deadhead does not include:
    - Charter service,
    - School bus service,
    - Travel to fueling facilities,
    - Travel to maintenance facilities,
    - Operator training,
    - Maintenance testing.
{% enddocs %}

{% docs ntd_scheduled_vehicles_passenger_car_revenue_miles %}
The total service scheduled to be provided for picking up and discharging passengers.
Scheduled service is computed from internal transit agency planning documents (e.g., run paddles, trip tickets, and public timetables).
Scheduled service excludes special additional services.
{% enddocs %}

{% docs ntd_directional_route_miles %}
The mileage in each direction over which public transportation vehicles travel while in revenue service.
Directional route miles (DRM) are:
    - A measure of the route path over a facility or roadway, not the service carried on the facility; e.g., number of routes, vehicles, or vehicle revenue miles.
    - Computed with regard to direction of service, but without regard to the number of traffic lanes or rail tracks existing in the right-of-way (ROW).
Directional route miles (DRM) do not include staging or storage areas at the beginning or end of a route.
{% enddocs %}

{% docs ntd_passenger_miles %}
The cumulative sum of the distances ridden by each passenger.
{% enddocs %}

{% docs ntd_train_miles %}
The miles that trains travel while in revenue service (actual vehicle revenue miles (VRM)) plus deadhead miles.
Train miles include:
    - Revenue service,
    - Deadhead.
Train miles exclude:
    - Miles for charter services,
    - Operator training,
    - Vehicle maintenance testing.
{% enddocs %}

{% docs ntd_train_revenue_miles %}
The miles that trains travel while in revenue service.
Train revenue miles include:
    - Revenue service.
Train revenue miles exclude:
    - Deadhead,
    - Operator training,
    - Maintenance testing,
    - Charter services.
{% enddocs %}

{% docs ntd_train_deadhead_miles %}
The miles that a train travels when out of revenue service. Deadhead includes:
    - Leaving or returning to the garage or yard facility,
    - Changing routes,
    - When there is no expectation of carrying revenue passengers.
However, deadhead does not include:
    - Charter service,
    - School bus service,
    - Travel to fueling facilities,
    - Travel to maintenance facilities,
    - Operator training,
    - Maintenance testing.
{% enddocs %}

{% docs ntd_trains_in_operation %}
The maximum number of trains actually operated to provide service during the year.
{% enddocs %}

{% docs ntd_ada_upt %}
Unlinked Passenger Trips embarked per stipulations of the Americans with Disabilities Act.
{% enddocs %}

{% docs ntd_sponsored_service_upt %}
Unlinked Passenger Trips embarked under sponsored service.
{% enddocs %}

{% docs ntd_unlinked_passenger_trips_upt %}
The number of passengers who board public transportation vehicles.
Passengers are counted each time they board a vehicle no matter how many vehicles they use to travel from their origin to their destination.
{% enddocs %}

{% docs ntd_time_service_begins %}
The time at which a particular mode/type of service begins revenue service, presented in a 24-hour format.
{% enddocs %}

{% docs ntd_time_service_ends %}
The time at which a particular mode/type of service ends revenue service, presented in a 24-hour format.
{% enddocs %}

{% docs ntd_days_of_service_operated %}
Days of revenue service within the fiscal year.
{% enddocs %}

{% docs ntd_days_not_operated_strikes %}
Days of revenue service not operated due to strikes.
{% enddocs %}

{% docs ntd_days_not_operated_emergencies %}
Days of revenue service not operated due to emergencies.
{% enddocs %}

{% docs ntd_mode_voms %}
The number of revenue vehicles operated by the given mode and type of service to meet the annual maximum service requirement.
This is the revenue vehicle count during the peak season of the year; on the week and day that maximum service is provided.
Vehicles operated in maximum service (VOMS) exclude atypical days and one-time special events.
{% enddocs %}

{% docs ntd_average_passenger_trip_length_aptl_ %}
The average distance ridden by each passenger in a single trip, computed as passenger miles traveled (PMT) divided by unlinked passenger trips (UPT).
May be determined by sampling, or calculated based on actual data.
{% enddocs %}

{% docs ntd_average_speed %}
The average speed of a vehicle/passenger car during revenue service.
{% enddocs %}

{% docs ntd_brt_non_statutory_mixed_traffic %}
Miles of roadway for Bus Rapid Transit modes which, while part of bus rapid transit system routes, are not considered fixed guideway for federal funding allocation purposes.
These are rare exceptions resulting from FTA’s review of each BRT system.
{% enddocs %}

{% docs ntd_mixed_traffic_right_of_way %}
Roadways other than exclusive and controlled access rights-of-way (ROW) used for transit operations that are mixed with pedestrian and/or vehicle traffic.
Does not include guideways that have only grade crossings with vehicular traffic.
{% enddocs %}

{% docs ntd_upt %}
Unlinked Passenger Trips (UPT) -
The number of passengers who board public transportation vehicles.
Passengers are counted each time they board vehicles no matter how
many vehicles they use to travel from their origin to their destination.
{% enddocs %}

{% docs ntd_voms %}
Vehicles Operated in Annual Maximum Service (VOMS) -
The number of revenue vehicles operated to meet the annual maximum
service requirement. This is the revenue vehicle count during the peak
season of the year; on the week and day that maximum service is
provided. Vehicles operated in maximum service (VOMS) exclude:
    - Atypical days; or
    - One-time special events.
{% enddocs %}

{% docs ntd_vrh %}
Vehicle Revenue Hours (VRH) -
The hours that vehicles are scheduled to or actually travel while in
revenue service. Vehicle revenue hours include:
    - Layover / recovery time.
Vehicle revenue hours exclude:
    - Deadhead;
    - Operator training;
    - Vehicle maintenance testing; and
    - Other non-revenue uses of vehicles.
{% enddocs %}

{% docs ntd_vrm %}
Vehicle Revenue Miles (VRM) -
The miles that vehicles are scheduled to or actually travel while in
revenue service. Vehicle revenue miles include:
    - Layover / recovery time.
Vehicle revenue miles exclude:
    - Deadhead;
    - Operator training;
    - Vehicle maintenance testing; and
    - Other non-revenue uses of vehicles.
{% enddocs %}

{% docs ntd_mode_type_of_service_status %}
Indicates whether a property reports (active) or not (inactive) during the most recent Annual report year.
{% enddocs %}

{% docs ntd_last_closed_report_year %}
The property’s most-recent closed-out annual report year.
In cases where the agency mode type of service combination does not have a closed out report year, this value will be null.
{% enddocs %}

{% docs ntd_last_closed_fy_end_month %}
The month the property’s fiscal year ends.
In cases where the agency mode type of service combination does not have a closed out report year, this value will be null.
{% enddocs %}

{% docs ntd_last_closed_fy_end_year %}
The year in which the property’s most-recent closed-out fiscal year ended.
In cases where the agency mode type of service combination does not have a closed out report year, this value will be null.
{% enddocs %}

{% docs ntd_passenger_miles_fy %}
Passenger miles for the most recent closed-out annual report year.
In cases where the agency mode type of service combination does not have a closed out report year, this value will be null.
{% enddocs %}

{% docs ntd_unlinked_passenger_trips_fy %}
Unlinked Passenger Trips for the most recent closed-out annual report year.
In cases where the agency mode type of service combination does not have a closed out report year, this value will be null.
{% enddocs %}

{% docs ntd_avg_trip_length_fy %}
The ratio of Passenger Miles per Unlinked Passenger trips.
In cases where the agency mode type of service combination does not have a closed out report year, this value will be null.
{% enddocs %}

{% docs ntd_fares_fy %}
The fare revenues collected during the most recent closed-out annual report year.
In cases where the agency mode type of service combination does not have a closed out report year, this value will be null.
{% enddocs %}

{% docs ntd_operating_expenses_fy %}
The expenses associated with the operation of the transit agency, and classified by function or activity, and the goods and services purchased for the most recent closed-out annual report year.
{% enddocs %}

{% docs ntd_avg_cost_per_trip_fy %}
The ratio of Total Operating Expenses per Unlinked Passenger Trips.
In cases where the agency mode type of service combination does not have a closed out report year, this value will be null.
{% enddocs %}

{% docs ntd_avg_fares_per_trip_fy %}
The ratio of Fares Earned per Unlinked Passenger Trips.
In cases where the agency mode type of service combination does not have a closed out report year, this value will be null.
{% enddocs %}

{% docs ntd_ridership_service_type %}
A summarization of modes into `Fixed Route`, `Demand Response`, or `Unknown`.
{% enddocs %}

{% docs ntd_top_150 %}
Values are: `Y` (Yes) and `N` (No)
{% enddocs %}

{% docs ntd_period_year %}
The Year for which data was collected.
{% enddocs %}

{% docs ntd_period_month %}
The Month for which data was collected.
{% enddocs %}

{% docs ntd_period_month_year %}
The Month and Year for which data was collected.
{% enddocs %}

{% docs ntd_period_year_month %}
The Year and Month for which data was collected.
{% enddocs %}

{% docs ntd_xlsx_dt %}
Date when the data was extracted.
{% enddocs %}

{% docs ntd_xlsx_execution_ts %}
Date and Time when the data was extracted.
{% enddocs %}
