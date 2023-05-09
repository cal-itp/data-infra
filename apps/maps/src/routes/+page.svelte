<!-- from https://dev.to/khromov/using-leaflet-with-sveltekit-3jn1 -->
<script>
    import {onMount, onDestroy} from 'svelte';
    import L from 'leaflet';
    import colormap from 'colormap';
    import {leafletLayer, LineSymbolizer} from 'protomaps';
    import {inflate} from 'pako';
    import {strFromU8, decompress} from 'fflate';
    import M from 'maplibre-gl';

    const USE_LEAFLET = true;
    const SOURCE = "https://storage.googleapis.com/calitp-map-tiles/metro_am.geojson.gz";
    const START_LAT_LON = [34, -118];
    let mapElement;
    let map;
    let jsonData;
    let selected;
    let options = [];
    let leafletGeoJSONLayer;

    const NSHADES = 10;
    const MAX_MPH = 50;

    let colorMap = colormap({
        colormap: 'RdBu',
        nshades: NSHADES,
        format: 'hex',
        alpha: 0.8,
    }).reverse();

    function speedFeatureColor(feature) {
        let avg_mph = feature.properties.avg_mph;

        if (avg_mph > MAX_MPH) {
            avg_mph = MAX_MPH;
        }
        let idx = Math.floor(avg_mph / (MAX_MPH / NSHADES));
        return colorMap[idx];
    }

    function speedFeatureHTML(feature) {
        return [
            `Stop name: ${feature.properties.stop_name}`,
            `Stop ID: ${feature.properties.stop_id}`,
            `Route ID: ${feature.properties.route_id}`,
            `Average MPH: ${feature.properties.avg_mph}`,
        ].join("<br>");
    }

    async function updateMap() {
        console.log(selected);
        if (!selected.url) {
            leafletGeoJSONLayer.clearLayers();
            return
        }
            const url = selected.url;
            fetch(url).then((response) => {
                if (response.headers.get("content-type") === "application/x-gzip") {
                    console.log("decompressing gzipped data");
                    response.arrayBuffer().then((raw) => {
                        // const json = JSON.parse(inflate(raw, {to: 'string'}));
                        // leafletGeoJSONLayer.addData(json);
                        decompress(new Uint8Array(raw), (err, data) => {
                                if (err) {
                                    console.error(err);
                                } else {
                                    leafletGeoJSONLayer.addData(JSON.parse(strFromU8(data)));
                                }
                            }
                        )
                    });
                } else {
                    jsonData = response.json().then((json) => {
                        leafletGeoJSONLayer.addData(json);
                    });
                }
            })
    }

    onMount(async () => {
        console.log("Loading map.");

        if (USE_LEAFLET) {
            map = L.map(mapElement).setView(START_LAT_LON, 11);

            // let PAINT_RULES = [
            //     {
            //         dataLayer: "Shapes_Arrays",
            //         symbolizer: new LineSymbolizer({"color": "black"})
            //     }
            // ];

            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
            }).addTo(map);


            // leafletLayer({
            //     url: "https://storage.googleapis.com/calitp-map-tiles/shapes.pmtiles",
            //     paint_rules: PAINT_RULES,
            // label_rules: LABEL_RULES
            // }).addTo(map)
            // const max = Math.max(...jsonData.features.map(feature => feature.properties.avg_mph));
            // const min = Math.min(...jsonData.features.map(feature => feature.properties.avg_mph));

            leafletGeoJSONLayer = L.geoJSON(false, {
                style: (feature) => {
                    return {
                        color: speedFeatureColor(feature),
                        opacity: 0.8,
                    }
                },
                onEachFeature: (feature, layer) => {
                    if (feature.properties) {
                        layer.bindTooltip(speedFeatureHTML(feature));
                    }
                }
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
                    feature.properties.color = speedFeatureColor(feature);
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

    body {
        margin: 0;
        padding: 0;
    }

    #map {
        height: 800px;
        /*position: absolute;*/
        /*top: 0;*/
        /*bottom: 0;*/
        width: 100%;
    }

    :global(.maplibregl-popup) {
        max-width: 400px;
        font: 12px/20px 'Helvetica Neue', Arial, Helvetica, sans-serif;
    }
</style>

<!--<script src="https://unpkg.com/protomaps@1.22.0/dist/protomaps.min.js"></script>-->
<!--<link rel="stylesheet" href="https://unpkg.com/leaflet@1.6.0/dist/leaflet.css"-->
<!--      integrity="sha512-xwE/Az9zrjBIphAcBb3F6JVqxf46+CDLwfLMHloNu6KEQCAWi6HcDUbeOfBIptF7tcCzusKFjFw2yuvEpDL9wQ=="-->
<!--      crossorigin=""/>-->
<select bind:value={selected} on:change="{updateMap}">
    {#each options as option}
        <option value={option}>
            {option.name}
        </option>
    {/each}
</select>
<div id="map" class="map" bind:this={mapElement}></div>
