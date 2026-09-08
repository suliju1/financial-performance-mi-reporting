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
