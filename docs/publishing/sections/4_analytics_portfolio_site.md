(publishing-analytics-portfolio-site)=

# The Cal-ITP Analytics Portfolio

Depending on the complexity of your visualizations, you may want to produce
a full website composed of multiple notebooks and/or the same notebook run
across different sets of data (for example, one report per Caltrans district).
For these situations, the [Jupyter Book-based](https://jupyterbook.org/en/stable/intro.html)
[publishing framework](https://github.com/cal-itp/data-analyses/tree/main/portfolio)
present in the data-analyses repo is your friend.

You can find the Cal-ITP Analytics Portfolio at [analysis.calitp.org](https://analysis.calitp.org).

## Setup

Before executing the build, there are a few prior steps you need to do.

1. Set up netlify key/make sure your Netlify token is up to date:

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

2. Create a `.yml` file in [data-analyses/portfolio/sites](https://github.com/cal-itp/data-analyses/tree/main/portfolio/sites). Each `.yml` file is a site, so if you have separate research topics, they should each have their own `.yml` file.

   - This `.yml` file will include the directory to the notebook(s) you want to publish.
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

       - Example: [rt.yml](https://github.com/cal-itp/data-analyses/blob/main/portfolio/sites/rt.yml)

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

       - Example: [hqta.yml](https://github.com/cal-itp/data-analyses/blob/main/portfolio/sites/hqta.yml)

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

### Build your Report

**Note:** The build command must be run from the root of the repo!

1. Navigate back to the repo data-analyses and install the portfolio requirements with
   `pip install -r portfolio/requirements.txt`
2. Then run `python portfolio/portfolio.py build my_report` to build your report
   - **Note:** `my_report.yml` will be replaced by the name of your `.yml` file in [data-analyses/portfolio/sites](https://github.com/cal-itp/data-analyses/tree/main/portfolio/sites).
   - Your build will be located in: `data-analyses/portfolio/my_report/_build/html/index.html`
3. Add the files using `git add` and commit your progress!

### Deploy your Report

1. Make sure you are in the root of the data-analyses repo: `~/data-analyses`

2. Run `python portfolio/portfolio.py build my_report --deploy`

   - By running `--deploy`, you are deploying the changes to display in the Analytics Portfolio.
   - **Note:** The `my_report` will be replaced by the name of your `.yml` file in [data-analyses/portfolio/sites](https://github.com/cal-itp/data-analyses/tree/main/portfolio/sites).
   - If you have already deployed but want to make changes to the README, run: `python portfolio/portfolio.py build my_report --papermill-no-execute`
     - Running this is helpful for larger outputs or if you are updating the README.

3. Once this runs, you can check the preview link at the bottom of the output. It should look something like:

   - `–no-deploy`: `file:///home/jovyan/data-analyses/portfolio/my_report/_build/html/index.html`
   - `–deploy`: `Website Draft URL: https://my-report--cal-itp-data-analyses.netlify.app`

4. Add the files using `git add` and commit!

5. Your notebook should now be displayed in the [Cal-ITP Analytics Portfolio](https://analysis.calitp.org/)

### Other Specifications

- You also have the option to specify: run `python portfolio/portfolio.py build --help` to see the following options:
  - `--deploy / --no-deploy`
    - deploy this component to netlify.
  - `--prepare-only / --no-prepare-only`
    - Pass-through flag to papermill; if true, papermill will not actually execute cells.
  - `--execute-papermill / --no-execute-papermill`
    - If false, will skip calls to papermill
  - `--no-stderr / --no-no-stderr`
    - If true, will clear stderr stream for cell outputs
  - `--continue-on-error / --no-continue-on-error`
    - Default: no-continue-on-error

## Adding to the Makefile

Another way to write to the Analytics Portfolio is to use the Makefile and run
`make build_my_report -f Makefile` in data-analyses

Example makefile in [`cal-itp/data-analyses`](https://github.com/cal-itp/data-analyses/blob/main/Makefile):

```
build_my_reports:
    pip install -r portfolio/requirements.txt
    git rm portfolio/my_report/ -rf
    python portfolio/portfolio.py build my_report --deploy
    git add portfolio/my_report/district_*/ portfolio/my_report/*.yml portfolio/my_report/*.md
    git add portfolio/sites/my_report.yml
```
