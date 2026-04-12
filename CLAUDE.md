# CLAUDE.md

Pipeline de dados para indicadores econômicos do governo brasileiro (IBGE, BCB, IPEA). Extrai dados públicos, processa com Spark, transforma com dbt e serve dashboards via Streamlit.

## Stack

- **Orquestração:** Apache Airflow 3.2 (Docker Compose, LocalExecutor)
- **Processamento:** PySpark 3.5 + Delta Lake 3.3 (local em dev, EMR Serverless em prod)
- **Transformação:** dbt Core + DuckDB (lê Delta do S3, materializa no PostgreSQL)
- **Serving:** PostgreSQL 16 (RDS free tier em prod, container local em dev)
- **Dashboard:** Streamlit (Community Cloud em prod)
- **Storage:** AWS S3 com arquitetura medalhão (bronze → silver → gold)
- **Linguagem:** Python 3.12

## Arquitetura de diretórios

```
dags/extraction/       → DAGs Airflow de ingestão (APIs governo → S3 bronze)
dags/processing/       → DAGs que executam PySpark (bronze → silver)
dags/transformation/   → DAGs que executam dbt (silver → gold → PostgreSQL)
spark_jobs/            → Scripts PySpark standalone
spark_jobs/common/     → Módulos compartilhados (spark_session.py)
dbt_project/           → Projeto dbt (models, macros, tests, seeds)
streamlit_app/         → App Streamlit para dashboards
docker/airflow/        → Dockerfile e requirements.txt customizados
config/                → Arquivos .env por ambiente (dev.env, prod.env)
infra/terraform/       → IaC para provisionamento AWS
```

## Ambientes

O projeto usa dois ambientes controlados por variáveis de ambiente em `config/dev.env` e `config/prod.env`. A variável `ENV` (dev ou prod) determina o comportamento:

- **dev:** PySpark roda local no container, lê/grava em `s3://indicadores-economicos-dev/`
- **prod:** Jobs pesados submetidos ao EMR Serverless, lê/grava em `s3://indicadores-economicos-prod/`

Nunca commitar arquivos .env. Credenciais AWS ficam apenas nos arquivos de config locais.

## Comandos

```bash
docker compose build                    # Build da imagem com Airflow + PySpark + dbt
docker compose up -d                    # Sobe o ambiente (Airflow UI em http://localhost:8080)
docker compose down                     # Para o ambiente
docker compose logs -f airflow-scheduler # Logs do scheduler
docker compose exec airflow-webserver bash  # Shell dentro do container

# dbt (rodar dentro do container)
cd /opt/airflow/dbt_project && dbt debug  # Testar conexão
cd /opt/airflow/dbt_project && dbt build  # Run + test

# Spark (rodar dentro do container)
python /opt/airflow/spark_jobs/process_ipca.py  # Testar job Spark
```

## Convenções de código

- DAGs usam a TaskFlow API do Airflow 3.2 com decorators `@dag` e `@task`
- DAGs usam Assets para scheduling data-aware (não cron quando possível)
- Scripts Spark usam `spark_jobs/common/spark_session.py` para criar o SparkSession — nunca instanciar SparkSession diretamente
- `get_s3_path(layer, table)` retorna o path S3 correto baseado na variável S3_BUCKET
- Models dbt seguem a convenção `silver_<entidade>.sql` e `gold_<entidade>.sql`
- Testes dbt obrigatórios: `not_null` em colunas-chave, `unique` em chaves primárias
- Código e comentários em português, nomes de variáveis/funções em inglês

## Regras importantes

- NUNCA hardcodar nomes de bucket S3 — sempre usar `os.environ["S3_BUCKET"]`
- NUNCA commitar credenciais ou arquivos .env
- DAGs devem ter `catchup=False` por padrão
- Scripts Spark devem sempre chamar `spark.stop()` ao final
- Delta Lake é o formato padrão para escrita no S3 (nunca Parquet puro)
- Ao criar novos indicadores, seguir o fluxo completo: DAG extração → script Spark → model dbt

## Quando compactar

Ao compactar, preservar: lista de arquivos modificados, estado atual do pipeline (quais DAGs existem), e decisões de arquitetura tomadas.