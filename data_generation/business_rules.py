# Mapping rules used to generate realistic combinations of
# GL accounts, products and cost centres.
#
# Each GL account is restricted to a set of valid products
# and cost centres so that synthetic financial transactions
# reflect realistic business relationships rather than
# random combinations.
#
# Example:
# Account 4100 = Core Platform Subscription Revenue
# → Product must be P001 (Core Platform)
# → Cost centre must be a Sales cost centre.

# Revenue
# Cost of Revenue
# Sales & Marketing
# Technology & R&D
# General & Administrative
# People & HR

ACCOUNT_RULES = {
    # Revenue
    "4100": {
        "products": ["P001"],
        "cost_centres": ["CC210", "CC220"],
    },
    "4110": {
        "products": ["P002"],
        "cost_centres": ["CC210", "CC220"],
    },
    "4120": {
        "products": ["P003"],
        "cost_centres": ["CC210", "CC220"],
    },
    "4200": {
        "products": ["P003"],
        "cost_centres": ["CC210", "CC220"],
    },
    "4300": {
        "products": ["P004"],
        "cost_centres": ["CC420"],
    },
    "4400": {
        "products": ["P004"],
        "cost_centres": ["CC430"],
    },
    "4900": {
        "products": ["P000"],
        "cost_centres": ["CC110"],
    },
        # Cost of Revenue
    "5100": {
        "products": ["P001", "P002", "P003"],
        "cost_centres": ["CC310", "CC330"],
    },
    "5110": {
        "products": ["P001", "P002", "P003", "P004"],
        "cost_centres": ["CC310", "CC330", "CC420"],
    },
    "5200": {
        "products": ["P001", "P002", "P003", "P004"],
        "cost_centres": ["CC410"],
    },
    "5300": {
        "products": ["P003"],
        "cost_centres": ["CC410"],
    },
    "5400": {
        "products": ["P004"],
        "cost_centres": ["CC420", "CC430"],
    },
        # Sales & Marketing
    "6100": {
        "products": ["P000"],
        "cost_centres": ["CC210", "CC220"],
    },
    "6110": {
        "products": ["P001", "P002", "P003", "P004"],
        "cost_centres": ["CC210", "CC220"],
    },
    "6120": {
        "products": ["P000"],
        "cost_centres": ["CC210", "CC220"],
    },
    "6200": {
        "products": ["P000"],
        "cost_centres": ["CC230"],
    },
    "6210": {
        "products": ["P001", "P002", "P003"],
        "cost_centres": ["CC230"],
    },
    "6220": {
        "products": ["P000", "P001", "P002", "P003"],
        "cost_centres": ["CC230"],
    },
    "6230": {
        "products": ["P000", "P001", "P002", "P003"],
        "cost_centres": ["CC230"],
    },
        # Technology & R&D
    "6300": {
        "products": ["P000", "P001", "P002", "P003"],
        "cost_centres": ["CC310"],
    },
    "6310": {
        "products": ["P000", "P001", "P002", "P003"],
        "cost_centres": ["CC310"],
    },
    "6320": {
        "products": ["P000", "P001", "P002", "P003"],
        "cost_centres": ["CC310"],
    },
    "6330": {
        "products": ["P001", "P002", "P003"],
        "cost_centres": ["CC310", "CC320"],
    },
    "6400": {
        "products": ["P000"],
        "cost_centres": ["CC330"],
    },
    "6410": {
        "products": ["P000"],
        "cost_centres": ["CC330"],
    },
    "6420": {
        "products": ["P000"],
        "cost_centres": ["CC330"],
    },
        # General & Administrative
    "6600": {
        "products": ["P000"],
        "cost_centres": ["CC120"],
    },
    "6610": {
        "products": ["P000"],
        "cost_centres": ["CC120"],
    },
    "6620": {
        "products": ["P000"],
        "cost_centres": ["CC120", "CC140"],
    },
    "6630": {
        "products": ["P000"],
        "cost_centres": ["CC110", "CC120"],
    },
    "6640": {
        "products": ["P000"],
        "cost_centres": ["CC110"],
    },
    "6650": {
        "products": ["P000"],
        "cost_centres": ["CC110", "CC120", "CC140"],
    },
    "6660": {
        "products": ["P000"],
        "cost_centres": ["CC120"],
    },
        # People & HR
    "6700": {
        "products": ["P000"],
        "cost_centres": ["CC130"],
    },
    "6710": {
        "products": ["P000"],
        "cost_centres": ["CC130"],
    },
    "6720": {
        "products": ["P000"],
        "cost_centres": ["CC130"],
    },
    "6730": {
        "products": ["P000"],
        "cost_centres": ["CC130"],
    },
    "6740": {
        "products": ["P000"],
        "cost_centres": ["CC130"],
    },
}

# Defines the probability of financial activity from each
# legal entity being attributed to each commercial region.
#
# Entity and Region are intentionally modelled separately:
# Entity represents the legal company where the transaction
# is booked, while Region represents the commercial market
# to which the activity is attributed.
#
# The weights allow an entity to support multiple regions
# while keeping most activity concentrated in its primary
# market. Weights for each entity must sum to 1.0.

ENTITY_REGION_WEIGHTS = {
    "ENT01": {
        "REG01": 0.70,
        "REG02": 0.12,
        "REG03": 0.10,
        "REG04": 0.08,
    },
    "ENT02": {
        "REG01": 0.10,
        "REG02": 0.72,
        "REG03": 0.10,
        "REG04": 0.08,
    },
    "ENT03": {
        "REG01": 0.08,
        "REG02": 0.10,
        "REG03": 0.74,
        "REG04": 0.08,
    },
    "ENT04": {
        "REG01": 0.08,
        "REG02": 0.10,
        "REG03": 0.12,
        "REG04": 0.70,
    },
}