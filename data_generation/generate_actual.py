import pandas as pd
import random
from datetime import date
from pathlib import Path

from actual_assumptions import (
    ACCOUNT_AMOUNT_RANGES,
    ACTUAL_END_DATE,
    ACTUAL_START_DATE,
    RANDOM_SEED,
    TRANSACTIONS_PER_BUSINESS_DAY,
    ACTUAL_ENTITY_WEIGHTS,
    ACCOUNT_CLASS_TRANSACTION_WEIGHTS,
    ACTUAL_PNL_AMOUNTS,
    JOURNAL_TYPES_BY_ACCOUNT_CLASS,
    GBP_PER_EUR_MONTHLY,
    ENTITY_LOCAL_CURRENCY,
    DUPLICATE_TRANSACTION_COUNT,
    MISSING_REGION_COUNT,
    INVALID_COST_CENTRE_COUNT,
    CURRENCY_MISMATCH_COUNT
)

from business_rules import (ACCOUNT_RULES,ENTITY_REGION_WEIGHTS)

# Fix the random seed so account and dimensional assignments are reproducible every time the Actual generator is run.
random.seed(RANDOM_SEED)


# Generate all business dates in the Actual reporting period, then create a fixed number of GL transaction skeleton records for each business day.

business_dates = pd.date_range(
    start=ACTUAL_START_DATE,
    end=ACTUAL_END_DATE,
    freq="B"
)

actual_rows = []

transaction_number = 1

for posting_date in business_dates:
    for daily_sequence in range(1, TRANSACTIONS_PER_BUSINESS_DAY+1):

        # Select the broad P&L account class using transaction frequency weights,
        # then randomly select one valid GL account within that class.
        account_class = random.choices(
            population=list(ACCOUNT_CLASS_TRANSACTION_WEIGHTS.keys()),
            weights=list(ACCOUNT_CLASS_TRANSACTION_WEIGHTS.values()),
            k=1
        )[0]

        accounts_in_class = [account for account in ACCOUNT_RULES if account.startswith(account_class)]

        account_code = random.choice(accounts_in_class)

        # Assign source-system metadata to each GL transaction. Journal type is selected according to the account class
        # to keep the entries plausible.
        journal_type = random.choice(JOURNAL_TYPES_BY_ACCOUNT_CLASS[account_class])

        description = (f"Synthetic {journal_type} - GL Account {account_code}")

        # Generate a transaction amount using the broad range associated with the selected accound class.
        minimum_amount, maximum_amount = (ACCOUNT_AMOUNT_RANGES[account_class])

        transaction_amount = round(random.uniform(minimum_amount,maximum_amount),2)

        valid_products = (ACCOUNT_RULES[account_code]["products"])

        valid_cost_centres = (ACCOUNT_RULES[account_code]["cost_centres"])

        product_code = random.choice(valid_products)

        cost_centre_code = random.choice(valid_cost_centres)

        # Select a legal entity using the expected transaction distribution, then select a 
        # commercial region using the region weights defined for that entity.
        entity_code = random.choices(
            population=list(ACTUAL_ENTITY_WEIGHTS.keys()),
            weights=list(ACTUAL_ENTITY_WEIGHTS.values()),
            k=1
        )[0]

        region_weights = ENTITY_REGION_WEIGHTS[entity_code]
        region_code = random.choices(
            population=list(region_weights.keys()),
            weights=list(region_weights.values()),
            k=1
        )[0]


        actual_rows.append(
            {"transaction_id":(f"TXN-{transaction_number:07d}"),
             "document_id":(f"DOC-{posting_date:%Y%m%d}-{daily_sequence:03d}"),
             "posting_date": posting_date.date(),
             "account_code":account_code,
             "cost_centre_code":cost_centre_code,
             "product_code":product_code,
             "entity_code":entity_code,
             "region_code":region_code,
             "transaction_amount":transaction_amount,
             "source_system":"ERP",
             "journal_type":journal_type,
             "description":description,
             "load_date":date.today()
             }
        )
        transaction_number += 1

actual_df = pd.DataFrame(actual_rows)

# Calibrate the randomly generated transaction amounts so each year's Revenue, Cost of Revenue and Operating Expenses reconcile to the 
# management P&L targets defined in actual_assumptions.py.
account_class_to_pnl = {
    "4": "revenue",
    "5": "cost_of_revenue",
    "6": "operating_expenses"
}

actual_df["year"] = pd.to_datetime(actual_df["posting_date"]).dt.year

actual_df["account_class"] = actual_df["account_code"].str[0]

for year, pnl_targets in ACTUAL_PNL_AMOUNTS.items():

    for account_class, pnl_name in account_class_to_pnl.items():

        row_filter = (
            (actual_df["year"] == year)
            & (actual_df["account_class"] == account_class)
        )

        current_total = actual_df.loc[row_filter, "transaction_amount"].sum()

        target_total = pnl_targets[pnl_name]

        scaling_factor = target_total / current_total

        actual_df.loc[row_filter, "transaction_amount"] *= scaling_factor

actual_df["transaction_amount"] = actual_df["transaction_amount"].round(2)

# Reconcile the calibrated Actual transactions back to the management P&L targets. A small tolerance is allowed because
# transaction amounts are rounded to two decimal places after scaling.
ACTUAL_RECONCILIATION_TOLERANCE = 100.00

for year, pnl_targets in ACTUAL_PNL_AMOUNTS.items():

    # print(actual_df.columns.tolist())

    year_df = actual_df[actual_df["year"] == year]

    generated_revenue = year_df.loc[year_df["account_class"] == "4", "transaction_amount"].sum()

    generated_cost_of_revenue = year_df.loc[year_df["account_class"] =="5","transaction_amount"].sum()

    generated_opex = year_df.loc[year_df["account_class"] == "6", "transaction_amount"].sum()

    generated_gross_profit = generated_revenue - generated_cost_of_revenue

    generated_ebitda = generated_gross_profit - generated_opex

    # Compare generated Actual P&L amounts with the management targets and stop the pipeline if any measure falls outside the allowed tolerance.
    reconciliation_checks = {
        "Revenue": (generated_revenue, pnl_targets["revenue"]),
        "Cost_of_Revenue": (generated_cost_of_revenue,  pnl_targets["cost_of_revenue"]),
        "Gross_Profit": (generated_gross_profit, pnl_targets["gross_profit"]),
        "Operating_Expenses": (generated_opex, pnl_targets["operating_expenses"]),
        "EBITDA": (generated_ebitda, pnl_targets["ebitda"])
    }

    reconciliation_failures = {}

    for measure, (generated_amount, expected_amount) in reconciliation_checks.items():

        difference = generated_amount - expected_amount

        if abs(difference) > ACTUAL_RECONCILIATION_TOLERANCE:
            reconciliation_failures[measure] = {
                "expected": expected_amount,
                "generated": generated_amount,
                "difference": difference
            }
    if reconciliation_failures:
        raise ValueError(f"{year} ACTUAL P&L RECONCILIATION FAILED: {reconciliation_failures}")  

    print(f"{year} ACTUAL P&L RECONCILIATION PASSED.")  

# Treat the calibrated transaction amount as the GBP group-reporting amount.
# Assign each entity's functional currency and use the historical monthly average FX rate to derive
# the equivalent local-currency amount.
actual_df["reporting_amount_gbp"] = actual_df["transaction_amount"]

actual_df["month"] = pd.to_datetime(actual_df["posting_date"]).dt.month

actual_df["local_currency"] = actual_df["entity_code"].map(ENTITY_LOCAL_CURRENCY)

def get_fx_rate(row):
    if row["local_currency"] == "GBP":
        return 1.0

    if row["local_currency"] == "EUR":
        return GBP_PER_EUR_MONTHLY[row["year"]][row["month"]]

    raise ValueError(f"Unsupported Currency: {row['local_currency']}")

actual_df["fx_rate_to_gbp"] = actual_df.apply(get_fx_rate, axis=1)

actual_df["local_amount"] = (actual_df["reporting_amount_gbp"] / actual_df["fx_rate_to_gbp"]).round(2)

# Define the group reporting currency explicitly. The original calibrated transaction_amount column is no longer needed
# once its GBP reporting value has been preserved in reporting_amount_gbp.
actual_df["reporting_currency"] = "GBP"

# Recalculate the GBP reporting amount from local currency and FX rate,
# then stop the pipeline if the translated value does not reconcile.
FX_RECONCILIATION_TOLERANCE = 0.02

actual_df["recalculated_gbp"] = (actual_df["local_amount"] * actual_df["fx_rate_to_gbp"]).round(2)

actual_df["difference"] = (actual_df["recalculated_gbp"] - actual_df["reporting_amount_gbp"]).abs()

fx_failures = (actual_df["difference"] > FX_RECONCILIATION_TOLERANCE)

if fx_failures.any():
    raise ValueError(f"FX RECONCILIATION FAILED: {fx_failures.sum()} transactions exceed the allowed tolerance.")

print("FX RECONCILIATION PASSED.")

# Remove temporary calculation and validation fields after all P&L and FX
# reconciliation controls have passed.
temporary_columns = [
    "transaction_amount",
    "year",
    "month",
    "account_class",
    "recalculated_gbp",
    "difference"
]

actual_df = actual_df.drop(columns=temporary_columns)

# Arrange the validated Actual dataset into a stable source schema before 
# export so the downstream SQL layer receives predictable column names and order.
actual_columns = [
    "transaction_id",
    "document_id",
    "posting_date",
    "account_code",
    "cost_centre_code",
    "product_code",
    "entity_code",
    "region_code",
    "local_currency",
    "local_amount",
    "fx_rate_to_gbp",
    "reporting_currency",
    "reporting_amount_gbp",
    "source_system",
    "journal_type",
    "description",
    "load_date"
]

actual_df = actual_df[actual_columns]

# Perform final source-data QA before export. The pipeline stops if transaction IDs are duplicated,
# critical fields are missing, dates fall outside the expected reporting period, or entity currencies
# do not match the master rule.
if actual_df["transaction_id"].duplicated().any():
    raise ValueError("ACTUAL QA FAILED: Duplicate transaction IDs found.")

critical_columns = [
    "transaction_id",
    "posting_date",
    "account_code",
    "cost_centre_code",
    "product_code",
    "entity_code",
    "region_code",
    "local_currency",
    "local_amount",
    "reporting_amount_gbp"
]

if actual_df[critical_columns].isna().any().any():
    raise ValueError("ACTUAL AQ FAILED: Missing values found in critical fields.")

if (actual_df["posting_date"].min() < ACTUAL_START_DATE or
    actual_df["posting_date"].max() > ACTUAL_END_DATE):
    raise ValueError("ACTUAL QA FAILED: Posting date outside expected range.")

expected_currency = (actual_df["entity_code"].map(ENTITY_LOCAL_CURRENCY))

if not actual_df["local_currency"].equals(expected_currency):
    raise ValueError("ACTUAL QA FAILED: Entity currency mapping is incorrect.")

print("ACTUAL FINAL QA PASSED.")

# Inject a controlled number of exact duplicate GL transactions into the raw dataset.
# These records are intentionally retained for SQL data-quality testing.
duplicate_transactions = actual_df.sample(n=DUPLICATE_TRANSACTION_COUNT, random_state=RANDOM_SEED)

actual_df = pd.concat([actual_df, duplicate_transactions], ignore_index=True)

print(f"Injected duplicate transactions: {DUPLICATE_TRANSACTION_COUNT}")

# Inject a controlled number of missing Region values into the raw Actual
# dataset so the SQL staging layer can identify and handle null geography.
missing_region_indices = actual_df.sample(n=MISSING_REGION_COUNT, random_state=RANDOM_SEED+1).index

actual_df.loc[missing_region_indices, "region_code"] = None
print(f"Injected missing region values: {MISSING_REGION_COUNT}")
print("Missing region count:", actual_df["region_code"].isna().sum())

# Inject a controlled number of invalid Cost Centre codes so the SQL staging layer can
# test referential-integrity checks against the Cost Centre master.
invalid_cost_centre_indices= actual_df.sample(n=INVALID_COST_CENTRE_COUNT, random_state=RANDOM_SEED + 2).index

actual_df.loc[invalid_cost_centre_indices, "cost_centre_code"] = "CC999"

print(f"Injected invalid cost centre values: {INVALID_COST_CENTRE_COUNT}")

# Inject a controlled number of entity-currency mismatches so the SQL staging layer 
# can test whether local currency agrees with the entity master data.
currency_mismatch_indices = actual_df.sample(n=CURRENCY_MISMATCH_COUNT, random_state=RANDOM_SEED + 3).index

for row_index in currency_mismatch_indices:

    entity_code = actual_df.loc[row_index, "entity_code"]

    if entity_code == "ENT01":
        actual_df.loc[row_index, "local_currency"] = "EUR"
    else:
        actual_df.loc[row_index, "local_currency"] = "GBP"

print(f"Injected entity-currency mismatches: {CURRENCY_MISMATCH_COUNT}")

# Verify that the controlled data-quality exceptions were injected exactly as expected
# before the raw Actual dataset is exported to the SQL staging layer.
duplicate_count = actual_df["transaction_id"].duplicated().sum()

missing_region_count = actual_df["region_code"].isna().sum()

invalid_cost_centre_count = (actual_df["cost_centre_code"] == "CC999").sum()

expected_currency = actual_df["entity_code"].map(ENTITY_LOCAL_CURRENCY)

currency_mismatch_count = (actual_df["local_currency"] != expected_currency).sum()

dq_injection_checks = {
    "Duplicate_transactions":(duplicate_count, DUPLICATE_TRANSACTION_COUNT),
    "Missing_regions": (missing_region_count, MISSING_REGION_COUNT),
    "Invalid_cost_centres": (invalid_cost_centre_count, INVALID_COST_CENTRE_COUNT),
    "Currency_mismatch": (currency_mismatch_count, CURRENCY_MISMATCH_COUNT)
}

for issue, (actual_count, expected_count) in dq_injection_checks.items():

    if actual_count != expected_count:
        raise ValueError(f"DQ INJECTION VERIFICATION FAILED: {issue} expected {expected_count}, found {actual_count}.")

print("DQ INJECTION VERIFICATION PASSED.")

# Export the controlled raw Actual dataset, including the intentionally injected data-quality exceptions
# for subsequent SQL staging, validation and cleansing.
project_root = Path(__file__).resolve().parents[1]
actual_output_path = project_root/"data"/"raw"/"actual.csv"

actual_df.to_csv(actual_output_path, index=False)

print(f"Actual exported successfully: {actual_output_path}")
print(f"Exported rows:{len(actual_df)}")
print(actual_df.columns.tolist())



