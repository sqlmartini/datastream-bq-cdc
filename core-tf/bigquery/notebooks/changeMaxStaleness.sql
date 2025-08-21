ALTER TABLE adventureworks_bronze.Sales_SalesOrderHeader SET OPTIONS (
    max_staleness = INTERVAL 0 MINUTE
);

ALTER TABLE adventureworks_bronze.Production_ProductCategory SET OPTIONS (
    max_staleness = INTERVAL 0 MINUTE
);

