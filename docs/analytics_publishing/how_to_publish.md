# Publishing Reports with Pull Requests (WIP)

Analysts have a variety of tools available to publish their final deliverables. With iterative work, analysts can implement certain best practices within these bounds to do as much as is programmatically practical. The workflow will look different depending on these factors:

* Are visualizations static or interactive?
* Does the deliverable need to be updated on a specified frequency or a one-off analysis?
* Is the deliverable format PDF, HTML, interactive dashboard, or a slide deck?

Analysts can string together a combination of these solutions:
* Static visualizations can be inserted directly into the slide deck
* HTML visualizations can be rendered in GitHub Pages and embedded as a URL into slide deck
* Static, HTML reports can be rendered in GitHub Pages.
* Reports can be rendered as PDFs and emailed to stakeholders.
* Interactive dashboards should be hosted in Metabase to share with external stakeholders.
* Use Airflow to schedule publishing reports, pushing data backing a dashboard, or emailing PDFs.

## Types of Reports

### Static Visualizations

Static visualizations should be created in a Jupyter Notebook, saved locally (in JupyterHub), and checked into GitHub.

```python

# matplotlib or seaborn
import matplotlib.pyplot as plot
import seaborn
plt.savefig("../my-visualization.png")

# altair
import altair as alt
import altair_saver
chart.save("../my-visualization.png")

# plotnine
from plotnine import *
chart.save(filename = '../my-visualization.png')
```

### HTML Visualizations

Visualizations that benefit from limited interactivity, such as displaying tooltips on hover or zooming in / out and scrolling can be rendered within GitHub pages.

A `folium` map can be saved as a local HTML file and checked into GitHub (`ipyleaflet` must be rendered directly in the notebook). Many chart packages, including `altair`, `matplotlib`, and `plotly` allow you to export as HTML.

```python
# altair
import altair as alt
chart.save("../my-visualization.html")

# matplotlib (by encoding it)
import matplotlib.pyplot as plt
import base64
from io import BytesIO

fig = plt.figure()

tmpfile = BytesIO()
fig.savefig(tmpfile, format='png')
encoded = base64.b64encode(tmpfile.getvalue()).decode('utf-8')

html = 'Some html head' + '<img src=\'data:image/png;base64,{}\'>'.format(encoded) + 'Some more html'

with open('test.html','w') as f:
    f.write(html)

# plotly
import plotly.express as px
fig.write_html("../my-visualization.html")

# folium
import folium
fig.save("../my-visualization.html")
```

Use GitHub pages to display these HTML pages.
1. Go to the repo's [settings](https://github.com/cal-itp/data-analyses/settings)
1. Navigate to `Pages` on the left
1. Change the branch GH pages is sourcing from: `main` to `my-current-branch`
1. Embed the URL into the slides. Example URL: https://docs.calitp.org/data-analyses/PROJECT-FOLDER/MY-VISUALIZATION.html
1. Once a PR is ready and merged, the GH pages can be changed back to source from `main`. The URL is preserved within the slide deck.
1. Note: If analysts working on different branches want to display GH pages, one of them needs to merge in `main`, the other needs to do a `git rebase`, and then can choose `my-other-branch` as the GH pages source.

Ex: [Service Density Map](https://docs.calitp.org/data-analyses/bus_service_increase/img/arrivals_pc_high.html)

### Dashboards

Interactive charts should be displayed in Metabase. Using Voila on Jupyter Notebooks works locally, but doesn't allow for sharing with external stakeholders. The data cleaning and processing should still be done within Python scripts or Jupyter notebooks. The processed dataset backing the dashboard should be exported to a Google Cloud Storage bucket.

An [Airflow DAG](https://github.com/cal-itp/data-infra/tree/main/airflow/dags) needs to be set up to copy the processed dataset into the data warehouse. Metabase can only source data from the data warehouse. The dashboard visualizations can be set up in Metabase, remain interactive, and easily shared to external stakeholders.

Any tweaks to the data processing steps are easily done in scripts and notebooks, and it ensures that the visualizations in the dashboard remain updated with little friction.

Ex: [Payments Dashboard](https://dashboards.calitp.org/dashboard/3-payments-performance-dashboard?transit_provider=mst)

### Publishing Reports
Reports can be shared as HTML webpages or PDFs.

A Jupyter Notebook can be converted to HTML with:

```python
import papermill as pm
import subprocess

OUTPUT_FILENAME = "sample-report"

pm.execute_notebook(
    # notebook to execute
    '../my-notebook.ipynb',
    # if needed, rename the notebook as something different
    # this will be the filename that is used when converting to HTML or PDF
    f'../{OUTPUT_FILENAME}.ipynb',
)

# shell out, run NB Convert
OUTPUT_FORMAT = 'html'
subprocess.run([
    "jupyter",
    "nbconvert",
    "--to",
    OUTPUT_FORMAT,
    "--no-input",
    "--no-prompt",
    f"../{OUTPUT_FILENAME}.ipynb",
])
```

A Jupyter Notebook can be converted to PDF for email distribution with:

```python
# Similar as converting to HTML, but change the output_format
# shell out, run NB Convert
OUTPUT_FORMAT = 'PDFviaHTML'
subprocess.run([
    "jupyter",
    "nbconvert",
    "--to",
    OUTPUT_FORMAT,
    "--no-input",
    "--no-prompt",
    f"../{OUTPUT_FILENAME}.ipynb",
])

```
### Scheduling Reports

Use Airflow to schedule publishing reports at some specified frequency. Run a Python script that uses `papermill` to execute a notebook and convert to HTML or PDF.

Ex: Reports Cal-ITP
