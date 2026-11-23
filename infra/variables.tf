# ==============================================================================
# Variáveis de Configuração do Ambiente AutoPrime (GCP)
# ==============================================================================

variable "project_id" {
  description = "ID do projeto no Google Cloud Platform"
  type        = string
}

variable "region" {
  description = "Região GCP onde os recursos serão criados"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Zona específica dentro da região GCP para a VM"
  type        = string
  default     = "us-central1-a"
}

variable "machine_type" {
  description = "Tipo e família da instância da aplicação na sub-rede privada (R9)"
  type        = string
  default     = "e2-medium"
}

variable "bastion_machine_type" {
  description = "Tipo da instância Bastion na sub-rede pública (R9)"
  type        = string
  default     = "e2-micro"
}

variable "vm_image" {
  description = "Imagem base do sistema operacional para a instância (Ubuntu 22.04 LTS)"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

# ---- Controles de Segurança: S1, R7, R8 ----

variable "allowed_ssh_cidr" {
  description = "CIDR autorizado para conexões SSH (R7/S1). NUNCA usar 0.0.0.0/0 (penalidade no edital)"
  type        = list(string)
  default     = ["177.0.0.0/24"] # Substituir pelo IP público real do seu computador / grupo
}

variable "ssh_user" {
  description = "Nome de usuário para autenticação SSH na VM (R8)"
  type        = string
  default     = "autoprime"
}

variable "ssh_public_key" {
  description = "Chave pública SSH (a chave privada NUNCA deve ir para o Git) (R8)"
  type        = string
  default     = ""
}

# ---- Controle S3: HTTPS ----

variable "domain_name" {
  description = "Domínio totalmente qualificado (FQDN) para emissão do certificado SSL gerenciado (S3)"
  type        = string
  default     = "autoprime.app"
}

# ---- Banco de Dados e Backup (Parte D) ----

variable "db_host" {
  description = "Host do banco de dados MariaDB (IP interno ou hostname)"
  type        = string
  default     = "10.0.2.0/24"
}

variable "db_name" {
  description = "Nome do banco de dados a ser feito backup"
  type        = string
  default     = "auto_prime"
}

variable "db_user" {
  description = "Usuário do banco de dados para dump"
  type        = string
  default     = "root"
}

variable "db_password" {
  description = "Senha do banco de dados (fornecida via TF_VAR_db_password ou Secret Manager)"
  type        = string
  sensitive   = true
}

variable "backup_retention_days" {
  description = "Dias para reter os backups no bucket (máximo de 2 dias pelo edital B6)"
  type        = number
  default     = 2
}
