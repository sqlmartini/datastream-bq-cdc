from pyspark.sql import SparkSession
from google.cloud import secretmanager
import sys

def access_secret(project_id, secret_id, version_id="latest"):
    """
    Access the payload for the given secret
    """

    # Create the Secret Manager client.
    client = secretmanager.SecretManagerServiceClient()

    # Build the resource name of the secret version.
    name = f"projects/{project_id}/secrets/{secret_id}/versions/{version_id}"

    # Access the secret version.
    response = client.access_secret_version(request={"name": name})

    payload = response.payload.data.decode("UTF-8")
    return payload

def read_config(table):
    """
    Read the ETL source to target mapping configuration
    """    
    
    config_df = (
        spark.read
        .format("bigquery")
        .option("table", table)
        .load()
    )

    config = config_df.collect()
    return config

def extract(source, db_url, db_user, db_password):
    """
    Read from source and return a dataframe
    """    
    
    print(f'source: {source}')

    extract_df = (
        spark.read
        .format("jdbc")
        .option("driver", "com.microsoft.sqlserver.jdbc.SQLServerDriver")   
        .option("url", db_url)
        .option("dbtable", source)
        .option("user", db_user)
        .option("password", db_password)
        .load()
    )

    return extract_df

def load(df, dataset_name, target):
    """
    Write to target table
    """   
    
    print(f'target: {target}')

    (df.write
        .format('bigquery')
        .mode("overwrite")
        .option("table", f"{dataset_name}.{target}")
        .option("writeMethod", "direct")
        .save())

if __name__ == "__main__":
        
    spark = SparkSession.builder.getOrCreate()

    # Parse arguments
    project_id = sys.argv[1]

    # Retrieve secret manager secrets
    db_user = access_secret(project_id, "airflow-variables-cloudsql-username")
    db_password = access_secret(project_id, "airflow-variables-cloudsql-password")
    db_ip = access_secret(project_id, "airflow-variables-cloudsql-ip")

    # Source variables
    database = "AdventureWorks2022"
    db_url = f"jdbc:sqlserver://{db_ip};databaseName={database};encrypt=true;trustServerCertificate=true;"

    # Sink variables
    dataset_name = "adventureworks_raw"  

    # Read ETL configuration
    config = read_config("adventureworks_raw.elt_config")

    # Loop through ETL configuration, read source and load to target
    for row in config:
        df = extract(row["sourceTableName"], db_url, db_user, db_password)
        load(df, dataset_name, row["targetTableName"])