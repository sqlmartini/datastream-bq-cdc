CREATE OR REPLACE PROCEDURE adventureworks_gold.Product_Merge()
BEGIN

  DECLARE watermark_gold INT64;
  SET watermark_gold = (SELECT IFNULL(MAX(watermark), 0) as watermark FROM adventureworks_gold.Product);

  MERGE adventureworks_gold.Product a
  USING (SELECT * FROM adventureworks_silver.Product b WHERE b.watermark > watermark_gold) b
  ON a.ProductID = b.ProductID
  WHEN NOT MATCHED THEN
    INSERT(ProductID, ProductName, ProductCategoryName, ProductSubcategoryName, ProductNumber, Color, ListPrice, ProductLine, watermark)
    VALUES(ProductID, ProductName, ProductCategoryName, ProductSubcategoryName, ProductNumber, Color, ListPrice, ProductLine, watermark)
  WHEN MATCHED THEN
    UPDATE SET 
      a.ProductName = b.ProductName
      , a.ProductCategoryName = b.ProductCategoryName
      , a.ProductSubcategoryName = b.ProductSubcategoryName
      , a.ProductNumber = b.ProductNumber
      , a.Color = b.Color
      , a.ListPrice = b.ListPrice
      , a.ProductLine = b.ProductLine
      , a.watermark = b.watermark;

END