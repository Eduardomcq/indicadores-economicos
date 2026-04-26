FROM apache/airflow:3.2.0
USER root
RUN apt-get update && apt-get install -y openjdk-17-jre-headless
USER airflow
RUN pip install apache-airflow-providers-apache-spark pyspark