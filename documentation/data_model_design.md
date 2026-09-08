# Finance Data Model Design

## 1. Management P&L Structure

The Financial Performance & MI Reporting Solution uses the following management P&L structure:

Revenue
- Subscription Revenue
- Usage Revenue
- Professional Services Revenue
- Other Revenue

Cost of Revenue
- Hosting & Infrastructure
- Customer Support
- Payment Processing
- Implementation Costs

Gross Profit

Operating Expenses
- Sales & Marketing
- Technology & R&D
- General & Administrative
- People & HR

EBITDA

## 2. Chart of Account Design

The Chart of Accounts acts as controlled master data between source-system transactions and management reporting.

Each GL account is mapped to:

- Account name
- Account Type
- P&L category
- P&L subcategory
- Reporting order
- Normal accounting balance
- Variance treatment

Reporting classifications are maintained in master data rather than embedded directly in transactional records. This allows reporting structures to be changed without modifying historical transactions.

## 3. Fact Tables

### FactActual

**Grain:** One row per general-ledger transaction line.

The table will contain actual financial transactions extracted from the simulated ERP system.

Key dimensions will include:

- Posting Date
- GL Account
- Cost Centre
- Product
- Legal Entity
- Region

### FactBudget

**Grain:** One row per month, account, cost centre, product, entity, region and budget version combination.

The table will contain financial planning data extracted from the simulated planning system.

FactActual and FactBudget will share conformed dimensions to allow consistent Actual vs Budget reporting.

## 4. Master Data Dimensions

### DimAccount

Provides the financial reporting hierarchy used to translate general-ledger accounts into management P&L reporting lines.

Key attributes include:

- Account Code
- Account Name
- Account Type
- P&L Category
- P&L Subcategory
- Reporting Order
- Normal Balance
- Variance Logic

### DimCostCentre

Represents the organisational ownership of financial activity.

Key attributes include:

- Cost Centre Code
- Cost Centre Name
- Department
- Business Function
- P&L Reporting Group
- Manager Role

Account classification and cost centre classification serve different purposes. Accounts describe the nature of financial activity, while cost centres identify organisational responsibility.

### DimProduct

Provides the product hierarchy used for revenue and cost analysis.

Key attributes include:

- Product Code
- Product Name
- Product Category
- Revenue Model
- Strategic Segment

### DimEntity

Represents the legal entities within the Aurelia Technologies group.

Key attributes include:

- Entity Code
- Entity Name
- Country
- Functional Currency
- Entity Type

### DimRegion

Provides the management geography used for regional performance reporting.

Key attributes include:

- Region Code
- Region Name
- Region Group

## 5. Logical Data Model

The reporting model will use a star-schema approach with two primary fact tables sharing conformed dimensions.

                     DimDate
                        |
                     DimAccount
                        |
DimCostCentre ---- FactActual ---- DimProduct
                        |
                     DimEntity
                        |
                     DimRegion


                     DimDate
                        |
                     DimAccount
                        |
DimCostCentre ---- FactBudget ---- DimProduct
                        |
                     DimEntity
                        |
                     DimRegion

The use of shared conformed dimensions enables Actual and Budget information to be analysed consistently using the same reporting hierarchies.

## 6. Table Grain

| Table | Grain |
|---|---|
| FactActual | One row per general-ledger transaction line |
| FactBudget | One row per month, account, cost centre, product, entity, region and budget version |
| DimAccount | One row per GL account |
| DimCostCentre | One row per cost centre |
| DimProduct | One row per product |
| DimEntity | One row per legal entity |
| DimRegion | One row per management reporting region |
| DimDate | One row per calendar date |