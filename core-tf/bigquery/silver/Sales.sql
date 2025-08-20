CREATE OR REPLACE VIEW adventureworks_silver.Sales AS

SELECT
  a.SalesOrderID
  , b.SalesOrderDetailID
  , a.OrderDate
  , a.DueDate
  , a.ShipDate
  , a.Status
  , a.SalesOrderNumber
  , a.CustomerID
  , b.OrderQty
  , b.ProductID
  , b.UnitPrice
  , b.UnitPriceDiscount
  , b.LineTotal
  , a.SubTotal
  , a.TaxAmt
  , a.TotalDue
  , CASE 
      WHEN a.datastream_metadata.source_timestamp > b.datastream_metadata.source_timestamp THEN a.datastream_metadata.source_timestamp
      ELSE b.datastream_metadata.source_timestamp
    END as watermark
FROM
  adventureworks_bronze.Sales_SalesOrderHeader a
LEFT OUTER JOIN
  adventureworks_bronze.Sales_SalesOrderDetail b
ON
  a.SalesOrderID = b.SalesOrderID