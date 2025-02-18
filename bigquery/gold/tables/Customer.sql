CREATE OR REPLACE TABLE adventureworks_gold.Customer
(
    CustomerID INTEGER
    , PersonID INTEGER
    , AccountNumber STRING
    , FirstName STRING
    , MiddleName STRING
    , LastName STRING
    , watermark INTEGER
    , delete_flag INTEGER
)
CLUSTER BY
  watermark;