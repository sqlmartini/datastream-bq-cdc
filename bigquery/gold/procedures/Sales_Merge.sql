CREATE OR REPLACE PROCEDURE adventureworks_gold.Sales_Merge()
BEGIN

  DECLARE watermark_gold INT64;
  SET watermark_gold = (SELECT IFNULL(MAX(watermark), 0) as watermark FROM adventureworks_gold.Sales);

  MERGE adventureworks_gold.Sales a
  USING (SELECT * FROM adventureworks_silver.Sales b WHERE b.watermark > watermark_gold) b
  ON a.SalesOrderDetailID = b.SalesOrderDetailID
  WHEN NOT MATCHED THEN
    INSERT(SalesOrderID, SalesOrderDetailID, OrderDate, DueDate, ShipDate, Status, SalesOrderNumber, CustomerID, OrderQty, ProductID, UnitPrice, UnitPriceDiscount, LineTotal, SubTotal, TaxAmt, TotalDue, watermark)
    VALUES(SalesOrderID, SalesOrderDetailID, OrderDate, DueDate, ShipDate, Status, SalesOrderNumber, CustomerID, OrderQty, ProductID, UnitPrice, UnitPriceDiscount, LineTotal, SubTotal, TaxAmt, TotalDue, watermark)
  WHEN MATCHED THEN
    UPDATE SET 
      a.OrderDate = b.OrderDate
      , a.DueDate = b.DueDate
      , a.ShipDate = b.ShipDate
      , a.Status = b.Status
      , a.SalesOrderNumber = b.SalesOrderNumber
      , a.CustomerID = b.CustomerID
      , a.OrderQty = b.OrderQty
      , a.ProductID = b.ProductID
      , a.UnitPrice = b.UnitPrice
      , a.UnitPriceDiscount = b.UnitPriceDiscount
      , a.LineTotal = b.LineTotal
      , a.SubTotal = b.SubTotal
      , a.TaxAmt = b.TaxAmt
      , a.TotalDue = b.TotalDue
      , a.watermark = b.watermark;

END