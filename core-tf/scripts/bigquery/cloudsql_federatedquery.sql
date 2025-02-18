--Query Cloud SQL
SELECT
  *
FROM
  EXTERNAL_QUERY( 
    'us-west3.cloud-sql',
    'SELECT * FROM driver'
  );


--Create external table on cloud storage
CREATE OR REPLACE EXTERNAL TABLE `anthonymm-477-20240907180337.federated_demo.ext_LicenseState`
(
    license_plate STRING,
    state STRING
)
OPTIONS (
    format = "CSV",
    field_delimiter = ',',
    skip_leading_rows = 0,
    uris = ['gs://processed-anthonymm-477-20240907180337-duznot7fh9/processed/taxi-data/license_state/*.csv']
);

--Query to join cloud sql and cloud storage tables
SELECT
  *
FROM
  EXTERNAL_QUERY( 
    'us-west3.cloud-sql',
    'SELECT * FROM driver'
  ) a
INNER JOIN
  federated_demo.ext_LicenseState b
ON
  a.license_plate = b.license_plate;