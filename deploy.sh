#Configuration
export LOCAL_ROOT=$PWD
export PROJECT_ID=$1
export GCP_REGION=$2

#Install Terraform
cd $LOCAL_ROOT/core-tf/scripts
source 0-installTerraform.sh

#Set project
cd $LOCAL_ROOT/core-tf/scripts
source 1-config.sh

#Run Terraform for organization policy edits and enabling Google APIs
cd $LOCAL_ROOT/foundations-tf
terraform init
terraform apply \
  -var="project_id=${PROJECT_ID}" \
  -auto-approve

#Set Terraform variables
cd $LOCAL_ROOT/core-tf/terraform
PROJECT_NBR=`gcloud projects describe $PROJECT_ID | grep projectNumber | cut -d':' -f2 |  tr -d "'" | xargs`
GCP_ACCOUNT_NAME=`gcloud auth list --filter=status:ACTIVE --format="value(account)"`

#Run the Terraform for provisioning the rest of the environment
terraform init
terraform apply \
  -var="project_id=${PROJECT_ID}" \
  -var="project_number=${PROJECT_NBR}" \
  -var="gcp_account_name=${GCP_ACCOUNT_NAME}" \
  -var="gcp_region=${GCP_REGION}" \
  -auto-approve