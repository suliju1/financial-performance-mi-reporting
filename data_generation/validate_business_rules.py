"""
Business rule validation checks:

1. Ensure every GL account has a corresponding business rule.
2. Ensure all product codes referenced in business rules exist in the product master.
3. Ensure all cost centre codes referenced in business rules exist in the cost centre master.
4. Ensure every product code is used by at least one business rule.
5. Ensure every cost centre code is used by at least one business rule.
6. Ensure all entity and region codes referenced in entity-region mappings exist in master data.
7. Ensure region weights sum to 100% for each entity.
"""

from pathlib import Path
import pandas as pd
from business_rules import ACCOUNT_RULES,ENTITY_REGION_WEIGHTS

PROJECT_ROOT = Path(__file__).resolve().parents[1]
RAW_DATA_DIR = PROJECT_ROOT / "data"/"raw"

chart_of_accounts = pd.read_csv(RAW_DATA_DIR / "chart_of_accounts.csv", dtype=str)
products = pd.read_csv(RAW_DATA_DIR / "products.csv", dtype=str)
cost_centres = pd.read_csv(RAW_DATA_DIR / "cost_centres.csv", dtype=str)
entities = pd.read_csv(RAW_DATA_DIR / "entities.csv", dtype=str)
regions = pd.read_csv(RAW_DATA_DIR / "regions.csv", dtype=str)

# Compare GL accounts in master data with configured business rules
# to identify missing or unexpected account mappings.
# Each GL account should have exactly one business rule mapping.

master_accounts = set(chart_of_accounts['account_code'])
rule_accounts = set(ACCOUNT_RULES.keys())

missing_rules = master_accounts - rule_accounts
extra_rules = rule_accounts - master_accounts

if not missing_rules and not extra_rules:
    print("PASS: All GL accounts have exactly one business rule mapping.")
else:
    print("FAIL: Some GL accounts are missing or have extra business rule mappings.")


# Validate that every product code referenced in ACCOUNT_RULES exists in
# the product master data. Any invalid codes are collected in a set so
# duplicates are removed automatically. If the set remains empty, all
# product mappings are valid; otherwise, the invalid codes are reported.

valid_products = set(products["product_code"])
invalid_products = set()

for rule in ACCOUNT_RULES.values():
    for product_code in rule["products"]:
        if product_code not in valid_products:
            invalid_products.add(product_code)

if not invalid_products:
    print("PASS: All product mappings reference valid master-data codes.")

else:
    print(f"FAIL: Invalid product codes: {', '.join(invalid_products)}")

# Validate that every cost centre code referenced in ACCOUNT_RULES exists
# in the cost centre master data. Any invalid codes are collected in a set
# so duplicates are removed automatically. If the set remains empty, all
# cost centre mappings are valid; otherwise, the invalid codes are reported.

valid_cost_centres = set(cost_centres["cost_centre_code"])
invalid_cost_centres = set()

for rule in ACCOUNT_RULES.values():
    for cost_centre_code in rule["cost_centres"]:
        if cost_centre_code not in valid_cost_centres:
            invalid_cost_centres.add(cost_centre_code)

if not invalid_cost_centres:
    print("PASS: All cost centre mappings reference valid master-data codes.")

else:
    print(f"FAIL: Invalid cost centre codes: {', '.join(invalid_cost_centres)}")

# Check whether every product in the product master is referenced by at least
# one account business rule. Products that exist in master data but are never
# used by any rule are reported as uncovered products.
master_products = set(products["product_code"])

rule_products = {
    product_code
    for rule in ACCOUNT_RULES.values()
    for product_code in rule["products"]
}

uncovered_products = master_products - rule_products

if not uncovered_products:
    print(
        "PASS: All product codes are covered "
        "by business rules."
    )
else:
    print(
        f"FAIL: Products not covered by business rules: "
        f"{uncovered_products}"
    )

# Check whether every cost centre in the cost centre master is referenced by
# at least one account business rule. Cost centres that are never used by any
# rule are reported as uncovered cost centres.
master_cost_centres = set(cost_centres["cost_centre_code"])

rule_cost_centres = {
    cost_centre_code
    for rule in ACCOUNT_RULES.values()
    for cost_centre_code in rule["cost_centres"]
}

uncovered_cost_centres = (
    master_cost_centres - rule_cost_centres
)

if not uncovered_cost_centres:
    print(
        "PASS: All cost centre codes are covered "
        "by business rules."
    )
else:
    print(
        f"FAIL: Cost centres not covered by business rules: "
        f"{uncovered_cost_centres}"
    )

# Validate that all entity and region codes used in ENTITY_REGION_WEIGHTS
# exist in the corresponding master-data tables. Any entity keys not found
# in the entity master are identified directly, while invalid region codes
# are collected from each entity's region-weight mapping. Validation passes
# only when both the invalid entity set and invalid region set are empty.

valid_entities = set(
    entities["entity_code"]
)

valid_regions = set(
    regions["region_code"]
)


invalid_entities = (
    set(ENTITY_REGION_WEIGHTS.keys())
    - valid_entities
)

invalid_regions = set()

for region_weights in ENTITY_REGION_WEIGHTS.values():
    for region_code in region_weights:
        if region_code not in valid_regions:
            invalid_regions.add(region_code)


if not invalid_entities and not invalid_regions:
    print(
        "PASS: Entity-region mappings reference "
        "valid master-data codes."
    )
else:
    print(
        f"FAIL: Invalid entities: {invalid_entities}; "
        f"Invalid regions: {invalid_regions}"
    )


# Validate that the region weights for each entity add up to 1.0 (100%).
# Because floating-point calculations can introduce very small precision
# differences, a small tolerance is used instead of checking for exact
# equality. Any entity whose weights do not total approximately 1.0 is
# stored with its calculated total and reported as a validation failure.

invalid_weight_totals = {}


for entity_code, region_weights in (
    ENTITY_REGION_WEIGHTS.items()
):
    total_weight = sum(region_weights.values())

    if abs(total_weight - 1.0) > 0.000001:
        invalid_weight_totals[entity_code] = (
            total_weight
        )


if not invalid_weight_totals:
    print(
        "PASS: Entity-region weights sum to 1.0 "
        "for every entity."
    )
else:
    print(
        f"FAIL: Invalid region-weight totals: "
        f"{invalid_weight_totals}"
    ) 

# Collect the result of each business-rule validation so the script can
# stop the pipeline if any validation check fails.
results = []

results.append(not missing_rules and not extra_rules)
results.append(not invalid_products)
results.append(not invalid_cost_centres)
results.append(not uncovered_products)
results.append(not uncovered_cost_centres)
results.append(not invalid_entities and not invalid_regions)
results.append(not invalid_weight_totals)

# Stop the pipeline if any business-rule validation fails.
if all(results):
    print("\nBUSINESS RULE VALIDATION PASSED.")
else:
    raise ValueError(
        "BUSINESS RULE VALIDATION FAILED. "
        "Resolve the errors before generating financial data."
    )

