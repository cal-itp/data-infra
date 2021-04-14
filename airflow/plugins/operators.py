import os
import pandas as pd

from functools import wraps

from airflow.contrib.operators.gcp_container_operator import GKEPodOperator
from airflow.contrib.operators.kubernetes_pod_operator import KubernetesPodOperator
from airflow.contrib.operators.gcs_to_bq import GoogleCloudStorageToBigQueryOperator
from airflow.contrib.hooks.bigquery_hook import BigQueryHook
from airflow.models import BaseOperator
from airflow.operators import PythonOperator, SubDagOperator

from airflow.utils.decorators import apply_defaults
from airflow import DAG

from calitp import (
    is_development,
    get_bucket,
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
            project_id=os.environ["GOOGLE_CLOUD_PROJECT"],
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


# CsvColumnSelectOperator ----

# Npte: airflow v1 doesn't have task groups, so trying out a SubDag as an
# alternative. They are not as nice in the UI, and have some other limitations.
# TODO: in the long run, should pull logic for uploading to bigquery into the
#       cal-itp package, so few operators are needed, and we don't have to
#       worry about stiching them together.
class stage_on_bigquery(SubDagOperator):
    # TODO: this should be a function that returns an operator, but an issue
    # in gusty requires using a class with an __init__ method.
    # see: https://github.com/chriscardillo/gusty/issues/26
    def __new__(
        cls,
        parent_id,
        gcs_dirs_xcom,
        dst_dir,
        filename,
        schema_fields,
        table_name,
        task_id,
        dag,
    ):
        from airflow.utils.dates import days_ago

        args = {
            "start_date": days_ago(2),
        }

        bucket = get_bucket().replace("gs://", "", 1)
        full_table_name = format_table_name(table_name, is_staging=True)

        subdag = DAG(dag_id=f"{parent_id}.{task_id}", default_args=args)

        column_names = [schema["name"] for schema in schema_fields]

        # by convention, preface task names with dag_id
        op_col_select = PythonTaskflowOperator(
            task_id="select_cols",
            python_callable=_keep_columns,
            # note that this input should have form schedule/{execution_date}/...
            taskflow={"gcs_dirs": {"dag_id": parent_id, "task_ids": gcs_dirs_xcom}},
            op_kwargs={
                "dst_dir": dst_dir,
                "filename": filename,
                "required_cols": [],
                "optional_cols": column_names,
            },
            dag=subdag,
        )

        op_stage_bq = GoogleCloudStorageToBigQueryOperator(
            task_id="stage_bigquery",
            bucket=bucket,
            # note that we can't really pull a list out of xcom without subclassing
            # operators, so we really on knowing that the task passing in
            # gcs_dirs_xcom data is using schedule/{execution_date}
            source_objects=[
                "schedule/{{execution_date}}/*/%s/%s" % (dst_dir, filename)
            ],
            schema_fields=schema_fields,
            destination_project_dataset_table=full_table_name,
            create_disposition="CREATE_IF_NEEDED",
            write_disposition="WRITE_TRUNCATE",
            # _keep_columns function includes headers in output
            skip_leading_rows=1,
            dag=subdag,
        )

        op_col_select >> op_stage_bq

        return SubDagOperator(subdag=subdag, dag=dag, task_id=task_id)

    def __init__(
        self,
        parent_id,
        gcs_dirs_xcom,
        dst_dir,
        filename,
        schema_fields,
        table_name,
        *args,
        **kwargs,
    ):
        pass


def _keep_columns(
    gcs_dirs, dst_dir, filename, required_cols, optional_cols, prepend_ids=True
):
    for path in gcs_dirs:
        full_src_path = f"{path}/{filename}"
        full_dst_path = f"{path}/{dst_dir}/{filename}"

        final_header = [*required_cols, *optional_cols]

        # read csv using object dtype, so pandas does not coerce data
        df = pd.read_csv(read_gcfs(full_src_path), dtype="object")

        # preprocess data to include cal-itp id columns ---
        # column names: calitp_id, calitp_url_number
        if prepend_ids:
            # hacky, but parse /path/.../{itp_id}/{url_number}
            basename = path.split("/")[-1]
            itp_id, url_number = map(int, basename.split("_"))

            df = df.assign(calitp_itp_id=itp_id, calitp_url_number=url_number)

        # get specified columns, inserting NA columns where needed ----
        df_cols = set(df.columns)
        opt_cols_present = [x for x in optional_cols if x in df_cols]

        df_select = df[[*required_cols, *opt_cols_present]]

        # fill in missing columns ----
        for ii, colname in enumerate(final_header):
            if colname not in df_select:
                print("INSERTING MISSING COLUMN")
                df_select.insert(ii, colname, pd.NA)
            print("SHAPE: ", df_select.shape)

        # save result ----
        csv_result = df_select

        encoded = csv_result.to_csv(index=False).encode()
        save_to_gcfs(encoded, full_dst_path, use_pipe=True)


# ----


class MoveStagingTablesOperator(BaseOperator):
    # TODO: does composer expose the project id in a non-internal env var?
    #       otherwise, we can define a custom one and use that.
    def __init__(
        self,
        dataset,
        dst_table_names,
        bigquery_conn_id="bigquery_default",
        *args,
        **kwargs,
    ):
        self.dataset = dataset
        self.dst_table_names = dst_table_names
        self.bigquery_conn_id = bigquery_conn_id

        super().__init__(*args, **kwargs)

    def execute(self, context):
        if self.dataset:
            raw_tables = [f"{self.dataset}.{tbl}" for tbl in self.dst_table_names]
        else:
            raw_tables = self.dst_table_names

        dst_table_names = [format_table_name(x) for x in raw_tables]

        src_table_names = [format_table_name(x, is_staging=True) for x in raw_tables]

        bq_hook = BigQueryHook(bigquery_conn_id=self.bigquery_conn_id)
        conn = bq_hook.get_conn()
        cursor = conn.cursor()

        for src, dst in zip(src_table_names, dst_table_names):
            cursor.run_copy(src, dst)

        # once all tables moved, then delete staging
        for src in src_table_names:
            cursor.run_table_delete(src)

        return dst_table_names
