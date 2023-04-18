# RT Analysis Module

## Start Here

This module, rt_analysis, applies various spatial processing, interpolation, and aggregation techniques in order to transform GTFS and GTFS-Realtime data into intermediate data products and production-ready visualizations. It can be found on GitHub at [https://github.com/cal-itp/data-analyses/tree/main/rt_delay/rt_analysis](https://github.com/cal-itp/data-analyses/tree/main/rt_delay/rt_analysis)

It includes its own interface and data model. Some functionality may shift to a more automated part of the pipeline in the future.

### Which analyses does it currently support?

* [California Transit Speed Maps](https://analysis.calitp.org/rt/README.html)
* Technical Metric Generation for Solutions for Congested Corridors Program, Local Partnership Program
* Various prioritization exercises from intermediate data, such as using aggregated speed data as an input for identifying bus route improvements as part of a broader model
* Various ad-hoc speed and delay analyses, such as highlighting relevant examples for presentations to stakeholders, or providing a shapefile of bus speeds on certain routes to support a district’s grant application

## How does it work?

This section includes detailed information about the data model and processing steps. Feel free to skip ahead to “How do I use it?” if you need a quicker start.

### Which data does it require?

* GTFS-RT Vehicle Positions
* GTFS Schedule Trips
* GTFS Schedule Stops
* GTFS Schedule Routes
* GTFS Schedule Stop Times
* GTFS Schedule Shapes

All of the above are sourced from the v2 warehouse. Note that all components must be present and consistently keyed in order to successfully analyze. This module works at the organization level in order to match the reports site and maintain the structure of the speedmap site.

For each organization, this module will combine and analyze all related GTFS Schedule and GTFS Realtime datasets that are `reports_site_assessed` in [`dim_provider_gtfs_data`](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.dim_provider_gtfs_data). Some organizations share GTFS datasets (Sacramento RT and City of Rancho Cordova, San Diego Airport and San Diego MTS...), in those cases the module can generate seperate analysis for each organization but they might duplicate each other. These are based on the underlying organization/dataset relationships in the Transit Database (Airtable).

### How is it structured?

The module is split into two major components, `rt_parser`, which generates intermediate data for detailed analysis, and `rt_filter_map_plot`, which provides a rich interface to analyze and generate products like speed maps.

### `rt_parser`: making sense of Vehicle Positions

```{mermaid}
flowchart TD
    subgraph warehouse["Warehouse Data"]
        vp{{GTFS-RT Vehicle Positions}}
        routes[GTFS Routes] -->|id, names| trips[GTFS Trips]
        stops[GTFS Stops]
        st[GTFS Stop Times]
        shapes[GTFS Shapes]
    end
    %% OperatorDayAnalysis processing step
    subgraph op_day["OperatorDayAnalysis"]
        subgraph per_shp[process per shape:]
            add_1k(add 1km segments if stops far apart)
        end
        subgraph per_trp[process per trip:]
            gen_int(generate interpolator object)
            store_int(self.position_interpolators) -->
            gen_sdv(generate stop_delay_view)
        end
        subgraph int_data[finished intermediate data]
            stop_delay["self.stop_delay_view (all trips)"]
            rt_trips["self.rt_trips (trip-level info)"]
        end
        %% local links
        gen_int --> vp_int --> store_int
        per_shp --> per_trp -->|combine all trips| int_data
        -->|self.export_views_gcs| gcs[("GCS (calitp-analytics-data/data_analyses/rt_delay)")]
    end
    %% VehiclePositionsInterpolator
    subgraph vp_int["VehiclePositionsInterpolator"]
        ck_data[check data quality] -->
        proj[project vehicle positions to shape] -->
        cast[cast to monotonic increasing] ---
        interface("interpolation interface: self.time_at_position")
    end
    %% top level links
    warehouse -->|single day of data| op_day
```

#### __What happens at the OperatorDayAnalysis stage?__

The OperatorDayAnalysis class is the top-level class for processing a day’s worth of data and outputting intermediate data to be used later for mapping and analysis through the RtFilterMapper interface. It’s useful to understand how it works when analyzing an organization's RT data on a date for the first time, though once this is accomplished nearly any analysis need can be fulfilled without regenerating OperatorDayAnalysis.

An OperatorDayAnalysis is generated for a specific organization on a specific date.

#### Gathering Data

First, OperatorDayAnalysis gathers GTFS and GTFS Realtime Vehicle Positions data for the feed and date selected (for a complete list of source data, see above).

#### Asserts/Data Checks

This step checks for the presence of Vehicle Positions data, with trip_ids matching schedule data, as well as the presence of GTFS Shapes data describing at least 90% of scheduled trips.

#### Generate Position Interpolators

This step attempts to generate VehiclePositionInterpolator objects for all trips for which data is present. For a detailed description, see below.

#### Generate Stop Delay View

This step uses the generated interpolator objects to estimate and store speed and delay information for every trip at each stop. Where stops are less frequent we add "virtual stops" every kilometer to support granular analysis of express and rural transit routes.

The results of this step are saved in OperatorDayAnalysis.stop_delay_view, a geodataframe.

||||
|--- |--- |--- |
|Column|Source|Type|
|shape_meters|Projection of GTFS Stop along GTFS Shape (with 0 being start of shape), additionally 1km segments generated where stops are infrequent|float64|
|stop_id|GTFS Schedule|string*|
|stop_name|GTFS Schedule|string*|
|geometry|GTFS Schedule|geometry|
|shape_id|GTFS Schedule|string|
|trip_id|GTFS Schedule|string|
|stop_sequence|GTFS Schedule|float64**|
|arrival_time|GTFS Schedule|np.datetime64[ns]*|
|route_id|GTFS Schedule|string|
|route_short_name|GTFS Schedule|string|
|direction_id|GTFS Schedule|float64|
|actual_time|VehiclePositionInterpolator|np.datetime64[ns]|
|delay_seconds|Calculated here (actual_time-arrival_time)***|float64*|

*null if location is an added 1km segment

**integer values from GTFS, but added 1km segments are inserted in between the nearest 2 stops with a decimal

***early arrivals currently represented as zero delay

#### __VehiclePositionsInterpolator: a foundational building block__

Analyzing speed and position from GTFS-RT Vehicle Positions data requires somewhat complex algorithms for each trip. In this module, these are implemented in the VehiclePositionsInterpolator class. When analyzing a day’s worth of data, the module generates an instance of VehiclePositionsInterpolator for each trip with Vehicle Positions data. There’s little need to interact with VehiclePositionsInterpolator directly for most uses.

#### Constructor

The constructor takes two arguments: a geodataframe of Vehicle Positions data, filtered to a single trip and joined with trip identifier information from GTFS Schedule, and a geodataframe of GTFS Shapes as line geometries, which must include the shape of the trip of interest. When constructed, it runs several data checks, enforcing that: Vehicle Positions and Shapes data are provided, both geodataframes have the same coordinate reference system (CA_NAD83Albers), and that Vehicle Positions data is only provided for a single trip and contains the required identifier information.

#### Basic Logging

VehiclePositionsInterpolator has simple logging functionality built in through the VehiclePositionsInterpolator.logassert method. This method is a simple wrapper to Python’s assert keyword that also uses Python’s built in logging module to log which error occurred before raising an AssertionError. By default, the logfile will be `./rt_log`.

#### Projection

Vehicle Positions data includes a series of positions for a single trip at different points in time. Since we’re interested in tracking speed and delay along the transit route, we need to project those lat/long positions to a linear reference along the actual transit route (GTFS Shape). This is accomplished by the constructor calling VehiclePositionsInterpolator._attach_shape, which first does a naive projection of each position using shapely.LineString.project. This linearly referenced value is stored in the shape_meters column.

Since later stages will have to interpolate these times and positions, it’s necessary to undertake some additional data cleaning. This happens by calling VehiclePositionsInterpolator._linear_reference, which casts shape_meters to be monotonically increasing with respect to time. This removes multiple position reports at the same location, as well as any positions that suggest the vehicle traveled backwards along the route. While this introduces the assumption that the GPS-derived Vehicle Positions data is fairly accurate, our experience is that this process produces good results in most cases. Future updates will better accommodate [looping and inlining](https://gtfs.org/schedule/best-practices/#shapestxt); these currently get dropped in certain cases, which is undesirable.

#### Interpolating, quickly

As you might expect, the main purpose of VehiclePositionsInterpolator is to provide a fast interface to estimate when a trip arrived at a point of interest (generally a transit stop or segment boundary) based on the two known nearest positions.

VehiclePositionsInterpolator.time_at_position(self, desired_position) provides this interface. Desired position is given in meters, with zero being the start of the GTFS Shape. If the position requested is within the spatial bounds of Vehicle Position data for the trip, this method will quickly return the estimated timestamp using a fast numpy array function, further sped up with [numba](https://numba.pydata.org/).

#### Saving Intermediate Data (largely automatically)

Intermediate data is saved using OperatorDayAnalysis.export_views_gcs()

This method saves 2 artifacts: a geoparquet of OperatorDayAnalysis.stop_delay_view and a parquet of OperatorDayAnalysis.rt_trips. These are saved in Google Cloud Storage at calitp-analytics-data/data-analyses/rt_delay/stop_delay_views and calitp-analytics-data/data-analyses/rt_delay/rt_trips respectively.

rt_trips is a dataframe of trip-level information for every trip for which a VehiclePositionsInterpolator was successfully generated. It supports filtering by various attributes and provides useful contextual information for maps and analyses.

||||
|--- |--- |--- |
|Column|Source|Type|
|feed_key*|v2 warehouse (gtfs mart)|string|
|trip_key|Key from v2 warehouse|string|
|gtfs_dataset_key*|v2 warehouse (gtfs mart)|string|
|activity_date|v2 warehouse|datetime.date|
|trip_id|GTFS Schedule|string|
|route_id|GTFS Schedule|string|
|route_short_name|GTFS Schedule|string|
|shape_id|GTFS Schedule|string|
|direction_id|GTFS Schedule|string|
|route_type|GTFS Schedule|string|
|route_long_name|GTFS Schedule|string|
|route_desc|GTFS Schedule|string|
|route_long_name|GTFS Schedule|string|
|calitp_itp_id|v2 warehouse (transit database)|int64|
|median_time|VehiclePositionsInterpolator|datetime.time|
|direction|VehiclePositionsInterpolator|string|
|mean_speed_mph|VehiclePositionsInterpolator|float64|
|organization_name|v2 warehouse (transit database)|string|

* keys and IDs in this table refer to GTFS Schedule datasets

## How do I use it?

### Viewing Data Availability (or starting from scratch)

Use shared_utils.rt_utils.get_operators to see dates and feeds with the core analysis already run and intermediate data available. With the v2 warehouse transition, this module is currently set to only generate new data from Jan 1, 2023 onward. If necessary, we can run older dates from v2 data after confirming that the organization/dataset mapping is as-desired. Intermediate data available from this utility from before 2023 is currently based off of prior v1 warehouse results, which may include different underlying datasets from current results.

To support commonality with other analyses, this module now generates the core analysis for dates recorded in [data_analyses/shared_utils/rt_dates.py](https://github.com/cal-itp/data-analyses/blob/main/_shared_utils/shared_utils/rt_dates.py).

Intermediate data for those selected dates will usually be already generated as part of the speedmap deployment process. For reference, if not already ran, use the OperatorDayAnalysis constructor to generate the core analysis and save intermediate data for the dates and feeds of interest. Note that this process can be time-consuming, especially for larger feeds like LA Metro.

This function supports an optional progress bar argument to show analysis progress. First make sure tqdm is installed, then create a blank progress bar and provide that as an argument to the function (see example notebook). Note that you may have to [enable the jupyter extension](https://github.com/tqdm/tqdm/issues/394#issuecomment-384743637).

For example, to generate data for Big Blue Bus on April 12, 2023:

```python
from rt_analysis import rt_parser
from tqdm.notebook import tqdm

pbar = tqdm()
rt_day = rt_parser.OperatorDayAnalysis(300, dt.date(2023, 4, 12), pbar)
rt_day.export_views_gcs()
```

### `rt_filter_map_plot`: your flexible analytics and mapping interface

```{mermaid}
flowchart TD
    gcs[("GCS (calitp-analytics-data/data_analyses/rt_delay)")]
    subgraph rt_fil_map[RtFilterMapper]
        st_flt[self.set_filter] -->
        flt[self._filter]
        rs_flt[self.reset_filter] -->
        flt
        subgraph stv[static views]
            self.calitp_agency_name
            self.rt_trips
            self.stop_delay_view
            self.endpoint_delay_summary
            self.endpoint_delay_view
        end
        subgraph dyn[dynamic tools]
            ssm[self.segment_speed_map] -->
            dmv[self.detailed_map_view] -->
            gis[/GIS Format Exports/]
            self.chart_variability
            self.map_variance
            self.chart_delays
            self.chart_speeds
            self.describe_slow_routes
            ssm --> rend[/renders map/]
            ssm --> ssv[self.stop_segment_speed_view]
            rend -.- dmv
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

#### Loading Intermediate Data (largely automatically)

To load intermediate data, use `rt_filter_map_plot.from_gcs` to create an RtFilterMapper instance for the itp_id and date of interest.

#### Filtering

Using the `set_filter` method, RtFilterMapper supports filtering based on at least one of these attributes at a time:

|||
|--- |--- |
|Attribute|Type|
|start_time|str (%H:%M, i.e. 11:00)|
|end_time|str (%H:%M, i.e. 19:00)|
|route_names|list, pd.Series|
|shape_ids|list, pd.Series|
|direction_id|str, '0' or '1'|
|direction|str, "Northbound", etc, _experimental_|
|trip_ids|list, pd.Series|
|route_types|list, pd.Series|

Mapping, charting, and metric generation methods, listed under "dynamic tools" in the chart above, will respect the current filter. After generating your desired output, you can call `set_filter` again to set a new filter, or use `reset_filter` to remove the filter entirely. Then you can continue to analyze, without needing to create a new RtFilterMapper instance.

#### Mapping

Use the `segment_speed_map` method to generate a speed map. Depending on parameters, the speeds visualized will either be the 20th percentile or average speeds for all trips in each segment matching the current filter, if any. See function docstring for additional information.

The `map_variance` method, currently under development, offers a spatial view of relative variance in speeds for all trips in each segment matching the current filter, if any.

#### `stop_segment_speed_view`

After generating a speed map, the underlying data is available at RtFilterMapper.stop_segment_speed_view, a geodataframe. This data can be easily exported into a geoparquet, geojson, shapefile, or spreadsheet with the appropriate geopandas method.

||||
|--- |--- |--- |
|Column|Source|Type|
|shape_meters|Projection of GTFS Stop along GTFS Shape (with 0 being start of shape), additionally 1km segments generated where stops are infrequent|float64|
|stop_id|GTFS Schedule|string*|
|stop_name|GTFS Schedule|string*|
|geometry|GTFS Schedule|geometry|
|shape_id|GTFS Schedule|string|
|trip_id|GTFS Schedule|string|
|stop_sequence|GTFS Schedule|float64**|
|route_id|GTFS Schedule|string|
|route_short_name|GTFS Schedule|string|
|direction_id|GTFS Schedule|float64|
|delay_seconds*|`stop_delay_view`|np.datetime64[ns]|
|seconds_from_last*|time for trip to travel to this stop from last stop|float64|
|last_loc*|previous stop `shape_meters`|float64|
|meters_from_last*|`shape_meters` - `last_loc`|float64|
|speed_from_last*|`meters_from_last` / `seconds_from_last`|float64|
|delay_chg_sec*|`delay_seconds` - delay at last stop|float64|
|speed_mph*|`speed_from_last` converted to miles per hour|float64|
|n_trips_shp**|number of unique trips on this GTFS shape in filter|int64|
|avg_mph**|average speed for all trips on this segment|float64|
|_20p_mph**|20th percentile speed for all trips on this segment|float64|
|var_mph**|statistical variance in speed for all trips on this segment|float64|
|trips_per_hour|`n_trips_shp` / hours in filter|float64|

*disaggregate value -- applies to this trip only

**aggregated value -- based on all trips in filter

#### Other Charts and Metrics

The `chart_variability` method provides a descriptitive view of the speeds experienced by each trip in each segments. It requires that a filter first be set to only one shape_id.

The `chart_speeds` and `chart_delays` methods provide aggregate charts showing speed and delay patterns throughout the day.

The `describe_slow_routes` method lists out the routes in the current filter experiencing the lowest speeds. It is mainly used on the California Transit Speed Maps site.

#### Corridor Analysis

It's often useful to measure transit delay on a specific corridor to support technical metric generation for the Solutions for Congested Corridors Program, Local Partnership Program, and other analyses.

If you've recieved a corridor from an SCCP/LPP applicant or elsewhere, load it as a geodataframe and add it using the `add_corridor` method. If you're already looking at a speed map and want to measure delay for a portion of the map, you can use the `autocorridor` method to specify a corridor using a shape_id and two stop_sequences. This saves time by avoiding the need to generate the polygon elsewhere.

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
    rcv_corr[/recieve corridor from applicant/] -->
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

* 2022 SCCP/LPP default timeframe is Apr 30 - May 9 2022.
