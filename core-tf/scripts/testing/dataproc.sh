PROJECT_ID="amm-dataproc-testing-434813"
REGION="us-central1"
JOB_CLUSTER_NAME="amm-elt-dev"
SUBNET="spark-snet"
SERVICE_ACCOUNT="cdf-lab-sa@$PROJECT_ID.iam.gserviceaccount.com"

gcloud dataproc clusters create $JOB_CLUSTER_NAME \
--service-account $SERVICE_ACCOUNT \
--project $PROJECT_ID \
--region $REGION \
--subnet $SUBNET \
--image-version 2.1 \
--master-machine-type n4-standard-2 \
--master-boot-disk-type hyperdisk-balanced \
--master-boot-disk-size 500 \
--num-workers 2 \
--worker-machine-type n4-standard-2 \
--worker-boot-disk-size 500 \
--worker-boot-disk-type hyperdisk-balanced