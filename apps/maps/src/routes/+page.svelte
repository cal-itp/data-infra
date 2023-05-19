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
    let mapElement;
    let map;
    let jsonData;
    /** @type {State} */
    let state;
    let options = [];
    let layer;
    let loading = false;

    const NSHADES = 10;
    const MAX_MPH = 50;

    const rgbaColorMap = colormap({
        colormap: 'RdBu',
        nshades: NSHADES,
        format: 'rgba',
    }).reverse();

    function fetchGeoJSON(url, callback) {
        fetch(url).then((response) => {
            if (url.endsWith(".gz") || response.headers.get("content-type") === "application/x-gzip") {
                console.log("decompressing gzipped data");
                response.arrayBuffer().then((raw) => {
                    decompress(new Uint8Array(raw), (err, data) => {
                            if (err) {
                                console.error(err);
                            } else {
                                console.log("adding data to layer");
                                callback(JSON.parse(strFromU8(data)));
                            }
                        }
                    )
                });
            } else {
                jsonData = response.json().then((json) => {
                    console.log("adding data to layer");
                    callback(json);
                });
            }
        })
    }

    function speedFeatureColor(feature, colorMap) {
        let avg_mph = feature.properties.avg_mph;

        if (avg_mph > MAX_MPH) {
          return colorMap[colorMap.length - 1];
        }

        return colorMap[Math.floor(avg_mph / (MAX_MPH / NSHADES))];
    }

    function getColor(feature, colorMap, alpha = 255) {
        if (feature && feature.properties.avg_mph) {
          const rgba = speedFeatureColor(feature, rgbaColorMap);
          const converted = rgba.slice(0, -1);
          converted.push(alpha);
          return converted;
        }

        // everything but speedmaps
        return [93, 106, 166, alpha];
    }

    function getTooltip(feature) {
      let html;
      if (feature.properties.hqta_type) {
        let lines = [
            `Agency (Primary): ${feature.properties.agency_name_primary}`,
            `Agency (Secondary): ${feature.properties.agency_name_secondary}`,
            `HQTA Type: ${feature.properties.hqta_type}`,
        ];
        if (feature.properties.stop_id) {
          lines.push(`Stop ID: ${feature.properties.stop_id}`);
        }
          html = lines.join("<br>");
      } else {
        // hopefully a speedmap
        html = [
            `Stop name: ${feature.properties.stop_name}`,
            `Stop ID: ${feature.properties.stop_id}`,
            `Route ID: ${feature.properties.route_id}`,
            `Average MPH: ${feature.properties.avg_mph}`,
        ].join("<br>");
      }

      return {
        html: html,
        style: {
          backgroundColor: "white",
          color: "black",
          fontSize: '1.2em',
        }
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

        const url = state.url;

        map = L.map(mapElement, {
            preferCanvas: true
        }).setView(START_LAT_LON, LEAFLET_START_ZOOM);

        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        }).addTo(map);

        if (url.endsWith(".pmtiles")) {
            layer = leafletLayer({
                url: url,
                paint_rules: [
                  {
                      dataLayer: "BusSpeeds",
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
            fetchGeoJSON(url, (json) => {
                layer = new LeafletLayer({
                    views: [
                        new MapView({
                            repeat: true
                        })
                    ],
                    layers: [
                        new GeoJsonLayer({
                            id: "geojson",
                            data: json,
                            pickable: true,
                            autoHighlight: true,
                            getPointRadius: 10,
                            getFillColor: (feature) => getColor(feature, rgbaColorMap, 127),
                            highlightColor: ({ object }) => getColor(object, rgbaColorMap, 255),
                        }),
                    ],
                    // these have to be called object if destructured like this
                    // onHover: ({ object }) => object && console.log(object),
                    getTooltip: ({ object }) => object && getTooltip(object),
                });
                map.addLayer(layer);

                if (state.bbox) {
                  console.log("zooming to", state.bbox);
                  map.flyToBounds(state.bbox, {maxZoom: 20});
                } else if (state.lat_lon && state.zoom) {
                  console.log("zooming to", state.lat_lon, state.zoom);
                    map.flyTo(state.lat_lon, state.zoom);
                } else {
                  const bbox = turf.bbox(json);
                  // have to flip; turf gives us back lon/lat
                  // leaflet always wants [lat, lng]
                  const latLngLike = [[bbox[1], bbox[0]], [bbox[3], bbox[2]]];
                  console.log("zooming to", latLngLike);
                  map.flyToBounds(latLngLike, {maxZoom: 20});
                }
                loading = false;
            })
        }
    })
    ;

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

    :global(.maplibregl-popup) {
        max-width: 400px;
        font: 12px/20px 'Helvetica Neue', Arial, Helvetica, sans-serif;
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
          <span>{state.name} (<a href="{state.url}">download GeoJSON</a>)</span>
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
