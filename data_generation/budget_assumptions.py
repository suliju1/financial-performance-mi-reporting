"""
Core assumptions used to generate the FY2026 approved management budget.

The assumptions define the overall financial scale of the synthetic company
and will later be allocated across accounts, products, cost centres, legal entities and commercial regions.
"""

BUDGET_YEAR = 2026
BUDGET_VERSION = "FY26 Approved"

# Define the high-level annual management budget. These assumptions set
# the overall scale and profitablility profile of the synthetic company.
ANNUAL_REVENUE = 80_000_000
TARGET_GROSS_MARGIN = 0.76
TARGET_EBITDA_MARGIN = 0.17

# Derive the main annual P&L totals from the high-level management assumptions.
ANNUAL_COST_OF_REVENUE = (ANNUAL_REVENUE * (1-TARGET_GROSS_MARGIN))
ANNUAL_GROSS_PROFIT = (ANNUAL_REVENUE - ANNUAL_COST_OF_REVENUE)
ANNUAL_EBITDA = (ANNUAL_REVENUE * TARGET_EBITDA_MARGIN) 
ANNUAL_OPERATING_EXPENSES = (ANNUAL_GROSS_PROFIT - ANNUAL_EBITDA)

# Define the planned revenue mix by product. The percentages represent 
# each product line's expected contributiion to total annual revenue and must sum to 100%.
PRODUCT_REVENUE_MIX = {"P000": 0.02, # Corporate / Non-Product 
                       "P001": 0.48, # Core Platform
                       "P002": 0.20, # Analytics
                       "P003": 0.20, # Payments,
                       "P004": 0.10  # Enterprise Services
                       } 

if abs(sum(PRODUCT_REVENUE_MIX.values()) - 1.0) > 0.000001:
    raise ValueError(
        "PRODUCT_REVENUE_MIX must sum to 1.0."  
    )

# Define monthly budget seasonality. Revenue is relatively stable throughout
# the year, with a modest uplift toward year-end. The monthly weights must
# together allocate 100% of the annual budget.
MONTHLY_WEIGHTS = {
    1: 0.078,
    2: 0.078,
    3: 0.082,
    4: 0.080,
    5: 0.081,
    6: 0.083,
    7: 0.081,
    8: 0.080,
    9: 0.084,
    10: 0.085,
    11: 0.088,
    12: 0.100,
}

if abs(sum(MONTHLY_WEIGHTS.values()) - 1.0) > 0.000001:
    raise ValueError(
        "MONTHLY_WEIGHTS must sum to 1.0."
    )