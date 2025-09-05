# Part 3 – MRR Calculation & Analytics Integration

This section documents how we designed and implemented a **lean, interview-ready solution** for **Monthly Recurring Revenue (MRR)** analytics, covering **multi-tenant, multi-currency, and multi-timezone** requirements.  
We use **S3 + Snowflake + dbt** to simulate ingestion, normalization, and reporting.

---

## 1) The Problem

Caravelo’s subscription events generate recurring revenue, but analytics require:

- **Temporal normalization**: map each renewal to the correct recognition month.  
- **Currency normalization**: unify native currencies into EUR (internal) and each client’s reporting currency (external).  
- **Billing period normalization**: monthly, quarterly, or annual charges must be reduced to a **monthly equivalent**.  
- **Multi-tenant support**: each client has its own timezone and reporting currency.  
- **Failed renewals**: must be excluded from MRR (or tracked separately as “at-risk”).  

The challenge is to design a data pipeline that ingests JSON events, FX rates, and client configs, and produces **clean MRR facts and reports**.

---

## 2) Sample Inputs

### a) Clients Config (JSONL)
```json
{ "clientCode": "Y4", "client_name": "Volaris", "reporting_timezone": "America/Mexico_City", "reporting_currency": "MXN" }
{ "clientCode": "F3", "client_name": "Flynas", "reporting_timezone": "Asia/Riyadh", "reporting_currency": "SAR" }
{ "clientCode": "US", "client_name": "US Airline", "reporting_timezone": "America/New_York", "reporting_currency": "USD" }
{ "clientCode": "UK", "client_name": "UK Airline", "reporting_timezone": "Europe/London", "reporting_currency": "GBP" }
{ "clientCode": "EU", "client_name": "EU Airline", "reporting_timezone": "Europe/Madrid", "reporting_currency": "EUR" }
```

### b) Subscription Events (JSONL, July excerpt)
```json
{ "eventId": "e1", "event": "SubscriptionRenewedEvent", "success": "true", "clientCode": "Y4",
  "subscriptionId": "s1", "invoiceId": "inv1", "currency": "MXN", "amount": "639.00",
  "eventDateTime": "01/Jul/2025:05:00:00 +0000", "quotaFromDate": "2025-07-01", "quotaToDate": "2025-07-31" }

{ "eventId": "e2", "event": "SubscriptionRenewedEvent", "success": "true", "clientCode": "US",
  "subscriptionId": "s2", "invoiceId": "inv2", "currency": "USD", "amount": "300.00",
  "eventDateTime": "02/Jul/2025:06:00:00 +0000", "quotaFromDate": "2025-07-01", "quotaToDate": "2025-09-30",
  "billingPeriod": "QUARTERLY" }
```

### c) FX Rates (CSV/JSONL, July excerpt)
```json
{ "date": "2025-07-31", "currency": "USD", "eur_per_unit": 0.930000 }
{ "date": "2025-07-31", "currency": "MXN", "eur_per_unit": 0.051000 }
{ "date": "2025-07-31", "currency": "GBP", "eur_per_unit": 1.170000 }
{ "date": "2025-07-31", "currency": "EUR", "eur_per_unit": 1.000000 }
```

---

## 3) Architecture Overview

```
S3 Sources: Clients JSONL / Events JSONL / FX JSONL
    ↓ (Snowflake External Tables in RAW)
STAGING Layer (dbt tables):
  - stg_clients
  - stg_fx_rates (+ stg_fx_rates_monthly)
  - stg_subscription_events
    ↓
ANALYTICS Layer (dbt views):
  - dim_client
  - fct_mrr_alloc  (fact table: normalized monthly MRR)
  - mart_customer__mrr_monthly (per-client reporting currency)
  - mart_internal__mrr_monthly_eur (internal consolidated EUR)
```

---

## 4) STAGING Layer (examples)

### `stg_clients`
| client_code | client_name | reporting_timezone  | reporting_currency |
|-------------|-------------|---------------------|--------------------|
| Y4          | Volaris     | America/Mexico_City | MXN                |
| F3          | Flynas      | Asia/Riyadh         | SAR                |
| US          | US Airline  | America/New_York    | USD                |

### `stg_fx_rates_monthly`
| fx_month   | currency | eur_per_unit |
|------------|----------|---------------|
| 2025-07-01 | USD      | 0.930000      |
| 2025-07-01 | MXN      | 0.051000      |
| 2025-07-01 | GBP      | 1.170000      |
| 2025-08-01 | MXN      | 0.048500      |
| 2025-08-01 | SAR      | 0.245000      |

### `stg_subscription_events`
| event_id | event_name               | is_success | client_code | subscription_id | currency_native | amount_native | quota_from_date | quota_to_date | billing_period_hint |
|----------|--------------------------|------------|-------------|-----------------|-----------------|---------------|-----------------|---------------|---------------------|
| e1       | SubscriptionRenewedEvent | true       | Y4          | s1              | MXN             | 639.00        | 2025-07-01      | 2025-07-31    | (null)              |
| e2       | SubscriptionRenewedEvent | true       | US          | s2              | USD             | 300.00        | 2025-07-01      | 2025-09-30    | QUARTERLY           |

---

## 5) Analytics Layer

### a) Fact Table: `fct_mrr_alloc`

Business rules applied:
- Recognition date = `quotaFromDate` → fallback to paid_from / invoice / event_ts.  
- Billing period normalized to monthly (divide quarterly by 3, annual by 12).  
- MRR converted to both **EUR** and **client reporting currency**.  
- Failed renewals excluded (`is_success = false`).  

**Sample Output (July 2025)**

| client_code | billing_period | recognition_month | currency_native | amount_native | mrr_native | mrr_eur | mrr_reporting_currency |
|-------------|----------------|------------------|-----------------|---------------|------------|---------|------------------------|
| Y4          | MONTHLY        | 2025-07-01       | MXN             | 639.00        | 639.00     | 32.59   | 639.00                 |
| US          | QUARTERLY      | 2025-07-01       | USD             | 300.00        | 100.00     | 93.00   | 100.00                 |
| UK          | ANNUAL         | 2025-07-01       | GBP             | 1000.00       | 83.33      | 97.50   | 83.33                  |
| EU          | MONTHLY        | 2025-07-01       | EUR             | 50.00         | 50.00      | 50.00   | 50.00                  |

---

### b) Customer-Facing View: `mart_customer__mrr_monthly`

| client_code | client_name | reporting_currency | recognition_month | mrr_reporting_currency |
|-------------|-------------|--------------------|------------------|------------------------|
| Y4          | Volaris     | MXN                | 2025-07-01       | 639.00                 |
| US          | US Airline  | USD                | 2025-07-01       | 100.00                 |
| UK          | UK Airline  | GBP                | 2025-07-01       | 83.33                  |
| EU          | EU Airline  | EUR                | 2025-07-01       | 50.00                  |

---

### c) Internal View: `mart_internal__mrr_monthly_eur`

| recognition_month | mrr_eur  |
|-------------------|----------|
| 2025-07-01        | 273.09   |
| 2025-08-01        | 161.13   |

---

## 6) Why This Works

- **Simple & Lean**: Uses only S3, Snowflake external tables, and dbt.  
- **Scalable**: Each layer is modular (FX can be swapped to daily if needed).  
- **Business-Ready**: Outputs exactly match what internal finance teams (EUR) and client-facing teams (local currency) need.  
- **Timezones**: Properly respected by using client reporting timezone in recognition fallback.  
- **Failed Renewals**: Excluded, but could easily power “at-risk MRR” reports.

---

## 7) Conclusion

This Part 3 solution delivers a **multi-tenant, multi-currency, multi-timezone MRR pipeline** that:  
- Ingests JSON events, FX, and client config from S3 → Snowflake RAW,  
- Normalizes them in STAGING with dbt,  
- Produces business-ready facts and reporting views in ANALYTICS.  

We successfully satisfy the requirements for:  
- **Temporal normalization** (recognition months),  
- **Currency conversion** (EUR + client reporting),  
- **Billing frequency normalization** (monthly equivalents),  
- **Clear reporting structures** (internal vs external).  

This lean design proves Caravelo’s MRR analytics gap can be solved with a simple, extensible architecture, without overengineering, while leaving room for automation (Snowpipe, EventBridge) in production.  
