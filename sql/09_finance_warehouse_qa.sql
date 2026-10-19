USE FinancialPerformanceMI;
GO

/*=======================================================================================================
  Final Warehouse QA
  Confirm that all dimensions and fact tables contain the expected number of records after transformation.
  ======================================================================================================= */
  SELECT 'DimAccount' AS table_name, COUNT(*) AS row_count
  FROM dw.DimAccount

  UNION ALL

  SELECT 'DimCostCentre' , COUNT(*) 
  FROM dw.DimCostCentre

  UNION ALL

  SELECT 'DimProduct' , COUNT(*) 
  FROM dw.DimProduct

  UNION ALL

  SELECT 'DimEntity' , COUNT(*) 
  FROM dw.DimEntity

  UNION ALL

  SELECT 'DimRegion' , COUNT(*) 
  FROM dw.DimRegion

  UNION ALL

  SELECT 'DimDate' , COUNT(*) 
  FROM dw.DimDate

  UNION ALL

  SELECT 'FactActual' , COUNT(*) 
  FROM dw.FactActual

  UNION ALL

  SELECT 'FactBudget' , COUNT(*) 
  FROM dw.FactBudget;

/* Confirm that controlled staging exceptions were handled correctly during the FactActual warehouse load. */
SELECT 'Unknown Cost Centre Mappings' AS qa_check, COUNT(*) AS result_count
FROM dw.FactActual AS f
INNER JOIN dw.DimCostCentre AS c
	ON f.cost_centre_key = c.cost_centre_key
WHERE c.cost_centre_code = 'CC_UNK'

UNION ALL

SELECT 'Unknown Region Mappings', COUNT(*) 
FROM dw.FactActual AS f
INNER JOIN dw.DimRegion AS r
	ON f.region_key = r.region_key
WHERE r.region_code = 'REG_UNK'

UNION ALL

SELECT 'Entity-currency Mismatch',COUNT(*) 
FROM dw.FactActual AS f
INNER JOIN dw.DimEntity AS e
	ON f.entity_key = e.entity_key
WHERE f.local_currency <> e.currency;

-- Confirm that no duplicate Actual transaction IDs remain.
SELECT transaction_id, COUNT(*) AS occurrence_count
FROM dw.FactActual
GROUP BY transaction_id
HAVING COUNT(*) > 1;

-- Confirm that the final Budget fact table still respects the defined monthly planning grain.
SELECT 
	date_key,
	account_key,
	cost_centre_key,
	product_key,
	entity_key,
	region_key,
	budget_version
FROM dw.FactBudget
GROUP BY 
	date_key,
	account_key,
	cost_centre_key,
	product_key,
	entity_key,
	region_key,
	budget_version
HAVING COUNT(*) > 1;

SELECT 
	'DimPLLine' AS table_name,
	COUNT(*) AS actual_row_count,
	5 AS expected_row_count,
	CASE WHEN COUNT(*) = 5 THEN 'PASS'
		 ELSE 'FAIL'
	END AS qa_status
FROM dw.DimPLLine;