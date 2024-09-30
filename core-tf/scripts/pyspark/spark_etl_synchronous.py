from pyspark.sql import SparkSession

database = "AdventureWorks2022"
db_url = f"jdbc:sqlserver://10.2.0.2;databaseName={database};encrypt=true;trustServerCertificate=true;"
db_user = "sqlserver"
db_password = "P@ssword@111"

project_name = "amm-beacon-demo"
dataset_name = "adventureworks_raw"
bucket = "s8s_data_and_code_bucket-188308391391"

def read_config(table):

    config_df = (
        spark.read
        .format("bigquery")
        .option("table", table)
        .load()
    )

    config = config_df.collect()

    for row in config:
        load_table(row["sourceTableName"], row["targetTableName"])

def load_table(source, target):
    print(f'source: {source}')
    print(f'target: {target}')

    load_df = (
        spark.read
        .format("jdbc")
        .option("driver", "com.ibm.as400.access.AS400JDBCDriver")   
        .option("url", db_url)
        .option("dbtable", source)
        .option("user", db_user)
        .option("password", db_password)
        .load()
    )

    load_df.write \
    .format('bigquery') \
    .mode("overwrite") \
    .option("table","{}.{}".format(dataset_name, target)) \
    .option("temporaryGcsBucket", bucket) \
    .save()        

spark = SparkSession.builder \
  .appName("ETL Testing")\
  .getOrCreate()

read_config("adventureworks_raw.elt_config")