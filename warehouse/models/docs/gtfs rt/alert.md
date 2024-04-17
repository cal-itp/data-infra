Original definitions from https://gtfs.org/realtime/reference/#message-alert

{% docs rt_alert__active_period %}
Time when the alert should be shown to the user. If missing, the alert will be shown as long as it appears in the feed. If multiple ranges are given, the alert will be shown during all of them.
{% enddocs %}

{% docs rt_alert__informed_entity %}
Entities whose users we should notify of this alert. At least one informed_entity must be provided.
{% enddocs %}

{% docs rt_alert__cause %}
Cause of this alert.
Values: UNKNOWN_CAUSE, OTHER_CAUSE, TECHNICAL_PROBLEM, STRIKE, DEMONSTRATION, ACCIDENT, HOLIDAY, WEATHER, MAINTENANCE, CONSTRUCTION, POLICE_ACTIVITY, MEDICAL_EMERGENCY.
If cause_detail is included, then Cause must also be included.
{% enddocs %}

{% docs rt_alert__effect %}
The effect of this problem on the affected entity.
Values: NO_SERVICE, REDUCED_SERVICE, SIGNIFICANT_DELAYS, DETOUR, ADDITIONAL_SERVICE, MODIFIED_SERVICE, OTHER_EFFECT, UNKNOWN_EFFECT, STOP_MOVED, NO_EFFECT, ACCESSIBILITY_ISSUE.
If effect_detail is included, then Effect must also be included.
{% enddocs %}

{% docs rt_alert__url %}
The URL which provides additional information about the alert.
{% enddocs %}

{% docs rt_alert__header_text %}
Header for the alert. This plain-text string will be highlighted, for example in boldface.
{% enddocs %}

{% docs rt_alert__description_text %}
Description for the alert. This plain-text string will be formatted as the body of the alert (or shown on an explicit "expand" request by the user). The information in the description should add to the information of the header.
{% enddocs %}

{% docs rt_alert__tts_header_text %}
Text containing the alert's header to be used for text-to-speech implementations. This field is the text-to-speech version of header_text. It should contain the same information as header_text but formatted such that it can read as text-to-speech (for example, abbreviations removed, numbers spelled out, etc.)
{% enddocs %}

{% docs rt_alert__tts_description_text %}
Text containing a description for the alert to be used for text-to-speech implementations. This field is the text-to-speech version of description_text. It should contain the same information as description_text but formatted such that it can be read as text-to-speech (for example, abbreviations removed, numbers spelled out, etc.)
{% enddocs %}

{% docs rt_alert__severity_level %}
Severity of the alert.
{% enddocs %}
