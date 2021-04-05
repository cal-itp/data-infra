"""
This module subclasses the GKEPodOperator from airflow, and makes a single change:

A return statement added to execute.
"""

# flake8: noqa

#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
import os
import subprocess
import tempfile

from airflow.contrib.operators.gcp_container_operator import GKEPodOperator

KUBE_CONFIG_ENV_VAR = "KUBECONFIG"


class GKEPodOperator2(GKEPodOperator):

    # NOTE: this method copied from GKEPodOperator
    def execute(self, context):
        # Specifying a service account file allows the user to using non default
        # authentication for creating a Kubernetes Pod. This is done by setting the
        # environment variable `GOOGLE_APPLICATION_CREDENTIALS` that gcloud looks at.
        key_file = None

        # If gcp_conn_id is not specified gcloud will use the default
        # service account credentials.
        if self.gcp_conn_id:
            from airflow.hooks.base_hook import BaseHook

            # extras is a deserialized json object
            extras = BaseHook.get_connection(self.gcp_conn_id).extra_dejson
            # key_file only gets set if a json file is created from a JSON string in
            # the web ui, else none
            key_file = self._set_env_from_extras(extras=extras)

        # Write config to a temp file and set the environment variable to point to it.
        # This is to avoid race conditions of reading/writing a single file
        with tempfile.NamedTemporaryFile() as conf_file:
            os.environ[KUBE_CONFIG_ENV_VAR] = conf_file.name
            # Attempt to get/update credentials
            # We call gcloud directly instead of using google-cloud-python api
            # because there is no way to write kubernetes config to a file, which is
            # required by KubernetesPodOperator.
            # The gcloud command looks at the env variable `KUBECONFIG` for where to save
            # the kubernetes config file.
            subprocess.check_call(
                [
                    "gcloud",
                    "container",
                    "clusters",
                    "get-credentials",
                    self.cluster_name,
                    "--zone",
                    self.location,
                    "--project",
                    self.project_id,
                ]
            )

            # Since the key file is of type mkstemp() closing the file will delete it from
            # the file system so it cannot be accessed after we don't need it anymore
            if key_file:
                key_file.close()

            # Tell `KubernetesPodOperator` where the config file is located
            self.config_file = os.environ[KUBE_CONFIG_ENV_VAR]
            return super(GKEPodOperator, self).execute(context)
