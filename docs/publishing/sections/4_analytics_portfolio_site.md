(publishing-analytics-portfolio-site)=
# The Cal-ITP Analytics Portfolio

Depending on the complexity of your visualizations, you may want to produce
a full website composed of multiple notebooks and/or the same notebook run
across different sets of data (for example, one report per Caltrans district).
For these situations, the [Jupyter Book-based](https://jupyterbook.org/en/stable/intro.html)
[publishing framework](https://github.com/cal-itp/data-analyses/tree/main/portfolio)
present in the data-analyses repo is your friend.

You can find the Cal-ITP Analytics Portfolio at [analysis.calitp.org](https://analysis.calitp.org).

## Setup:
Before executing the build, there are a few prior steps you need to do.

1. Set up netlify key:
    * install netlify: `npm install -g netlify-cli`
    * Navigate to your main directory
    * Edit your bash profile:
        * enter `vi ~/.bash_profile` in the command line
        * Type `o` to enter a new line
        * Once in insert mode, can copy and paste the following keys, prefixing it with "export":
            * `export NETLIFY_AUTH_TOKEN= YOURTOKENHERE123`
            * `export NETLIFY_SITE_ID=cal-itp-data-analyses`
        * Press `ESC` + `:wq` to stop insert mode and to close the vim
            * note: `ESC` + `dd` gets rid of unwanted lines
        * In the terminal enter command: `env | grep NETLIFY` to see that your Netlify token is there

2. Create a `.yml` file in [data-analyses/portfolio/sites](https://github.com/cal-itp/data-analyses/tree/main/portfolio/sites). Each `.yml` file is a site, so if you have separate research topics, they should each have their own `.yml` file.
    * This `.yml` file will include the directory to the notebook(s) you want to publish.
    * Name your `.yml` file
    * The structure of your `.yml` file depends on the type of your analysis:
        * If you have one parameterized notebook with **one parameter**:

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
         * If you have a parameterized notebook with **multiple parameters**:

            ```
            title: My Analyses
            directory: ./my-analyses/
            readme: ./my-analyses/README.md
            notebook: ./my-analyses/my-notebook.ipynb
            parts:
            - chapters:
              - caption: County Name
                params:
                  paramter1_county_name
                sections:
                - city: parameter2_city_name
                - city: parameter2_city_name
            ```
         * If you have an individual notebook with **no parameters**:

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
## Running the Build Command:
**Note:** The build command must be run from the root of the repo!
1. Navigate back to the repo data-analyses and install the portfolio requirements with
`pip install -r portfolio/requirements.txt`
2. Then run `python portfolio/portfolio.py build my_report --deploy`
    * The `my_report` will be replaced by the name of your `.yml` file in [data-analyses/portfolio/sites](https://github.com/cal-itp/data-analyses/tree/main/portfolio/sites).
    * You also have the option to specify: run `python portfolio/portfolio.py build --help` to see the following options:
        * `--deploy / --no-deploy`
            * deploy this component to netlify.
        * `--prepare-only / --no-prepare-only`
            * Pass-through flag to papermill; if true, papermill will not actually execute cells.
        * Other specifications:
            * `--execute-papermill / --no-execute-papermill`
            * `--no-stderr / --no-no-stderr`
            * `--continue-on-error / --no-continue-on-error`

3. Once this runs, you can check the preview link at the bottom of the output. It should look something like:
    * `–no-deploy`: `file:///home/jovyan/data-analyses/portfolio/my-analysis/_build/html/index.html`
    * `–deploy`: `Website Draft URL: https://my-analysis--cal-itp-data-analyses.netlify.app`

4. Add the files using `git add` and commit!
5. Your notebook should now be displayed in the [Cal-ITP Analytics Portfolio](https://analysis.calitp.org/)

## Adding to the Makefile:

Another way to write to the Analytics Portfolio is to use the Makefile and run
`make build_my_report -f Makefile` in data-analyses

Example makefile in [`cal-tip/data-analyses`](https://github.com/cal-itp/data-analyses/blob/main/Makefile):

```
build_my_reports:
    pip install -r portfolio/requirements.txt
    git rm portfolio/my-analyses/ -rf
    python portfolio/portfolio.py build my-analyses --deploy
    git add portfolio/my-analyses/district_*/ portfolio/dla/*.yml portfolio/dla/*.md
    git add portfolio/sites/my-analyses.yml
```
