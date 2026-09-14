from pathlib import Path
import pandas as pd 

PROJECT_ROOT = Path(__file__).resolve().parents[1]
RAW_DATA_DIR = PROJECT_ROOT / "data" / "raw"

print(f"Project root directory: {PROJECT_ROOT}")
print(f"Raw data directory: {RAW_DATA_DIR}")

chart_of_accounts = pd.read_csv(RAW_DATA_DIR / "chart_of_accounts.csv", dtype = {"account_code":"string"})

cost_centres = pd.read_csv(RAW_DATA_DIR / "cost_centres.csv")

products = pd.read_csv(RAW_DATA_DIR / "products.csv")

entities = pd.read_csv(RAW_DATA_DIR / "entities.csv")

regions = pd.read_csv(RAW_DATA_DIR / "regions.csv")

print("Master data loaded successfully.")

print("\nRecord counts:")
print(f"Chart of Accounts: {len(chart_of_accounts)} records")
print(f"Cost Centres: {len(cost_centres)} records")
print(f"Products: {len(products)} records")
print(f"Entities: {len(entities)} records")
print(f"Regions: {len(regions)} records")

print()
results = []

def check_unique_key(df, key_column, table_name):
    """Check that a business key contains no nulls or duplicates."""

    null_count = df[key_column].isnull().sum()
    duplicate_count = df[key_column].duplicated().sum()

    if null_count == 0 and duplicate_count == 0:
        print(f"PASS:{table_name}.{key_column} is valid (no nulls or duplicates).")
        return True

    print(f"Fail:{table_name}.{key_column} has {null_count} nulls and {duplicate_count} duplicates.")
    return False

results.append(check_unique_key(chart_of_accounts, "account_code", "chart_of_accounts"))
results.append(check_unique_key(cost_centres, "cost_centre_code", "cost_centres"))
results.append(check_unique_key(products, "product_code", "products"))
results.append(check_unique_key(entities, "entity_code", "entities"))
results.append(check_unique_key(regions, "region_code", "regions"))

def check_required_columns(df, required_columns, table_name):
    """Check that all required columns are present in the DataFrame."""
    missing_columns = [col for col in required_columns if col not in df.columns]
    if not missing_columns:
        print(f"PASS:{table_name} contains all required columns.")
        return True
    print(f"FAIL:{table_name} is missing required columns: {missing_columns}")
    return False

EXPECTED_COLUMNS = {
    "chart_of_accounts": ["account_code", 
                          "account_name", 
                          "account_type",
                          "pl_category",
                          "pl_subcategory",
                          "reporting_order", 
                          "normal_balance",
                          "variance_logic"],
    "cost_centres": ["cost_centre_code", 
                     "cost_centre_name",
                     "department",
                     "business_function",
                     "pl_reporting_group",
                     "manager_role",
                     "active_flag"],
    "products": ["product_code", 
                 "product_name",
                 "product_category",
                 "revenue_model",
                 "strategic_segment",
                 "active_flag"],
    "entities": ["entity_code", 
                 "entity_name",
                 "country",
                 "currency",
                 "entity_type",
                 "active_flag"],
    "regions": ["region_code", 
                "region_name",
                "region_group",
                "active_flag"]
}


results.append(check_required_columns(chart_of_accounts, EXPECTED_COLUMNS["chart_of_accounts"], "chart_of_accounts"))
results.append(check_required_columns(cost_centres, EXPECTED_COLUMNS["cost_centres"], "cost_centres"))
results.append(check_required_columns(products, EXPECTED_COLUMNS["products"], "products"))
results.append(check_required_columns(entities, EXPECTED_COLUMNS["entities"], "entities"))
results.append(check_required_columns(regions, EXPECTED_COLUMNS["regions"], "regions"))

def check_accounting_logic(chart_of_accounts):
    """Validate normal balances against account types."""

    invalid_revenue = chart_of_accounts[(chart_of_accounts["account_type"] == "Revenue") 
                                        & (chart_of_accounts["normal_balance"] != "Credit")]

    invalid_expense = chart_of_accounts[(chart_of_accounts["account_type"] == "Expense")
                                        & (chart_of_accounts["normal_balance"] != "Debit")]

    if invalid_revenue.empty and invalid_expense.empty:
        print("PASS: Accounting normal_balance values are valid.")
        return True

    print("FAIL: Invalid account normal_balance values found.")

    return False

results.append(check_accounting_logic(chart_of_accounts))

print()
print(results)

if all(results):
    print("All master data validation checks passed.")
else:
    raise ValueError("MASTER DATA VALIDATION FAILED:Resolve the errors before generating financial data.")



 