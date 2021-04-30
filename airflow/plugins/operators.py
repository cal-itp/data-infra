import os
import pandas as pd

from functools import wraps

from airflow.utils.db import provide_session
from airflow.sensors import ExternalTaskSensor
from airflow.contrib.operators.gcp_container_operator import GKEPodOperator
from airflow.contrib.operators.kubernetes_pod_operator import KubernetesPodOperator
from airflow.contrib.operators.bigquery_operator import (
    BigQueryCreateExternalTableOperator,
)
from airflow.contrib.hooks.bigquery_hook import BigQueryHook
from airflow.models import BaseOperator
from airflow.operators import PythonOperator
from googleapiclient.errors import HttpError

from airflow.utils.decorators import apply_defaults
from airflow import AirflowException

from calitp import (
    is_development,
    get_project_id,
    format_table_name,
    save_to_gcfs,
    read_gcfs,
)


@wraps(KubernetesPodOperator)
def pod_operator(*args, **kwargs):
    # TODO: tune this, and add resource limits
    namespace = "default"

    if is_development():
        return GKEPodOperator(
            *args,
            in_cluster=False,
            project_id=get_project_id(),
            location=os.environ["POD_LOCATION"],
            cluster_name=os.environ["POD_CLUSTER_NAME"],
            namespace=namespace,
            **kwargs,
        )

    else:
        return KubernetesPodOperator(*args, namespace=namespace, **kwargs)


class PythonTaskflowOperator(PythonOperator):
    @apply_defaults
    def __init__(
        self,
        python_callable,
        op_args=None,
        op_kwargs=None,
        provide_context=False,
        templates_dict=None,
        templates_exts=None,
        taskflow=None,
        *args,
        **kwargs,
    ):
        super(PythonOperator, self).__init__(*args, **kwargs)

        # taskflow specific ----
        self.taskflow = taskflow
        if isinstance(python_callable, str):
            # if python_callable is a string of form mod_name.func_name,
            # try to import function
            import importlib

            *mod_path, func_name = python_callable.split(".")
            python_callable = getattr(
                importlib.import_module(".".join(mod_path)), func_name
            )

        # original PythonOperator init code
        self.python_callable = python_callable
        self.op_args = op_args or []
        self.op_kwargs = op_kwargs or {}
        self.provide_context = provide_context
        self.templates_dict = templates_dict
        if templates_exts:
            self.template_ext = templates_exts

    def execute(self, context):
        if self.taskflow:
            ti = context["task_instance"]

            # update op_kwargs to include data pulled from xcom
            for k, v in self.taskflow.items():
                from collections.abc import Mapping

                if isinstance(v, Mapping):
                    dag_id = v.get("dag_id", None)
                    task_ids = v["task_ids"]
                else:
                    dag_id = None
                    task_ids = v

                self.op_kwargs[k] = ti.xcom_pull(dag_id=dag_id, task_ids=task_ids)

        return super().execute(context)


class MaterializedViewOperator(BaseOperator):
    def __init__(
        self,
        sql,
        src_table,
        bigquery_conn_id="bigquery_default",
        num_retries=0,
        **kwargs,
    ):
        self.sql = sql
        self.src_table = src_table
        self.bigquery_conn_id = bigquery_conn_id
        self.num_retries = num_retries
        super().__init__(**kwargs)

    def execute(self, context):
        full_table_name = format_table_name(self.src_table)
        dataset_id, table_id = full_table_name.split(".")

        bq_hook = BigQueryHook(bigquery_conn_id=self.bigquery_conn_id)
        conn = bq_hook.get_conn()
        cursor = conn.cursor()

        table_resource = {
            "tableReference": {"table_id": table_id},
            "materializedView": {"query": self.sql},
        }

        # bigquery.Table.from_api_repr(table_resource)
        project_id = get_project_id()

        try:
            cursor.service.tables().insert(
                projectId=project_id, datasetId=dataset_id, body=table_resource
            ).execute(num_retries=self.num_retries)

            self.log.info(
                "Table created successfully: %s:%s.%s", project_id, dataset_id, table_id
            )
        except HttpError as err:
            raise AirflowException("BigQuery error: %s" % err.content)


class SqlToWarehouseOperator(BaseOperator):
    template_fields = ("sql",)

    def __init__(
        self,
        sql,
        dst_table_name,
        bigquery_conn_id="bigquery_default",
        create_disposition="CREATE_IF_NEEDED",
        **kwargs,
    ):
        self.sql = sql
        self.dst_table_name = dst_table_name
        self.bigquery_conn_id = bigquery_conn_id
        self.create_disposition = create_disposition
        super().__init__(**kwargs)

    def execute(self, context):
        full_table_name = format_table_name(self.dst_table_name)
        print(full_table_name)

        bq_hook = BigQueryHook(bigquery_conn_id=self.bigquery_conn_id)
        conn = bq_hook.get_conn()
        cursor = conn.cursor()

        print(self.sql)

        # table_resource = {
        #    "tableReference": {"table_id": table_id},
        #    "materializedView": {"query": self.sql}
        # }

        # bigquery.Table.from_api_repr(table_resource)

        try:
            cursor.run_query(
                sql=self.sql,
                destination_dataset_table=full_table_name,
                write_disposition="WRITE_TRUNCATE",
                create_disposition=self.create_disposition,
                use_legacy_sql=False,
            )

            self.log.info(
                "Query table as created successfully: {}".format(full_table_name)
            )
        except HttpError as err:
            raise AirflowException("BigQuery error: %s" % err.content)


class ExternalTable(BigQueryCreateExternalTableOperator):
    def execute(self, context):
        super().execute(context)

        return self.schema_fields


class OnceOffExternalTaskSensor(ExternalTaskSensor):
    def __init__(self, external_dag_id, **kwargs):
        super().__init__(external_dag_id=external_dag_id, **kwargs)

        last_exec = self.get_dag_last_execution_date(self.external_dag_id)

        # a once dag runs only on its start_date (which can be set by users)
        self.execution_date_fn = lambda crnt_dttm: last_exec

    @provide_session
    def get_dag_last_execution_date(self, dag_id, session):
        from airflow.models import DagModel

        q = session.query(DagModel).filter(DagModel.dag_id == self.external_dag_id)

        dag = q.first()
        return dag.get_last_dagrun().execution_date


def _keep_columns(
    src_path, dst_path, colnames, itp_id=None, url_number=None, extracted_at=None,
):

    # read csv using object dtype, so pandas does not coerce data
    df = pd.read_csv(read_gcfs(src_path), dtype="object")

    if itp_id is not None:
        df["calitp_itp_id"] = itp_id

    if url_number is not None:
        df["calitp_url_number"] = url_number

    # get specified columns, inserting NA columns where needed ----
    df_cols = set(df.columns)
    cols_present = [x for x in colnames if x in df_cols]

    df_select = df.loc[:, cols_present]

    # fill in missing columns ----
    print("DataFrame missing columns: ", set(df_select.columns) - set(colnames))

    for ii, colname in enumerate(colnames):
        if colname not in df_select:
            df_select.insert(ii, colname, pd.NA)

    if extracted_at is not None:
        df_select["calitp_extracted_at"] = extracted_at

    # save result ----
    csv_result = df_select.to_csv(index=False).encode()

    save_to_gcfs(csv_result, dst_path, use_pipe=True)
