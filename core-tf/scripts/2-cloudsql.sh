cd ~/repos/gcp_analytics_demo/core-tf/database
gsutil cp AdventureWorks2022.bak gs://$PROJECT_ID-cloudsql-backup
gcloud sql import bak $PROJECT_ID gs://$PROJECT_ID-cloudsql-backup/AdventureWorks2022.bak --database=AdventureWorks2022 --quiet

cd ~/repos/gcp_analytics_demo/core-tf/database
gsutil cp AdventureWorksDW2022.bak gs://$PROJECT_ID-cloudsql-backup
gcloud sql import bak $PROJECT_ID gs://$PROJECT_ID-cloudsql-backup/AdventureWorksDW2022.bak --database=AdventureWorksDW2022 --quiet