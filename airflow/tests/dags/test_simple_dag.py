from airflow.models import DagBag

# This will test the DAG is valid and the tasks are properly set up
def test_valid_dag():
    dag = get_dag()
    assert dag is not None
    assert len(dag.tasks) == 1 # assert tasks are correctly found in the DAG

# This will execute the DAG tasks and test the return value of the task
def test_return_goodbye_message():
    dag = get_dag()

    results = dag.test() # execute the DAG and get the DagRun response
    ti = results.get_task_instance(task_id='return_goodbye_message')
    assert ti.xcom_pull() == 'Hi and hello, whoops goodbye!' # assert the return value of the task

def get_dag():
    dag_bag = DagBag(include_examples=False, dag_folder='dags')
    assert dag_bag.import_errors == {}
    return dag_bag.get_dag('simple')
