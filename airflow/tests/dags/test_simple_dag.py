import os
import pathlib
from airflow.models import DagBag

def get_dag():
    current_directory = os.path.dirname(os.path.realpath(__file__))
    dag_folder = pathlib.Path(current_directory) / '..' / '..' / 'dags'
    dag_bag = DagBag(include_examples=False, dag_folder=dag_folder, collect_dags=False)
    filepath = dag_folder / 'simple_dag.py'
    dag_bag.process_file(filepath=str(filepath.resolve()))
    assert dag_bag.import_errors == {}
    return dag_bag.get_dag('simple')

def test_return_goodbye_message():
    dag = get_dag()
    results = dag.test()
    ti = results.get_task_instance(task_id='return_goodbye_message')
    assert ti.xcom_pull() == 'Hi and hello, beans!'
