# Embeddable mapping application

This Svelte app and related Python code are intended to provide a minimal interactive map (configured by URL query params) for embedding
in Jupyter notebooks, especially those built into static websites using JupyterBook. By using `IFrame` widgets to
call the deployed application with a specific URL containing the desired state, a Jupyter user can render geospatial
data that has been stored in GCS. This avoids a common problem of `ipyleaflet` and other Jupyter visualization widgets
that store their data in the static HTML of a rendered JupyterBook webpage; we cannot control data compression or loading,
resulting in HTML pages that fail to load at all.

The Python code in `calitp_map_utils` defines the contract between data producers (i.e. notebooks) and the data consumer (i.e. the Svelte app) as well
as provides some utilities for validating the GeoJSON of specific analysis types.

## Developing

You can run a development server locally and use the `calitp_map_utils` CLI to generate a valid state URL for testing.

```bash
# in one terminal:
npm run dev

# in another terminal:
echo '{ "legend_url": "https://storage.googleapis.com/calitp-map-tiles/legend_test.svg", "layers": [ {"name": "D7 State Highway Network", "url": "https://storage.googleapis.com/calitp-map-tiles/d7_shn.geojson.gz", "type": "state_highway_network"}, {"name": "California High Quality Transit Areas - Stops", "url": "https://storage.googleapis.com/calitp-map-tiles/ca_hq_transit_stops.geojson.gz"}, {"name": "LA Metro Bus Speed Maps AM Peak", "url": "https://storage.googleapis.com/calitp-map-tiles/metro_am.geojson.gz", "type": "speedmap"} ] }' | gzip | basenc --base64url | poetry run python -m calitp_map_utils validate-state --base64url --compressed --data --verbose --host=http://localhost:5173
...
URL: localhost:5173?state=H4sIAO38fWQC_6WSMU_DMBCF_8opM03GSt0KDAwUgcqGkHVNr47B8RnfhZJW_e8kbVE6FAY6WSef3_fek7dZwJqyCYTG-yvIPLaUpJtftj832e0Y5opKcOdstcYWHkjXnN6zbr9Jvl-pVKNMikKUE1rKLbP1hNFJXnJdlOidxlGNcaTOkxTLsZEq5Jb4Tbg7N72WtnHPkx5mqgPMhAEWE0dK6kiOhndXMNi86SArTsHh3ig8NT21heeEQZzCNBEKjLosHOUC7yWa6sPoQdVIr3Y-yLHSv13fT2FGmhiuG4F5JFrCDKPAdAaPhJd0XPeyBuvfWu5Z3fb5Yl_3f0GN5zAk2TDXw7RY8NfJhEKdmik5rJw9-VBkKSzNPzMcXyuJ5vJps9039EE5DrACAAA%3D
```

## Build and deploy to Netlify

To deploy to Netlify (preview or prod), you must use `npm run build` to produce a bundle that will work as a static site.

```bash
npm run build
netlify deploy --site=embeddable-maps-calitp-org --dir=build (optional --prod)
```

We could look into using the [Netlify adapter](https://kit.svelte.dev/docs/adapter-netlify) at some point.
