from pyspark.sql import SparkSession
import sys

def main():
    # Deixe o Spark buscar as configurações do spark-submit automaticamente
    spark = SparkSession.builder.getOrCreate()

    print("--- INICIANDO TESTE SPARK ---")
    try:
        dados = [("Docker", 1), ("Airflow", 2), ("Spark", 3)]
        df = spark.createDataFrame(dados, ["Ferramenta", "ID"])
        df.show()
        print("--- TESTE FINALIZADO COM SUCESSO ---")
    except Exception as e:
        print(f"Erro durante a execução: {e}")
    finally:
        spark.stop()

if __name__ == "__main__":
    main()