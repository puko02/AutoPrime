# ==============================================================================
# S1 — Bloqueio de SSH por senha + S2 — Saída restrita na rede (Egress)
# + R1, R2, R3, R4, R5, R6, R7, R10 — Topologia de Rede Segura GCP
# ==============================================================================

# ---- R1, R2: Rede VPC e Sub-redes (Pública e Privada) ----

# Rede VPC customizada para o ambiente AutoPrime (R1)
resource "google_compute_network" "autoprime_vpc" {
  name                    = "autoprime-vpc"
  project                 = var.project_id
  auto_create_subnetworks = false
  description             = "Rede VPC segmentada para o ambiente AutoPrime"
}

# Sub-rede Pública para recursos expostos / Load Balancer / Bastion (R2)
resource "google_compute_subnetwork" "autoprime_subnet_public" {
  name          = "autoprime-subnet-public"
  project       = var.project_id
  network       = google_compute_network.autoprime_vpc.id
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Sub-rede Privada para instâncias internas e banco de dados (R2, R5)
resource "google_compute_subnetwork" "autoprime_subnet_private" {
  name                     = "autoprime-subnet-private"
  project                  = var.project_id
  network                  = google_compute_network.autoprime_vpc.id
  ip_cidr_range            = "10.0.2.0/24"
  region                   = var.region
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# ---- R4: Cloud Router e Cloud NAT Gerenciado ----

# Cloud Router para gerenciar o NAT da rede privada
resource "google_compute_router" "autoprime_router" {
  name    = "autoprime-nat-router"
  project = var.project_id
  region  = var.region
  network = google_compute_network.autoprime_vpc.id
}

# IP público estático reservado para o NAT Gerenciado (R4, R11)
resource "google_compute_address" "autoprime_nat_ip" {
  name    = "autoprime-nat-ip"
  project = var.project_id
  region  = var.region
}

# Cloud NAT gerenciado para saída de internet da sub-rede privada (R4)
resource "google_compute_router_nat" "autoprime_nat" {
  name                               = "autoprime-cloud-nat"
  project                            = var.project_id
  router                             = google_compute_router.autoprime_router.name
  region                             = var.region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.autoprime_nat_ip.self_link]
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.autoprime_subnet_private.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# ---- R6: IP Público Estático para o Bastion (Recurso de Acesso) ----

resource "google_compute_address" "autoprime_bastion_ip" {
  name        = "autoprime-bastion-ip"
  project     = var.project_id
  region      = var.region
  description = "IP público estático para o Bastion de acesso administrativo (R6)"
}

# ---- R6, S1, R8, R9, R10: Instância Bastion (Sub-rede Pública) ----

resource "google_compute_instance" "autoprime_bastion" {
  name         = "bastion-ubuntu"
  machine_type = var.bastion_machine_type
  zone         = var.zone
  project      = var.project_id

  # S1 — Chave SSH injetada nos metadados da instância (OS Login desativado para aceitar chave direta)
  metadata = {
    enable-oslogin = "FALSE"
    ssh-keys       = var.ssh_public_key != "" ? "${var.ssh_user}:${var.ssh_public_key}" : null
  }

  boot_disk {
    initialize_params {
      image = var.vm_image # Ubuntu 22.04 LTS (var.vm_image)
      size  = 10
      type  = "pd-standard"
      labels = {
        env     = "production"
        managed = "terraform"
        role    = "bastion"
        os      = "ubuntu-22-04"
      }
    }
    kms_key_self_link = google_kms_crypto_key.autoprime_disk_key.id
  }

  # Conectado à sub-rede pública com IP estático (R6)
  network_interface {
    network    = google_compute_network.autoprime_vpc.id
    subnetwork = google_compute_subnetwork.autoprime_subnet_public.id

    access_config {
      nat_ip = google_compute_address.autoprime_bastion_ip.address
    }
  }

  # S1 — Hardening do Bastion: desabilita senha e login root
  metadata_startup_script = <<-SCRIPT
    #!/bin/bash
    set -e
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/^#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    systemctl restart sshd || systemctl restart ssh
  SCRIPT

  tags = ["autoprime-bastion", "allow-ssh-bastion"]

  labels = {
    env     = "production"
    managed = "terraform"
    projeto = "autoprime"
    grupo   = "projeto-integrador"
    role    = "bastion"
    os      = "ubuntu-22-04"
  }

  depends_on = [
    google_kms_crypto_key_iam_binding.compute_engine_cmek,
    google_project_service.compute_api
  ]

  allow_stopping_for_update = true
}

# ---- R5, S1, S6, R8, R9, R10: Instância da Aplicação (Sub-rede Privada SEM IP Público) ----

resource "google_compute_instance" "autoprime_vm" {
  name         = "autoprime-app-vm"
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project_id

  # S1 — Chave SSH injetada nos metadados da instância (OS Login desativado para aceitar chave direta)
  metadata = {
    enable-oslogin = "FALSE"
    ssh-keys       = var.ssh_public_key != "" ? "${var.ssh_user}:${var.ssh_public_key}" : null
  }

  # S6 — Disco de boot com criptografia de chave gerenciada pelo cliente (CMEK)
  boot_disk {
    initialize_params {
      image = var.vm_image
      size  = 30
      type  = "pd-standard"
      labels = {
        env     = "production"
        managed = "terraform"
        role    = "app"
      }
    }
    kms_key_self_link = google_kms_crypto_key.autoprime_disk_key.id
  }

  # R5 — Conectado à sub-rede privada SEM access_config (SEM IP público)
  # Toda saída de internet é roteada pelo Cloud NAT gerenciado (R4, D4)
  network_interface {
    network    = google_compute_network.autoprime_vpc.id
    subnetwork = google_compute_subnetwork.autoprime_subnet_private.id
  }

  # S1 — Script de inicialização: desabilita senha SSH, bloqueia root e instala Docker
  metadata_startup_script = <<-SCRIPT
    #!/bin/bash
    set -e

    echo "=== Iniciando hardening de seguranca da instancia privada ==="

    # S1 — Bloqueio de SSH por senha e login direto de root
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/^#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/^#\?KbdInteractiveAuthentication.*/KbdInteractiveAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

    grep -q "^PasswordAuthentication" /etc/ssh/sshd_config || echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
    grep -q "^PermitRootLogin" /etc/ssh/sshd_config || echo "PermitRootLogin no" >> /etc/ssh/sshd_config

    systemctl restart sshd || systemctl restart ssh
    echo "SSH configurado com sucesso: autenticacao por senha e root desativados (S1)."

    # Instalacao do Docker Engine via conexao NAT privada
    echo "Instalando Docker Engine via Cloud NAT..."
    apt-get update -y
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    systemctl enable docker
    systemctl start docker
    echo "Docker configurado e pronto para deploy do AutoPrime."
  SCRIPT

  tags = ["autoprime-app", "allow-internal-ssh", "allow-health-check", "allow-web"]

  labels = {
    env     = "production"
    managed = "terraform"
    projeto = "autoprime"
    grupo   = "projeto-integrador"
    role    = "app"
    os      = "ubuntu-22-04"
  }

  depends_on = [
    google_kms_crypto_key_iam_binding.compute_engine_cmek,
    google_project_service.compute_api,
    google_compute_router_nat.autoprime_nat
  ]

  allow_stopping_for_update = true
}

# ---- S1, R7: Regras de Firewall para Acesso SSH e Web ----

# SSH da internet liberado APENAS para o Bastion a partir do CIDR autorizado (R7, S1)
resource "google_compute_firewall" "autoprime_allow_ssh_bastion" {
  name    = "autoprime-allow-ssh-bastion"
  network = google_compute_network.autoprime_vpc.id
  project = var.project_id

  description = "S1/R7 — Permite SSH externo apenas para o Bastion e apenas do CIDR do grupo"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allowed_ssh_cidr
  target_tags   = ["allow-ssh-bastion"]
  direction     = "INGRESS"
  priority      = 1000
}

# SSH Interno: Bastion (sub-rede pública 10.0.1.0/24) -> App VM (sub-rede privada) (D3)
resource "google_compute_firewall" "autoprime_allow_internal_ssh" {
  name    = "autoprime-allow-internal-ssh"
  network = google_compute_network.autoprime_vpc.id
  project = var.project_id

  description = "D3 — Permite conexao SSH interna a partir do Bastion para a VM privada"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["10.0.1.0/24"]
  target_tags   = ["allow-internal-ssh"]
  direction     = "INGRESS"
  priority      = 1000
}

# Permite tráfego web do Load Balancer para a aplicação na sub-rede privada
resource "google_compute_firewall" "autoprime_allow_web" {
  name    = "autoprime-allow-web"
  network = google_compute_network.autoprime_vpc.id
  project = var.project_id

  description = "Permite trafego web do Load Balancer GCP (proxies) para a aplicacao"

  allow {
    protocol = "tcp"
    ports    = ["80", "8080"]
  }

  # Faixas de IP dos proxies do Load Balancer externo e da VPC interna
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16", "10.0.0.0/16"]
  target_tags   = ["allow-web"]
  direction     = "INGRESS"
  priority      = 1000
}

# Health Check do GCP Load Balancer (necessário para o S3)
resource "google_compute_firewall" "autoprime_allow_health_check" {
  name    = "autoprime-allow-health-check"
  network = google_compute_network.autoprime_vpc.id
  project = var.project_id

  description = "Permite sondas de health check do Load Balancer GCP"

  allow {
    protocol = "tcp"
    ports    = ["80", "8080"]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["allow-health-check"]
  direction     = "INGRESS"
  priority      = 1000
}

# ---- S2: Saída Restrita na Rede (Egress Rules) ----

# Permite comunicação interna de saída entre as sub-redes da VPC (Bastion -> App VM e vice-versa)
resource "google_compute_firewall" "autoprime_allow_internal_egress" {
  name    = "autoprime-allow-internal-egress"
  network = google_compute_network.autoprime_vpc.id
  project = var.project_id

  description = "Permite trafego de saida interno entre as sub-redes da VPC (10.0.0.0/16)"

  allow {
    protocol = "all"
  }

  direction          = "EGRESS"
  destination_ranges = ["10.0.0.0/16"]
  priority           = 900
}

# S2: Bloqueia todo o tráfego de saída por padrão para a internet (prioridade baixa)
resource "google_compute_firewall" "autoprime_deny_all_egress" {
  name    = "autoprime-deny-all-egress"
  network = google_compute_network.autoprime_vpc.id
  project = var.project_id

  description = "S2 — Bloqueia todo o tráfego de egress por padrão"

  deny {
    protocol = "all"
  }

  direction          = "EGRESS"
  destination_ranges = ["0.0.0.0/0"]
  priority           = 65534
}

# S2: Permite saída para DNS (porta 53 TCP e UDP)
resource "google_compute_firewall" "autoprime_allow_egress_dns" {
  name    = "autoprime-allow-egress-dns"
  network = google_compute_network.autoprime_vpc.id
  project = var.project_id

  description = "S2 — Permite saída estrita para resolução de nomes DNS (porta 53)"

  allow {
    protocol = "tcp"
    ports    = ["53"]
  }
  allow {
    protocol = "udp"
    ports    = ["53"]
  }

  direction          = "EGRESS"
  destination_ranges = ["0.0.0.0/0"]
  priority           = 1000
}

# S2: Permite saída para HTTP (porta 80) para repositórios de pacotes
resource "google_compute_firewall" "autoprime_allow_egress_http" {
  name    = "autoprime-allow-egress-http"
  network = google_compute_network.autoprime_vpc.id
  project = var.project_id

  description = "S2 — Permite saída estrita para tráfego HTTP de atualizações de pacotes"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  direction          = "EGRESS"
  destination_ranges = ["0.0.0.0/0"]
  priority           = 1000
}

# S2: Permite saída para HTTPS (porta 443) para APIs, GitHub e Docker Registry
resource "google_compute_firewall" "autoprime_allow_egress_https" {
  name    = "autoprime-allow-egress-https"
  network = google_compute_network.autoprime_vpc.id
  project = var.project_id

  description = "S2 — Permite saída estrita para HTTPS (atualizações, GHCR, Google APIs)"

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  direction          = "EGRESS"
  destination_ranges = ["0.0.0.0/0"]
  priority           = 1000
}

# S2: Permite saída para NTP (porta 123 UDP)
resource "google_compute_firewall" "autoprime_allow_egress_ntp" {
  name    = "autoprime-allow-egress-ntp"
  network = google_compute_network.autoprime_vpc.id
  project = var.project_id

  description = "S2 — Permite saída estrita para sincronização de relógio NTP (porta 123 UDP)"

  allow {
    protocol = "udp"
    ports    = ["123"]
  }

  direction          = "EGRESS"
  destination_ranges = ["0.0.0.0/0"]
  priority           = 1000
}

# ---- S2: Conector VPC Serverless para Cloud Run ----

resource "google_vpc_access_connector" "autoprime_connector" {
  name          = "autoprime-conn"
  project       = var.project_id
  region        = var.region
  network       = google_compute_network.autoprime_vpc.name
  ip_cidr_range = "10.8.0.0/28"

  min_instances = 2
  max_instances = 3

  depends_on = [
    google_project_service.vpcaccess_api
  ]
}
