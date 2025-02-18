CREATE OR REPLACE VIEW adventureworks_bronze.Person_current AS

WITH PersonCurrent AS
(
  SELECT 
    *
    , ROW_NUMBER() OVER(PARTITION BY BusinessEntityID ORDER BY datastream_metadata.source_timestamp DESC) as rownbr
  FROM 
    adventureworks_bronze.Person_Person
)
SELECT 
  *
  , CASE 
      WHEN datastream_metadata.change_type = 'DELETE' THEN 1
      ELSE 0
  END as delete_flag
FROM 
  PersonCurrent 
WHERE 
  rownbr = 1;