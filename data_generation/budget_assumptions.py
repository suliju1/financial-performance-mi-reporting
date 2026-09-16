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

# Define how each product's revenue is allocated across the relevant GL
# revenue accounts. The account weights for each product must sum to 100%.
REVENUE_ACCOUNT_MIX = {
    "P000": {
        "4900": 1.00,
    },
    "P001": {
        "4100": 1.00,
    },
    "P002": {
        "4110": 1.00,
    },
    "P003": {
        "4120": 0.65,
        "4200": 0.35,
    },
    "P004": {
        "4300": 0.60,
        "4400": 0.40,
    },
}


# Validate that the revenue-account allocation for each product totals 100%.
for product_code, account_mix in REVENUE_ACCOUNT_MIX.items():
    if abs(sum(account_mix.values()) - 1.0) > 0.000001:
        raise ValueError(
            f"Revenue account mix for {product_code} "
            "must sum to 1.0."
        )

# Define how revenue is distributed across legal entities. These weights
# represent the expected share of group revenue booked by each entity and
# must sum to 100%.
ENTITY_REVENUE_MIX = {
    "ENT01": 0.55,  # UK
    "ENT02": 0.18,  # Germany
    "ENT03": 0.15,  # France
    "ENT04": 0.12,  # Netherlands
}

if abs(sum(ENTITY_REVENUE_MIX.values()) - 1.0) > 0.000001:
    raise ValueError(
        "ENTITY_REVENUE_MIX must sum to 1.0."
    )


# Define how revenue accounts with multiple valid sales cost centres are
# allocated between those cost centres. Accounts with only one valid cost
# centre receive 100% of the budget in that cost centre.
REVENUE_COST_CENTRE_MIX = {
    "4100": {
        "CC210": 0.60,
        "CC220": 0.40,
    },
    "4110": {
        "CC210": 0.60,
        "CC220": 0.40,
    },
    "4120": {
        "CC210": 0.60,
        "CC220": 0.40,
    },
    "4200": {
        "CC210": 0.60,
        "CC220": 0.40,
    },
    "4300": {
        "CC420": 1.00,
    },
    "4400": {
        "CC430": 1.00,
    },
    "4900": {
        "CC110": 1.00,
    },
}


# Validate that each revenue account's cost-centre allocation totals 100%.
for account_code, cost_centre_mix in (
    REVENUE_COST_CENTRE_MIX.items()
):
    if abs(sum(cost_centre_mix.values()) - 1.0) > 0.000001:
        raise ValueError(
            f"Cost centre mix for {account_code} "
            "must sum to 1.0."
        )