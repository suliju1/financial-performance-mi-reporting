USE FinancialPerformanceMI;
GO

-- Confirm that the full raw Actual dataset was loaded into staging.
SELECT COUNT(*) AS total_rows
FROM stg.Actual;

-- Identify transaction IDs that appear more than once in the raw dataset.
SELECT transaction_id,  COUNT(*) AS occurrence_count
FROM stg.Actual
GROUP BY transaction_id
HAVING COUNT(*) > 1;

-- Count transactions with a missing Region code.
SELECT COUNT(*) AS missing_region_count
FROM stg.Actual
WHERE region_code IS NULL;

-- Count transactions containing the intentionally invalid Cost Centre code.
SELECT COUNT(*) AS invalid_cost_centre_count
FROM stg.Actual
WHERE cost_centre_code = 'CC999';

-- Identify Actual transactions whose Cost Centre does not exist in the Cost Centre master data.
SELECT
	a.transaction_id,
	a.cost_centre_code
FROM stg.Actual AS a
LEFT JOIN stg.CostCentre AS c
	ON a.cost_centre_code = c.cost_centre_code
WHERE c.cost_centre_code IS NULL;


SELECT
	COUNT(*) AS invalid_cost_centre_code
FROM stg.Actual AS a
LEFT JOIN stg.CostCentre AS c
	ON a.cost_centre_code = c.cost_centre_code
WHERE c.cost_centre_code IS NULL;

-- Identify transactions where local currency does not match the expected functional currency for the legal entity.
SELECT 
	transaction_id,
	entity_code,
	local_currency
FROM stg.Actual
WHERE 
	(entity_code = 'ENT01' AND local_currency <> 'GBP')
	OR
	(entity_code IN ('ENT02','ENT03','ENT04') AND local_currency <> 'EUR')


SELECT COUNT(*)
FROM stg.Actual
WHERE 
	(entity_code = 'ENT01' AND local_currency <> 'GBP')
	OR
	(entity_code IN ('ENT02','ENT03','ENT04') AND local_currency <> 'EUR')

-- Identify Actual transactions whose GL account does not exist in the Chart of Accounts master.
SELECT 
	a.transaction_id,
	a.account_code
FROM stg.Actual AS a
LEFT JOIN stg.Accounts AS acc
	ON a.account_code = acc.account_code
WHERE acc.account_code IS NULL

-- Identify Actual transactions where the local currency does not match 
-- the functional currency defined in the legal entity master.
SELECT 
	a.transaction_id,
	a.entity_code,
	a.local_currency,
	e.currency
FROM stg.Actual AS a
LEFT JOIN stg.Entity AS e
	ON a.entity_code = e.entity_code
WHERE e.entity_code IS NULL OR a.local_currency <> e.currency;

-- Identify Actual transactions whose Region code does not exist in
-- the commercial reporting-region master.
SELECT 
	a.transaction_id,
	a.region_code
FROM stg.Actual AS a
LEFT JOIN stg.Region AS r
	ON a.region_code = r.region_code
WHERE a.region_code IS NOT NULL AND r.region_code IS NULL;

-- Count transactions where Region is missing entirely.
SELECT COUNT(*) AS missing_region_count
FROM stg.Actual
WHERE region_code IS NULL;

-- Summarise the main staging data-quality checks into a single result set
-- so source data exceptions can be reviewed before warehouse loading.
SELECT
	'Total raw rows' AS dq_check,
	COUNT(*) AS issue_count
FROM stg.Actual

UNION ALL

SELECT 
	'Duplicate transactions',
	COALESCE(SUM(occurrence_count - 1),0)
FROM(
	SELECT
		transaction_id,
		COUNT(*) AS occurrence_count
	FROM stg.Actual
	GROUP BY transaction_id
	HAVING COUNT(*) > 1
	) AS duplicates

UNION ALL

SELECT 
	'Missing regions',
	COUNT(*) 
FROM stg.Actual
WHERE region_code IS NULL

UNION ALL

SELECT 
	'Invalid accounts',
	COUNT(*) 
FROM stg.Actual AS a
LEFT JOIN stg.Accounts AS acc
	ON a.account_code = acc.account_code
WHERE acc.account_code IS NULL

UNION ALL

SELECT 
	'Invalid cost centres',
	COUNT(*) 
FROM stg.Actual AS a
LEFT JOIN stg.CostCentre AS c
	ON a.cost_centre_code = c.cost_centre_code
WHERE c.cost_centre_code IS NULL

UNION ALL

SELECT 
	'Invalid products',
	COUNT(*) 
FROM stg.Actual AS a
LEFT JOIN stg.Products AS p
	ON a.product_code = p.product_code
WHERE p.product_code IS NULL

UNION ALL

SELECT 
	'Invalid regions',
	COUNT(*) 
FROM stg.Actual AS a
LEFT JOIN stg.Region AS r
	ON a.region_code = r.region_code
WHERE a.region_code IS NOT NULL AND r.region_code IS NULL

UNION ALL

SELECT
	'Entity-currency mismatches',
	COUNT(*)
FROM stg.Actual AS a
LEFT JOIN stg.Entity AS e
	ON a.entity_code = e.entity_code
WHERE a.entity_code IS NOT NULL
	  AND a.local_currency <> e.currency;

/*==================================================================
  BUDGET STAGING DATA QUALITY CHECKS
  ==================================================================*/

-- Confirm that the full FY2026 approved Budget dataset was loaded.
SELECT COUNT(*) AS budget_row_count
FROM stg.Budget;

-- Identify Budget rows with missing critical business fields.
SELECT COUNT(*) AS critical_null_count
FROM stg.Budget
WHERE 
	budget_id IS NULL
	OR budget_month IS NULL
    OR account_code IS NULL
    OR cost_centre_code IS NULL
    OR product_code IS NULL
    OR entity_code IS NULL
    OR region_code IS NULL
    OR budget_version IS NULL
    OR budget_currency IS NULL
    OR budget_amount IS NULL;


-- Check that each Budget business-grain combination appears only once.
SELECT
	budget_month,
	account_code,
	cost_centre_code,
	product_code, 
    entity_code, 
    region_code,
    budget_version, 
    COUNT(*) AS occurrence_count
FROM stg.Budget
GROUP BY 
	budget_month,
	account_code,
	cost_centre_code,
	product_code, 
    entity_code, 
    region_code,
    budget_version
HAVING COUNT(*) > 1;

-- Identify Budget rows whose GL account does not exist 
-- in the Chart of Accounts master.
SELECT COUNT(*) AS invalid_budget_account_count
FROM stg.Budget AS b
LEFT JOIN stg.Accounts AS a
	ON b.account_code = a.account_code
WHERE a.account_code IS NULL;

-- Identify Budget rows whose Cost Centre does not exist 
-- in the Cost Centre master.
SELECT COUNT(*) as invalid_budget_cost_centre_count
FROM stg.Budget AS b
LEFT JOIN stg.CostCentre AS c
	ON b.cost_centre_code = c.cost_centre_code
WHERE c.cost_centre_code IS NULL;

-- Identify Budget rows whose Product does not exist
-- in the Product master.
SELECT COUNT(*) AS invalid_budget_product_count
FROM stg.Budget AS b
LEFT JOIN stg.Products AS p
	ON b.product_code = p.product_code
WHERE p.product_code IS NULL;

-- Identify Budget rows whose Entity does not exist
-- in the legal-entity master.
SELECT COUNT(*) AS invalid_budget_entity_count
FROM stg.Budget AS b
LEFT JOIN stg.Entity AS e
	ON b.entity_code = e.entity_code
WHERE e.entity_code IS NULL;

-- Identify Budget rows whose Region does not exist
-- in the commercial reporting-region master.
SELECT COUNT(*) AS invalid_budget_region_count
FROM stg.Budget AS b
LEFT JOIN stg.Region AS r
	ON b.region_code = r.region_code
WHERE r.region_code IS NULL;

-- Identify Budget rows outside the approved FY2026 period.
SELECT COUNT(*) AS invalid_budget_period_count
FROM stg.Budget
WHERE budget_month < '2026-01-01'
	OR budget_month > '2026-12-01';

-- Identify rows that do not belong to the approved FY2026 budget version.
SELECT COUNT(*) AS invalid_budget_version_count
FROM stg.Budget
WHERE budget_version <> 'FY26 Approved';

SELECT 
	budget_version,
	COUNT(*) AS row_count
FROM stg.Budget
GROUP BY budget_version;

-- Confirm that all Budget values are stored in GBP reporting currency.
SELECT COUNT(*) AS invalid_budget_currency_count
FROM stg.Budget
WHERE budget_currency <> 'GBP';

SELECT budget_currency, COUNT(*) AS row_count
FROM stg.Budget
GROUP BY budget_currency;
