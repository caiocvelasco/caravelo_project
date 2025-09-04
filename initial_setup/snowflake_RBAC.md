# Snowflake RBAC Setup for Caravelo Ingestion & Analytics

This document focuses on **Role-Based Access Control (RBAC)** in Snowflake for Caravelo, where raw data is ingested from S3 and exposed to analysts.  
It shows how to create roles, grant privileges, and assign them to users in a clear, didactic way.

---

## Step 0: Context

- Database: `CARAVELO_DB`
- Schemas:
  - `RAW` – raw/external data (ingestion layer)
  - `STAGING` – dbt staging models
  - `ANALYTICS` – final/curated models
- Users:
  - `DBT_USER` → ingestion & transformation
  - `ANALYST_USER` → read-only analytics

---

## Step 1: Create Roles

```sql
-- Role for ingestion & transformation (dbt, external tables, file formats)
CREATE ROLE IF NOT EXISTS INGEST_TRANSFORM_ROLE;

-- Role for analysts (read-only access)
CREATE ROLE IF NOT EXISTS ANALYST_ROLE;
```

## Step 2: Grant Privileges

### 2.1 Database Usage
```sql
-- Allow roles to access the database
GRANT USAGE ON DATABASE CARAVELO_DB TO ROLE INGEST_TRANSFORM_ROLE;
GRANT USAGE ON DATABASE CARAVELO_DB TO ROLE ANALYST_ROLE;
```

### 2.2 Schema Usage & Object Creation
```sql
-- INGEST_TRANSFORM_ROLE: full control over schemas
GRANT USAGE ON SCHEMA CARAVELO_DB.RAW TO ROLE INGEST_TRANSFORM_ROLE;
GRANT USAGE ON SCHEMA CARAVELO_DB.STAGING TO ROLE INGEST_TRANSFORM_ROLE;
GRANT USAGE ON SCHEMA CARAVELO_DB.ANALYTICS TO ROLE INGEST_TRANSFORM_ROLE;

-- RAW schema: create tables, stages, file formats
GRANT CREATE TABLE, CREATE STAGE, CREATE FILE FORMAT
  ON SCHEMA CARAVELO_DB.RAW TO ROLE INGEST_TRANSFORM_ROLE;

-- STAGING schema: create tables & views
GRANT CREATE TABLE, CREATE VIEW
  ON SCHEMA CARAVELO_DB.STAGING TO ROLE INGEST_TRANSFORM_ROLE;

-- ANALYTICS schema: create tables & views
GRANT CREATE TABLE, CREATE VIEW
  ON SCHEMA CARAVELO_DB.ANALYTICS TO ROLE INGEST_TRANSFORM_ROLE;

-- Account-level privilege for ingestion role
GRANT CREATE INTEGRATION ON ACCOUNT TO ROLE INGEST_TRANSFORM_ROLE;
```
### 2.3 Analyst Read-Only Access
```sql
-- Analyst can use schemas
GRANT USAGE ON SCHEMA CARAVELO_DB.STAGING TO ROLE ANALYST_ROLE;
GRANT USAGE ON SCHEMA CARAVELO_DB.ANALYTICS TO ROLE ANALYST_ROLE;

-- Analyst can query all existing tables
GRANT SELECT ON ALL TABLES IN SCHEMA CARAVELO_DB.STAGING TO ROLE ANALYST_ROLE;
GRANT SELECT ON ALL TABLES IN SCHEMA CARAVELO_DB.ANALYTICS TO ROLE ANALYST_ROLE;

```
### 2.4 Future-Proof Grants
```sql
-- Ensure roles can access future objects
GRANT SELECT ON FUTURE TABLES IN SCHEMA CARAVELO_DB.RAW TO ROLE INGEST_TRANSFORM_ROLE;
GRANT SELECT ON FUTURE TABLES IN SCHEMA CARAVELO_DB.STAGING TO ROLE INGEST_TRANSFORM_ROLE;
GRANT SELECT ON FUTURE TABLES IN SCHEMA CARAVELO_DB.ANALYTICS TO ROLE INGEST_TRANSFORM_ROLE;

GRANT SELECT ON FUTURE TABLES IN SCHEMA CARAVELO_DB.STAGING TO ROLE ANALYST_ROLE;
GRANT SELECT ON FUTURE TABLES IN SCHEMA CARAVELO_DB.ANALYTICS TO ROLE ANALYST_ROLE;

```

### Step 3: Assign Roles to Users
```sql
-- Assign ingestion role to dbt user
GRANT ROLE INGEST_TRANSFORM_ROLE TO USER DBT_USER;

-- Assign read-only role to analyst user
GRANT ROLE ANALYST_ROLE TO USER ANALYST_USER;
```

## Summary of RBAC Structure
| Role                   | Schemas / Objects                   | Privileges / Permissions                                                |
|------------------------|------------------------------------|------------------------------------------------------------------------|
| INGEST_TRANSFORM_ROLE  | RAW                                | USAGE, CREATE TABLE, CREATE STAGE, CREATE FILE FORMAT, SELECT on future tables |
|                        | STAGING                             | USAGE, CREATE TABLE, CREATE VIEW, SELECT on future tables               |
|                        | ANALYTICS                           | USAGE, CREATE TABLE, CREATE VIEW, SELECT on future tables               |
|                        | Account-level                       | CREATE INTEGRATION                                                      |
| ANALYST_ROLE           | STAGING                             | USAGE, SELECT on all current and future tables                           |
|                        | ANALYTICS                           | USAGE, SELECT on all current and future tables                           |
| SYSADMIN / ACCOUNTADMIN| All                                 | Full control                                                            |
