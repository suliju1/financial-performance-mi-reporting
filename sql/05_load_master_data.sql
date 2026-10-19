USE FinancialPerformanceMI;
GO

-- Store the Cost Centre master in staging so Actual transactions can be 
-- validated against an authoritative list of valid Cost Centre codes.
CREATE TABLE stg.CostCentre(
	cost_centre_code           VARCHAR(10),
	cost_centre_name           VARCHAR(100),
	department                 VARCHAR(100),
	business_function          VARCHAR(100),
	pl_reporting_group         VARCHAR(100),
	manager_role               VARCHAR(100),
	active_flag                CHAR(1)
	);
GO

BULK INSERT stg.CostCentre
FROM 'E:\Projects\financial-performance-mi-reporting\data\raw\cost_centres.csv'
WITH (
	FORMAT = 'CSV',
	FIRSTROW = 2,
	FIELDQUOTE = '"',
	TABLOCK
	);
GO

SELECT * 
FROM stg.CostCentre;

-- Store the Chart of Accounts master in staging so Actual transactions 
-- can be validated against the list of GL accounts.
CREATE TABLE stg.Accounts(
	account_code       VARCHAR(10),
	account_name       VARCHAR(100),
    account_type       VARCHAR(20),
    pl_category        VARCHAR(50),
    pl_subcategory     VARCHAR(100),
    reporting_order    INT,
    normal_balance     VARCHAR(10),
    variance_logic     VARCHAR(20)
	);
GO

BULK INSERT stg.Accounts
FROM 'E:\Projects\financial-performance-mi-reporting\data\raw\chart_of_accounts.csv'
WITH (
	FORMAT = 'CSV',
	FIRSTROW = 2,
	FIELDQUOTE = '"',
	TABLOCK
	);
GO

SELECT *
FROM stg.Accounts

-- Store the Product master in staging so Actual transactions can be validated
-- against the list of valid Product codes.
CREATE TABLE stg.Products (
	product_code       VARCHAR(10),
    product_name       VARCHAR(100),
    product_category   VARCHAR(100),
    revenue_model      VARCHAR(100),
    strategic_segment  VARCHAR(50),
    active_flag        CHAR(1)
	);
GO

BULK INSERT stg.Products
FROM 'E:\Projects\financial-performance-mi-reporting\data\raw\products.csv'
WITH (
	FORMAT = 'CSV',
	FIRSTROW = 2,
	FIELDQUOTE = '"',
	TABLOCK
	);
GO

SELECT *
FROM stg.Products;

SELECT COUNT(*) AS product_count
FROM stg.Products;

-- Store the legal entity master in staging so Actual transactions can be validated
-- against valid entities and their functional currencies.
CREATE TABLE stg.Entity(
	entity_code          VARCHAR(10),
    entity_name          VARCHAR(100),
    country              VARCHAR(50),
    currency             CHAR(3),
    entity_type          VARCHAR(50),
    active_flag          CHAR(1)
	);
GO

BULK INSERT stg.Entity
FROM 'E:\Projects\financial-performance-mi-reporting\data\raw\entities.csv'
WITH (
	FORMAT = 'CSV',
	FIRSTROW = 2,
	FIELDQUOTE = '"',
	TABLOCK
	);
GO


-- Store the commercial reporting-region master in staging.
CREATE TABLE stg.Region (
	region_code    VARCHAR(10),
    region_name    VARCHAR(100),
    region_group   VARCHAR(100),
    active_flag    CHAR(1)
	);
GO

BULK INSERT stg.Region
FROM 'E:\Projects\financial-performance-mi-reporting\data\raw\regions.csv'
WITH (
	FORMAT = 'CSV',
	FIRSTROW = 2,
	FIELDQUOTE = '"',
	TABLOCK
	);
GO

SELECT *
FROM stg.Entity;

SELECT *
FROM stg.Region;