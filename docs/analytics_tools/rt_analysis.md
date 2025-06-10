# RT Analysis Module (Legacy)

The former `rt_parser` module, including the `OperatorDayAnalysis` and `VehiclePositionsInterpolator` classes, has been deprecated. A truncated version of these docs remains as a guide to accessing processed speeds outputs that predate the `rt_segment_speeds` pipeline. `rt_filter_map_plot` is still usable as of June 2025, or artifacts on GCS can be accessed directly.

## `rt_filter_map_plot`: your flexible analytics and mapping interface

```{mermaid}
flowchart TD
    gcs[("GCS (calitp-analytics-data/data_analyses/rt_delay)")]
    map_gcs[("Public GCS (calitp-map-tiles/)")]
    subgraph rt_fil_map[RtFilterMapper]
        st_flt[self.set_filter] -->
        flt[self._filter]
        rs_flt[self.reset_filter] -->
        flt
        subgraph stv[static views]
            self.organization_name
            self.rt_trips
            self.stop_delay_view
            self.endpoint_delay_summary
            self.endpoint_delay_view
        end
        subgraph dyn[dynamic tools]
            ssm[self.segment_speed_map] -->|optionally renders map| dmv
            dmv[self.detailed_map_view] -->
            gis[/Manual GIS Format Exports/]
            dmv --> mgz[self.map_gz_export]
            self.chart_variability
            mpv[self.map_variance]
            mpv --> |optionally renders map| mgz
            mgz -.-> map_gcs
            map_gcs -.-> spa
            mgz -.-> |self.spa_map_state| spa
            mgz -->|self.display_spa_map| spa([render maps via external app + IFrame])
            self.chart_delays
            self.chart_speeds
            self.describe_slow_routes
            ssm --> ssv[self.stop_segment_speed_view]
            subgraph cor[corridor tools]
                acor[self.autocorridor] -.->
                add_cor[self.add_corridor] -->
                qmc[self.quick_map_corridor]
                c_met[self.corridor_metrics]
                add_cor --> c_met
                ext[/external corridor/] -.-> add_cor
            end
            ssv -.-> acor
        end
        %% add_cor -.->|corridor= True| ssm
        flt --> dyn
        stv --> dyn
    end
    %% top level links
    gcs -->|rt_trips| fm_gcs
    gcs -->|stop_delay_view| fm_gcs
    fm_gcs[rt_filter_map_plot.from_gcs] --> rt_fil_map
    rt_fil_map --> speedmaps[/CA Transit Speed Maps/]
    rt_fil_map --> bb[/Better Buses Analysis/]
    rt_fil_map --> sccp[/SCCP/LPP Transit Delay/]
    rt_fil_map --> other[/Other Exposures/]
```

`rt_filter_map_plot` exists to provide robust analytics functionality separately from the compute-intensive raw data processing steps. It includes the RtFilterMapper class, which provides an interface for loading and filtering a day of data, plus tools to generate various maps, charts, and metrics.

_Check out the [walkthrough notebook](https://github.com/cal-itp/data-analyses/blob/main/rt_delay/31_tutorial.ipynb) for further explanation/demo of these steps_

### Loading Intermediate Data (largely automatically)

To load intermediate data, use `rt_filter_map_plot.from_gcs` to create an RtFilterMapper instance for the itp_id and date of interest.

### Filtering

Using the `set_filter` method, RtFilterMapper supports filtering based on at least one of these attributes at a time:

|              |                                        |
| ------------ | -------------------------------------- |
| Attribute    | Type                                   |
| start_time   | str (%H:%M, i.e. 11:00)                |
| end_time     | str (%H:%M, i.e. 19:00)                |
| route_names  | list, pd.Series                        |
| shape_ids    | list, pd.Series                        |
| direction_id | str, '0' or '1'                        |
| direction    | str, "Northbound", etc, _experimental_ |
| trip_ids     | list, pd.Series                        |
| route_types  | list, pd.Series                        |

Mapping, charting, and metric generation methods, listed under "dynamic tools" in the chart above, will respect the current filter. After generating your desired output, you can call `set_filter` again to set a new filter, or use `reset_filter` to remove the filter entirely. Then you can continue to analyze, without needing to create a new RtFilterMapper instance.

### Mapping

Use the `segment_speed_map` method to generate a speed map. Depending on parameters, the speeds visualized will either be the 20th percentile or average speeds for all trips in each segment matching the current filter, if any. See function docstring for additional information.

The `map_variance` method, currently under development, offers a spatial view of variation in speeds for all trips in each segment matching the current filter, if any. This is now quantified as the ratio between 80th percentile and 20th percentile speeds, and used on the CA Transit Speed Maps tool.

### More performant maps via embedded app

Rather than render the maps directly in the notebook via geopandas and folium, we now have the capability to save them as compressed GeoJSON to GCS and render them in an IFrame using a [minimal web app](https://github.com/cal-itp/data-infra/tree/main/apps/maps).

This method is much more efficient, and we rely on it to maintain the quantity and quality of maps on the [CA Transit Speed Maps](https://analysis.calitp.org/rt/README.html) site.

`display_spa_map` will always show the most recent map generated with either `segment_speed_map` or `map_variance`, then saved via `map_gz_export`.

### `stop_segment_speed_view`

After generating a speed map, the underlying data is available at RtFilterMapper.stop_segment_speed_view, a geodataframe. This data can be easily exported into a geoparquet, geojson, shapefile, or spreadsheet with the appropriate geopandas method.

|                     |                                                                                                                                        |                     |
| ------------------- | -------------------------------------------------------------------------------------------------------------------------------------- | ------------------- |
| Column              | Source                                                                                                                                 | Type                |
| shape_meters        | Projection of GTFS Stop along GTFS Shape (with 0 being start of shape), additionally 1km segments generated where stops are infrequent | float64             |
| stop_id             | GTFS Schedule                                                                                                                          | string              |
| stop_name           | GTFS Schedule                                                                                                                          | string              |
| geometry            | GTFS Schedule                                                                                                                          | geometry            |
| shape_id            | GTFS Schedule                                                                                                                          | string              |
| trip_id             | GTFS Schedule                                                                                                                          | string              |
| stop_sequence       | GTFS Schedule                                                                                                                          | float64             |
| route_id            | GTFS Schedule                                                                                                                          | string              |
| route_short_name    | GTFS Schedule                                                                                                                          | string              |
| direction_id        | GTFS Schedule                                                                                                                          | float64             |
| delay_seconds\*     | `stop_delay_view`                                                                                                                      | np.datetime64\[ns\] |
| seconds_from_last\* | time for trip to travel to this stop from last stop                                                                                    | float64             |
| last_loc\*          | previous stop `shape_meters`                                                                                                           | float64             |
| meters_from_last\*  | `shape_meters` - `last_loc`                                                                                                            | float64             |
| speed_from_last\*   | `meters_from_last` / `seconds_from_last`                                                                                               | float64             |
| delay_chg_sec\*     | `delay_seconds` - delay at last stop                                                                                                   | float64             |
| speed_mph\*         | `speed_from_last` converted to miles per hour                                                                                          | float64             |
| n_trips_shp\*\*     | number of unique trips on this GTFS shape in filter                                                                                    | int64               |
| avg_mph\*\*         | average speed for all trips on this segment                                                                                            | float64             |
| \_20p_mph\*\*       | 20th percentile speed for all trips on this segment                                                                                    | float64             |
| \_80p_mph\*\*       | 80th percentile speed for all trips on this segment                                                                                    | float64             |
| fast_slow_ratio\*\* | ratio between p80 speed and p20 speed for all trips on this segment                                                                    | float64             |
| trips_per_hour      | `n_trips_shp` / hours in filter                                                                                                        | float64             |

\*disaggregate value -- applies to this trip only

\*\*aggregated value -- based on all trips in filter

### Other Charts and Metrics

The `chart_variability` method provides a descriptitive view of the speeds experienced by each trip in each segments. It requires that a filter first be set to only one shape_id.

The `chart_speeds` and `chart_delays` methods provide aggregate charts showing speed and delay patterns throughout the day.

The `describe_slow_routes` method lists out the routes in the current filter experiencing the lowest speeds. It is mainly used on the California Transit Speed Maps site.

### Corridor Analysis

It's often useful to measure transit delay on a specific corridor to support technical metric generation for the Solutions for Congested Corridors Program, Local Partnership Program, and other analyses.

If you've received a corridor from an SCCP/LPP applicant or elsewhere, load it as a geodataframe and add it using the `add_corridor` method. If you're already looking at a speed map and want to measure delay for a portion of the map, you can use the `autocorridor` method to specify a corridor using a shape_id and two stop_sequences. This saves time by avoiding the need to generate the polygon elsewhere.

The corridor must be a single polygon, and in order to generate metrics it must include at least one transit stop.

Once the corridor is attached, the `quick_map_corridor` method is available to generate an overview map of the corridor, including the transit stops just before, within, and just after the corridor. The `corridor_metrics` method will generate both a speed-based and schedule-based transit delay metric.

The speed-based metric is a daily average of the sum of delays for each trip traversing the corridor as compared to a reference speed of 16 miles per hour. To further explain, we take each corridor trip that we have data for and calculate the hypothetical time it would take for that trip to traverse the corridor at a speed of 16 mph. The difference between the actual time it took for the trip to traverse the corridor and that hypothetical time is the speed-based delay for that trip, and we sum those delays to create the metric. This metric is intended to provide a more consistent basis for comparison independent of scheduling practices.

In other words, if we expect a hypothetical bus lane/signal priority/payment system etc to increase corridor speeds to 16mph, this is how much time we could save per day.

The schedule-based metric is a daily average of the sum of median trip stop delays along the corridor. To further explain, we take each corridor trip that we have data for and look at the delay in comparison to the schedule at each stop, after subtracting off any delay present as the trip entered the corridor. For each trip we then take the median delay of all stops along the corridor, and sum these medians to create the metric.

Finally, you can use the `corridor = True` argument in the `segment_speed_map` method to generate a speed map for only corridor segments.

While all of these methods respect any filter you may have set with `set_filter`, don't set a filter for SCCP/LPP metric generation.

## Example Workflow: California Transit Speed Maps

See [`data_analyses/ca_transit_speed_maps/technical_notes.md`](https://github.com/cal-itp/data-analyses/blob/main/ca_transit_speed_maps/technical_notes.md) !

## Example Workflow: SCCP

```{mermaid}
flowchart TD
    rcv_corr[/receive corridor from applicant/] -->
    ver_corr[/verify corridor is polygon/] -->
    gen_data[generate analysis data for timeframe*]
    subgraph fm[RtFilterMapper]
        atc_corr["attach corridor (self.add_corridor)"]
        atc_corr --> metrics[self.corridor_metrics]
        atc_corr -.-> self.quick_map_corridor
        atc_corr -.-> map_corr["corridor = True on speedmaps"]
    end
    gen_data --> fm
    metrics --> pub>"share both speed and schedule metrics (appropriately averaged for SCCP/LPP)"]
```

Note that these steps are substantially automated using the `rt_analysis.sccp_tools.sccp_average_metrics` function.

- 2022 SCCP/LPP default timeframe is Apr 30 - May 9 2022.
