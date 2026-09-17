"""
Generate the FY2026 approved revenue budget baseline.

The budget is allocated from the annual company revenue target into
monthly periods, products and GL revenue accounts. Further allocation
to cost centres, entities and commercial regions will be added later.
"""
from datetime import date
from pathlib import Path
import pandas as pd

# Define the project output location so the generated budget dataset is written consistently to the raw-data layer used by later pipeline stages.
PROJECT_ROOT = Path(__file__).resolve().parents[1]
RAW_DATA_DIR = PROJECT_ROOT / "data" / "raw"


# Import budget assumptions and validated business-rule mappings used
# to allocate the annual P&L budget across reporting dimensions.
from budget_assumptions import (
    ANNUAL_COST_OF_REVENUE,
    ANNUAL_OPERATING_EXPENSES,
    ANNUAL_REVENUE,
    BUDGET_VERSION,
    BUDGET_YEAR,
    COST_OF_REVENUE_ACCOUNT_MIX,
    ENTITY_REVENUE_MIX,
    MONTHLY_WEIGHTS,
    OPEX_ACCOUNT_MIX,
    OPEX_GROUP_MIX,
    PRODUCT_REVENUE_MIX,
    REVENUE_ACCOUNT_MIX,
    REVENUE_COST_CENTRE_MIX,
    ANNUAL_GROSS_PROFIT,
    ANNUAL_EBITDA
)

from business_rules import (
    ACCOUNT_RULES,
    ENTITY_REGION_WEIGHTS,
)

# Allocate the annual revenue budget through each reporting dimension:
# Month → Product → Account → Cost Centre → Entity → Commercial Region.
# Each allocation layer uses weights that sum to 100%, so the detailed
# records should reconcile exactly to the original annual revenue target.
budget_rows = []

for month_number, month_weight in MONTHLY_WEIGHTS.items():

    for product_code, product_weight in (
        PRODUCT_REVENUE_MIX.items()
    ):

        for account_code, account_weight in (
            REVENUE_ACCOUNT_MIX[product_code].items()
        ):

            for cost_centre_code, cost_centre_weight in (
                REVENUE_COST_CENTRE_MIX[account_code].items()
            ):

                for entity_code, entity_weight in (
                    ENTITY_REVENUE_MIX.items()
                ):

                    for region_code, region_weight in (
                        ENTITY_REGION_WEIGHTS[entity_code].items()
                    ):

                        budget_amount = (
                            ANNUAL_REVENUE
                            * month_weight
                            * product_weight
                            * account_weight
                            * cost_centre_weight
                            * entity_weight
                            * region_weight
                        )

                        budget_rows.append(
                            {
                                "budget_month": date(BUDGET_YEAR, month_number, 1),
                                "budget_version": BUDGET_VERSION,
                                "account_code": account_code,
                                "cost_centre_code": cost_centre_code,
                                "product_code": product_code,
                                "entity_code": entity_code,
                                "region_code": region_code,
                                "budget_amount": round(
                                    budget_amount,
                                    2,
                                ),
                            }
                        )


# Generate Cost of Revenue budget records. Each account receives its share
# of the annual Cost of Revenue budget, which is then allocated evenly across
# the valid products and cost centres defined in ACCOUNT_RULES. Entity and
# region allocation follows the existing management allocation assumptions.
for month_number, month_weight in MONTHLY_WEIGHTS.items():

    for account_code, account_weight in (
        COST_OF_REVENUE_ACCOUNT_MIX.items()
    ):

        valid_products = ACCOUNT_RULES[account_code]["products"]
        valid_cost_centres = ACCOUNT_RULES[account_code]["cost_centres"]

        product_weight = 1 / len(valid_products)
        cost_centre_weight = 1 / len(valid_cost_centres)

        for product_code in valid_products:
            for cost_centre_code in valid_cost_centres:
                for entity_code, entity_weight in (
                    ENTITY_REVENUE_MIX.items()
                ):
                    for region_code, region_weight in (
                        ENTITY_REGION_WEIGHTS[entity_code].items()
                    ):

                        budget_amount = (
                            ANNUAL_COST_OF_REVENUE
                            * month_weight
                            * account_weight
                            * product_weight
                            * cost_centre_weight
                            * entity_weight
                            * region_weight
                        )

                        budget_rows.append(
                            {
                                "budget_month": date(BUDGET_YEAR, month_number, 1),
                                "budget_version": BUDGET_VERSION,
                                "account_code": account_code,
                                "cost_centre_code": cost_centre_code,
                                "product_code": product_code,
                                "entity_code": entity_code,
                                "region_code": region_code,
                                "budget_amount": round(budget_amount, 2),
                            }
                        )

# Generate Operating Expense budget records. The annual Opex target is first
# allocated to management P&L groups, then to individual GL accounts. Valid
# product and cost-centre combinations come from ACCOUNT_RULES.
for month_number, month_weight in MONTHLY_WEIGHTS.items():

    for opex_group, group_weight in OPEX_GROUP_MIX.items():

        for account_code, account_weight in (
            OPEX_ACCOUNT_MIX[opex_group].items()
        ):

            valid_products = ACCOUNT_RULES[account_code]["products"]
            valid_cost_centres = ACCOUNT_RULES[account_code]["cost_centres"]

            product_weight = 1 / len(valid_products)
            cost_centre_weight = 1 / len(valid_cost_centres)

            for product_code in valid_products:
                for cost_centre_code in valid_cost_centres:
                    for entity_code, entity_weight in (
                        ENTITY_REVENUE_MIX.items()
                    ):
                        for region_code, region_weight in (
                            ENTITY_REGION_WEIGHTS[entity_code].items()
                        ):

                            budget_amount = (
                                ANNUAL_OPERATING_EXPENSES
                                * month_weight
                                * group_weight
                                * account_weight
                                * product_weight
                                * cost_centre_weight
                                * entity_weight
                                * region_weight
                            )

                            budget_rows.append(
                                {
                                    "budget_month": date(BUDGET_YEAR, month_number, 1),
                                    "budget_version": BUDGET_VERSION,
                                    "account_code": account_code,
                                    "cost_centre_code": cost_centre_code,
                                    "product_code": product_code,
                                    "entity_code": entity_code,
                                    "region_code": region_code,
                                    "budget_amount": round(budget_amount, 2),
                                }
                            )


# Reconcile the generated detailed budget back to the high-level annual
# management P&L assumptions before exporting any data.
expected_total = (
    ANNUAL_REVENUE
    + ANNUAL_COST_OF_REVENUE
    + ANNUAL_OPERATING_EXPENSES
)

generated_total = sum(
    row["budget_amount"]
    for row in budget_rows
)

print(f"Number of budget records: {len(budget_rows)}")
print(f"Expected budget total: £{expected_total:,.2f}")
print(f"Generated budget total: £{generated_total:,.2f}")

# Reconcile the detailed budget records back to the main management P&L.
# Revenue, Cost of Revenue and Operating Expense accounts are identified from the allocation assumptions.
# The resulting Gross Profit and EBITDA are then compared with the original high-level budget assumptions.

revenue_accounts = {
    account_code 
    for account_mix in REVENUE_ACCOUNT_MIX.values()
    for account_code in account_mix
}

cost_of_revenue_accounts = set(COST_OF_REVENUE_ACCOUNT_MIX.keys())

opex_accounts = {
    account_code
    for account_mix in OPEX_ACCOUNT_MIX.values()
    for account_code in account_mix 
}

generated_revenue = sum(
    row["budget_amount"]
    for row in budget_rows
    if row["account_code"] in revenue_accounts
)

generated_cost_of_revenue = sum(
    row["budget_amount"]
    for row in budget_rows
    if row["account_code"] in cost_of_revenue_accounts
)

generated_opex = sum(
    row["budget_amount"]
    for row in budget_rows
    if row["account_code"] in opex_accounts
)

generated_gross_profit = generated_revenue - generated_cost_of_revenue
generated_ebitda = generated_gross_profit - generated_opex

print()
print("FY2026 Management P&L Budget")
print("----------------------------")
print(f"Revenue: £{generated_revenue:,.2f}")
print(f"Cost of Revenue: £{generated_cost_of_revenue:,.2f}")
print(f"Gross Profit: £{generated_gross_profit:,.2f}")
print(f"Operating Expenses: £{generated_opex:,.2f}")
print(f"EBITDA: £{generated_ebitda:,.2f}")

# Reconcile each generated P&L measure to the original annual management assumptions.
# A small tolerance is allowed because thousands of detailed budget records are rounded to two decimal places before being aggregated.
# If any measure falls outside the tolerance, the pipeline stops immediately.
RECONCILIATION_TOLERANCE = 100.00

reconciliation_checks = {
    "Revenue": (generated_revenue, ANNUAL_REVENUE),
    "Cost of Revenue": (generated_cost_of_revenue, ANNUAL_COST_OF_REVENUE),
    "Gross Profit": (generated_gross_profit, ANNUAL_GROSS_PROFIT),
    "Operating Expenses": (generated_opex, ANNUAL_OPERATING_EXPENSES),
    "EBITDA": (generated_ebitda, ANNUAL_EBITDA)
}

reconciliation_failures = {}

for measure, (generated_amount, expected_amount) in reconciliation_checks.items():
    if abs(generated_amount - expected_amount) > RECONCILIATION_TOLERANCE:
        reconciliation_failures[measure] = {
            "expected": expected_amount,
            "generated": generated_amount,
            "difference": generated_amount - expected_amount
        }


if not reconciliation_failures:
    print()
    print("Reconciliation successful: All generated P&L measures are within the tolerance.")
else:
    raise ValueError(
        "Reconciliation failed: The following P&L measures are outside the tolerance:"
        f"{reconciliation_failures}"
    )

# Convert the generated budget records into a DataFrame and write to CSV for use in later pipeline stages.
# Each month/account/cost-centre/product/entity/region/budget-version combination should occur only once before export.

budget_df = pd.DataFrame(budget_rows)

budget_grain = [
    "budget_month",
    "account_code",
    "cost_centre_code",
    "product_code",
    "entity_code",
    "region_code",
    "budget_version"
]

duplicated_budget_rows = (budget_df.duplicated(subset=budget_grain, keep=False))

if duplicated_budget_rows.any():
    raise ValueError(
        "Duplicate budget records found for the following month/account/cost-centre/product/entity/region/budget-version combinations:"
        f"{budget_df[duplicated_budget_rows]}"
    )

print("BUDGET GRAIN VALIDATION PASSED.")

# Export the validated FY2026 approved budget to the raw-data layer for subsequent SQL ingestion and transformation.
budget_output_path = (RAW_DATA_DIR / "budget.csv")

budget_df.to_csv(
    budget_output_path,
    index=False,
    float_format="%.2f"
)

print(f"Budget exported successfully to: {budget_output_path}.")
print(f"Exported rows:{len(budget_df)}")
