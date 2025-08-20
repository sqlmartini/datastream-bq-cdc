CREATE OR REPLACE TABLE adventureworks_gold.Product
(
    ProductID INTEGER
    , ProductName STRING
    , ProductCategoryName STRING
    , ProductSubcategoryName STRING
    , ProductNumber STRING
    , Color STRING
    , ListPrice NUMERIC
    , ProductLine STRING
    , watermark INTEGER
)
CLUSTER BY
  watermark;