<!-- from https://dev.to/khromov/using-leaflet-with-sveltekit-3jn1 -->
<script>
    import {onMount, onDestroy} from 'svelte';
    import L from 'leaflet';
    import colormap from 'colormap';
    import {leafletLayer, LineSymbolizer} from 'protomaps';
    import {strFromU8, decompress} from 'fflate';
    import M from 'maplibre-gl';
    import {LeafletLayer} from 'deck.gl-leaflet';
    import {MapView} from '@deck.gl/core';
    import {GeoJsonLayer} from '@deck.gl/layers';
    import '@fortawesome/fontawesome-free/css/all.css'
    import { dev } from '$app/environment';

    const USE_LEAFLET = true;
    const USE_LEAFLET_DECKGL = true;
    const SOURCE = "https://storage.googleapis.com/calitp-map-tiles/metro_am.geojson.gz";
    const START_LAT_LON = [34, -118];
    let mapElement;
    let map;
    let jsonData;
    let selected;
    let options = [];
    let layer;
    let loading = false;

    const NSHADES = 10;
    const MAX_MPH = 50;

    const hexColorMap = colormap({
        colormap: 'RdBu',
        nshades: NSHADES,
        format: 'hex',
    }).reverse();

    const rgbaColorMap = colormap({
        colormap: 'RdBu',
        nshades: NSHADES,
        format: 'rgba',
    }).reverse();

    let PAINT_RULES = [
        {
            dataLayer: "BusSpeeds",
            symbolizer: new LineSymbolizer({
                // https://gist.github.com/makella/950a7baee78157bf1c315a7c2ea191e7
                color: (p) => {
                    return "black"
                }
            })
        }
    ];

    function speedFeatureColor(feature, colorMap) {
        let avg_mph = feature.properties.avg_mph;

        if (avg_mph > MAX_MPH) {
          return colorMap[colorMap.length - 1];
        }

        return colorMap[Math.floor(avg_mph / (MAX_MPH / NSHADES))];
    }

    function speedFeatureHTML(feature) {
        return [
            `Stop name: ${feature.properties.stop_name}`,
            `Stop ID: ${feature.properties.stop_id}`,
            `Route ID: ${feature.properties.route_id}`,
            `Average MPH: ${feature.properties.avg_mph}`,
        ].join("<br>");
    }

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

    async function updateMap() {
        console.log(selected);
        if (layer) {
            map.removeLayer(layer);
            layer = null;
        }

        if (!selected.url) {
            return
        }

        loading = true;
        const url = selected.url;

        if (url.endsWith(".pmtiles")) {
            layer = leafletLayer({
                url: url,
                paint_rules: PAINT_RULES,
            }).addTo(map);
            loading = false;
        } else if (USE_LEAFLET_DECKGL) {
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
                            // id: ,
                            data: json,
                            pickable: true,
                            autoHighlight: true,
                            highlightColor: ({ object }) => {
                                const rgba = speedFeatureColor(object, rgbaColorMap);
                                const converted = rgba.slice(0, -1);
                                // have to convert from 0-1 alpha to 0-255
                                converted.push(rgba[3] * 255);
                                return converted;
                            },
                            getFillColor: (feature) => {
                              if (feature) {
                                const rgba = speedFeatureColor(feature, rgbaColorMap);
                                const converted = rgba.slice(0, -1);
                                converted.push(rgba[3] * 127);
                                return converted;
                              }
                            },
                        }),
                    ],
                    // these have to be called object if destructured like this
                    // onHover: ({ object }) => object && console.log(object),
                    getTooltip: ({ object }) => object && {
                      html: speedFeatureHTML(object),
                      style: {
                        backgroundColor: "white",
                        color: "black",
                        fontSize: '1.2em',
                      }
                    },
                });
                map.addLayer(layer);
                loading = false;
            })
        } else {
            layer = L.geoJSON(false, {
                style: (feature) => {
                    return {
                        color: speedFeatureColor(feature, hexColorMap),
                        opacity: 0.8,
                    }
                },
                onEachFeature: (feature, layer) => {
                    if (feature.properties) {
                        layer.bindTooltip(speedFeatureHTML(feature));
                    }
                }
            }).addTo(map);
            fetchGeoJSON(url, (json) => {
                layer.addData(json);
                loading = false;
            });
        }
    }

    onMount(async () => {
        console.log("Loading map.");

        if (USE_LEAFLET) {
            map = L.map(mapElement, {
                preferCanvas: true
            }).setView(START_LAT_LON, 11);

            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
            }).addTo(map);
        } else {
            map = new M.Map({
                container: 'map',
                style: 'https://api.maptiler.com/maps/streets/style.json?key=get_your_own_OpIi9ZULNHzrESv6T2vL',
                // style: 'https://openmaptiles.github.io/osm-bright-gl-style/style-cdn.json',
                // style: {
                //     'version': 8,
                //     'sources': {
                //         'raster-tiles': {
                //             'type': 'raster',
                //             'tiles': [
                //                 'https://stamen-tiles.a.ssl.fastly.net/watercolor/{z}/{x}/{y}.jpg'
                //             ],
                //             'tileSize': 256,
                //             'attribution':
                //                 'Map tiles by <a target="_top" rel="noopener" href="http://stamen.com">Stamen Design</a>, under <a target="_top" rel="noopener" href="http://creativecommons.org/licenses/by/3.0">CC BY 3.0</a>. Data by <a target="_top" rel="noopener" href="http://openstreetmap.org">OpenStreetMap</a>, under <a target="_top" rel="noopener" href="http://creativecommons.org/licenses/by-sa/3.0">CC BY SA</a>'
                //         }
                //     },
                //     'layers': [
                //         {
                //             'id': 'simple-tiles',
                //             'type': 'raster',
                //             'source': 'raster-tiles',
                //             'minzoom': 0,
                //             'maxzoom': 22
                //         }
                //     ]
                // },
                center: START_LAT_LON.toReversed(),
                zoom: 9
            });

            if (jsonData) {
                // https://maplibre.org/maplibre-gl-js-docs/example/data-driven-lines/
                jsonData.features.forEach((feature) => {
                    feature.properties.color = speedFeatureColor(feature, hexColorMap);
                });

                map.on('load', () => {
                    map.addSource(SOURCE, {
                        'type': 'geojson',
                        'data': jsonData // this could be a URL if we had the color in properties already
                    });
                    map.addLayer({
                        'id': 'speeds',
                        'type': 'fill',
                        'source': SOURCE,
                        'paint': {
                            'fill-color': ['get', 'color'],
                            'fill-opacity': 0.4
                        },
                        'filter': ['==', '$type', 'Polygon']
                    });
                });

                // https://maplibre.org/maplibre-gl-js-docs/example/popup-on-hover/
                // Create a popup, but don't add it to the map yet.
                // let popup = new M.Popup({
                //     closeButton: false,
                //     closeOnClick: false
                // });
                //
                // map.on('mouseenter', 'speeds', function (e) {
                //     // Change the cursor style as a UI indicator.
                //     map.getCanvas().style.cursor = 'pointer';
                //
                //     // TODO: figure out what's going on here
                //     let coordinates = e.features[0].geometry.coordinates.slice()[0][0];
                //     console.log(coordinates);
                //
                //     // Ensure that if the map is zoomed out such that multiple
                //     // copies of the feature are visible, the popup appears
                //     // over the copy being pointed to.
                //     while (Math.abs(e.lngLat.lng - coordinates[0]) > 180) {
                //         coordinates[0] += e.lngLat.lng > coordinates[0] ? 360 : -360;
                //     }
                //
                //     // Populate the popup and set its coordinates
                //     // based on the feature found.
                //     // popup.setLngLat(coordinates).setHTML(speedFeatureHTML(e.features[0])).addTo(map);
                //     console.log(e.lngLat);
                //     popup.setLngLat(e.lngLat).setHTML("test test 123").addTo(map);
                //     console.log(popup);
                // });
                //
                // map.on('mouseleave', 'speeds', function () {
                //     map.getCanvas().style.cursor = '';
                //     popup.remove();
                // });

                // https://maplibre.org/maplibre-gl-js-docs/example/polygon-popup-on-click/
                // When a click event occurs on a feature in the states layer, open a popup at the
                // location of the click, with description HTML from its properties.
                map.on('click', 'speeds', function (e) {
                    new M.Popup()
                        .setLngLat(e.lngLat)
                        .setHTML(e.features[0].properties.stop_name)
                        .addTo(map);
                });

                // Change the cursor to a pointer when the mouse is over the states layer.
                map.on('mouseenter', 'speeds', function () {
                    map.getCanvas().style.cursor = 'pointer';
                });

                // Change it back to a pointer when it leaves.
                map.on('mouseleave', 'speeds', function () {
                    map.getCanvas().style.cursor = '';
                });
            }
        }

        console.log("Loading layer options.");
        const layersResponse = await fetch("layers.json");
        const json = await layersResponse.json();
        options = [{"name": "", "url": ""}].concat(json);
        if (dev) {
          selected = options[2];
          await updateMap();
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
    <div class="navbar-item">
      California Transit Speed Maps
    </div>
    <button class="button navbar-burger">
      <span></span>
      <span></span>
      <span></span>
    </button>
  </div>

  <div class="navbar-menu">
    <div class="navbar-start">
      <div class="navbar-item">
        <label for="select">Select data:</label>
      </div>
      <div class="navbar-item">
        <div class="select">
          <select id="select" bind:value={selected} on:change="{updateMap}">
            {#each options as option}
              <option value={option}>
                {option.name}
              </option>
            {/each}
          </select>
        </div>
      </div>
      <div class="navbar-item">
        {#if loading}
          <div class="icon-text">
            <span class="icon">
              <i class="fas fa-circle-notch fa-spin"></i>
            </span>
            <span>Loading...</span>
          </div>
        {:else if (selected && selected.url)}
          <span>Viewing {selected.url}</span>
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
