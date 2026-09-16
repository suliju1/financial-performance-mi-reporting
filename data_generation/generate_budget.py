"""
Generate the FY2026 approved revenue budget baseline.

The budget is allocated from the annual company revenue target into
monthly periods, products and GL revenue accounts. Further allocation
to cost centres, entities and commercial regions will be added later.
"""

from budget_assumptions import (
    ANNUAL_REVENUE,
    BUDGET_VERSION,
    BUDGET_YEAR,
    ENTITY_REVENUE_MIX,
    MONTHLY_WEIGHTS,
    PRODUCT_REVENUE_MIX,
    REVENUE_ACCOUNT_MIX,
    REVENUE_COST_CENTRE_MIX,
)

from business_rules import ENTITY_REGION_WEIGHTS

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
                                "budget_year": BUDGET_YEAR,
                                "budget_month": month_number,
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


# Review a small sample and confirm that the detailed allocations still
# reconcile to the original £80m annual revenue budget.
for row in budget_rows[:10]:
    print(row)

total_budget = sum(
    row["budget_amount"]
    for row in budget_rows
)

print()
print(f"Number of budget records: {len(budget_rows)}")
print(f"Total revenue budget: £{total_budget:,.2f}")