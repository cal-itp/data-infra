from tests.conftest import get_dag, get_most_recent_dag_run

def test_fetches_device_health(dag_bag):
    get_dag(dag_bag, 'sync_kuba_dag.py', 'sync_kuba').test()
    dag_run = get_most_recent_dag_run('sync_kuba')
    ti = dag_run.get_task_instance(task_id='fetch_locations')
    assert ti.xcom_pull() == 'beans'
