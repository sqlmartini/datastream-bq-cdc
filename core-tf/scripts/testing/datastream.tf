resource "google_sql_database_instance" "instance" {
    name                = local.project_id
    project             = local.project_id
    database_version    = "SQLSERVER_2022_STANDARD"
    region              = local.location
    root_password       = "P@ssword@111"
    settings {
        tier = "db-custom-2-4096"
        ip_configuration {
            // Datastream IPs will vary by region.
            // https://cloud.google.com/datastream/docs/ip-allowlists-and-regions
            authorized_networks {
                value = "34.71.242.81"
            }

            authorized_networks {
                value = "34.72.28.29"
            }

            authorized_networks {
                value = "34.67.6.157"
            }

            authorized_networks {
                value = "34.67.234.134"
            }

            authorized_networks {
                value = "34.72.239.218"
            }
        }
    }
}

resource "google_sql_database" "db" {
    name       = "db"
    project    = local.project_id    
    instance   = google_sql_database_instance.instance.name
    depends_on = [google_sql_user.user]
}

resource "google_sql_user" "user" {
    name     = "datastream"
    project  = local.project_id    
    instance = google_sql_database_instance.instance.name
    password = "P@ssword@111"
}

resource "google_datastream_connection_profile" "source" {
    display_name          = "SQL Server Source"
    project               = local.project_id    
    location              = "us-central1"
    connection_profile_id = "source-profile"

    sql_server_profile {
        hostname = google_sql_database_instance.instance.public_ip_address
        port     = 1433
        username = google_sql_user.user.name
        password = google_sql_user.user.password
        database = google_sql_database.db.name
    }
}

resource "google_datastream_connection_profile" "destination" {
    display_name          = "BigQuery Destination"
    project               = local.project_id    
    location              = "us-central1"
    connection_profile_id = "destination-profile"

    bigquery_profile {}
}

resource "google_datastream_stream" "default" {
    display_name = "SQL Server to BigQuery"
    project      = local.project_id    
    location     = "us-central1"
    stream_id    = "stream"

    source_config {
        source_connection_profile = google_datastream_connection_profile.source.id
        sql_server_source_config {
            include_objects {
                schemas {
                    schema = "schema"
                    tables {
                        table = "table"
                    }
                }
            }
        }
    }

    destination_config {
        destination_connection_profile = google_datastream_connection_profile.destination.id
        bigquery_destination_config {
            data_freshness = "900s"
            source_hierarchy_datasets {
                dataset_template {
                    location = "us-central1"
                }
            }
        }
    }

    backfill_none {}
}