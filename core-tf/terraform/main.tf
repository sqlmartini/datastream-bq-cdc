#############################################################################################################################################################
# About
# In this script, we will -
# 1. Create user managed service account (UMSA)
# 2. Apply role grants to UMSA
# 3. Service account impersonation for admin user
# 4. IAM role grants to admin user
# 5. Create VPC network and subnets
# 6. Create BigQuery datasets
# 7. Create Cloud SQL instance
# 8. Import database backup to Cloud SQL
# 9. Create Datastream profiles and streams
#############################################################################################################################################################

/******************************************
Local variables declaration
 *****************************************/

locals {
project_id                  = "${var.project_id}"
project_nbr                 = "${var.project_number}"
admin_upn_fqn               = "${var.gcp_account_name}"
location                    = "${var.gcp_region}"
umsa                        = "analytics-lab-sa"
umsa_fqn                    = "${local.umsa}@${local.project_id}.iam.gserviceaccount.com"
vpc_nm                      = "vpc-main"
spark_subnet_nm             = "spark-snet"
spark_subnet_cidr           = "10.0.0.0/16"
composer_subnet_nm          = "composer-snet"
composer_subnet_cidr        = "10.1.0.0/16"
compute_subnet_nm           = "compute-snet"
compute_subnet_cidr         = "10.2.0.0/16"
bq_dataset_bronze           = "adventureworks_bronze"
bq_dataset_silver           = "adventureworks_silver"
bq_dataset_gold             = "adventureworks_gold"
cloudsql_bucket_nm          = "${local.project_id}-cloudsql-backup"
}

/******************************************
1. User Managed Service Account Creation
 *****************************************/
module "umsa_creation" {
  source     = "terraform-google-modules/service-accounts/google"
  project_id = local.project_id
  names      = ["${local.umsa}"]
  display_name = "User Managed Service Account"
  description  = "User Managed Service Account for lab"
}

/******************************************
2. IAM role grants to User Managed Service Account
 *****************************************/

module "umsa_role_grants" {
  source                  = "terraform-google-modules/iam/google//modules/member_iam"
  service_account_address = "${local.umsa_fqn}"
  prefix                  = "serviceAccount"
  project_id              = local.project_id
  project_roles = [    
    "roles/iam.serviceAccountUser",
    "roles/iam.serviceAccountTokenCreator",
    "roles/storage.objectViewer",
    "roles/storage.admin",
    "roles/bigquery.dataEditor",
    "roles/bigquery.admin",
    "roles/cloudsql.client",
  ]
  depends_on = [module.umsa_creation]
}

/******************************************************
3. Service Account Impersonation Grants to Admin User
 ******************************************************/

module "umsa_impersonate_privs_to_admin" {
  source  = "terraform-google-modules/iam/google//modules/service_accounts_iam/"
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
  projects = ["${local.project_id}"]
  mode     = "additive"

  bindings = {
    "roles/storage.admin" = [
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
    "roles/iam.serviceAccountUser" = [
      "user:${local.admin_upn_fqn}",
    ]
    "roles/iam.serviceAccountTokenCreator" = [
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
  create_duration = "60s"
  depends_on = [
    module.umsa_creation,
    module.umsa_role_grants,
    module.umsa_impersonate_privs_to_admin,
    module.administrator_role_grants,
  ]
}

/******************************************
5. VPC Network & Subnet Creation
 *****************************************/
module "vpc_creation" {
  source                                 = "terraform-google-modules/network/google"
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
6. BigQuery dataset creation
******************************************/

resource "google_bigquery_dataset" "bq_dataset_bronze_creation" {
  dataset_id                  = local.bq_dataset_bronze
  location                    = "us-central1"
  project                     = local.project_id  
}

resource "google_bigquery_dataset" "bq_dataset_silver_creation" {
  dataset_id                  = local.bq_dataset_silver
  location                    = "us-central1"
  project                     = local.project_id  
}

resource "google_bigquery_dataset" "bq_dataset_gold_creation" {
  dataset_id                  = local.bq_dataset_gold
  location                    = "us-central1"
  project                     = local.project_id  
}

/******************************************
7. Cloud SQL instance creation
******************************************/

module "sql-db_private_service_access" {
  source        = "terraform-google-modules/sql-db/google//modules/private_service_access"
  project_id    = local.project_id
  vpc_network   = local.vpc_nm
  depends_on = [ 
        module.vpc_creation
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
  additional_users  = [{name = "datastream", password = "P@ssword@111", random_password = false}]
  ip_configuration  = {
    "allocated_ip_range": null,
    "authorized_networks": [{ value = "34.71.242.81" },{ value = "34.72.28.29" },{ value = "34.67.6.157" },{ value = "34.67.234.134" },{ value = "34.72.239.218" }],
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
  depends_on = [module.sql-db_mssql.instance]
}

/******************************************
8. Import database to Cloud SQL
******************************************/

resource "null_resource" "import_database" {
 provisioner "local-exec" {
    command = "/bin/bash ../scripts/2-cloudsql.sh"
  }
 depends_on = [module.sql-db_mssql.instance]  
}

resource "time_sleep" "sleep_after_import_database" {
  create_duration = "60s"
  depends_on = [null_resource.import_database]
}

/******************************************
9. Datastream
******************************************/
resource "google_datastream_connection_profile" "source" {
    display_name          = "SQL Server Source"
    project               = local.project_id    
    location              = "us-central1"
    connection_profile_id = "source-profile"

    sql_server_profile {
        hostname = module.sql-db_mssql.instance_first_ip_address
        port     = 1433
        username = "sqlserver"
        password = "P@ssword@111"
        database = "AdventureWorks2022"
    }
    depends_on = [time_sleep.sleep_after_import_database]  
}

resource "google_datastream_connection_profile" "destination" {
    display_name          = "BigQuery Destination"
    project               = local.project_id    
    location              = "us-central1"
    connection_profile_id = "destination-profile"

    bigquery_profile {}
    depends_on = [time_sleep.sleep_after_import_database]
}

resource "google_datastream_stream" "cdc_stream" {
    display_name = "cdc-stream"
    project      = local.project_id    
    location     = "us-central1"
    stream_id    = "cdc-stream"
    desired_state = "RUNNING"

    source_config {
        source_connection_profile = google_datastream_connection_profile.source.id
        sql_server_source_config {
            include_objects {
                schemas {
                    schema = "Production"
                    tables {table = "Product"} 
                    tables {table = "ProductCategory"}
                    tables {table = "ProductSubcategory"}
                  }
              }
            change_tables {}            
          }
      }

    destination_config {
        destination_connection_profile = google_datastream_connection_profile.destination.id
        bigquery_destination_config {
            data_freshness = "900s"
            merge {}
            single_target_dataset {dataset_id = "${local.project_id}:adventureworks_bronze"}
            }
      }
    backfill_all{}
    depends_on = [
        google_datastream_connection_profile.source, 
        google_datastream_connection_profile.destination
      ]
}

resource "google_datastream_stream" "append_stream" {
    display_name = "append-stream"
    project      = local.project_id    
    location     = "us-central1"
    stream_id    = "append-stream"
    desired_state = "RUNNING"

    source_config {
        source_connection_profile = google_datastream_connection_profile.source.id
        sql_server_source_config {
            include_objects {
                schemas {
                    schema = "Sales"
                    tables {table = "SalesOrderDetail"} 
                    tables {table = "SalesOrderHeader"}
                    tables {table = "Customer"}
                  }
                schemas {
                    schema = "Person"
                    tables {table = "Person"} 
                  }                  
              }
            change_tables {}            
          }
      }

    destination_config {
        destination_connection_profile = google_datastream_connection_profile.destination.id
        bigquery_destination_config {
            data_freshness = "900s"
            merge {}
            single_target_dataset {dataset_id = "${local.project_id}:adventureworks_bronze"}
            }
      }
    backfill_all{}
    depends_on = [
        google_datastream_connection_profile.source, 
        google_datastream_connection_profile.destination
      ]
}

/******************************************
DONE
******************************************/