# ==============================================================================
# Outputs da Infraestrutura (R11 do Edital + Controles de Segurança e Backup)
# ==============================================================================

# R11 — IP público do recurso de acesso (Host Bastion na sub-rede pública)
output "bastion_public_ip" {
  description = "IP público estático do Bastion de acesso administrativo (R6, R11)"
  value       = google_compute_address.autoprime_bastion_ip.address
}

# Alias para compatibilidade com o edital
output "vm_public_ip" {
  description = "IP público do recurso de acesso (Bastion) (R11)"
  value       = google_compute_address.autoprime_bastion_ip.address
}

# R11 — IP público do NAT gerenciado
output "nat_public_ip" {
  description = "IP público estático do Cloud NAT para saída da rede privada (R4, R11)"
  value       = google_compute_address.autoprime_nat_ip.address
}

# R11 — IPs privados das instâncias
output "vm_private_ip" {
  description = "IP privado interno da VM da aplicação na sub-rede privada (R5, R11)"
  value       = google_compute_instance.autoprime_vm.network_interface[0].network_ip
}

# Comandos de apoio para acesso administrativo SSH (D3)
output "ssh_bastion_command" {
  description = "Comando para conectar diretamente no Bastion via SSH (D3)"
  value       = "ssh -i ~/.ssh/chave-autoprime ${var.ssh_user}@${google_compute_address.autoprime_bastion_ip.address}"
}

output "ssh_app_command" {
  description = "Comando para conectar na VM privada passando pelo Bastion (Jump Host - D3)"
  value       = "ssh -i ~/.ssh/chave-autoprime -J ${var.ssh_user}@${google_compute_address.autoprime_bastion_ip.address} ${var.ssh_user}@${google_compute_instance.autoprime_vm.network_interface[0].network_ip}"
}

# S3 & R11 — URL e IP do Load Balancer HTTPS
output "load_balancer_ip" {
  description = "Endereço IP global estático do Load Balancer HTTPS (S3)"
  value       = google_compute_global_address.autoprime_lb_ip.address
}

output "application_url" {
  description = "URL segura de acesso à aplicação via HTTPS (R11, S3)"
  value       = "https://${var.domain_name}"
}

# S6 — Chaves Criptográficas CMEK
output "kms_keyring" {
  description = "Nome do KeyRing central do Cloud KMS (S6)"
  value       = google_kms_key_ring.autoprime_keyring.name
}

# Parte D — Outputs do Sistema de Backup Mínimo
output "backup_bucket_name" {
  description = "Nome do bucket GCS criptografado onde os backups são armazenados (B6, S6)"
  value       = google_storage_bucket.db_backup.name
}

output "backup_bucket_url" {
  description = "URL no formato gs:// do bucket de backup"
  value       = "gs://${google_storage_bucket.db_backup.name}"
}

output "backup_job_name" {
  description = "Nome do Cloud Run Job de backup"
  value       = google_cloud_run_v2_job.db_backup_job.name
}

output "backup_schedule" {
  description = "Expressão cron do agendamento diário de backup"
  value       = google_cloud_scheduler_job.db_backup_schedule.schedule
}

output "service_account_email" {
  description = "Email da Service Account de menor privilégio para o backup (S5)"
  value       = google_service_account.backup_sa.email
}
