--- These are GTFS RT trip update (stoptimeupdate) prediction accuracy metrics ---

{% docs column_gtfs_rt__tu_prediction_error %}

Difference between the predicted_arrival and actual_arrival.
Units can be seconds or minutes based on column name.

For interpretation, the magnitude is important. For many transit operators, the definition of 
on-time can be much looser, such as between 1 minute early and 1 minute late. 
This column provides flexibility for various definitions.

Early arrivals: actual_arrival - predicted_arrival > 0.
Ex: the bus is predicted to arrive at 9:00 AM; it arrives at 9:02 AM, departs at 9:03 AM; 
9:02 AM - 9:00 AM gives difference = 2 minutes; it is 2 minutes early.
Following the prediction allows you to catch the bus, but with a wait.

Late arrivals: actual_departure - predicted_arrival < 0.
Ex: the bus is predicted to arrive at 9:00 AM; it arrives at 8:55 AM, departs at 8:59 AM; 
8:59 AM - 9:00 AM gives difference = -1 minutes; it is 1 minutes late. 
Following the prediction leads you to miss the bus.

On-time: predicted_arrival is between actual_arrival and actual_departure.

{% enddocs %}


{% docs column_gtfs_rt__tu_scaled_prediction_error %}

The scaled prediction error divides the prediction_error by the number of minutes away from arrival.
Scaled prediction error does not have units of seconds or minutes.
Predictions 30 minutes away from arrival have prediction_errors divided by 30 minutes, and are weighted less than predictions that are 1 minute away.

{% enddocs %}


{% docs column_gtfs_rt__tu_accurate_minutes %}

Number of minutes (up to 30 minutes before arrival for each service_date-trip-stop_id-stop_sequence combination) that have accurate predictions.

Predictions are "accurate" if they are within the bounds of this equation:
`-60ln(minutes_until_arrival+1.3) < Prediction Error < 60ln(minutes_until_arrival+1.5)`.

The percent of predictions that are accurate is calculated by dividing by total number of minutes available.
pct_tu_accurate_minutes = n_tu_accurate_minutes / n_tu_minutes_available

{% enddocs %}


{% docs column_gtfs_rt__tu_complete_minutes %}

The number of minutes (up to 30 minutes before arrival for each service_date-trip-stop_id-stop_sequence combination) that has 2+ trip updates for that minute.

The percent of predictions that are complete is calculated by dividing by total number of minutes available.
pct_tu_complete_minutes = n_tu_complete_minutes / n_tu_minutes_available

{% enddocs %}


{% docs column_gtfs_rt__tu_predictions_by_category %}

Total number of stoptimeupdate messages, or predictions, by category.
Category values are: `early`, `on-time`, or `late`.

The percent of predictions are early, on-time, or late is calculated by dividing by total
number of predictions (n_predictions).
* pct_predictions_early = n_predictions_early / n_predictions
* pct_predictions_ontime = n_predictions_ontime / n_predictions
* pct_predictions_late = n_predictions_late / n_predictions

{% enddocs %}


{% docs column_gtfs_rt__tu_prediction_spread %}

The cumulative change across how the predicted_arrival changes from minute to minute, for a service_date-trip-stop_id-stop_sequence combination. 

This is the jitter, or the wobble, that describes the flucations of predicted stop arrivals.
{% enddocs %}
