# Cloud Run Job que executa o mysqldump e faz upload para o GCS
resource "google_cloud_run_v2_job" "db_backup_job" {
  name     = "autoprime-db-backup-job"
  location = var.region

  template {
    template {
      service_account = google_service_account.backup_sa.email

      # Conexao segura com a VPC privada para alcancar o MariaDB
      vpc_access {
        connector = google_vpc_access_connector.autoprime_connector.id
        egress    = "PRIVATE_RANGES_ONLY"
      }

      # Timeout generoso para dumps grandes
      timeout = "600s"

      containers {
        # Imagem oficial do MariaDB (contém mysqldump) + gsutil
        image = "gcr.io/google.com/cloudsdktool/cloud-sdk:slim"

        # Script inline: faz dump e envia para o bucket
        command = ["/bin/bash", "-c"]
        args = [
          <<-EOT
            set -e
            DATE=$(date +%Y-%m-%d)
            DUMP_FILE="/tmp/backup-$${DATE}-daily.sql.gz"

            echo "Iniciando dump do banco $${DB_NAME}..."
            mysqldump \
              -h "$${DB_HOST}" \
              -u "$${DB_USER}" \
              -p"$${DB_PASSWORD}" \
              --single-transaction \
              --routines \
              --triggers \
              "$${DB_NAME}" | gzip > "$${DUMP_FILE}"

            echo "Enviando para o bucket..."
            gsutil cp "$${DUMP_FILE}" "gs://${google_storage_bucket.db_backup.name}/daily/"

            echo "Backup concluido: $${DUMP_FILE}"
          EOT
        ]

        env {
          name  = "DB_HOST"
          value = var.db_host
        }
        env {
          name  = "DB_NAME"
          value = var.db_name
        }
        env {
          name  = "DB_USER"
          value = var.db_user
        }
        env {
          name  = "DB_PASSWORD"
          value = var.db_password
        }

        resources {
          limits = {
            cpu    = "1"
            memory = "512Mi"
          }
        }
      }
    }
  }

  labels = {
    managed = "terraform"
    purpose = "db-backup"
  }
}
