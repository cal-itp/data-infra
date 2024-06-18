(publishing-analytics-portfolio-site)=

# The Cal-ITP Analytics Portfolio

Depending on the complexity of your visualizations, you may want to produce
a full website composed of multiple notebooks and/or the same notebook that is rerun across different parameters.
For these situations, the [Jupyter Book-based](https://jupyterbook.org/en/stable/intro.html)
[publishing framework](https://github.com/cal-itp/data-analyses/tree/main/portfolio)
present in the data-analyses repo is your friend. You can find the Cal-ITP Analytics Portfolio at [analysis.calitp.org](https://analysis.calitp.org).

## Netlify Setup

Netlify is the platform turns our Jupyter Notebooks uploaded to GitHub into a full website. You must set up netlify key and/or make sure your Netlify token is up to date:

- Install netlify: `npm install -g netlify-cli`
- Navigate to your main directory
- Edit your bash profile using Nano:
  - In your terminal, enter `nano ~/.bash_profile` to edit.
  - Navigate using arrows (down, right, etc) to create 2 new lines. Paste (`CTRL` + `V`) your netlify key in the lines in the following format, each line prefixed with "export"
    - `export NETLIFY_AUTH_TOKEN= YOURTOKENHERE123`
    - `export NETLIFY_SITE_ID=cal-itp-data-analyses`
  - To exit, press `CTRL` + `X`
  - Nano will ask if you want to save your changes. Type `Y` to save.
    - Type `N` to discard your changes and exit
- For the changes to take effect, open a new terminal or run `source ~/.bash_profile`
  - Back in your terminal, enter `env | grep NETLIFY` to see that your Netlify token is there

## File Setup

In order to publish to analysis.calitp.org, you need to create three different files.

- A Jupyter Notebook (with a few particular elements to parameterize successfully).
- A README.md.
- A YML.

### Jupyter Notebook

Setting up your Jupyter Notebook to be parameterized and published to the analysis.calitp.org requires a few extra steps. Please refer to to the [next section](https://docs.calitp.org/data-infra/publishing/sections/5_notebooks_styling.html) on how to style your notebook in accordance to our StyleGuide.

[See a sample parameterized notebook here.](https://github.com/cal-itp/data-analyses/blob/main/starter_kit/parameterized_notebook.ipynb)

#### Packages to include

Copy and paste this code block below in every notebook for the portfolio. Order matters, %%capture must go first.

```
# Include this in the cell where packages are imported

%%capture

import warnings
warnings.filterwarnings('ignore')

import calitp_data_analysis.magics
```

#### Capturing Parameters

When parameterizing a notebook, there are  2 places in which the parameter must be injected.

- Header:
  The first Markdown cell must include parameters to inject.

  - Ex: If `district` is one of the parameters in your `sites/my_report.yml`, a header Markdown cell could be `# District {district} Analysis`.
  - Note: The site URL is constructed from the original notebook name and the parameter in the JupyterBook build: `0_notebook_name__district_x_analysis.html`

- Code Cell:

  - Create a code cell in which your parameter will be captured. Make sure the `parameter` tag for the cell is turned on.
  - Capture parameters - this option won't display locally in your notebook (it will still show `{district_number}`), but will be injected with the value when the JupyterBook is built.

  In a code cell:

  ````
  ```
  %%capture_parameters

  district_number = f"{df.caltrans_district.iloc[0].split('-')[0].strip()}"
  ```
  ````

<b> Amanda Note, IDK what this means</b>

- If you're using a heading, you can either use HTML or capture the parameter and inject.

- HTML - this option works when you run your notebook locally.

  ```
  from IPython.display import HTML

  display(HTML(f"<h3>Header with {variable}</h3>"))
  ```

##### Consecutive Headers

Headers must move consecutively in Markdown cells or the parameterized notebook will not generate. No skipping!

```
# Notebook Title
## First Section
## Second Section
### Another subheading
```

To get around consecutive headers, you can use `display(HTML())`.

```
  display(HTML(<h1>First Header</h1>) display(HTML(<h3>Next Header</h3>))
```

### README.md

Create a `README.md` file in the repo where your work lies to detail the purpose of your website, methologies, relevant links, instructions, and more.

- Your file should <b>always</b> be titled as `README.md`. No other variants such as `README_gtfs.md` or `read me.md` or ` README.md`. The portfolio can only take a `README.md` file when generating the landing page of your website.
- If you do accidentally create a `README.md` file with extra strings, you can fix this by taking the following steps:
  - `git rm portfolio/my_analysis/README_accidentally_named_something_else.md`
  - `rm portfolio/my_analysis/_build/html/README_accidentally_named_something.html`. We use `rm` because \_build/html folder is not checked into GitHub
  - `python portfolio/portfolio.py build my_report --no-execute-papermill --deploy` to rerun the portfolio to incorporate only the new changes to your `README.md` if the other pages are correct.

### YML

A `.yml` specifies the parameter you want your notebook to iterate over.  For example, the [DLA Grant Analysis's`.yml`](https://github.com/cal-itp/data-analyses/blob/main/portfolio/sites/dla.yml) runs the same notebook for each of the 12 Caltrans districts and the districts are also listed on the \[left hand side\]((https://dla--cal-itp-data-analyses.netlify.app/readme) to form the "Table of Contents."

Because each `.yml` file creates a new site on the [Portfolio's Index Page](https://analysis.calitp.org/), so every project needs its own file. DLA Grant Analysis, SB125 Route Illustrations, and Active Transportation Program all have their own `.yml` file.

The `.yml` files live here at [data-analyses/portfolio/sites](https://github.com/cal-itp/data-analyses/tree/main/portfolio/sites).

To create a `yml` file:

- Include the directory to the notebook(s) you want to publish.
- Name your `.yml` file. For now we will use `my_report.yml` as an example.
- The structure of your `.yml` file depends on the type of your analysis:
  - If you have one parameterized notebook with **one parameter**:

    - Example: [dla.yml](https://github.com/cal-itp/data-analyses/blob/main/portfolio/sites/dla.yml)

    ```
    title: My Analyses
    directory: ./my-analyses/
    readme: ./my-analyses/README.md
    notebook: ./my-analyses/my-notebook.ipynb
    parts:
       - caption: Introduction
       - chapters:
         - params:
              district_parameter: 1
              district_title: District 1
    ```

  - If you have a parameterized notebook with **multiple parameters**:

    - Example: [rt.yml](https://github.com/cal-itp/data-analyses/blob/main/portfolio/sites/rt.yml). You can automate making a `.yml` file using a script, [example here](https://github.com/cal-itp/data-analyses/blob/main/gtfs_digest/deploy_portfolio_yaml.py).

    ```
    title: My Analyses
    directory: ./my-analyses/
    readme: ./my-analyses/README.md
    notebook: ./my-analyses/my-notebook.ipynb
    parts:
    - chapters:
      - caption: County Name
        params:
          parameter1_county_name
        sections:
        - city: parameter2_city_name
        - city: parameter2_city_name
    ```

  - If you have an individual notebook with **no parameters**:

    ```
    title: My Analyses
    directory: ./my-analyses/
    readme: ./my-analyses/README.md
    parts:
    - caption: Introduction
    - chapters:
      - notebook: ./my-analyses/notebook_1.ipynb
      - notebook: ./my-analyses/notebook_2.ipynb
    ```

  - If you have multiple parameterized notebooks with **the same parameters**:

    - Example: [rt_parallel.yml](https://github.com/cal-itp/data-analyses/blob/main/portfolio/rt_parallel.yml)

    ```
    title: My Analyses
    directory: ./my-analyses/
    readme: ./my-analyses/README.md
    parts:
    - caption: District Name
    - chapters:
      - caption: Parameter 1
        params:
          itp_id: parameter_1
            sections: &sections
            - notebook: ./analysis_1/notebook_1.ipynb
            - notebook: ./analysis_2/notebook_2.ipynb
      - caption: Parameter 2
        params:
          itp_id: parameter_2
            sections: *sections
    ```
