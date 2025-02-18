from pendulum import datetime
import os
import random
import string
from airflow.decorators import dag
from airflow.models import Variable
from airflow.providers.google.cloud.operators.dataproc import DataprocCreateBatchOperator

@dag(
    start_date=datetime(2024, 1, 1), schedule=None, catchup=False
)
def dataproc_synchronous():

    # Airflow environment variables
    PROJECT_ID = os.environ['ENV_PROJECT_ID'] 
    REGION = os.environ['ENV_DATAPROC_REGION'] 
    SUBNET = os.environ['ENV_DATAPROC_SUBNET']
    DATAPROC_BUCKET = os.environ['ENV_DATAPROC_BUCKET']

    # Airflow secret backend - google cloud secret manager
    SERVICE_ACCOUNT_ID = Variable.get('dataproc-service-account')

    JOB_FILE = f"{DATAPROC_BUCKET}/scripts/pyspark/spark_etl_synchronous.py"
    JAR_FILE = f"{DATAPROC_BUCKET}/drivers/mssql-jdbc-12.4.0.jre8.jar"

    # This is to add a random suffix to the serverless Spark batch ID that needs to be unique each run 
    ran = ''.join(random.choices(string.digits, k = 10))
    BATCH_ID = "cloudsql-extract-"+str(ran)

    BATCH_CONFIG = {
        "pyspark_batch": {
            "main_python_file_uri": JOB_FILE,
            "args": [
                PROJECT_ID
            ],
            "jar_file_uris": [JAR_FILE]
        },
        "environment_config":{
            "execution_config":{
                "service_account": SERVICE_ACCOUNT_ID,
                "subnetwork_uri": SUBNET
                }
        },
        "runtime_config":{
            "version":"2.2"
        }            
    }

    run_spark = DataprocCreateBatchOperator(
        task_id="extract_cloudsql",
        project_id=PROJECT_ID,
        region=REGION,
        batch=BATCH_CONFIG,
        batch_id=BATCH_ID
    )

    run_spark

dataproc_synchronous()