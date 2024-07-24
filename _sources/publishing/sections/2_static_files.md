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

Or you can try:

```python
# Execute NB
jupyter nbconvert --to notebook --execute --inplace my_notebook.ipynb
    
# Convert NB to HTML then to PDF
jupyter nbconvert --to html --no-input --no-prompt my_notebook.ipynb
```

You can also convert a Jupyter Notebook to PDF for distribution in a few different ways. You might wonder why we don't suggest simply doing  `File -> Save and Export Notebook As -> PDF`. We don't recommend this method because it leaves all your code cells visible, which usually isn't desirable.

All the code below are to be pasted into the <b>terminal</b>.

- The PDF generated has a very academic look, similar to a LaTex document.

```python
# Convert your original notebook
jupyter nbconvert --to pdf my_notebook.ipynb
```

- `Nbconvert` also has configuration options available. [Read about them here.](https://nbconvert.readthedocs.io/en/latest/config_options.html)

```python
# Hide all the code cells by adding --no-input
jupyter nbconvert --to pdf --no-input my_notebook.ipynb
```

- For a less academic look, you can convert your notebook into html before using `weasyprint`. This might cause blank pages to appear, typically at the beginning of your PDF. You will need to manually remove them using Adobe.

```python
# Make sure to install `weasyprint`
pip install WeasyPrint

# Execute NB
jupyter nbconvert --to notebook --execute --inplace my_notebook.ipynb
    
# Convert NB to HTML then to PDF
jupyter nbconvert --to html --no-input --no-prompt my_notebook.ipynb

# Convert to PDF
weasyprint my_notebook.html my_notebook.pdf
```

- There are assignments that require you to rerun the same notebook for different values and save each of these new notebooks in PDF format. This  essentially combines parameterization principles using `papermill`  with the `weasyprint` steps above. You can reference the code that was used to generate the CSIS scorecards [here](https://github.com/cal-itp/csis-metrics/blob/main/project_prioritization/metrics_summaries/run_papermill.py). This script iterates over [this notebook](https://github.com/cal-itp/csis-metrics/blob/main/project_prioritization/metrics_summaries/sb1_scorecard.ipynb) to produce 50+ PDF files for each of the nominated projects.

  Briefly, the script above does the following:

  - Automates the naming of the new PDF files by taking away punctuation that isn't allowed.
  - Saves the notebook as html files.
  - Converts the html files to PDF.
  - Saves each PDF to the folder (organized by district) to our GCS.
  - Deletes irrelevant files.

- Here are some tips and tricks when converting notebooks to HTML before PDF conversions.

  - Any formatting should be done in HTML/CSS first.

  - To create page breaks, add the following in a <b>Markdown</b> cell with however many `<br>` tags you'd like.

    ```python
    <br>
    <br>
    <br>
    <br>
    <br>
    ```

  - Follow the writing, rounding, and visualization ideas outlined in [Getting Notebooks Ready for the Portfolio](https://docs.calitp.org/data-infra/publishing/sections/4_notebooks_styling.html) section.
