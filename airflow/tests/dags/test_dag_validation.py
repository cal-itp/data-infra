from airflow.models import DagBag


def test_no_import_errors():
    dag_bag = DagBag(dag_folder="../../dags/", include_examples=False)
    assert len(dag_bag.import_errors) == 0, "No Import Failures"


def test_retries_present():
    dag_bag = DagBag(dag_folder="../../dags/", include_examples=False)
    print(dag_bag)
    for dag in dag_bag.dags:
        retries = dag_bag.dags[dag].default_args.get("retries", [])
        error_msg = "Retries not set to 2 for DAG {id}".format(id=dag)
        assert retries == 0, error_msg
