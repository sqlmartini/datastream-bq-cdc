EXEC msdb.dbo.gcloudsql_cdc_enable_db 'AdventureWorks2022'
GO

EXEC sys.sp_cdc_enable_table
@source_schema = N'Sales',
@source_name = N'SalesOrderDetail',
@role_name = NULL
GO

EXEC sys.sp_cdc_enable_table
@source_schema = N'Sales',
@source_name = N'SalesOrderHeader',
@role_name = NULL
GO

EXEC sys.sp_cdc_enable_table
@source_schema = N'Sales',
@source_name = N'SalesTerritory',
@role_name = NULL
GO

EXEC sys.sp_cdc_enable_table
@source_schema = N'Production',
@source_name = N'Product',
@role_name = NULL
GO

EXEC sys.sp_cdc_enable_table
@source_schema = N'Production',
@source_name = N'ProductCategory',
@role_name = NULL
GO

EXEC sys.sp_cdc_enable_table
@source_schema = N'Production',
@source_name = N'ProductSubcategory',
@role_name = NULL
GO

ALTER DATABASE AdventureWorks2022 SET ALLOW_SNAPSHOT_ISOLATION ON;

--First create login through google cloud console
CREATE USER datastream FOR LOGIN datastream;

EXEC sp_addrolemember 'db_owner', 'datastream';
EXEC sp_addrolemember 'db_denydatawriter', 'datastream';

--Optional
USE [AdventureWorks2022];
CREATE TABLE dbo.gcp_datastream_truncation_safeguard (
  [id] INT IDENTITY(1,1) PRIMARY KEY,
  CreatedDate DATETIME DEFAULT GETDATE(),
  [char_column] CHAR(8)
  );
