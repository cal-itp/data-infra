FROM python:3.9
ADD requirements.txt /
RUN pip install -r /requirements.txt
ADD gtfs-rt-archive.py /
ENTRYPOINT [ "python", "/gtfs-rt-archive.py" ]
