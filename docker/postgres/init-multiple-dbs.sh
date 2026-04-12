#!/bin/bash
# =============================================================================
# Script de inicialização do PostgreSQL: cria o banco de dados "indicadores"
#
# COMO ESTE SCRIPT É EXECUTADO:
#   A imagem oficial do PostgreSQL tem um mecanismo de inicialização embutido:
#   qualquer arquivo .sh ou .sql colocado em /docker-entrypoint-initdb.d/
#   é executado automaticamente na PRIMEIRA vez que o container sobe
#   (ou seja, quando o volume postgres-data ainda está vazio).
#
#   Em execuções subsequentes (quando o volume já tem dados), esses scripts
#   são IGNORADOS — o PostgreSQL assume que a inicialização já foi feita.
#
# POR QUE ESTE SCRIPT EXISTE:
#   O PostgreSQL suporta múltiplos bancos de dados num único servidor.
#   Neste projeto, usamos o mesmo container para dois propósitos diferentes:
#
#   1. banco "airflow"      → metadados internos do Airflow
#                             (dag_runs, task_instances, connections, etc.)
#                             Criado automaticamente pela variável POSTGRES_DB
#                             na imagem oficial.
#
#   2. banco "indicadores"  → dados processados pelo pipeline
#                             (modelos gold do dbt, consumidos pelo Streamlit)
#                             Criado por ESTE script.
#
#   Em produção, esses seriam dois bancos RDS separados. Em dev, colocar tudo
#   num container só economiza recursos e simplifica o setup.
# =============================================================================
set -e
# set -e: faz o script parar imediatamente se qualquer comando falhar.
# Sem isso, um erro no CREATE DATABASE passaria silenciosamente e o banco
# "indicadores" não seria criado, causando falhas misteriosas no dbt mais tarde.

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Cria o banco de dados para os dados processados pelo pipeline dbt
    CREATE DATABASE indicadores;

    -- Concede ao usuário do Airflow acesso completo ao banco indicadores.
    -- O mesmo usuário (airflow) acessa ambos os bancos por simplicidade em dev.
    -- Em prod, o dbt usaria credenciais separadas com privilégios mínimos.
    GRANT ALL PRIVILEGES ON DATABASE indicadores TO $POSTGRES_USER;
EOSQL
