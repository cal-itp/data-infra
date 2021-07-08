FROM python:3.9
RUN pip install pyyaml google-auth requests
ADD gtfs-rt-archive.py /
ENTRYPOINT [ "python", "/gtfs-rt-archive.py" ]
