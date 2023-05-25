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

    const STATE_QUERY_PARAM = "state";
    const START_LAT_LON = [34.05, -118.25];
    const LEAFLET_START_ZOOM = 13;
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

    const alphaBase = 255;

    function getColor(feature, alphaMultiplier = 1) {
      let color = [100, 100, 100]; // if no color, just return grey

      if (feature.properties.color) {
        color = [...feature.properties.color];
      } else if (feature.properties.avg_mph) {
        // LEGACY: support speedmaps testing
        const rgba = speedFeatureColor(feature, rgbaColorMap);
        color = rgba.slice(0, -1);
      }

      color.push(Math.floor(alphaBase * alphaMultiplier));
      return color;
    }

    const DEFAULT_TOOLTIP_STYLE = {
          backgroundColor: "white",
          color: "black",
          fontSize: '1.2em',
      };

    function getTooltip(feature) {
      if (feature.properties.tooltip) {
        return {
          html: feature.properties.tooltip.html,
          style: feature.properties.tooltip.style || DEFAULT_TOOLTIP_STYLE,
        }
      }

      if (feature.properties.hqta_type) {
        let lines = [
          `Agency (Primary): ${feature.properties.agency_name_primary}`,
          `Agency (Secondary): ${feature.properties.agency_name_secondary}`,
          `HQTA Type: ${feature.properties.hqta_type}`,
        ];
        if (feature.properties.stop_id) {
          lines.push(`Stop ID: ${feature.properties.stop_id}`);
        }

        return {
          html: lines.join("<br>"),
          style: DEFAULT_TOOLTIP_STYLE,
        }
      }

      return {
        html: JSON.stringify(feature.properties),
        style: DEFAULT_TOOLTIP_STYLE,
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
            // NOTE: When defining interaction callbacks, I think they use https://deck.gl/docs/developer-guide/interactivity#the-picking-info-object
            console.log("Creating layers.");
            outerLayer = new LeafletLayer({
                views: [
                    new MapView({
                        repeat: true
                    })
                ],
                layers: state.layers.map((layer, idx) => {
                  const layerProperties = layer.properties || {};
                  return new GeoJsonLayer({
                    id: layer.name,
                    data: fetchGeoJSON(layer.url),
                    pickable: true,
                    autoHighlight: true,
                    getPointRadius: 10,
                    ...layerProperties,
                    getFillColor: (feature) => getColor(feature, 0.5),
                    highlightColor: ({object}) => getColor(object),
                    onDataLoad: (data) => {
                      console.log("Finished loading", layer);

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
                // these have to be called object if destructured like this
                // onHover: ({ object }) => object && console.log(object),
                getTooltip: ({ object }) => object && getTooltip(object),
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
            preferCanvas: true
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
    @import 'leaflet/dist/leaflet.css';

    #map {
        margin: 10px;
        height: 800px;
    }

    /* Use :global to prevent namespacing of CSS for elements that are created dynamically */
    /* TODO: maybe we can define some of these things up front? For example create the legend div in HTML. */
    :global(.maplibregl-popup) {
        max-width: 400px;
        font: 12px/20px 'Helvetica Neue', Arial, Helvetica, sans-serif;
    }

    :global(.legend > svg) {
      height: auto;
      width: 128px;
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
<nav class="navbar" role="navigation" aria-label="main navigation">
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
      <div class="navbar-item">
        {#if loading}
          <div class="icon-text">
            <span class="icon">
              <i class="fas fa-circle-notch fa-spin"></i>
            </span>
            <span>Loading...</span>
          </div>
        {:else if (state)}
          <span>{state.layers.slice(-1)[0].name} (<a href="{state.layers.slice(-1)[0].url}">download GeoJSON</a>)</span>
        {:else}
          <span>No state found in URL.</span>
        {/if}
      </div>
    </div>
  </div>
</nav>

<div id="map" class="map" bind:this={mapElement}></div>

<footer>
  <div class="content has-text-centered">
    <p>
      &copy; Cal-ITP 2023. All rights reserved.
    </p>
  </div>
</footer>
