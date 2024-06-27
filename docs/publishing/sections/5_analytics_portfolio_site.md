(publishing-analytics-portfolio-site)=

# The Cal-ITP Analytics Portfolio

Now that your notebook(s) are portfolio-ready, it's time to publish your work to the portfolio!

## Netlify Setup

Netlify is the platform turns our Jupyter Notebooks uploaded to GitHub into a full website.

To setup your netlify key:

- Ask in Slack/Teams for a Netlify key if you don't have one yet.
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

In order to publish to analysis.calitp.org, you need to create two different files.

- A README.md.
- A YML.

### README.md

Create a `README.md` file in the repo where your work lies. This also forms the landing page of your website.

- Your file should <b>always</b> be titled as `README.md`. No other variants such as `README_gtfs.md` or `read me.md` or ` README.md` are allowed. The portfolio can only take a `README.md` when generating the landing page of your website.
- The `README.md` is the first thing the audience will see when they visit your website. Therefore, this page should contain content such as the goal of your work, the methodology you used, relevant links, and more. [Here](https://github.com/cal-itp/data-analyses/blob/main/portfolio/template_README.md) is a template for you to populate.
- If you do accidentally create a `README.md` file with extra strings, you can fix this by taking the following steps:
  - `git rm portfolio/my_analysis/README_accidentally_named_something_else.md`
  - `rm portfolio/my_analysis/_build/html/README_accidentally_named_something.html`. We use `rm` because \_build/html folder is not checked into GitHub
  - `python portfolio/portfolio.py build my_report --no-execute-papermill --deploy` to rerun the portfolio to incorporate only the new changes to your `README.md` if the other pages are correct.

### YML

Each `.yml` file creates a new site on the [Portfolio's Index Page](https://analysis.calitp.org/), so every project needs its own file. DLA Grant Analysis, SB125 Route Illustrations, and Active Transportation Program all have their own `.yml` file.

All the `.yml` files live here at [data-analyses/portfolio/sites](https://github.com/cal-itp/data-analyses/tree/main/portfolio/sites).

Here's how to create a `yml` file:

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
         - params:
              district_parameter: 2
              district_title: District 2
        and so on...
        - params:
              district_parameter: 12
              district_title: District 12
    ```

  - If you have a parameterized notebook with **multiple parameters**:

    - Example: [rt.yml](https://github.com/cal-itp/data-analyses/blob/main/portfolio/sites/rt.yml). You can also automate making a `.yml` file using a script, [example here](https://github.com/cal-itp/data-analyses/blob/main/gtfs_digest/deploy_portfolio_yaml.py).

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

    - Example: [quarterly_performance_metrics.yml](https://github.com/cal-itp/data-analyses/blob/main/portfolio/sites/quarterly_performance_metrics.yml).

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

## Building and Deploying your Report

After your Jupyter Notebook (refer to the previous section), `README.md`, and `.yml` files are setup properly, it's time to deploy your work to the Portfolio!

### Build your Report

**Note:** The build command must be run from the root of the repo at `~/data-analyses`!

1. Navigate back to the `~/data-analyses` and install the portfolio requirements with
   `pip install -r portfolio/requirements.txt`
2. Run `python portfolio/portfolio.py build my_report` to build your report
   - **Note:** `my_report.yml` will be replaced by the name of your `.yml` file in [data-analyses/portfolio/sites](https://github.com/cal-itp/data-analyses/tree/main/portfolio/sites).
   - Your build will be located in: `data-analyses/portfolio/my_report/_build/html/index.html`
3. Add the files using `git add` and commit your progress!

### Deploy your Report

1. Make sure you are in the root of the data-analyses repo: `~/data-analyses`.

2. Run `python portfolio/portfolio.py build my_report --deploy`.

   - By running `--deploy`, you are deploying the changes to display in the Analytics Portfolio.
   - **Note:** The `my_report` will be replaced by the name of your `.yml` file in [data-analyses/portfolio/sites](https://github.com/cal-itp/data-analyses/tree/main/portfolio/sites).
   - If you have already deployed but want to make changes to the README, run: `python portfolio/portfolio.py build my_report --no-execute-papermill --deploy`
     - Running this is helpful for larger outputs or if you are updating the README.

3. Once this runs, you can check the preview link at the bottom of the output. It should look something like:

   - `–no-deploy`: `file:///home/jovyan/data-analyses/portfolio/my_report/_build/html/index.html`
   - `–deploy`: `Website Draft URL: https://my-report--cal-itp-data-analyses.netlify.app`

4. Add the files using `git add` and commit!

5. Your notebook should now be displayed in the [Cal-ITP Analytics Portfolio](https://analysis.calitp.org/)

   - If your work isn't showing up on the Index page above, run `python portfolio/portfolio.py index --deploy --prod` to add it.

### Other Specifications

- You also have the option to specify after the initial `python portfolio/portfolio.py build my_report [specification goes here]` command: run `python portfolio/portfolio.py build --help` to see the following options:
  - `--deploy / --no-deploy`
    - deploy this component to netlify.
  - `--prepare-only / --no-prepare-only`
    - Pass-through flag to papermill; if true, papermill will not actually execute cells.
  - `--execute-papermill / --no-execute-papermill`
    - If false, will skip calls to papermill
    - For example, if only the `README.md` is updated but the notebooks have remained the same, you would run
      `python portfolio/portfolio.py build my_report --no-execute-papermill --deploy`.
  - `--no-stderr / --no-no-stderr`
    - If true, will clear stderr stream for cell outputs
  - `--continue-on-error / --no-continue-on-error`
    - Default: no-continue-on-error

### Adding to the Makefile

Another and more efficient way to write to the Analytics Portfolio is to use the Makefile and run
`make build_my_report -f Makefile` in the `data-analyses` repo.

Here's an example makefile in [`cal-itp/data-analyses`](https://github.com/cal-itp/data-analyses/blob/main/Makefile):

```
build_my_reports:
    pip install -r portfolio/requirements.txt
    git rm portfolio/my_report/ -rf
    python portfolio/portfolio.py build my_report --deploy
    git add portfolio/my_report/district_*/ portfolio/my_report/*.yml portfolio/my_report/*.md
    git add portfolio/sites/my_report.yml
```
