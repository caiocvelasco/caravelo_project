# Access Control Setup for AWS ↔️ Snowflake Storage Integration (Caravelo Project)

This document explains how to configure **IAM Users, Groups, Roles, and Policies** in AWS, and connect them securely with **Snowflake Storage Integrations**.  
This ensures that Snowflake and your ingestion jobs can read/write files in your S3 bucket (`caravelo-data-source`) while following least-privilege principles.

---

## Step 0: Prerequisites

- AWS Account with an existing S3 bucket (`caravelo-data-source`)  
- Snowflake account with privileges to create integrations  
- A dedicated Snowflake ingestion user (e.g., `CaraveloProjectUser`)  
- Access to AWS Console → IAM  
- Your Snowflake **Account ID** and later the **External ID** (via `DESC INTEGRATION`)  

---

## Step 1: Create IAM Policy with S3 Bucket Access

Create a policy named `caravelo-s3-policy`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowListBucket",
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::caravelo-data-source"
    },
    {
      "Sid": "AllowObjectAccess",
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::caravelo-data-source/*"
    }
  ]
}
```
This policy allows listing the bucket and full read/write/delete access to all objects inside.

## Step 2: Create IAM Group and User for Ingestion

1. **Group**:  
   - Name: `CaraveloProjectGroup`  
   - Attach the `caravelo-s3-policy` policy  

2. **User**:  
   - Name: `CaraveloProjectUser`  
   - Access type: **Programmatic access** only (no console)  
   - Add user to the group `CaraveloProjectGroup`  

3. **Access Keys**:  
   - Generate and save the `AccessKeyId` and `SecretAccessKey` (used in `.env`)  

At this point:  
- `CaraveloProjectUser` can read/write/delete objects in `caravelo-data-source`.  
- Use this user for **ETL jobs, local ingestion scripts, or Meltano**.  

Example `.env`:  

```env
S3_REGION=eu-north-1
S3_BUCKET_NAME=caravelo-data-source
S3_ACCESS_KEY_ID=...
S3_SECRET_ACCESS_KEY=...
```

## Step 3: Create IAM Policy for Snowflake Storage Integration

Snowflake requires its own **IAM Role** (not the ingestion user) to assume.  
You can reuse the same permissions, or create a separate policy. Let's use the same one `caravelo-s3-policy`.

## Step 4: Create IAM Role for Snowflake

1. Go to **IAM → Roles → Create role**  
2. Choose **Another AWS Account**  
3. Enter the **Snowflake AWS Account ID** (from `DESC INTEGRATION`)  
4. Require external ID → paste the `STORAGE_AWS_EXTERNAL_ID` from Snowflake  
5. Name the role: `CaraveloSnowflakeRole`  
6. Attach the policy `caravelo-s3-policy`  

At this point:  
- The role can be assumed by Snowflake using the external ID.  
- It has full access to the `caravelo-data-source` bucket.  

Example ARN for reference:

```json
arn:aws:iam::<ACCOUNT_ID>:role/CaraveloSnowflakeRole
```

## Step 5: Update Trust Policy for Snowflake Role

Replace the trust policy of the role with the following JSON (adjust placeholders to your Snowflake values):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::694318440714:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "IW52833_SFCRole=2_QCZ9fyLR4h0ACvQH2Si9Q335t7Y="
        }
      }
    }
  ]
}
```

- Replace `694318440714` with Snowflake’s AWS Account ID (from `DESC INTEGRATION`)

- Replace the sts:ExternalId with your Snowflake integration’s external ID

## Final Setup Summary

- **Ingestion User** (CaraveloProjectUser): programmatic keys for ETL pipelines → stored in .env
- **Group** (CaraveloProjectGroup): attaches the caravelo-s3-policy policy
- **Snowflake Role** (CaraveloSnowflakeRole): trust policy with Snowflake’s AWS account + external ID
- **Shared S3 Policy**: grants access to caravelo-data-source bucket