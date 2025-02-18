CREATE OR REPLACE PROCEDURE adventureworks_gold.Cleanup()
BEGIN
  truncate table adventureworks_gold.Product;
  truncate table adventureworks_gold.Customer;
  truncate table adventureworks_gold.Sales;
END