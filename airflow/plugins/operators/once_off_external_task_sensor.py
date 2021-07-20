from airflow.sensors import ExternalTaskSensor
from airflow.utils.db import provide_session


class OnceOffExternalTaskSensor(ExternalTaskSensor):
    def __init__(self, external_dag_id, **kwargs):
        super().__init__(external_dag_id=external_dag_id, **kwargs)

        # a once dag runs only on its start_date (which can be set by users)
        # so we create a function to get that date.
        def dag_last_exec(crnt_dttm):
            return self.get_dag_last_execution_date(self.external_dag_id)

        self.execution_date_fn = dag_last_exec

    @provide_session
    def get_dag_last_execution_date(self, dag_id, session):
        from airflow.models import DagModel

        q = session.query(DagModel).filter(DagModel.dag_id == self.external_dag_id)

        dag = q.first()
        return dag.get_last_dagrun().execution_date
