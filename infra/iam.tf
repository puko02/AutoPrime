# Service Account dedicada ao processo de backup
resource "google_service_account" "backup_sa" {
  account_id   = "autoprime-backup-sa"
  display_name = "AutoPrime DB Backup Service Account"
  description  = "Service account com permissão mínima para gravar backups no GCS"
}

# Permissão para gravar objetos no bucket de backup
resource "google_storage_bucket_iam_member" "backup_writer" {
  bucket = google_storage_bucket.db_backup.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.backup_sa.email}"
}

# Permissão para o Cloud Run Job usar a service account
resource "google_project_iam_member" "backup_sa_run" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.backup_sa.email}"
}
