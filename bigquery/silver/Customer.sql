CREATE OR REPLACE VIEW adventureworks_silver.Customer AS
SELECT 
  a.CustomerID
  , a.PersonID
  , a.AccountNumber
  , b.FirstName
  , b.MiddleName
  , b.LastName
  , CASE 
      WHEN a.datastream_metadata.source_timestamp > b.datastream_metadata.source_timestamp THEN a.datastream_metadata.source_timestamp
      ELSE b.datastream_metadata.source_timestamp
    END as watermark
  , a.delete_flag
FROM
  adventureworks_bronze.Customer_current a
LEFT OUTER JOIN
  adventureworks_bronze.Person_current b
ON
  a.PersonID = b.BusinessEntityID
