USE FinancialPerformanceMI;
GO

-- Create the clean Actual fact table at transaction-line grain.
-- Dimension business codes are replaced by warehouse surrogate keys.
CREATE TABLE dw.FactActual (
	actual_key           BIGINT IDENTITY(1,1) PRIMARY KEY,
	transaction_id       VARCHAR(20) NOT NULL,
	document_id          VARCHAR(30) NOT NULL,
	
	date_key             INT NOT NULL,
	account_key          INT NOT NULL,
	cost_centre_key      INT NOT NULL,
	product_key          INT NOT NULL,
	entity_key           INT NOT NULL,
	region_key           INT NOT NULL,
	
	local_currency       CHAR(3) NOT NULL,
	local_amount         DECIMAL(18,2) NOT NULL,
	fx_rate_to_gbp       DECIMAL(10,6) NOT NULL,
	reporting_currency   CHAR(3) NOT NULL,
	reporting_amount_gbp DECIMAL(18,2) NOT NULL,

	source_system        VARCHAR(50),
	journal_type         VARCHAR(50),
	description          VARCHAR(200),
	load_date            DATE,

	CONSTRAINT UQ_FactActual_Transaction UNIQUE(transaction_id),

	CONSTRAINT FK_FactActual_Date   FOREIGN KEY (date_key)    REFERENCES dw.DimDate(date_key),

	CONSTRAINT FK_FactActual_Account   FOREIGN KEY (account_key)    REFERENCES dw.DimAccount(account_key),

	CONSTRAINT FK_FactActual_CostCentre   FOREIGN KEY (cost_centre_key)    REFERENCES dw.DimCostCentre(cost_centre_key),

	CONSTRAINT FK_FactActual_Product   FOREIGN KEY (product_key)    REFERENCES dw.DimProduct(product_key),

	CONSTRAINT FK_FactActual_Entity   FOREIGN KEY (entity_key)    REFERENCES dw.DimEntity(entity_key),

	CONSTRAINT FK_FactActual_Region   FOREIGN KEY (region_key)    REFERENCES dw.DimRegion(region_key)
	
	);
GO

SELECT 
	t.name AS table_name,
	s.name AS schema_name
FROM sys.tables AS t
JOIN sys.schemas AS s
	ON t.schema_id = s.schema_id
WHERE t.name = 'FactActual';

-- Reload the clean Actual fact table from staging.
TRUNCATE TABLE dw.FactActual;

-- Duplicate source transactions by transaction_id.
-- The injected duplicates are exact copies, so keeping one row is sufficient.
WITH DuplicatedActual AS (
	SELECT 
		*, ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY transaction_id) AS row_number
	FROM stg.Actual
	)
INSERT INTO dw.FactActual(
	transaction_id,
    document_id,
    date_key,
    account_key,
    cost_centre_key,
    product_key,
    entity_key,
    region_key,
    local_currency,
    local_amount,
    fx_rate_to_gbp,
    reporting_currency,
    reporting_amount_gbp,
    source_system,
    journal_type,
    description,
    load_date)
SELECT
	a.transaction_id,
	a.document_id,
	d.date_key,
	acc.account_key,

	COALESCE(
		cc.cost_centre_key, 
		(SELECT cost_centre_key
		 FROM dw.DimCostCentre
		 WHERE cost_centre_code = 'CC_UNK')) AS cost_centre_key,

	p.product_key,
	e.entity_key,

	COALESCE(r.region_key,
			(SELECT region_key
			 FROM dw.DimRegion
			 WHERE region_code = 'REG_UNK')) AS region_key,

	e.currency AS local_currency,
	a.local_amount,
	a.fx_rate_to_gbp,
	a.reporting_currency,
	a.reporting_amount_gbp,
	a.source_system,
	a.journal_type,
	a.description,
	a.load_date

FROM DuplicatedActual AS a

INNER JOIN dw.DimDate AS d
	ON a.posting_date = d.full_date

INNER JOIN dw.DimAccount AS acc
	ON a.account_code = acc.account_code

LEFT JOIN dw.DimCostCentre AS cc
	ON a.cost_centre_code = cc.cost_centre_code

INNER JOIN dw.DimProduct AS p
	ON a.product_code = p.product_code

INNER JOIN dw.DimEntity AS e
	ON a.entity_code = e.entity_code

LEFT JOIN dw.DimRegion AS r
	ON a.region_code = r.region_code

WHERE a.row_number = 1;
GO

SELECT COUNT (*) AS fact_actual_count
FROM dw.FactActual;

-- Check the unknown Cost Centre.
SELECT COUNT(*) AS unknon_cost_centre_count
FROM dw.FactActual AS f
INNER JOIN dw.DimCostCentre AS cc
	ON f.cost_centre_key = cc.cost_centre_key
WHERE cc.cost_centre_code = 'CC_UNK';

-- Check the missing regions.
SELECT COUNT(*) AS unknon_region_count
FROM dw.FactActual AS f
INNER JOIN dw.DimRegion AS r
	ON f.region_key = r.region_key
WHERE r.region_code = 'REG_UNK';

-- Confirm the currency mismatch still exist in the raw staging data.
SELECT COUNT(*) AS staging_currency_mismatch_count
FROM stg.Actual AS a
LEFT JOIN dw.DimEntity AS e
	ON a.entity_code = e.entity_code
WHERE a.local_currency <> e.currency;


-- Confirm that FactActual local currency agrees with the functional currency defined in the Entity dimension.
SELECT COUNT(*) AS fact_currency_mismatch_count
FROM dw.FactActual AS f
LEFT JOIN dw.DimEntity AS e
	ON f.entity_key = e.entity_key
WHERE f.local_currency <> e.currency;

/* ==============================================================
   FactActual Post-load Financial Reconciliation
   ============================================================== */

   -- Reconcile Revenue, Cost of Revenue and Operating Expenses
   -- between the duplicated staging source and the warehouse fact table.

WITH DuplicatedActual AS (
	SELECT 
		*,
		ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY transaction_id) AS row_number
	FROM stg.Actual),

SourceTotals AS (
	SELECT
		YEAR(posting_date) AS reporting_year,
		
		SUM(CASE WHEN LEFT(account_code,1) = '4' THEN reporting_amount_gbp ELSE 0 END) AS revenue,

		SUM(CASE WHEN LEFT(account_code,1) = '5' THEN reporting_amount_gbp ELSE 0 END) AS cost_of_revenue,

		SUM(CASE WHEN LEFT(account_code,1) = '6' THEN reporting_amount_gbp ELSE 0 END) AS operating_expenses

	FROM DuplicatedActual
	WHERE row_number = 1
	GROUP BY YEAR(posting_date)
	),

	WarehousTotals AS (
		SELECT
			d.calendar_year AS reporting_year,
			SUM(CASE WHEN LEFT(a.account_code,1) = '4' THEN f.reporting_amount_gbp ELSE 0 END) AS revenue,
			SUM(CASE WHEN LEFT(a.account_code,1) = '5' THEN f.reporting_amount_gbp ELSE 0 END) AS cost_of_revenue,
			SUM(CASE WHEN LEFT(a.account_code,1) = '6' THEN f.reporting_amount_gbp ELSE 0 END) AS operating_expenses

		FROM dw.FactActual AS f
		INNER JOIN dw.DimDate AS d
			ON f.date_key = d.date_key
		INNER JOIN dw.DimAccount AS a
			ON f.account_key = a. account_key
		GROUP BY d.calendar_year
		)

	SELECT 
		s.reporting_year,
		s.revenue AS source_revenue,
		w.revenue AS warehouse_revenue,
		w.revenue - s.revenue AS revenue_difference,

		s.cost_of_revenue AS source_cost_of_revenue,
		w.cost_of_revenue AS warehouse_cost_of_revenue,
		w.cost_of_revenue - s.cost_of_revenue AS cost_of_revenue_difference,

		s.operating_expenses AS source_opex,
		w.operating_expenses AS warehouse_opex,
		w.operating_expenses - s.operating_expenses AS opex_difference

	FROM SourceTotals AS s
	INNER JOIN WarehousTotals AS w
		ON s.reporting_year = w.reporting_year
	ORDER BY s.reporting_year;

-- Reconcile the full management P&L between the duplicated staging source and the clean 
-- warehouse FactActual table.
WITH DuplicatedActual AS (
	SELECT 
		*,
		ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY transaction_id) AS row_number
	FROM stg.Actual),

SourceTotals AS (
	SELECT
		YEAR(posting_date) AS reporting_year,
		
		SUM(CASE WHEN LEFT(account_code,1) = '4' THEN reporting_amount_gbp ELSE 0 END) AS revenue,

		SUM(CASE WHEN LEFT(account_code,1) = '5' THEN reporting_amount_gbp ELSE 0 END) AS cost_of_revenue,

		SUM(CASE WHEN LEFT(account_code,1) = '6' THEN reporting_amount_gbp ELSE 0 END) AS operating_expenses

	FROM DuplicatedActual
	WHERE row_number = 1
	GROUP BY YEAR(posting_date)
	),

	WarehousTotals AS (
		SELECT
			d.calendar_year AS reporting_year,
			SUM(CASE WHEN LEFT(a.account_code,1) = '4' THEN f.reporting_amount_gbp ELSE 0 END) AS revenue,
			SUM(CASE WHEN LEFT(a.account_code,1) = '5' THEN f.reporting_amount_gbp ELSE 0 END) AS cost_of_revenue,
			SUM(CASE WHEN LEFT(a.account_code,1) = '6' THEN f.reporting_amount_gbp ELSE 0 END) AS operating_expenses

		FROM dw.FactActual AS f
		INNER JOIN dw.DimDate AS d
			ON f.date_key = d.date_key
		INNER JOIN dw.DimAccount AS a
			ON f.account_key = a. account_key
		GROUP BY d.calendar_year
		)

	SELECT 
		s.reporting_year,
		s.revenue AS source_revenue,
		w.revenue AS warehouse_revenue,
		w.revenue - s.revenue AS revenue_difference,

		s.revenue - s.cost_of_revenue AS source_gross_profit,
		w.revenue - w.cost_of_revenue AS warehouse_gross_profit,
		(w.revenue - w.cost_of_revenue) - (s.revenue - s.cost_of_revenue) AS gross_profit_difference,
		
		s.revenue - s.cost_of_revenue - s.operating_expenses AS source_ebitda,
		w.revenue - w.cost_of_revenue - w.operating_expenses AS warehouse_ebitda,
		(w.revenue - w.cost_of_revenue - w.operating_expenses) - (s.revenue - s.cost_of_revenue - s.operating_expenses) AS ebitda_difference

	FROM SourceTotals AS s
	INNER JOIN WarehousTotals AS w
		ON s.reporting_year = w.reporting_year
	ORDER BY s.reporting_year;

/*================================================================
  FactActual VS Management P&L Targets
  ================================================================ */
-- Reconcile the warehouse Actual P&L against the management targets.
-- A £100 tolerance is retained because transaction-level amounts were rounded to two decimal places during synthetic data generation.

WITH ExpectedTargets AS (
	SELECT *
	FROM (
		VALUES
			(2025, 72000000.00, 18720000.00, 43920000.00),
			(2026, 52500000.00, 13125000.00, 30975000.00)
			) AS t (
				reporting_year,
				expected_revenue,
				expected_cost_of_revenue,
				expected_operating_expenses)),

WarehousTotals AS (
		SELECT
			d.calendar_year AS reporting_year,
			SUM(CASE WHEN LEFT(a.account_code,1) = '4' THEN f.reporting_amount_gbp ELSE 0 END) AS actual_revenue,
			SUM(CASE WHEN LEFT(a.account_code,1) = '5' THEN f.reporting_amount_gbp ELSE 0 END) AS actual_cost_of_revenue,
			SUM(CASE WHEN LEFT(a.account_code,1) = '6' THEN f.reporting_amount_gbp ELSE 0 END) AS actual_operating_expenses

		FROM dw.FactActual AS f
		INNER JOIN dw.DimDate AS d
			ON f.date_key = d.date_key
		INNER JOIN dw.DimAccount AS a
			ON f.account_key = a. account_key
		GROUP BY d.calendar_year
		)

SELECT 
	w.reporting_year,
	w.actual_revenue - t .expected_revenue AS revenue_difference,
	w.actual_cost_of_revenue - t.expected_cost_of_revenue AS cost_of_revenue_difference,
	w.actual_operating_expenses - t.expected_operating_expenses AS opex_difference,
	CASE WHEN ABS(w.actual_revenue - t .expected_revenue) <= 100
		 AND ABS(w.actual_cost_of_revenue - t.expected_cost_of_revenue) <= 100
		 AND ABS(w.actual_operating_expenses - t.expected_operating_expenses) <= 100
		 THEN 'PASS'
		 ELSE 'FAIL'
	END AS reconciliation_status

FROM WarehousTotals AS w
INNER JOIN ExpectedTargets AS t
	ON w.reporting_year = t.reporting_year
ORDER BY w.reporting_year;

/* Data quality and reconciliation controls finished:
   1. Validate raw staging data for duplicates, missing values,
      invalid references and currency mismatches.
   2. Reconcile staging to DW to confirm transformation integrity.
   3. Reconcile DW Actuals to management P&L targets.
*/

