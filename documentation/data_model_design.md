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


