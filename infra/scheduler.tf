# Habilita a API do Cloud Scheduler
resource "google_project_service" "scheduler_api" {
  service            = "cloudscheduler.googleapis.com"
  disable_on_destroy = false
}

# Job agendado: dispara o backup diariamente às 02:00 (horário de Brasília = 05:00 UTC)
resource "google_cloud_scheduler_job" "db_backup_schedule" {
  name        = "autoprime-db-backup-daily"
  description = "Aciona o Cloud Run Job de backup do MariaDB todo dia às 02:00 BRT"
  schedule    = "0 5 * * *" # 05:00 UTC = 02:00 BRT
  time_zone   = "America/Sao_Paulo"
  region      = var.region

  depends_on = [google_project_service.scheduler_api]

  http_target {
    http_method = "POST"
    uri         = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/${google_cloud_run_v2_job.db_backup_job.name}:run"

    oauth_token {
      service_account_email = google_service_account.backup_sa.email
    }
  }
}
