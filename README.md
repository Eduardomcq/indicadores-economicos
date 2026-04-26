# indicadores-economicos

## Subindo a infraestrutura

```bash
# 1. Construir a imagem customizada do Airflow (Airflow 3.2.0 + Java 17 + PySpark)
docker compose build

# 2. Inicializar o banco de metadados e criar o usuário admin
docker compose up airflow-init

# 3. Subir todos os serviços em segundo plano
docker compose up -d
```

## Acessos

- Airflow UI: http://localhost:8080 (usuário: `airflow` / senha: `airflow`)
- Spark Master UI: http://localhost:8081

## Derrubando a infraestrutura

```bash
docker compose down
```
