CREATE OR REPLACE TABLE adventureworks_gold.Sales
(
    SalesOrderID INTEGER
    , SalesOrderDetailID INTEGER
    , OrderDate DATETIME
    , DueDate DATETIME
    , ShipDate DATETIME
    , Status INTEGER
    , SalesOrderNumber STRING
    , CustomerID INTEGER
    , OrderQty INTEGER
    , ProductID INTEGER
    , UnitPrice NUMERIC
    , UnitPriceDiscount NUMERIC
    , LineTotal BIGNUMERIC
    , SubTotal NUMERIC
    , TaxAmt NUMERIC
    , TotalDue NUMERIC
    , watermark INTEGER
)
CLUSTER BY
  watermark;