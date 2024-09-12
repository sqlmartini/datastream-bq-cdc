SELECT
  *
FROM
  EXTERNAL_QUERY( 
    'us-west3.cloud-sql',
    'SELECT * FROM driver'
  )