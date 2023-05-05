<!-- from https://dev.to/khromov/using-leaflet-with-sveltekit-3jn1 -->
<script>
    import {onMount, onDestroy} from 'svelte';
    import L from 'leaflet';
    import {leafletLayer, LineSymbolizer} from 'protomaps';

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

        leafletLayer({
            url: "https://storage.googleapis.com/calitp-map-tiles/shapes.pmtiles",
            paint_rules: PAINT_RULES,
            // label_rules: LABEL_RULES
        }).addTo(map)

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
