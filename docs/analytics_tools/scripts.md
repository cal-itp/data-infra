(scripts)=

# Scripts

Most Cal-ITP analysts will be using Jupyter Notebooks in our Jupyter Hub for their work. Jupyter Notebooks have numerous benefits, including seeing outputs at the end of each code block, ability to weave narrative with analysis through Markdown cells, and the ability to convert what's written in code directly into an HTML or pdf for making automated reports. They are great for exploratory work.

Larger analytics projects often require substantial data processing, wrangling, and transformations. Those steps, while initially may be undertaken in a notebook, should become Python scripts. Only the latter stages, such as visualizations or debugging, should be done in Jupyter Notebooks.

## Benefits

### Modularity

**Notebooks**

- Functions and classes defined within a notebook stay within a notebook.
- No portability, hindering reproducibility, resulting in duplicative code for yourself or duplicative work in an organization.

**Scripts**

- Functions and classes defined here are importable to be used in notebooks and scripts.

### Self-Hinting

**Notebooks**

- You need to run a series of notebooks to complete all the data processing needed. The best case scenario is that you've provided the best documentation in a README and intuitive notebook names (neither of which are a given). This best case scenario is still more brittle compared to using a Makefile.

**Scripts**

- Pairing the series of scripts with a Makefile self-hints the order in which scripts should be executed.
- Running a single make command is a simple way to schedule and execute an entire workflow.

### Easy Git

**Notebooks**

- Re-running or clearing cells are changes that Git tracks.
- Potential merge conflicts when collaborating with others or even from switching branches.
- Merge conflicts are extremely difficult to resolve. This is due to the fact that Jupyter Notebook outputs are JSON. Even if someone else opened your notebook and didn't change anything, that could lead to changes in the underlying JSON metadata...resulting in a painful merge conflict that may not even be resolved.

**Scripts**

- Python scripts (`.py`) are plain text files. Git tracks plain text changes easily.
- Merge conflicts may arise but are easy to resolve.

### Robust and Scalable

**Notebooks**

- Different versions of notebooks may prevent reproducibility.
- There are issues with scaling notebooks, especially when wanting to test out different parameters, and making copies of notebooks is not wise. If you discovered an error later, would you make that change in the 10 notebook copies? Or make 10 duplicates again?

**Scripts**

- Scripts are robust to scaling and reproducing work.
- Injecting various parameters is not an issue, as scripts often hold functions that can take different parameters and arguments. Rerunning a script when you detect an error is fairly straightforward.

## Best Practices

**At minimum**, all research tasks / projects must include:

- 1 script for importing external data and changing it from shapefile/geojson/csv to parquet/geoparquet
- If only using warehouse data or upstream warehouse data cached in GCS, can skip this first script
- At least 1 script for data processing to produce processed output for visualization
- Break out scripts by concepts / stages
- Include data catalog, README for the project
- All functions used in scripts should have docstrings. Type hints are encouraged!

For **larger projects**, introduce more of these principles:

- Distinguish between data processing that is fairly one-off vs data processing that could be part of a pipeline (shared across multiple downstream products)
- Data processing pipeline refactored to scale
  - Make it work, make it right, make it fast
- Add logging capability
- Identify shared patterns for functions that could be abstracted more generally.
- Replace functions that live in python scripts with top-level functions
  - Make these top-level functions “installable” across directories
  - Point downstream uses in scripts or notebooks at these top-level / upstream functions
- Batch scripting to create a pipeline for processing data very similarly
  - YAML file to hold project configuration variables / top-level parameters

### References

- [Good Data Scientists Write Code Code](https://towardsdatascience.com/good-data-scientists-write-good-code-28352a826d1f)
- [Does Your Code Smell](https://towardsdatascience.com/does-your-code-smell-acb9f24bbb46)
- [Modularity, Readability, Speed](https://towardsdatascience.com/3-key-components-of-a-well-written-data-model-c426b1c1a293)
- [Batch scripting](https://aaltoscicomp.github.io/python-for-scicomp/scripts/)
- [Start in notebooks, finish in scripts](https://learnpython.com/blog/python-scripts-vs-jupyter-notebooks/)
