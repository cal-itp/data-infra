# Embeddable mapping application

This Svelte app and related Python code are intended to provide a minimal, embeddable interactive map for embedding
in Jupyter notebooks, especially those built into static websites using JupyterBook. By using `IFrame` widgets to
call the deployed application with a specific URL containing the desired state, a Jupyter user can render geospatial
data that has been stored in GCS. This avoids the problem of `ipyleaflet` and other Jupyter visualization widgets
that store their data in the static HTML of a rendered JupyterBook webpage. The Python code in `calitp_map_utils`
defines the contract between data producers (i.e. notebooks) and the data consumer (i.e. the Svelte app) as well
as provides some utilities for validating the GeoJSON of specific analysis types.

## calitp_map_utils

As mentioned above, `calitp_map_utils` is a small utility library that defines Pydantic types that can be used for
data validation as well as Typescript types for type-hinting in the Svelte app. Also, the library contains
a few CLI commands to facilitate validating pre-existing data with those types and/or generate a quick URL
with state for testing.

A GitHub Action workflow exists to build the package and publish it to PyPi. Be sure to bump the version date in `pyproject.toml` in any pull request that updates the library.

## Developing the maps app

You can run a development server locally; use the calitp-map-utils CLI to generate a valid state URL for testing.

```bash
npm run dev
echo '{ "legend_url": "https://storage.googleapis.com/calitp-map-tiles/legend_test.svg", "layers": [ {"name": "D7 State Highway Network", "url": "https://storage.googleapis.com/calitp-map-tiles/d7_shn.geojson.gz", "type": "state_highway_network"}, {"name": "California High Quality Transit Areas - Stops", "url": "https://storage.googleapis.com/calitp-map-tiles/ca_hq_transit_stops.geojson.gz"}, {"name": "LA Metro Bus Speed Maps AM Peak", "url": "https://storage.googleapis.com/calitp-map-tiles/metro_am.geojson.gz", "type": "speedmap"} ] }' | gzip | basenc --base64url | poetry run python -m calitp_map_utils validate-state --base64url --compressed --data --verbose --host=http://localhost:5173
...
URL: localhost:5173?state=H4sIAO38fWQC_6WSMU_DMBCF_8opM03GSt0KDAwUgcqGkHVNr47B8RnfhZJW_e8kbVE6FAY6WSef3_fek7dZwJqyCYTG-yvIPLaUpJtftj832e0Y5opKcOdstcYWHkjXnN6zbr9Jvl-pVKNMikKUE1rKLbP1hNFJXnJdlOidxlGNcaTOkxTLsZEq5Jb4Tbg7N72WtnHPkx5mqgPMhAEWE0dK6kiOhndXMNi86SArTsHh3ig8NT21heeEQZzCNBEKjLosHOUC7yWa6sPoQdVIr3Y-yLHSv13fT2FGmhiuG4F5JFrCDKPAdAaPhJd0XPeyBuvfWu5Z3fb5Yl_3f0GN5zAk2TDXw7RY8NfJhEKdmik5rJw9-VBkKSzNPzMcXyuJ5vJps9039EE5DrACAAA%3D
```

You can point the `--host` parameter at a Netlify URL to provide an easy way to test against an already-published version of the app. As of 2023-07-21
the production URL is [https://embeddable-maps.calitp.org](https://embeddable-maps.calitp.org) but you can also use preview
Netlify sites deployed via `netlify deploy ...` with `--alias=some-alias` and/or without the `--prod` flag (see below).

## Build and deploy to Netlify

The site is deployed to production on merges to main, as defined in [../../.github/workflows/deploy-apps-maps.yml](../../.github/workflows/deploy-apps-maps.yml).

You may also deploy manually with the following:

```bash
(from the apps/maps folder)
npm run build
netlify deploy --site=embeddable-maps-calitp-org --dir=build
```

By default, this deploys a preview site with a generated alias prefix. You may pass an explicit alias with `--alias=<some-alias>`
or deploy to production with `--prod`.

We could look into using the [Netlify adapter](https://kit.svelte.dev/docs/adapter-netlify) at some point.
