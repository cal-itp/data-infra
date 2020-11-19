FROM jupyter/datascience-notebook:python-3.8.6

USER root
# Having a CLI text editor is nice.
RUN apt-get update && apt-get install -y vim graphviz openssh-client gdebi-core bash-completion libaio1 

# Rstudio integration
RUN apt-get update && \
    curl --silent -L --fail https://download2.rstudio.org/server/xenial/amd64/rstudio-server-1.3.1093-amd64.deb > /tmp/rstudio.deb && \
    apt-get install -y /tmp/rstudio.deb && \
    rm /tmp/rstudio.deb && \
    apt-get clean
ENV PATH=$PATH:/usr/lib/rstudio-server/bin
USER $NB_UID

# Install conda dependencies early, as it takes a long time.
RUN conda install -c conda-forge \
  geopandas \
  intake \
  intake-parquet \
  jupyter_nbextensions_configurator \ 
  nodejs \
  xlrd 

# R shiny-server needs to be installed after the R package
USER root
RUN wget https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-1.5.9.923-amd64.deb -O /tmp/shiny.deb
RUN gdebi -n /tmp/shiny.deb && fix-permissions /var/log/shiny-server /var/lib/shiny-server
RUN rm /tmp/shiny.deb
USER $NB_UID

# Install Oracle Instant Client drivers.
USER root
RUN wget https://download.oracle.com/otn_software/linux/instantclient/19600/instantclient-basic-linux.x64-19.6.0.0.0dbru.zip -O instant_client.zip
RUN unzip instant_client.zip && mkdir -p /opt/oracle && mv instantclient_19_6 /opt/oracle/
RUN echo /opt/oracle/instantclient_19_6 > /etc/ld.so.conf.d/oracle-instantclient.conf && ldconfig
RUN rm instant_client.zip
USER $NB_UID

# Install some stuff from CRAN + Github that is not available on conda-forge.
# env tar for r urbanmapper / github install r packages
ENV TAR="/bin/tar"
RUN R -e "install.packages(c('tidycensus'), dependencies=TRUE, repos = 'http://cran.us.r-project.org')"

# Rebuilding lab also takes a long time.
RUN jupyter labextension install --no-build @jupyter-voila/jupyterlab-preview
RUN jupyter labextension install --no-build @jupyter-widgets/jupyterlab-manager
RUN jupyter labextension install --no-build @jupyterlab/geojson-extension
RUN jupyter labextension install --no-build @jupyterlab/git
RUN jupyter labextension install --no-build @jupyterlab/github
RUN jupyter labextension install --no-build @jupyterlab/toc
#RUN jupyter labextension install --no-build caltrans-labextension@0.1.0
RUN jupyter labextension install --no-build bqplot
RUN jupyter labextension install --no-build arcgis-map-ipywidget
RUN jupyter labextension install --no-build dask-labextension
RUN jupyter labextension install --no-build jupyter-leaflet
RUN jupyter labextension install --no-build jupyterlab-plotly
RUN jupyter labextension install --no-build jupyterlab-dash
RUN jupyter labextension install --no-build jupyterlab-spreadsheet
RUN jupyter labextension install --no-build nbdime-jupyterlab
RUN jupyter labextension install --no-build plotlywidget

# jupyterlab-sql installs a labextension behind the scenes.
RUN pip install \
  dask_labextension>=1.0 \
  jupyter-rsession-proxy \
  jupyterlab-dash==0.1.0a3 \
  jupyterlab_git>=0.6.1 \
  jupyterlab_github>=1.0 \
  jupyterlab_sql>=0.3 \
  nbdime \
  voila  

# Enable the serverextensions that do not use the conf.d approach
#RUN jupyter serverextension enable --sys-prefix jupyterlab_sql
#RUN jupyter serverextension enable --sys-prefix jupyterlab_git

# Build JupyterLab.
RUN jupyter lab build --dev-build=False --debug && jupyter lab clean

# Install some python-only packages using pip
RUN pip install \
  altair \
  arcgis==1.7.0 \
  black \
  bqplot \
  census-data-downloader \
  CensusData \
  contextily \
  cookiecutter \ 
  cx_Oracle \
  descartes \
  flake8 \
  folium \
  geoalchemy2 \
  geocoder \
  geopy \
  ibis-framework \
  intake_geopandas \
  intake_dcat \
  ipyleaflet \
  ipywidgets \
  isort \
  kmodes \
  mapboxgl \
  markov_clustering \
  mypy \
  openpyxl \
  papermill \
  partridge \
  plotly>=4.0 \
  plotly-geo>=1.0 \
  polyline \
  psycopg2 \
  selenium \
  sodapy \
  usaddress \
  vega-datasets \
  xlsxwriter

# Jupyter/IPython config
USER root
RUN mkdir -p /etc/ipython
COPY ipython_config.py /etc/ipython/
COPY jupyter_notebook_config.py ${CONDA_DIR}/etc/jupyter/
USER $NB_UID

# Environment-related
USER root
COPY custom.sh /tmp/custom.sh
RUN cat /tmp/custom.sh >> /etc/bash.bashrc
USER $NB_UID

# Use bash login shell for entrypoint in order
# to automatically source user's .bash_profile
CMD ["bash", "-l", "-c", "'start-notebook.sh'"]
