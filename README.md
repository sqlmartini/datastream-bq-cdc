# Ingest data with Cloud Data Fusion from Cloud SQL and load to BigQuery

## About the lab

This repo demonstrates the configuration of a data ingestion process that connects a private Cloud Data Fusion instance to a private Cloud SQL instance.

### Prerequisites

- A pre-created project
- You need to have organization admin rights, and project owner privileges or work with privileged users to complete provisioning.

## 1. Clone this repo in Cloud Shell

```
cd ~
mkdir repos
cd repos
<<<<<<< HEAD
git clone https://github.com/sqlmartini/gcp-analytic-demo.git
=======
git clone https://github.com/sqlmartini/gcp_analytics_demo.git
>>>>>>> 1d0d0f0a44d6e3a50e35cac0a585003c81c8b2d0
```

## 2. Foundational provisioning automation with Terraform 
The Terraform in this section updates organization policies and enables Google APIs.<br>

1. Configure project you want to deploy to by running the following in Cloud Shell

```
export LOCAL_ROOT=~/repos/cdf-private/core-tf
export PROJECT_ID="enter your project id here"
cd ~/repos/$LOCAL_ROOT/core-tf/scripts
source 1-config.sh
```

2. Run Terraform for organization policy edits and enabling Google APIs

```
cd ~/repos/$LOCAL_ROOT/foundations-tf
terraform init
terraform apply \
  -var="project_id=${PROJECT_ID}" \
  -auto-approve
```

**Note:** Wait till the provisioning completes (~5 minutes) before moving to the next section.

## 3. Core resource provisioning automation with Terraform 

### 3.1. Resources provisioned
In this section, we will provision:
1. User Managed Service Account and role grants
2. Network, subnets, firewall rules
5. BigQuery dataset
6. Cloud SQL instance
7. GCE SQL proxy VM with static private IP

### 3.2. Run the terraform scripts

1. Paste this in Cloud Shell after editing the GCP region variable to match your nearest region-

```
cd ~/repos/$LOCAL_ROOT/core-tf/terraform
PROJECT_NBR=`gcloud projects describe $PROJECT_ID | grep projectNumber | cut -d':' -f2 |  tr -d "'" | xargs`
GCP_ACCOUNT_NAME=`gcloud auth list --filter=status:ACTIVE --format="value(account)"`
GCP_REGION="us-central1"
```

2. Run the Terraform for provisioning the rest of the environment

```
terraform init
terraform apply \
  -var="project_id=${PROJECT_ID}" \
  -var="project_number=${PROJECT_NBR}" \
  -var="gcp_account_name=${GCP_ACCOUNT_NAME}" \
  -var="gcp_region=${GCP_REGION}" \
  -auto-approve
```

**Note:** Takes ~20 minutes to complete.

## 4. Download and import Cloud SQL- SQL Server sample database

### 4.1 Download AdventureWorks sample database

```
mkdir ~/repos/cdf-private/core-tf/database
cd ~/repos/cdf-private/core-tf/database
curl -LJO https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2022.bak
```

### 4.2 Import sample database to Cloud SQL 

```
cd ~/repos/$LOCAL_ROOT/core-tf/scripts
source 2-cloudsql.sh
```

# datastream-bq-cdc
