from airflow.operators import PythonOperator
from airflow.utils.decorators import apply_defaults


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
