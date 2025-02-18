CREATE OR REPLACE VIEW adventureworks_silver.Product AS
SELECT
    a.ProductID
    , a.Name as ProductName
    , c.Name as ProductCategoryName    
    , b.Name as ProductSubcategoryName    
    , a.ProductNumber
    , a.Color
    , a.ListPrice
    , a.ProductLine
    , CASE
        WHEN a.datastream_metadata.source_timestamp > b.datastream_metadata.source_timestamp AND a.datastream_metadata.source_timestamp > c.datastream_metadata.source_timestamp THEN a.datastream_metadata.source_timestamp
        WHEN b.datastream_metadata.source_timestamp > a.datastream_metadata.source_timestamp AND b.datastream_metadata.source_timestamp > c.datastream_metadata.source_timestamp THEN b.datastream_metadata.source_timestamp
        ELSE c.datastream_metadata.source_timestamp
    END as watermark
FROM
    adventureworks_bronze.Production_Product a
INNER JOIN
        adventureworks_bronze.Production_ProductSubcategory b
ON
    a.ProductSubcategoryID = b.ProductSubcategoryID
INNER JOIN
        adventureworks_bronze.Production_ProductCategory c
ON
    b.ProductCategoryID = c.ProductCategoryID