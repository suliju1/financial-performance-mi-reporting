USE FinancialPerformanceMI;
GO

-- Create the raw Actual staging table. The structure closely follows the source CSV 
-- and intentionally allows data-quality issues to remain in staging.
CREATE TABLE stg.Actual(
	transaction_id        VARCHAR(20),
	document_id           VARCHAR(30),
	posting_date          DATE,
	account_code          VARCHAR(10),
	cost_centre_code      VARCHAR(10),
	product_code          VARCHAR(10),
	entity_code           VARCHAR(10),
    region_code           VARCHAR(10) NULL,
    local_currency        CHAR(3),
    local_amount          DECIMAL(18, 2),
    fx_rate_to_gbp        DECIMAL(10, 6),
    reporting_currency    CHAR(3),
    reporting_amount_gbp  DECIMAL(18, 2),
    source_system         VARCHAR(50),
    journal_type          VARCHAR(50),
    description           VARCHAR(200),
    load_date             DATE
    );
 GO

 SELECT name
 FROM sys.schemas
 WHERE name IN ('stg','dw')

 -- Store the raw Budget dataset in staging before validation and 
 -- transformation into the dimensional warehouse.
 CREATE TABLE stg.Budget (
    budget_id           VARCHAR(30),
    budget_month        DATE,
    account_code        VARCHAR(10),
    cost_centre_code    VARCHAR(10),
    product_code        VARCHAR(10),
    entity_code         VARCHAR(10),
    region_code         VARCHAR(10),
    budget_version      VARCHAR(50),
    budget_currency     CHAR(3),
    budget_amount       DECIMAL(18, 2),
    source_system       VARCHAR(50),
    load_date           DATE
    );
GO