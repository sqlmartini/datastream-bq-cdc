CREATE OR REPLACE VIEW adventureworks_bronze.Customer_current AS

WITH CustomerCurrent AS
(
  SELECT 
    *
    , ROW_NUMBER() OVER(PARTITION BY CustomerID ORDER BY datastream_metadata.source_timestamp DESC) as rownbr
  FROM 
    adventureworks_bronze.Sales_Customer
)
SELECT 
  *
  , CASE 
      WHEN datastream_metadata.change_type = 'DELETE' THEN 1
      ELSE 0
  END as delete_flag
FROM 
  CustomerCurrent 
WHERE 
  rownbr = 1;