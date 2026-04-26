from airflow.decorators import dag, task
from datetime import datetime


@dag(
    dag_id='DagTaxaSelic',
    schedule=None,
    start_date=datetime(2023, 1, 1),
    catchup=False,
    tags=['exemplo', 'generica'],
)
def exemplo_taskflow():

    @task
    def primeira_tarefa():
        print("Iniciando o fluxo: tarefa 1 executada.")
        return "dados_da_tarefa_1"

    @task
    def segunda_tarefa(input_data):
        print(f"Processando {input_data}: tarefa 2 executada.")
        return "dados_da_tarefa_2"

    @task
    def terceira_tarefa(input_data):
        print(f"Finalizando com {input_data}: tarefa 3 executada.")

    # Definindo a dependência (o fluxo dos dados)
    dados_1 = primeira_tarefa()
    dados_2 = segunda_tarefa(dados_1)
    terceira_tarefa(dados_2)

# Instanciando a DAG
exemplo_taskflow()