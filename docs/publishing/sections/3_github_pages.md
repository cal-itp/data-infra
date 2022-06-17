(publishing-github-pages)=
# HTML Visualizations

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

## Rendering Jupyter Notebook as HTML
A single notebook can be converted to HTML using `nbconvert`. If it's a quick analysis in a standalone notebook, sometimes an analyst may choose not to go down the [portfolio method](publishing-analytics-portfolio-site).

* In the terminal: `jupyter nbconvert --to html --no-input --no-prompt`
    * `--no-input`: hide code cells
    * `--no-prompt`: hide prompts to have all cells vertically aligned
* A longer example of [converting multiple notebooks into HTML pages and uploading to GitHub](https://github.com/cal-itp/data-analyses/blob/main/bus_service_increase/publish_single_report.py)


## Use GitHub pages to display these HTML pages
1. Go to the repo's [settings](https://github.com/cal-itp/data-analyses/settings)
1. Navigate to `Pages` on the left
1. Change the branch GH pages is sourcing from: `main` to `my-current-branch`
1. Embed the URL into the slides. Example URL: https://docs.calitp.org/data-analyses/PROJECT-FOLDER/MY-VISUALIZATION.html
1. Once a PR is ready and merged, the GH pages can be changed back to source from `main`. The URL is preserved within the slide deck.
1. Note: If analysts working on different branches want to display GH pages, one of them needs to merge in `main`, the other needs to do a `git rebase`, and then can choose `my-other-branch` as the GH pages source.

Ex: [Service Density Map](https://docs.calitp.org/data-analyses/bus_service_increase/img/arrivals_pc_high.html)
