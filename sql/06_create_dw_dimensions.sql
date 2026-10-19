USE FinancialPerformanceMI;
GO

-- Create the Account dimension with a warehouse-generated surrogate key.
-- account_code remains the business key from the source Chart of Accounts.
CREATE TABLE dw.DimAccount (
	account_key    INT IDENTITY(1,1)  PRIMARY KEY,
	account_code   VARCHAR(10)  NOT NULL,
	account_name      VARCHAR(100) NOT NULL,
    account_type      VARCHAR(20),
    pl_category       VARCHAR(50),
    pl_subcategory    VARCHAR(100),
    reporting_order   INT,
    normal_balance    VARCHAR(10),
    variance_logic    VARCHAR(20),
    
    CONSTRAINT UQ_DimAccount_AccountCode  UNIQUE (account_code)
    );
GO

-- Load the validated Chart of Account from staging into the warehouse dimension.
INSERT INTO dw.DimAccount(
    account_code,
    account_name,
    account_type,
    pl_category,
    pl_subcategory,
    reporting_order,
    normal_balance,
    variance_logic
    )
SELECT 
    account_code,
    account_name,
    account_type,
    pl_category,
    pl_subcategory,
    reporting_order,
    normal_balance,
    variance_logic
FROM stg.Accounts;
GO

SELECT * 
FROM dw.DimAccount
ORDER BY account_key;

-- Create the Cost Centre dimension with a wardhouse-generated surrogate key.
-- cost_centre_code remains the business key from the source master data.
CREATE TABLE dw.DimCostCentre (
    cost_centre_key      INT IDENTITY(1,1)  PRIMARY KEY,
    cost_centre_code     VARCHAR(10)   NOT NULL,
    cost_centre_name     VARCHAR(100)  NOT NULL,
    department           VARCHAR(100),
    business_function    VARCHAR(100),
    pl_reporting_group   VARCHAR(100),
    manager_role         VARCHAR(100),
    active_flag          CHAR(1),

    CONSTRAINT UQ_DimCostCentre_Code UNIQUE (cost_centre_code)
    );
GO

-- Load the validated Cost Centre master from staging into the warehouse dimension.
INSERT INTO dw.DimCostCentre (
    cost_centre_code,
    cost_centre_name,
    department,
    business_function,
    pl_reporting_group,
    manager_role,
    active_flag
    )
SELECT
    cost_centre_code,
    cost_centre_name,
    department,
    business_function,
    pl_reporting_group,
    manager_role,
    active_flag
FROM stg.CostCentre;
GO

SELECT *
FROM dw.DimCostCentre
ORDER BY cost_centre_key;

SELECT COUNT(*) AS dim_cost_centre_count
FROM dw.DimCostCentre;

-- Create the Product dimension with a warehouse generated surrogate key.
-- product_code remains the business key from the source Product master.
CREATE TABLE dw.DimProduct (
    product_key           INT IDENTITY(1,1)  PRIMARY KEY,
    product_code          VARCHAR(10) NOT NULL,
    product_name          VARCHAR(100) NOT NULL,
    product_category      VARCHAR(100),
    revenue_model         VARCHAR(100),
    strategic_segment     VARCHAR(50),
    active_flag           CHAR(1),

    CONSTRAINT UQ_DimProduct_Code UNIQUE (product_code)
    );
GO

-- Load the validated Products master from staging into the warehouse dimension.
INSERT INTO dw.DimProduct (
    product_code,
    product_name,
    product_category,
    revenue_model,
    strategic_segment,
    active_flag
    )
SELECT
    p.product_code,
    p.product_name,
    p.product_category,
    p.revenue_model,
    p.strategic_segment,
    p.active_flag
FROM stg.Products AS p
WHERE NOT EXISTS  (
    SELECT 1
    FROM dw.DimProduct AS d
    WHERE d.product_code = p.product_code
    );
GO

SELECT COUNT(*) AS product_count
FROM dw.DimProduct;

SELECT *
FROM dw.DimProduct
ORDER BY product_key;

-- Create the Entity dimension with a warehouse generated surrogate key.
-- entity_code remains the business key from the legal-entity master.
CREATE TABLE dw.DimEntity(
    entity_key     INT IDENTITY(1,1)    PRIMARY KEY,
    entity_code    VARCHAR(10)   NOT NULL,
    entity_name    VARCHAR(100)  NOT NULL,
    country        VARCHAR(50),
    currency       CHAR(3),
    entity_type    VARCHAR(50),
    active_flag    CHAR(1)

    CONSTRAINT  UQ_DimEntity_Code  UNIQUE (entity_code)
    );
GO

-- Load only entities that do not already exist in the warehouse dimension.
INSERT INTO dw.DimEntity (
    entity_code,
    entity_name,
    country,
    currency,
    entity_type,
    active_flag
    )
SELECT 
    e.entity_code,
    e.entity_name,
    e.country,
    e.currency,
    e.entity_type,
    e.active_flag
FROM stg.Entity AS e
WHERE NOT EXISTS (
    SELECT 1
    FROM dw.DimEntity AS d
    WHERE d.entity_code = e.entity_code
    );
GO

SELECT *
FROM dw.DimEntity
ORDER BY entity_key;

SELECT COUNT(*) AS dim_entity_count
FROM dw.DimEntity;

-- Create the Region dimension with a warehouse generated surrogate key
-- region_code remains the business key from the reporting-region master.
CREATE TABLE dw.DimRegion (
    region_key     INT  IDENTITY(1,1)   PRIMARY KEY,
    region_code    VARCHAR(10)    NOT NULL,
    region_name    VARCHAR(100)   NOT NULL,
    region_group   VARCHAR(100),
    active_flag    CHAR(1),

    CONSTRAINT   UQ_DimRegion_Code  UNIQUE (region_code)
    );
GO

-- Load only regions that do not already exist in the warehouse dimension.
INSERT INTO dw.DimRegion (
    region_code,
    region_name,
    region_group,
    active_flag
    )
SELECT
    r.region_code,
    r.region_name,
    r.region_group,
    r.active_flag
FROM stg.Region AS r
WHERE NOT EXISTS (
    SELECT 1
    FROM dw.DimRegion AS d
    WHERE d.region_code = r.region_code
    );
GO

SELECT *
FROM dw.DimRegion
ORDER BY region_key;

SELECT COUNT (*) AS dim_region_count
FROM dw.DimRegion;

-- Create a Date dimension covering the full Actual and Budget reporting period.
CREATE TABLE dw.DimDate (
    date_key          INT   PRIMARY KEY,
    full_date         DATE NOT NULL UNIQUE,
    calendar_year     INT NOT NULL,
    quarter_number    INT NOT NULL,
    month_number      INT NOT NULL,
    month_name        VARCHAR(20) NOT NULL,
    year_month        CHAR(7) NOT NULL,
    year_month_sort   INT NOT NULL,
    month_start_date  DATE NOT NULL
    );
GO

-- Generate one Date dimension row for every calendar day 
-- from 1 Jan 2025 through 31 Dec 2026.
WITH DateSeries AS (
    SELECT CAST('2025-01-01' AS DATE) AS full_date

    UNION ALL

    SELECT DATEADD (DAY, 1, full_date)
    FROM DateSeries
    WHERE full_date < '2026-12-31'
    )
INSERT INTO dw.DimDate (
    date_key,
    full_date,
    calendar_year,
    quarter_number,
    month_number,
    month_name,
    year_month,
    year_month_sort,
    month_start_date
    )
SELECT
    YEAR(full_date) * 10000 + MONTH(full_date) * 100 + DAY(full_date),
    full_date,
    YEAR(full_date),
    DATEPART(QUARTER,full_date),
    MONTH(full_date),
    DATENAME(MONTH,full_date),
    CONVERT(CHAR(7),full_date,126),
    YEAR(full_date) * 100 + MONTH(full_date),
    DATEFROMPARTS(YEAR(full_date),MONTH(full_date),1)
FROM DateSeries
OPTION (MAXRECURSION 0);
GO

SELECT TOP 10 *
FROM dw.DimDate
ORDER BY full_date DESC;

SELECT COUNT(*) AS dim_date_count
FROM dw.DimDate;

-- Create an Unknown Cost Centre member so transactions with invalid source Cost Centre codes 
-- can remain in the warehouse without breaking financial reconciliation.
IF NOT EXISTS (
    SELECT 1
    FROM dw.DimCostCentre
    WHERE cost_centre_code = 'CC_UNK')
BEGIN
    INSERT INTO dw.DimCostCentre (
        cost_centre_code,
        cost_centre_name,
        department,
        business_function,
        pl_reporting_group,
        manager_role,
        active_flag )
    VALUES (
        'CC_UNK',
        'Unknown Cost Centre',
        'Unknown',
        'Unknown',
        'Unknown',
        'Unknown',
        'Y');
END;
GO

SELECT *
FROM dw.DimCostCentre
WHERE cost_centre_code = 'CC_UNK';

-- Create an Unknown Region member so transactions with missing Region values 
-- can remain in the warehouse.
IF NOT EXISTS (
    SELECT 1
    FROM dw.DimRegion
    WHERE region_code = 'REG_UNK')
BEGIN
    INSERT INTO dw.DimRegion (
        region_code,
        region_name,
        region_group,
        active_flag
        )
    VALUES (
        'REG_UNK',
        'Unknown Region',
        'Unknown',
        'Y');
END;
GO

SELECT *
FROM dw.DimRegion
WHERE region_code = 'REG_UNK';