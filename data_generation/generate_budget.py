"""
Generate the monthly FY2026 approved budget baseline.

This first version creates the planning calendar and applies the annual
revenue target and monthly seasonality assumptions. Detailed allocation
across accounts, products, cost centres, entities and regions will be
added in the next development step.
"""

from datetime import date

from budget_assumptions import (
    ANNUAL_REVENUE,
    BUDGET_VERSION,
    BUDGET_YEAR,
    MONTHLY_WEIGHTS,
)


# Generate one planning record for each month of FY2026 and allocate the
# annual revenue target according to the approved monthly seasonality.
budget_summary = []

for month_number, month_weight in MONTHLY_WEIGHTS.items():
    budget_month = date(
        BUDGET_YEAR,
        month_number,
        1,
    )

    monthly_revenue = (
        ANNUAL_REVENUE * month_weight
    )

    budget_summary.append(
        {
            "budget_month": budget_month,
            "budget_version": BUDGET_VERSION,
            "revenue_budget": round(
                monthly_revenue,
                2,
            ),
        }
    )


# Display the generated monthly budget summary so the assumptions can be
# reviewed before detailed budget allocation logic is introduced.
for row in budget_summary:
    print(row)