(publishing-static-files)=
# Static Visualizations

Static visualizations should be created in a Jupyter Notebook, saved locally
(in JupyterHub), and checked into GitHub. For example, you can save charts
as image files (such as PNGs) and commit them to the repository.

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

## Publishing Reports
Reports can be shared as HTML webpages or PDFs. Standalone HTML pages tend
to be self-contained and can be sent via email or similar.

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
