/******************************************
Local variables declaration
 *****************************************/

locals {
project_id                  = "${var.project_id}"
project_nbr                 = "${var.project_number}"
admin_upn_fqn               = "${var.gcp_account_name}"
location                    = "${var.gcp_region}"
umsa                        = "cdf-lab-sa"
umsa_fqn                    = "${local.umsa}@${local.project_id}.iam.gserviceaccount.com"
vpc_nm                      = "vpc-main"
spark_subnet_nm             = "spark-snet"
spark_subnet_cidr           = "10.0.0.0/16"
composer_subnet_nm          = "composer-snet"
composer_subnet_cidr        = "10.1.0.0/16"
compute_subnet_nm           = "compute-snet"
compute_subnet_cidr         = "10.2.0.0/16"
cdf_name                    = "${var.cdf_name}"
cdf_version                 = "${var.cdf_version}"
cdf_release                 = "${var.cdf_release}"
bq_datamart_ds              = "adventureworks"
CDF_GMSA_FQN                = "serviceAccount:service-${local.project_nbr}@gcp-sa-datafusion.iam.gserviceaccount.com"
CC_GMSA_FQN                 = "service-${local.project_nbr}@cloudcomposer-accounts.iam.gserviceaccount.com"
GCE_GMSA_FQN                = "${local.project_nbr}-compute@developer.gserviceaccount.com"
cloudsql_bucket_nm          = "${local.project_id}-cloudsql-backup"
s8s_data_and_code_bucket    = "s8s_data_and_code_bucket-${local.project_nbr}"
CLOUD_COMPOSER2_IMG_VERSION = "${var.cloud_composer_image_version}"
subnet_resource_uri         = "projects/${local.project_id}/regions/${local.location}/subnetworks/${local.spark_subnet_nm}"
}

/******************************************
1. User Managed Service Account Creation
 *****************************************/
module "umsa_creation" {
  source     = "terraform-google-modules/service-accounts/google"
  version = "4.2.2"
  project_id = local.project_id
  names      = ["${local.umsa}"]
  display_name = "User Managed Service Account"
  description  = "User Managed Service Account for CDF"
}

/******************************************
2a. IAM role grants to User Managed Service Account
 *****************************************/

module "umsa_role_grants" {
  source                  = "terraform-google-modules/iam/google//modules/member_iam"
  version = "7.7.1"
  service_account_address = "${local.umsa_fqn}"
  prefix                  = "serviceAccount"
  project_id              = local.project_id
  project_roles = [    
    "roles/iam.serviceAccountUser",
    "roles/iam.serviceAccountTokenCreator",
    "roles/storage.objectViewer",
    "roles/storage.admin",
    "roles/dataproc.worker",
    "roles/dataproc.editor",
    "roles/bigquery.dataEditor",
    "roles/bigquery.admin",
    "roles/datafusion.runner",
    "roles/iam.serviceAccountUser",
    "roles/cloudsql.client",
    "roles/composer.worker",
    "roles/composer.admin"    
  ]
  depends_on = [module.umsa_creation]
}

/******************************************
2b. IAM role grants to Google Managed 
Service Account for Cloud Data Fusion
 *****************************************/

resource "google_project_iam_binding" "gmsa_role_grants_serviceagent" {
  project = local.project_id
  role    = "roles/datafusion.serviceAgent"
  members = [
    "${local.CDF_GMSA_FQN}"
  ]
}

resource "google_project_iam_binding" "gmsa_role_grants_serviceaccountuser" {
  project = local.project_id
  role    = "roles/iam.serviceAccountUser"
  members = [
    "${local.CDF_GMSA_FQN}"
  ]
}

resource "google_project_iam_binding" "gmsa_role_grants_cloudsqlclient" {
  project = local.project_id
  role    = "roles/cloudsql.client"
  members = [
    "${local.CDF_GMSA_FQN}"
  ]
}

resource "google_project_iam_binding" "gmsa_role_grants_datalineageproducer" {
  project = local.project_id
  role    = "roles/datalineage.producer"
  members = [
    "${local.CDF_GMSA_FQN}"
  ]
}

/******************************************
2c. IAM role grants to Google Managed Service Account for Cloud Composer 2
 *****************************************/

module "gmsa_role_grants_cc" {
  source                  = "terraform-google-modules/iam/google//modules/member_iam"
  version = "7.7.1"
  service_account_address = "${local.CC_GMSA_FQN}"
  prefix                  = "serviceAccount"
  project_id              = local.project_id
  project_roles = [
    
    "roles/composer.ServiceAgentV2Ext",
  ]
  depends_on = [
    module.umsa_role_grants
  ]
}

/******************************************************
3. Service Account Impersonation Grants to Admin User
 ******************************************************/

module "umsa_impersonate_privs_to_admin" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam/"
  version = "7.7.1"
  service_accounts = ["${local.umsa_fqn}"]
  project          = local.project_id
  mode             = "additive"
  bindings = {
    "roles/iam.serviceAccountUser" = [
      "user:${local.admin_upn_fqn}"
    ],
    "roles/iam.serviceAccountTokenCreator" = [
      "user:${local.admin_upn_fqn}"
    ]
  }
  depends_on = [
    module.umsa_creation
  ]
}

/******************************************************
4. IAM role grants to Admin User
 ******************************************************/

module "administrator_role_grants" {
  source   = "terraform-google-modules/iam/google//modules/projects_iam"
  version = "7.7.1"
  projects = ["${local.project_id}"]
  mode     = "additive"

  bindings = {
    "roles/storage.admin" = [
      "user:${local.admin_upn_fqn}",
    ]
    "roles/metastore.admin" = [

      "user:${local.admin_upn_fqn}",
    ]
    "roles/dataproc.admin" = [
      "user:${local.admin_upn_fqn}",
    ]
    "roles/bigquery.admin" = [
      "user:${local.admin_upn_fqn}",
    ]
    "roles/bigquery.user" = [
      "user:${local.admin_upn_fqn}",
    ]
    "roles/bigquery.dataEditor" = [
      "user:${local.admin_upn_fqn}",
    ]
    "roles/bigquery.jobUser" = [
      "user:${local.admin_upn_fqn}",
    ]
    "roles/composer.environmentAndStorageObjectViewer" = [
      "user:${local.admin_upn_fqn}",
    ]
    "roles/iam.serviceAccountUser" = [
      "user:${local.admin_upn_fqn}",
    ]
    "roles/iam.serviceAccountTokenCreator" = [
      "user:${local.admin_upn_fqn}",
    ]
    "roles/composer.admin" = [
      "user:${local.admin_upn_fqn}",
    ]
  }
  depends_on = [
    module.umsa_role_grants,
    module.umsa_impersonate_privs_to_admin
  ]

  }

/*******************************************
Introducing sleep to minimize errors from
dependencies having not completed
********************************************/
resource "time_sleep" "sleep_after_identities_permissions" {
  create_duration = "120s"
  depends_on = [
    module.umsa_creation,
    module.umsa_role_grants,
    module.umsa_impersonate_privs_to_admin,
    module.administrator_role_grants,
    google_project_iam_binding.gmsa_role_grants_serviceagent,
    google_project_iam_binding.gmsa_role_grants_serviceaccountuser,
    google_project_iam_binding.gmsa_role_grants_cloudsqlclient,
    google_project_iam_binding.gmsa_role_grants_datalineageproducer
  ]
}

/******************************************
5. VPC Network & Subnet Creation
 *****************************************/
module "vpc_creation" {
  source                                 = "terraform-google-modules/network/google"
  version                                = "9.0.0"
  project_id                             = local.project_id
  network_name                           = local.vpc_nm
  routing_mode                           = "REGIONAL"

  subnets = [
    {
      subnet_name           = "${local.spark_subnet_nm}"
      subnet_ip             = "${local.spark_subnet_cidr}"
      subnet_region         = "${local.location}"
      subnet_range          = local.spark_subnet_cidr
      subnet_private_access = true
    }
    ,
    {
      subnet_name           = "${local.composer_subnet_nm}"
      subnet_ip             = "${local.composer_subnet_cidr}"
      subnet_region         = "${local.location}"
      subnet_range          = local.composer_subnet_cidr
      subnet_private_access = true
    }    
    ,
    {
      subnet_name           = "${local.compute_subnet_nm}"
      subnet_ip             = "${local.compute_subnet_cidr}"
      subnet_region         = "${local.location}"
      subnet_range          = local.compute_subnet_cidr
      subnet_private_access = true
    }    
  ]
  depends_on = [time_sleep.sleep_after_identities_permissions]
}

/******************************************
6. Firewall rules creation
 *****************************************/

resource "google_compute_firewall" "allow_intra_snet_ingress_to_any" {
  project   = local.project_id 
  name      = "allow-intra-snet-ingress-to-any"
  network   = local.vpc_nm
  direction = "INGRESS"
  source_ranges = [local.spark_subnet_cidr]
  allow {
    protocol = "all"
  }
  description        = "Creates firewall rule to allow ingress from within Spark subnet on all ports, all protocols"
  depends_on = [module.vpc_creation]
}

/******************************************
7. Private IP allocation for Data Fusion
 *****************************************/

resource "google_compute_global_address" "private_ip_alloc" {
  name          = "datafusion-ip-alloc"
  project       = local.project_id 
  address_type  = "INTERNAL"
  purpose       = "VPC_PEERING"
  prefix_length = 22
  network       = module.vpc_creation.network_id
  depends_on = [module.vpc_creation]
}

/*******************************************
Introducing sleep to minimize errors from
dependencies having not completed
********************************************/
resource "time_sleep" "sleep_after_network_and_firewall_creation" {
  create_duration = "120s"
  depends_on = [
    module.vpc_creation,
    google_compute_firewall.allow_intra_snet_ingress_to_any,
    google_compute_global_address.private_ip_alloc
  ]
}

/******************************************
8a. Data Fusion instance creation
 *****************************************/

resource "google_data_fusion_instance" "create_instance" {
  name                          = local.cdf_name
  region                        = local.location
  type                          = local.cdf_version
  enable_stackdriver_logging    = true
  enable_stackdriver_monitoring = true
  private_instance              = true
  network_config {
    network                     = local.vpc_nm
    ip_allocation               = "${google_compute_global_address.private_ip_alloc.address}/22"
  }    
  version                       = local.cdf_release
  dataproc_service_account      = local.umsa_fqn
  project                       = var.project_id
  depends_on = [time_sleep.sleep_after_network_and_firewall_creation]
}

/******************************************
8b. Create a peering connection between Data Fusion tenant VPC and Dataproc VPC
 *****************************************/

resource "google_compute_network_peering" "cdf-peering" {
  name         = "cdf-peering"
  network      = module.vpc_creation.network_self_link
  peer_network = "https://www.googleapis.com/compute/v1/projects/${google_data_fusion_instance.create_instance.tenant_project_id}/global/networks/${local.location}-${local.cdf_name}"
  depends_on = [google_data_fusion_instance.create_instance]
}

/******************************************
9. BigQuery dataset creation
******************************************/

resource "google_bigquery_dataset" "bq_dataset_creation" {
  dataset_id                  = local.bq_datamart_ds
  location                    = "US"
  project                     = local.project_id  
}

/******************************************
10. Cloud SQL instance creation
******************************************/

module "sql-db_private_service_access" {
  source        = "terraform-google-modules/sql-db/google//modules/private_service_access"
  version = "19.0.0"
  project_id    = local.project_id
  vpc_network   = local.vpc_nm
  depends_on = [ 
        time_sleep.sleep_after_network_and_firewall_creation
   ]  
}

module "sql-db_mssql" {
  source            = "terraform-google-modules/sql-db/google//modules/mssql"
  name              = local.project_id
  project_id        = local.project_id
  region            = local.location  
  availability_type = "ZONAL"
  database_version  = "SQLSERVER_2022_STANDARD"
  disk_size         = 100
  root_password     = "P@ssword@111"
  ip_configuration  = {
    "allocated_ip_range": null,
    "authorized_networks": [],
    "ipv4_enabled": true,
    "private_network": module.vpc_creation.network_id,
    "require_ssl": true
    }
  depends_on = [module.sql-db_private_service_access]
}

#Storage bucket for SQL Server backup file
resource "google_storage_bucket" "cloudsql_bucket_creation" {
  project                           = local.project_id 
  name                              = local.cloudsql_bucket_nm
  location                          = local.location
  uniform_bucket_level_access       = true
  force_destroy                     = true
  depends_on = [module.sql-db_private_service_access]
}

#Grant Cloud SQL service account access to import backup from cloud storage
resource "google_storage_bucket_iam_member" "member" {
  bucket = google_storage_bucket.cloudsql_bucket_creation.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.sql-db_mssql.instance_service_account_email_address}"
  depends_on = [module.sql-db_mssql]
}

/******************************************
11. Enable private CDF to access private Cloud SQL
******************************************/

#Create firewall rule to CDF ingress traffic
resource "google_compute_firewall" "allow_private_cdf" {
  project   = local.project_id 
  name      = "allow-private-cdf"
  network   = local.vpc_nm
  direction = "INGRESS"
  source_ranges = ["${google_compute_global_address.private_ip_alloc.address}/22"]
  allow {
    protocol = "tcp"
    ports    = ["22", "1433"] 
  }
  description        = "Creates firewall rule to allow ingress from private CDF from port 22 and 1433 (SQL Server)"
  depends_on = [
    google_compute_global_address.private_ip_alloc,
    google_data_fusion_instance.create_instance
  ]
}

#Create static internal IP for VM
module "sql_proxy_address" {
  source     = "terraform-google-modules/address/google"
  version    = "~> 3.1"
  project_id = local.project_id
  region     = local.location
  subnetwork = local.compute_subnet_nm
  names      = ["sql-proxy-ip"]
  depends_on = [
    module.vpc_creation,
    google_data_fusion_instance.create_instance
  ]
}

#Create SQL proxy VM
resource "google_compute_instance" "sql-proxy" {
  name         = "sql-proxy"
  project      = local.project_id 
  machine_type = "g1-small"
  zone         = "us-central1-a"
  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable-109-17800-66-27"
    }
  }
  network_interface {
    subnetwork = local.compute_subnet_nm    
    subnetwork_project = local.project_id
    network_ip = tolist(module.sql_proxy_address.addresses)[0] 
    access_config {}
  }
  service_account {
    email  = local.umsa_fqn
    scopes = ["cloud-platform"]
  }
  scheduling {
    on_host_maintenance = "MIGRATE"
  }
  metadata = {
    startup-script = "docker run -d -p 0.0.0.0:1433:1433 gcr.io/cloudsql-docker/gce-proxy:latest /cloud_sql_proxy -instances=${local.project_id}:${local.location}:${local.project_id}=tcp:0.0.0.0:1433"
  }
  depends_on = [module.sql_proxy_address]
}

#Output static IP for JDBC connection
output "sql_proxy_ip" {
  value = tolist(module.sql_proxy_address.addresses)[0]
}

/******************************************
11. Spark Code Bucket Creation
******************************************/

resource "google_storage_bucket" "s8s_data_and_code_bucket_creation" {
  name                              = local.s8s_data_and_code_bucket
  project                           = local.project_id 
  location                          = local.location
  uniform_bucket_level_access       = true
  force_destroy                     = true
  depends_on = [ time_sleep.sleep_after_network_and_firewall_creation ]
}

resource "google_storage_bucket_object" "pyspark_scripts_upload_to_gcs" {
  for_each = fileset("../scripts/pyspark/", "*")
  source = "../scripts/pyspark/${each.value}"
  name = "scripts/pyspark/${each.value}"
  bucket = "${local.s8s_data_and_code_bucket}"
  depends_on = [ google_storage_bucket.s8s_data_and_code_bucket_creation ]
}

resource "google_storage_bucket_object" "pyspark_jars_upload_to_gcs" {
  for_each = fileset("../drivers/", "*")
  source = "../drivers/${each.value}"
  name = "drivers/${each.value}"
  bucket = "${local.s8s_data_and_code_bucket}"
  depends_on = [ google_storage_bucket.s8s_data_and_code_bucket_creation ]
}

/******************************************
12. Cloud Composer 2 creation
******************************************/

resource "google_composer_environment" "cloud_composer_env_creation" {
  name   = "${local.project_id}-cc2"
  project = local.project_id
  region = local.location
  provider = google-beta
  config {

    software_config {
      image_version = local.CLOUD_COMPOSER2_IMG_VERSION 
      env_variables = {
        
        AIRFLOW_VAR_PROJECT_ID = "${local.project_id}"
        AIRFLOW_VAR_PROJECT_NBR = "${local.project_nbr}"        
        AIRFLOW_VAR_REGION = "${local.location}"
        AIRFLOW_VAR_CODE_BUCKET = "${local.s8s_data_and_code_bucket}"
        AIRFLOW_VAR_BQ_DATASET = "${local.bq_datamart_ds}"
        AIRFLOW_VAR_METASTORE_DB = "${local.bq_datamart_ds}"
        AIRFLOW_VAR_SUBNET_URI = "${local.subnet_resource_uri}"
        AIRFLOW_VAR_UMSA = "${local.umsa}"
      }
    }

    node_config {
      network    = local.vpc_nm
      subnetwork = local.spark_subnet_nm
      service_account = local.umsa_fqn
    }
  }

  depends_on = [time_sleep.sleep_after_network_and_firewall_creation] 

  timeouts {
    create = "75m"
  } 
}

/*******************************************
Introducing sleep to minimize errors from
dependencies having not completed
********************************************/
resource "time_sleep" "sleep_after_composer_creation" {
  create_duration = "300s"
  depends_on = [
      google_composer_environment.cloud_composer_env_creation
  ]
}

/******************************************
13. Cloud Composer 2 DAG bucket capture so we can upload DAG to it
******************************************/

output "CLOUD_COMPOSER_DAG_BUCKET" {
  value = google_composer_environment.cloud_composer_env_creation.config.0.dag_gcs_prefix
}

/*******************************************
14. Upload Airflow DAG to Composer DAG bucket
******************************************/
# Remove the gs:// prefix and /dags suffix

resource "google_storage_bucket_object" "airflow_dag_upload_to_cc2_dag_bucket" {
  for_each = fileset("../scripts/composer-dag/", "*")
  source = "../scripts/composer-dag/${each.value}"
  name = "dags/${each.value}"
  bucket = substr(substr(google_composer_environment.cloud_composer_env_creation.config.0.dag_gcs_prefix, 5, length(google_composer_environment.cloud_composer_env_creation.config.0.dag_gcs_prefix)), 0, (length(google_composer_environment.cloud_composer_env_creation.config.0.dag_gcs_prefix)-10))
  depends_on = [
    time_sleep.sleep_after_composer_creation
  ]
}

/******************************************
DONE
******************************************/