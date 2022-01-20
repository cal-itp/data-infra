FROM python:3.9
ADD requirements.txt /
RUN pip install -r /requirements.txt
ADD src /usr/local/src
RUN pip install /usr/local/src
ENTRYPOINT [ "python", "-m", "gtfs_rt_archive" ]
