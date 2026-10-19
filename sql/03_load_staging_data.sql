USE FinancialPerformanceMI;
GO

-- Clear the staging table before reload so the script can be rerun safely
-- without appending the same source file multiple times.
TRUNCATE TABLE stg.Actual;
GO

-- Load the raw Actual CSV into the staging layer. The intentionally injected duplicates,
-- null regions and invalid codes are retained for later DQ checks.
BULK INSERT stg.Actual
FROM 'E:\Projects\financial-performance-mi-reporting\data\raw\actual.csv'
WITH (
	FORMAT = 'CSV',
	FIRSTROW = 2,
	FIELDQUOTE = '"',
	TABLOCK
	);
GO

SELECT COUNT(*) AS row_count
FROM stg.Actual

SELECT TOP 10 *
FROM stg.Actual

-- Load the Budget staging table from the raw CSV source.
TRUNCATE TABLE stg.Budget;

BULK INSERT stg.Budget
FROM 'E:\Projects\financial-performance-mi-reporting\data\raw\budget.csv'
WITH (
	FORMAT = 'CSV',
	FIRSTROW = 2,
	FIELDQUOTE = '"',
	TABLOCK
	);
GO

SELECT COUNT(*) AS budget_row_count
FROM stg.Budget;

SELECT TOP 10 *
FROM stg.Budget;
