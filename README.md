# Change Data Capture (CDC) with Datastream

## About the lab

This repo demonstrates using the Datastream service to perform CDC on a source Cloud SQL- SQL Server database to a BigQuery destination.

### Prerequisites

- A pre-created project
- You need to have organization admin rights, and project owner privileges or work with privileged users to complete provisioning

## 1. Clone this repo in Cloud Shell

```
cd ~
mkdir repos
cd repos
git clone https://github.com/sqlmartini/datastream-bq-cdc.git
cd datastream-bq-cdc
```

## 2. Deploy environment
The bash script uses Terraform to update organization policies, enables Google APIs, and deploy the appropriate GCP resources.<br>

```
bash deploy.sh <gcp_project_id_here> <gcp_region_here>

example usage:
bash deploy.sh amm-datastream-cdc us-central1
```