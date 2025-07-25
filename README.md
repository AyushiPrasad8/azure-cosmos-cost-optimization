# Azure Cosmos DB Billing Records Cost Optimization

This project implements a cost-effective archival solution for billing records in a serverless Azure architecture using Python, Azure Functions, and Terraform.

## 🔧 Problem

- Azure Cosmos DB costs are increasing due to data growth (2M+ records, ~300KB each).
- Records older than 3 months are rarely accessed but must be available on demand.
- APIs must remain unchanged, with no downtime or data loss.

## ✅ Solution Overview

1. **Cold Data Archival**:
   - Automatically move records older than 3 months from Cosmos DB to Azure Blob Storage (cold tier).
   - Archive format: GZIP-compressed JSON.

2. **On-Demand Lazy Loading**:
   - When an old record is requested, check Cosmos DB.
   - If not found, retrieve from Blob Storage, cache back to Cosmos for 24h.

3. **Seamless API Experience**:
   - A middleware layer in Azure Function maintains transparent access.
   - No changes to external API contracts.

4. **Infra-as-Code**:
   - Terraform templates to provision storage, functions, and schedules.

# System Architecture

## Components

- **Azure Cosmos DB**: Stores active billing records (<3 months old).
- **Azure Blob Storage (Cold Tier)**: Stores archived JSON records (>3 months old).
- **Azure Function (Python)**: 
  - Triggered daily to archive old records.
  - On-demand function for lazy retrieval.
- **Timer Trigger**: Initiates archival job nightly.

## Workflow

1. **Archival Pipeline** (Daily):
   - Azure Function queries Cosmos DB for records older than 90 days.
   - Exports and compresses them.
   - Uploads to Blob Storage.
   - Deletes from Cosmos DB.

2. **On-Demand Access**:
   - Read API checks Cosmos DB.
   - If not found, fetch from Blob, decompress, insert back into Cosmos, return result.

3. **Write API**: Unchanged; still writes to Cosmos DB only.

## 💸 Cost Benefits

- Blob Storage is 20x cheaper than Cosmos DB for infrequently accessed data.
- Reduced RU consumption and total item size in Cosmos DB.

## Cost Savings Summary

| Component           | Before (Monthly) | After (Monthly) | Savings |
|--------------------|------------------|------------------|---------|
| Cosmos DB Storage  | $600             | $120             | ~80%    |
| Blob Storage       | N/A              | $15              | Minimal |
| Azure Function     | N/A              | ~$2              | Minimal |
| **Total**          | $600             | ~$137            | **~77%** |

Additional benefits:
- Lower RU/s requirement due to smaller active dataset.
- Faster queries on Cosmos DB.


##Summary of Flow
1. API Call → Cosmos DB → Returns result if < 3 months.

2. If not found → Calls Cold Fetch Function.

3. Cold Fetch Function → Retrieves from Blob → Returns → Restores to Cosmos DB.

4. Timer-Triggered Function runs nightly:

   - Selects records older than 90 days from Cosmos DB.

   - Compresses and uploads to Blob Storage.

   - Deletes them from Cosmos DB.

## 🚀 Deployment Steps

1. Clone the repo:
   ```bash
   git clone https://github.com/your-org/azure-billing-cost-optimization.git
   cd azure-billing-cost-optimization

2. Provision Infrastructure:
   ```bash
   cd terraform
   terraform init
   terraform apply

3. Deploy Archive Function:
   ```bash
   az functionapp deployment source config-zip \
  --resource-group your-rg \
  --name archiveFunctionApp \
  --src ../src/archive_trigger_function.zip


