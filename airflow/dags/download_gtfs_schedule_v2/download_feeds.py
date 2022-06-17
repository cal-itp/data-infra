# ---
# python_callable: download_all
# provide_context: true
# dependencies:
#   - generate_provider_list
# ---
import traceback

import os
import pendulum
import re
from airflow.models import Variable
from airflow.utils.db import create_session
from requests import Session
from typing import List
from calitp.storage import get_fs
from utils import prefix_bucket, GTFSFeed, GTFSFeedType, GTFSExtract


def download_all(task_instance, execution_date, **kwargs):
    # TODO: use laurie's method for this
    # https://stackoverflow.com/a/61808755
    with create_session() as session:
        auth_dict = {var.key: var.val for var in session.query(Variable)}

    # TODO: get these from Airtable or whatever
    feeds: List[GTFSFeed] = [
        GTFSFeed(
            type=GTFSFeedType.schedule,
            url="https://www.bart.gov/dev/schedules/google_transit.zip",
        ),
    ]

    exceptions = []

    for feed in feeds:
        try:
            s = Session()
            r = s.prepare_request(feed.build_request(auth_dict))
            resp = s.send(r)

            # we can try a few different locations for the filename
            disp1 = re.search(
                'filename="(.+)"', resp.headers.get("content-disposition", "")
            )
            disp2 = re.search(
                'filename="(.+)"', resp.headers.get("Content-Disposition", "")
            )

            filename = (
                (disp1.group(0) if disp1 else None)
                or (disp2.group(0) if disp1 else None)
                or (os.path.basename(resp.url) if resp.url.endswith(".zip") else None)
                or "content.zip"
            )

            extract = GTFSExtract(
                feed=feed,
                filename=filename,
                response_code=resp.status_code,
                response_headers=resp.headers,
                download_time=pendulum.now(),
            )

            extract.save_content(
                fs=get_fs(),
                bucket=prefix_bucket("gtfs-schedule-raw"),
                content=resp.content,
            )

            # if resp.headers['content-type'] != 'application/zip':

        except Exception as e:
            print(
                f"exception occurred while attempting to download feed: {str(e)}",
                traceback.format_exc(),
            )
            exceptions.append(e)

    if exceptions:
        exc_str = "\n".join(map(str, exceptions))
        raise RuntimeError(
            f"got {len(exceptions)} exceptions out of {len(feeds)} feeds: {exc_str}"
        )
    else:
        print(f"successfully handled all {len(feeds)} feeds!")
