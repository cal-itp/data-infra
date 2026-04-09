(publishing-analytics-portfolio-site)=

# The Cal-ITP Analytics Portfolio

Now that your notebook(s) are portfolio-ready, it's time to publish your work to the portfolio!

## File Setup

In order to publish to analysis.dds.dot.ca.gov, you need to create two different files:

### README

Create a `README.md` file in the repo where your work lies. This also forms the landing page of your website.

The `README.md` is the first thing the audience will see when they visit your website. Therefore, this page should contain content such as the goal of your work, the methodology you used, relevant links, and more. [Here](https://github.com/cal-itp/data-analyses/blob/main/portfolio/template_README.md) is a template for you to populate.

Need a node graph to illustrate where your data comes from and how it's processed? Try mermaid ([documentation here](https://mermaid.js.org/intro/)).

See [GTFS Digest](https://github.com/cal-itp/data-analyses/blob/main/gtfs_digest/mermaid.md) for a current example.

### YML

Each `.yml` file creates a new site on the Portfolio's Index Page, so every project needs its own file.

All the `.yml` files live here at [data-analyses/portfolio/sites](https://github.com/cal-itp/data-analyses/tree/main/portfolio/sites). Navigate to this folder to create the .yml file.

Here's how to create a `yml` file:

- Include the directory to the notebook(s) you want to publish.

- Name your `.yml` file. For now we will use `my_report.yml` as an example.

- `.yml` file should contain the title, directory, README.md path and notebook path.

- The structure of your `.yml` file depends on the type of your analysis:

  You can automate making a `.yml` file using a script, [example here](https://github.com/cal-itp/data-analyses/blob/main/gtfs_digest/deploy_portfolio_yaml.py).

  - If you have one parameterized notebook with **one parameter**:

    Example: [\_param_analyses_test.yml](https://github.com/cal-itp/data-analyses/blob/main/portfolio/sites/_param_analyses_test.yml)

    ```
    title: My Analyses
    directory: ./my-analyses/
    readme: ./my-analyses/README.md
    notebook: ./my-analyses/my-notebook.ipynb
    parts:
      - chapters:
        - params:
            district_parameter: 1
         - params:
            district_parameter: 2
    and so on...
         - params:
            district_parameter: 12
    ```

  - If you have one parameterized notebook with **one parameter** and **grouped chapters**:

    Examples: [\_group_and_params_analyses_test.yml](https://github.com/cal-itp/data-analyses/blob/main/portfolio/sites/_group_and_params_analyses_test.yml)

    ```
    title: My Analyses
    directory: ./my-analyses/
    readme: ./my-analyses/README.md
    notebook: ./my-analyses/my-notebook.ipynb
    parts:
      - caption: County Name
        chapters:
        - params:
            city: parameter2_city_name
        - params:
            city: parameter2_city_name
    ```

  - If you have notebooks with **no parameters**:

    Examples: [\_basic_analyses_test.yml](https://github.com/cal-itp/data-analyses/blob/main/portfolio/sites/_basic_analyses_test.yml)

    ```
    title: My Analyses
    directory: ./my-analyses/
    readme: ./my-analyses/README.md
    parts:
      - chapters:
        - notebook: ./my-analyses/notebook_1.ipynb
        - notebook: ./my-analyses/notebook_2.ipynb
    ```

  - If you have multiple parameterized notebooks with **the same parameters**:

    Example: [\_section_analyses_test.yml](https://github.com/cal-itp/data-analyses/blob/main/portfolio/sites/_section_analyses_test.yml)

    ```
    title: My Analyses
    directory: ./my-analyses/
    readme: ./my-analyses/README.md
    parts:
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

## Building and Deploying your Report

After your Jupyter Notebook (refer to the previous section), `README.md`, and `.yml` files are setup properly, it's time to deploy your work to the Portfolio!

Follow the instructions on [data-analyses repo](https://github.com/cal-itp/data-analyses/tree/main/portfolio).
