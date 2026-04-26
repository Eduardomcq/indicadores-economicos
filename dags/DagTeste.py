from airflow import DAG
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator
from datetime import datetime

with DAG(
    dag_id='dag_teste_conexao_spark',
    start_date=datetime(2023, 1, 1),
    schedule=None,
    catchup=False,
    tags=['teste']
) as dag:

    testar_spark = SparkSubmitOperator(
        task_id='executar_script_teste',
        # Caminho onde o arquivo está Mapeado dentro do container do Airflow
        application='/opt/airflow/src/teste_spark.py',
        # ID da conexão que você deve criar na UI do Airflow
        conn_id='spark_local',
        name='airflow_spark_test_job',
        verbose=True
    )

    testar_spark