import os
import pathlib
from airflow.models import DagBag,DagRun


def get_most_recent_dag_run(dag_id: str):
    dag_runs = DagRun.find(dag_id=dag_id)
    dag_runs.sort(key=lambda x: x.execution_date, reverse=True)
    return dag_runs[0] if dag_runs else None

def get_dag(dag_id: str):
    current_directory = os.path.dirname(os.path.realpath(__file__))
    dag_folder = pathlib.Path(current_directory) / '..' / '..' / 'dags'
    dag_bag = DagBag(include_examples=False, dag_folder=dag_folder, collect_dags=False)
    filepath = dag_folder / 'simple_dag.py'
    dag_bag.process_file(filepath=str(filepath.resolve()))
    assert dag_bag.import_errors == {}
    return dag_bag.get_dag(dag_id)


def test_return_goodbye_message():
    dag = get_dag('simple')
    dag.test()
    dagrun = get_most_recent_dag_run('simple')
    ti = dagrun.get_task_instance(task_id='return_goodbye_message')
    assert ti.xcom_pull() == 'Hi and hello, whoops goodbye!'
