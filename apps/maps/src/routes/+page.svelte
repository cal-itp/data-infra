<!-- from https://dev.to/khromov/using-leaflet-with-sveltekit-3jn1 -->
<script>
    import {onMount, onDestroy} from 'svelte';
    import { page } from '$app/stores';
    import L from 'leaflet';
    import colormap from 'colormap';
    import {leafletLayer, LineSymbolizer} from 'protomaps';
    import {strFromU8, decompress, decompressSync} from 'fflate';
    import {LeafletLayer} from 'deck.gl-leaflet';
    import {MapView} from '@deck.gl/core';
    import {GeoJsonLayer} from '@deck.gl/layers';
    import '@fortawesome/fontawesome-free/css/all.css'
    import * as turf from '@turf/turf';
    import { Base64 } from 'js-base64';
    import { titleCase } from "title-case";
    import * as convert from 'color-convert';

    import "leaflet-loading";

    const STATE_QUERY_PARAM = "state";
    const START_LAT_LON = [37.6, -120.1];
    const LEAFLET_START_ZOOM = 6;
    const DEFAULT_BASEMAP_CONFIG = {
      "url": 'https://{s}.basemaps.cartocdn.com/{variant}/{z}/{x}/{y}{r}.png',
      "options": {
        'attribution': '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>',
        'subdomains': 'abcd',
        'maxZoom': 20,
        'variant': 'light_all',
      }
    };
    let mapElement;
    let map;
    /** @type {State} */
    let state;
    let outerLayer;
    let loading = false;

    const NSHADES = 10;
    const MAX_MPH = 50;

    const rgbaColorMap = colormap({
        colormap: 'RdBu',
        nshades: NSHADES,
        format: 'rgba',
    }).reverse();

    // https://github.com/101arrowz/fflate/wiki/FAQ
    const promisify = (func) => {
      return (...args) => {
        return new Promise((resolve, reject) => {
          func(...args, (err, res) => err
                  ? reject(err)
                  : resolve(res)
          );
        });
      }
    }

    function fetchGeoJSON(url, context) {
      console.log("Fetching", url);
      return fetch(url).then((response) => {
        if (url.endsWith(".gz") || response.headers.get("content-type") === "application/x-gzip") {
          console.log("decompressing gzipped data");

          return response.arrayBuffer().then((raw) => {
            return promisify(decompress)(new Uint8Array(raw)).then((data) => {
              return JSON.parse(strFromU8(data));
            });
          });
        }

        return response.json();
      });
    }

    function speedFeatureColor(feature, colorMap) {
        let avg_mph = feature.properties.avg_mph;

        if (avg_mph > MAX_MPH) {
          return colorMap[colorMap.length - 1];
        }

        return colorMap[Math.floor(avg_mph / (MAX_MPH / NSHADES))];
    }

    function getColor(feature, layer, saturationMultiplier = 1, alpha = 255) {
      if (feature.properties.color) {
        if (feature.properties.color.length === 4) {
          return feature.properties.color;
        }

        if (feature.properties.color.length === 3) {
          const hsv = convert.rgb.hsv(feature.properties.color);
          hsv[1] = hsv[1] * saturationMultiplier;
          const rgb = convert.hsv.rgb(hsv);
          return [...rgb, alpha];
        }
      }

      if (feature.properties.avg_mph) {
        // LEGACY: support speedmaps testing
        const rgba = speedFeatureColor(feature, rgbaColorMap);
        return [...rgba.slice(0, -1), alpha];
      }

      return [100, 100, 100, 127];
    }

    const DEFAULT_TOOLTIP_STYLE = {
          backgroundColor: "white",
          borderRadius: '.25rem',
          boxShadow: "0 0 0 1px rgb(0 0 0 / 10%), .75em .75em .75em -.75em rgb(0 0 0 / 30%)",
          color: "black",
          fontSize: '1.2em',
      };

    /**
     *
     * @param feature
     * @param layer: Layer
     * @returns {{html: string, style: {boxShadow: string, backgroundColor: string, borderRadius: string, color: string, fontSize: string}}}
     */
    function getTooltip(feature, layer) {
      const html = feature.properties.tooltip ? feature.properties.tooltip.html : null;
      const style = feature.properties.tooltip ? (feature.properties.tooltip.style || DEFAULT_TOOLTIP_STYLE) : DEFAULT_TOOLTIP_STYLE;

      if (html) {
        return {
          html: html,
          style: style,
        }
      }

      const layerType = layer.props.type;

      // TODO: this should probably be a map of functions?
      if (layerType === "new_speedmap") {
        const { tooltip_speed_key } = layer.props;
        const { stop_pair_name, segment_id, route_short_name, route_id, avg_mph, trips_hr_sch, shape_id } = feature.properties;

        let speed = avg_mph;

        if (tooltip_speed_key && feature.properties[tooltip_speed_key]) {
          speed = feature.properties[tooltip_speed_key];
          console.log(speed);
        }

        let display_pair_name = stop_pair_name.replace("__", " &#8594 ");
        let segment_postfix = segment_id.charAt(segment_id.length - 1);

        let segment_type = "Stop to Stop";

        if (segment_postfix !== "1") {
          segment_type = "Interpolated";
          console.log(segment_type);
        }

        return {
          html: `
            <h2 class="has-text-weight-bold has-text-teal-bold">
              ${display_pair_name ?? 'Non-stop segment'}
              <span class="tag ml-2">
                <i class="fas fa-circle mr-2" style="color: rgb(${getColor(feature)})"></i>
                ${speed}&nbsp;
                <span class="has-text-weight-normal">mph</span>
              </span>
            </h2>

            <ul class="tooltip-meta-list has-text-slate-bold">
              <li class="tooltip-meta-item">
                <div class="tooltip-meta-key">Route</div>
                <div class="tooltip-meta-value">${route_short_name ?? '\u2014'}</div>
              </li>
              <li class="tooltip-meta-item">
                <div class="tooltip-meta-key">Segment ID</div>
                <div class="tooltip-meta-value">${segment_id ?? '\u2014'}</div>
              </li>
              <li class="tooltip-meta-item">
                <div class="tooltip-meta-key">Route ID</div>
                <div class="tooltip-meta-value">${route_id ?? '\u2014'}</div>
              </li>
              <li class="tooltip-meta-item">
                <div class="tooltip-meta-key">Trips/Hour</div>
                <div class="tooltip-meta-value">${trips_hr_sch ?? '\u2014'}</div>
              </li>
              <li class="tooltip-meta-item">
                <div class="tooltip-meta-key">GTFS Shape ID</div>
                <div class="tooltip-meta-value">${shape_id ?? '\u2014'}</div>
              </li>
              <li class="tooltip-meta-item">
                <div class="tooltip-meta-key">Segment Type</div>
                <div class="tooltip-meta-value">${segment_type ?? '\u2014'}</div>
              </li>
            </ul>
          `,
          style: style,
        }
      }

      if (layerType === "new_speed_variation") {
        const { tooltip_speed_key } = layer.props;
        const { stop_pair_name, segment_id, route_short_name, route_id, p20_mph, p80_mph, avg_mph, fast_slow_ratio, trips_hr_sch, shape_id } = feature.properties;

        let speed = avg_mph;

        if (tooltip_speed_key && feature.properties[tooltip_speed_key]) {
          speed = feature.properties[tooltip_speed_key];
          console.log(speed);
        }

        let display_pair_name = stop_pair_name.replace("__", " &#8594 ");
        let segment_postfix = segment_id.charAt(segment_id.length - 1);

        let segment_type = "Stop to Stop";

        if (segment_postfix !== "1") {
          segment_type = "Interpolated";
          console.log(segment_type);
        }

        return {
          html: `
            <h2 class="has-text-weight-bold has-text-teal-bold">
              ${display_pair_name ?? 'Non-stop segment'}
              <span class="tag ml-2">
                <i class="fas fa-circle mr-2" style="color: rgb(${getColor(feature)})"></i>
                <span class="has-text-weight-normal"><sup>p80</sup> &#8260; <sub>p20</sub> </span>
                &nbsp;${fast_slow_ratio}
              </span>
            </h2>

            <ul class="tooltip-meta-list has-text-slate-bold">
              <li class="tooltip-meta-item">
                <div class="tooltip-meta-key"><sup>p80</sup> &#8260; <sub>p20</sub></div>
                <div class="tooltip-meta-value"><sup>${p80_mph} mph</sup> &#8260; <sub>${p20_mph} mph</sub></div>
              </li>
              <li class="tooltip-meta-item">
                <div class="tooltip-meta-key">Route</div>
                <div class="tooltip-meta-value">${route_short_name ?? '\u2014'}</div>
              </li>
              <li class="tooltip-meta-item">
                <div class="tooltip-meta-key">Segment ID</div>
                <div class="tooltip-meta-value">${segment_id ?? '\u2014'}</div>
              </li>
              <li class="tooltip-meta-item">
                <div class="tooltip-meta-key">Route ID</div>
                <div class="tooltip-meta-value">${route_id ?? '\u2014'}</div>
              </li>
              <li class="tooltip-meta-item">
                <div class="tooltip-meta-key">Trips/Hour</div>
                <div class="tooltip-meta-value">${trips_hr_sch ?? '\u2014'}</div>
              </li>
              <li class="tooltip-meta-item">
                <div class="tooltip-meta-key">GTFS Shape ID</div>
                <div class="tooltip-meta-value">${shape_id ?? '\u2014'}</div>
              </li>
              <li class="tooltip-meta-item">
                <div class="tooltip-meta-key">Segment Type</div>
                <div class="tooltip-meta-value">${segment_type ?? '\u2014'}</div>
              </li>
            </ul>
          `,
          style: style,
        }
      }

      if (layerType === "speedmap") {
        const { tooltip_speed_key } = layer.props;
        const { stop_name, stop_id, route_short_name, route_id, avg_mph, trips_per_hour, shape_id, stop_sequence } = feature.properties;

        let speed = avg_mph;

        if (tooltip_speed_key && feature.properties[tooltip_speed_key]) {
          speed = feature.properties[tooltip_speed_key];
          console.log(speed);
        }

        return {
          html: `
            <h2 class="has-text-weight-bold has-text-teal-bold">
              ${stop_name ?? 'Non-stop segment'}
              <span class="tag ml-2">
                <i class="fas fa-circle mr-2" style="color: rgb(${getColor(feature)})"></i>
                ${speed}&nbsp;
                <span class="has-text-weight-normal">mph</span>
              </span>
            </h2>

            <ul class="tooltip-meta-list has-text-slate-bold">
              <li class="tooltip-meta-item">
                <div class="tooltip-meta-key">Route</div>
                <div class="tooltip-meta-value">${route_short_name ?? '\u2014'}</div>
              </li>
              <li class="tooltip-meta-item">
                <div class="tooltip-meta-key">Stop ID</div>
                <div class="tooltip-meta-value">${stop_id ?? '\u2014'}</div>
              </li>
              <li class="tooltip-meta-item">
                <div class="tooltip-meta-key">Route ID</div>
                <div class="tooltip-meta-value">${route_id ?? '\u2014'}</div>
              </li>
              <li class="tooltip-meta-item">
                <div class="tooltip-meta-key">Trips/Hour</div>
                <div class="tooltip-meta-value">${trips_per_hour ?? '\u2014'}</div>
              </li>
              <li class="tooltip-meta-item">
                <div class="tooltip-meta-key">GTFS Shape ID</div>
                <div class="tooltip-meta-value">${shape_id ?? '\u2014'}</div>
              </li>
              <li class="tooltip-meta-item">
                <div class="tooltip-meta-key">GTFS Stop Sequence</div>
                <div class="tooltip-meta-value">${stop_sequence ?? '\u2014'}</div>
              </li>
            </ul>
          `,
          style: style,
        }
      }

      if (layerType === "speed_variation") {
        const { stop_name, stop_id, route_short_name, route_id, fast_slow_ratio, p20_mph, p80_mph, trips_per_hour, shape_id, stop_sequence} = feature.properties;

        return {
          html: `
            <h2 class="has-text-weight-bold has-text-teal-bold">
              ${stop_name ?? 'Non-stop segment'}
              <span class="tag ml-2">
                <i class="fas fa-circle mr-2" style="color: rgb(${getColor(feature)})"></i>
                <span class="has-text-weight-normal"><sup>p80</sup> &#8260; <sub>p20</sub> </span>
                &nbsp;${fast_slow_ratio}
              </span>
            </h2>

            <ul class="tooltip-meta-list has-text-slate-bold">
              <li class="tooltip-meta-item">
                <div class="tooltip-meta-key"><sup>p80</sup> &#8260; <sub>p20</sub></div>
                <div class="tooltip-meta-value"><sup>${p80_mph} mph</sup> &#8260; <sub>${p20_mph} mph</sub></div>
              </li>
              <li class="tooltip-meta-item">
                <div class="tooltip-meta-key">Route</div>
                <div class="tooltip-meta-value">${route_short_name ?? '\u2014'}</div>
              </li>
              <li class="tooltip-meta-item">
                <div class="tooltip-meta-key">Stop ID</div>
                <div class="tooltip-meta-value">${stop_id ?? '\u2014'}</div>
              </li>
              <li class="tooltip-meta-item">
                <div class="tooltip-meta-key">Route ID</div>
                <div class="tooltip-meta-value">${route_id ?? '\u2014'}</div>
              </li>
              <li class="tooltip-meta-item">
                <div class="tooltip-meta-key">Trips/Hour</div>
                <div class="tooltip-meta-value">${trips_per_hour ?? '\u2014'}</div>
              </li>
              <li class="tooltip-meta-item">
                <div class="tooltip-meta-key">GTFS Shape ID</div>
                <div class="tooltip-meta-value">${shape_id ?? '\u2014'}</div>
              </li>
              <li class="tooltip-meta-item">
                <div class="tooltip-meta-key">GTFS Stop Sequence</div>
                <div class="tooltip-meta-value">${stop_sequence ?? '\u2014'}</div>
              </li>
            </ul>`,
          style: style,
        }
      }

      if (layerType === "state_highway_network") {
        const { Route, County, District, RouteType } = feature.properties;

        const routeLabel = (RouteType === "Interstate") ? `${RouteType} ${Route}` : `${RouteType} Route ${Route}`;

        return {
          html: `
            <div class="has-text-weight-bold has-text-teal-bold">${routeLabel}</div>
            <div class="has-text-slate-bold">${County} County, District ${District}</div>`,
          style: style,
        }
      }

      // just try to render properties as key-value mapping
      const lines = Object.entries(feature.properties).map(([key, value], idx) => {
        return `<li class="tooltip-meta-item">
          <div class="tooltip-meta-key">${titleCase(key.replaceAll("_", " "))}</div>
          <div class="tooltip-meta-value">${value}</div>
        </li>`;
      });
      return {
        html: `
              <ul class="tooltip-meta-list has-text-slate-bold">
              ${lines.join("")}
              </ul>
        `,
        style: style,
      }
    }

    /**
   * @param {Layer[]} layers
   */
    function createLeafletLayer(layers) {
        if (layers[0].url.endsWith(".pmtiles")) {
            console.error("PMTiles not officially supported yet.");
            outerLayer = leafletLayer({
                url: url,
                paint_rules: [
                  {
                      dataLayer: layer.name,
                      symbolizer: new LineSymbolizer({
                          // https://gist.github.com/makella/950a7baee78157bf1c315a7c2ea191e7
                          color: (p) => {
                              return "black"
                          }
                      })
                  }
              ],
            }).addTo(map);
            loading = false;
        } else {
            // NOTE: Most interaction callbacks use https://deck.gl/docs/developer-guide/interactivity#the-picking-info-object
            console.log("Creating layers.");
            outerLayer = new LeafletLayer({
                views: [
                    new MapView({
                        repeat: true
                    })
                ],
                layers: state.layers.map((layer, idx) => {
                  // deckgl saves all unknown properties on layer.props
                  // so we can just stick the type here
                  const layerProperties = {
                    type: layer.type,
                    ...(layer.properties || {})
                  };
                  map.fire("dataloading");
                  return new GeoJsonLayer({
                    id: layer.name,
                    data: fetchGeoJSON(layer.url),
                    pickable: true,
                    autoHighlight: true,
                    getPointRadius: 12,
                    pointRadiusUnits: "pixels", // point radius is less zoom dependendent
                    pointRadiusScale: 0.3, //slows growth of points when zooming out
                    getLineWidth: 3,
                    lineWidthUnits: "pixels",
                    ...layerProperties,
                    getFillColor: (feature) => getColor(feature, layer, 1, 200),
                    getLineColor: (feature) => getColor(feature, layer, 1, 200),
                    highlightColor: ({ object, layer }) => getColor(object, layer, layerProperties.highlight_saturation_multiplier || 0.7),
                    onDataLoad: (data) => {
                      console.log("Finished loading", layer);
                      map.fire("dataload");

                      if (idx === state.layers.length - 1) {
                        if (state.bbox) {
                          console.log("flyToBounds", state.bbox);
                          map.flyToBounds(state.bbox, {maxZoom: 20});
                        } else if (state.lat_lon) {
                          const zoom = state.zoom ? state.zoom : 13;
                          console.log("flyTo", state.lat_lon, zoom);
                          map.flyTo(state.lat_lon, zoom);
                        } else {
                          const bbox = turf.bbox(data);
                          // have to flip; turf gives us back lon/lat
                          // leaflet always wants [lat, lng]
                          const latLngLike = [[bbox[1], bbox[0]], [bbox[3], bbox[2]]];
                          console.log("flyToBounds", latLngLike);
                          map.flyToBounds(latLngLike, {maxZoom: 20});
                        }
                      }

                    },
                  });
                }),
                // onHover: ({ object }) => object && console.log(object),
                getTooltip: ({ object, layer }) => object && getTooltip(object, layer),
            });
            map.addLayer(outerLayer);
            loading = false;
        }
    }

    onMount(async () => {
        let encoded = $page.url.searchParams.get(STATE_QUERY_PARAM);

        if (!encoded) {
            return
        }

        // inspired by https://www.scottantipa.com/store-app-state-in-urls

        try {
          // this library handles base64url
          state = JSON.parse(Base64.decode(encoded));
          console.log("Loaded uncompressed state from URL.");
        } catch (error) {
          console.log("Failed to parse state, checking if compressed.");
          state = JSON.parse(strFromU8(decompressSync(Base64.toUint8Array(encoded))));
          console.log("Loaded compressed state from URL.");
        }

        map = L.map(mapElement, {
          preferCanvas: true,
          loadingControl: true,
        }).setView(START_LAT_LON, LEAFLET_START_ZOOM);

        const basemapConfig = state.basemap_config || DEFAULT_BASEMAP_CONFIG;
        L.tileLayer(basemapConfig.url, basemapConfig.options).addTo(map);

        L.control.scale().addTo(map);

        createLeafletLayer(state.layers);

        if (state.legend_url) {
          console.log("Adding legend to map", state.legend_url);
          let legend = L.control({position: "topright"});
          legend.onAdd = function (map) {
            this._div = L.DomUtil.create('div', 'legend');
            return this._div;
          };
          fetch(state.legend_url).then((resp) => resp.text().then((data) => {
            legend._div.innerHTML = data;
          }));
          legend.addTo(map);
        }

    });

    onDestroy(async () => {
        if (map) {
            console.log('Unloading map.');
            map.remove();
        }
    });
</script>

<style>
    @import "leaflet-loading/src/Control.Loading.css";
    @import 'leaflet/dist/leaflet.css';

    .navbar {
      box-shadow: 0 0 1em rgba(0, 0, 0, .2);
      z-index: 999;
    }

    #map {
      height: 550px;
    }



    /* Use :global to prevent namespacing of CSS for elements that are created dynamically */
    /* TODO: maybe we can define some of these things up front? For example create the legend div in HTML. */
    :global(.tooltip-meta-list) {
      display: flex;
      line-height: calc(4 / 3);
      list-style: none;
      margin: 0;
      padding: 0;
    }

    :global(.tooltip-meta-item + .tooltip-meta-item) {
      border-left: 1px solid #eee;
      margin-left: .5rem;
      padding-left: .5rem;
    }

    :global(.tooltip-meta-key) {
      color: #aaa;
      font-size: smaller;
    }

    :global(.maplibregl-popup) {
        max-width: 400px;
        font: 12px/20px 'Helvetica Neue', Arial, Helvetica, sans-serif;
    }

    :global(.legend > svg) {
      height: auto;
      max-width: 512px;
    }

    :global(.legend) {
      padding: 6px 8px;
      font: 14px/16px Arial, Helvetica, sans-serif;
      background: white;
      background: rgba(255,255,255,0.8);
      box-shadow: 0 0 15px rgba(0,0,0,0.2);
      border-radius: 5px;
  }

  :global(.legend h4) {
      margin: 0 0 5px;
      color: #777;
  }
</style>

<link rel="stylesheet" href="https://unpkg.com/leaflet@1.6.0/dist/leaflet.css"
      integrity="sha512-xwE/Az9zrjBIphAcBb3F6JVqxf46+CDLwfLMHloNu6KEQCAWi6HcDUbeOfBIptF7tcCzusKFjFw2yuvEpDL9wQ=="
      crossorigin=""/>
<nav class="navbar" aria-label="main navigation">
  <div class="navbar-brand">
    <a class="navbar-item" href="https://www.calitp.org/">
      <img src="https://reports.calitp.org/images/calitp-logo.svg" alt="Cal-ITP logo">
    </a>
    <button class="button navbar-burger">
      <span></span>
      <span></span>
      <span></span>
    </button>
  </div>

  <div class="navbar-menu">
    <div class="navbar-start">
      <div class="navbar-item has-text-teal-bold">
        {#if loading}
          <div class="icon-text">
            <span class="icon">
              <i class="fas fa-circle-notch fa-spin"></i>
            </span>
            <span>Loading&hellip;</span>
          </div>
        {:else if (state)}
          <h1 class="has-text-weight-bold">{state.layers.slice(-1)[0].name}</h1>
        {:else}
          No state found in URL
        {/if}
      </div>
      {#if (state)}
        <a class="navbar-item has-text-teal-bold" href="{state.layers.slice(-1)[0].url}">
          <div class="icon-text">
            <span class="icon">
              <i class="fas fa-file-arrow-down"></i>
            </span>
            <span>Download GeoJSON</span>
          </div>
        </a>
      {/if}
    </div>
  </div>
</nav>

<div id="map" class="map" bind:this={mapElement}></div>

<footer>
  <div class="content has-text-centered p-2">
    <p>
      &copy; Cal-ITP {new Date().getFullYear()}. All rights reserved.
    </p>
  </div>
</footer>
