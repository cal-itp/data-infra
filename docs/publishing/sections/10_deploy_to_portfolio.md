(deploy_to_portfolio)=

# Building and Deploying your Report

After your Jupyter Notebook, README.md, and `.yml` files are setup properly, it's time to deploy your work to the Portfolio!

## Build your Report

**Note:** The build command must be run from the root of the repo at `~/data-analyses`!

1. Navigate back to the `~/data-analyses` and install the portfolio requirements with
   `pip install -r portfolio/requirements.txt`
2. Then run `python portfolio/portfolio.py build my_report` to build your report
   - **Note:** `my_report.yml` will be replaced by the name of your `.yml` file in [data-analyses/portfolio/sites](https://github.com/cal-itp/data-analyses/tree/main/portfolio/sites).
   - Your build will be located in: `data-analyses/portfolio/my_report/_build/html/index.html`
3. Add the files using `git add` and commit your progress!

## Deploy your Report

1. Make sure you are in the root of the data-analyses repo: `~/data-analyses`

2. Run `python portfolio/portfolio.py build my_report --deploy`

   - By running `--deploy`, you are deploying the changes to display in the Analytics Portfolio.
   - **Note:** The `my_report` will be replaced by the name of your `.yml` file in [data-analyses/portfolio/sites](https://github.com/cal-itp/data-analyses/tree/main/portfolio/sites).
   - If you have already deployed but want to make changes to the README, run: `python portfolio/portfolio.py build my_report --no-execute-papermill --deploy`
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
    - For example, if only the `README.md` is updated but the notebooks have remained the same, you would run
      `python portfolio/portfolio.py build my_report --no-execute-papermill --deploy`.
  - `--no-stderr / --no-no-stderr`
    - If true, will clear stderr stream for cell outputs
  - `--continue-on-error / --no-continue-on-error`
    - Default: no-continue-on-error

## Adding to the Makefile

Another and more efficient way to write to the Analytics Portfolio is to use the Makefile and run
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
