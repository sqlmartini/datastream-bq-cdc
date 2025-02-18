CREATE OR REPLACE PROCEDURE adventureworks_gold.Customer_Merge()
BEGIN

  DECLARE watermark_gold INT64;
  SET watermark_gold = (SELECT IFNULL(MAX(watermark), 0) as watermark FROM adventureworks_gold.Customer);

  MERGE adventureworks_gold.Customer a
  USING (SELECT * FROM adventureworks_silver.Customer b WHERE b.watermark > watermark_gold) b
  ON a.CustomerID = b.CustomerID
  WHEN NOT MATCHED THEN
    INSERT(CustomerID, PersonID, AccountNumber, FirstName, MiddleName, LastName, watermark, delete_flag)
    VALUES(CustomerID, PersonID, AccountNumber, FirstName, MiddleName, LastName, watermark, delete_flag)
  WHEN MATCHED THEN
    UPDATE SET 
      a.CustomerID = b.CustomerID
      , a.PersonID = b.PersonID
      , a.AccountNumber = b.AccountNumber
      , a.FirstName = b.FirstName
      , a.MiddleName = b.MiddleName
      , a.LastName = b.LastName
      , a.watermark = b.watermark
      , a.delete_flag = b.delete_flag;

END
