export LOCAL_ROOT="datastream-bq-cdc"

cd ~/repos/$LOCAL_ROOT/foundations-tf/
rm -r .terraform
rm .terraform.lock.hcl
rm terraform.tfstate

cd ~/repos/$LOCAL_ROOT/core-tf/
rm -r .terraform
rm .terraform.lock.hcl
rm terraform.tfstate