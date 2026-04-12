# =============================================================================
# Imagem base: Airflow 3.2 oficial com Python 3.12
#
# Usamos a imagem OFICIAL do Airflow como ponto de partida porque ela já vem
# com o Airflow instalado corretamente, incluindo todas as dependências internas
# (Flask, SQLAlchemy, Celery, etc.) nas versões certas.
#
# Criar uma imagem do zero (FROM python:3.12) seria muito mais trabalhoso e
# propenso a conflitos de dependência.
#
# A tag "3.2.0-python3.12" garante:
#   - Versão exata do Airflow (3.2.0)
#   - Versão exata do Python (3.12)
#   - Build reproduzível: o mesmo tag sempre gera o mesmo resultado
# =============================================================================
FROM apache/airflow:3.2.0-python3.12

# =============================================================================
# Instalação do Java (necessário para o PySpark)
#
# PySpark não é um programa Python puro — ele é uma interface Python para o
# Apache Spark, que é escrito em Scala/Java. Quando você executa um script
# PySpark, o Python inicia uma JVM (Java Virtual Machine) por baixo dos panos.
# Sem Java instalado, o PySpark falha com erro "JAVA_HOME is not set".
#
# POR QUE USER ROOT?
# A imagem oficial do Airflow roda como um usuário não-privilegiado chamado
# "airflow" (UID 50000). Isso é uma boa prática de segurança: se alguém
# invadir o container, fica restrito a um usuário sem permissões especiais.
#
# Porém, instalar pacotes do sistema operacional com "apt-get" requer
# privilégios de administrador (root). Por isso, temporariamente viramos root
# apenas para esta etapa de instalação do sistema.
# =============================================================================
USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    # openjdk-17-jre-headless: Java Runtime Environment versão 17
    #
    # Por que JRE e não JDK?
    #   JDK (Java Development Kit) = JRE + compilador javac + ferramentas de debug
    #   JRE (Java Runtime Environment) = só o necessário para EXECUTAR programas Java
    #   PySpark só executa Java (não compila), então o JDK seria desperdício de espaço.
    #
    # Por que "-headless"?
    #   A variante headless exclui bibliotecas gráficas (AWT, Swing, JavaFX).
    #   Um container de servidor nunca vai abrir janelas — essas libs são inúteis
    #   e adicionariam ~100MB à imagem sem nenhum benefício.
    #
    # Por que Java 17?
    #   Java 17 é o LTS (Long Term Support) atual e é suportado pelo PySpark 3.5.
    #   Java 21 existe mas tem algumas incompatibilidades com JARs internos do Spark.
    openjdk-17-jre-headless \
    # --no-install-recommends: não instala pacotes "recomendados" (opcionais).
    # Esses pacotes raramente são necessários em ambiente de servidor e
    # podem adicionar centenas de MB à imagem sem nenhum benefício prático.
    && apt-get clean \
    # Remove o índice de pacotes do apt após a instalação.
    # Este índice (~50MB) só é necessário durante o "apt-get install".
    # Removê-lo aqui mantém esta layer do Docker mais compacta.
    # IMPORTANTE: isso deve estar no mesmo RUN que o apt-get para funcionar —
    # cada RUN cria uma layer separada no Docker, e o índice já estaria salvo
    # se estivesse em um RUN diferente.
    && rm -rf /var/lib/apt/lists/*

# Informa ao PySpark (e a qualquer outro programa) onde o Java está instalado.
# Sem JAVA_HOME, o PySpark tenta encontrar o Java automaticamente e pode falhar
# dependendo de como o PATH está configurado dentro do container.
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# Adiciona o binário do Java ao PATH para que "java -version" funcione
# diretamente no shell sem precisar especificar o caminho completo.
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# =============================================================================
# Instalação das dependências Python
#
# VOLTA para o usuário "airflow" ANTES de instalar pacotes Python.
#
# Por que isso importa?
#   O pip instala pacotes no diretório home do usuário atual:
#   - root  → /root/.local/lib/python3.12/site-packages/
#   - airflow → /home/airflow/.local/lib/python3.12/site-packages/
#
#   O Airflow roda como usuário "airflow". Se instalássemos como root,
#   o Airflow não encontraria os pacotes em runtime — eles estariam no
#   diretório do root, não no do airflow.
# =============================================================================
USER airflow

# Copia o arquivo de dependências para dentro da imagem ANTES de instalar.
#
# Por que copiar antes?
#   Docker constrói imagens em layers (camadas). Cada instrução (RUN, COPY, etc.)
#   gera uma layer que é cacheada. Se você não mudar o requirements.txt,
#   a layer do "pip install" fica em cache e o rebuild é instantâneo.
#
#   Se copiássemos o código todo antes do pip install, qualquer mudança
#   em qualquer arquivo (inclusive um DAG) invalidaria o cache do pip install,
#   tornando todos os rebuilds lentos (5-10 minutos).
COPY requirements.txt /opt/airflow/requirements.txt

RUN pip install --no-cache-dir -r /opt/airflow/requirements.txt
# --no-cache-dir: não salva o cache de download dos pacotes DENTRO da imagem.
# O cache do pip é útil para rebuilds rápidos na sua máquina local,
# mas dentro de uma imagem Docker ele ocupa espaço sem nenhum benefício
# (a imagem é recriada do zero cada vez que a build roda em CI/CD).
