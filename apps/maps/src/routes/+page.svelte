<!-- from https://dev.to/khromov/using-leaflet-with-sveltekit-3jn1 -->
<script>
    import {onMount, onDestroy} from 'svelte';
    import L from 'leaflet';
    import {leafletLayer, LineSymbolizer} from 'protomaps';
    import colormap from 'colormap';
    import {inflate} from 'pako';

    let mapElement;
    let map;

    onMount(async () => {
        console.log("loading map");
        map = L.map(mapElement).setView([34, -118], 13);

        let PAINT_RULES = [
            {
                dataLayer: "Shapes_Arrays",
                symbolizer: new LineSymbolizer({"color": "black"})
            }
        ];

        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        }).addTo(map);

        // leafletLayer({
        //     url: "https://storage.googleapis.com/calitp-map-tiles/shapes.pmtiles",
        //     paint_rules: PAINT_RULES,
        //     label_rules: LABEL_RULES
        // }).addTo(map)
        console.log("fetching data");
        // TODO: figure out getting the gzipped file
        const response = await fetch("https://storage.googleapis.com/calitp-map-tiles/metro_am.geojson")
        const jsonData = await response.json();
        // const max = Math.max(...jsonData.features.map(feature => feature.properties.avg_mph));
        // const min = Math.min(...jsonData.features.map(feature => feature.properties.avg_mph));

        const NSHADES = 10;
        const MAX_MPH = 50;

        let colorMap = colormap({
            colormap: 'RdBu',
            nshades: NSHADES,
            format: 'hex',
            alpha: 1,
        }).reverse();
        L.geoJson(jsonData, {
            style: (feature) => {
                let avg_mph = feature.properties.avg_mph;

                if (avg_mph > MAX_MPH) {
                    avg_mph = MAX_MPH;
                }
                let idx = Math.floor(avg_mph / (MAX_MPH / NSHADES));
                return {
                    color: colorMap[idx],
                }
            },
            onEachFeature: (feature, layer) => {
                if (feature.properties) {
                    const popupStr = [
                        `Stop name: ${feature.properties.stop_name}`,
                        `Stop ID: ${feature.properties.stop_id}`,
                        `Route ID: ${feature.properties.route_id}`,
                        `Average MPH: ${feature.properties.avg_mph}`,
                    ].join("<br>");
                    layer.bindPopup(popupStr);
                }
            }
        }).addTo(map);

    });

    onDestroy(async () => {
        if (map) {
            console.log('Unloading Leaflet map.');
            map.remove();
        }
    });
</script>

<style>
    @import 'leaflet/dist/leaflet.css';

    .map {
        height: 800px;
    }
</style>

<!--<script src="https://unpkg.com/protomaps@1.22.0/dist/protomaps.min.js"></script>-->
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.6.0/dist/leaflet.css"
      integrity="sha512-xwE/Az9zrjBIphAcBb3F6JVqxf46+CDLwfLMHloNu6KEQCAWi6HcDUbeOfBIptF7tcCzusKFjFw2yuvEpDL9wQ=="
      crossorigin=""/>
<div class="map" bind:this={mapElement}></div>
