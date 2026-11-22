# ==============================================================================
# S3 — HTTPS para a aplicação
# Cloud Load Balancing com terminação TLS, certificado SSL gerenciado e redirecionamento HTTP -> HTTPS
# ==============================================================================

# IP Público Global estático para o Load Balancer (S3)
resource "google_compute_global_address" "autoprime_lb_ip" {
  name        = "autoprime-lb-ip"
  project     = var.project_id
  description = "IP público estático do Load Balancer HTTPS do AutoPrime"
}

# Certificado SSL Gerenciado pelo Google para o domínio da aplicação (S3)
resource "google_compute_managed_ssl_certificate" "autoprime_cert" {
  name    = "autoprime-managed-cert"
  project = var.project_id

  managed {
    domains = [var.domain_name]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Grupo de instâncias não gerenciado contendo a VM da aplicação
resource "google_compute_instance_group" "autoprime_ig" {
  name        = "autoprime-instance-group"
  project     = var.project_id
  zone        = var.zone
  description = "Grupo de instâncias para balanceamento da aplicação AutoPrime"

  instances = [
    google_compute_instance.autoprime_vm.self_link
  ]

  named_port {
    name = "http"
    port = 80
  }
}

# Health Check para verificar se o frontend/backend está online
resource "google_compute_health_check" "autoprime_hc" {
  name                = "autoprime-health-check"
  project             = var.project_id
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = 80
    request_path = "/"
  }
}

# Backend Service que encaminha requisições para a VM
resource "google_compute_backend_service" "autoprime_backend" {
  name                  = "autoprime-backend-service"
  project               = var.project_id
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  timeout_sec           = 30
  health_checks         = [google_compute_health_check.autoprime_hc.id]

  backend {
    group           = google_compute_instance_group.autoprime_ig.id
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
    capacity_scaler = 1.0
  }
}

# URL Map principal (HTTPS) direcionando para o backend service
resource "google_compute_url_map" "autoprime_https_map" {
  name            = "autoprime-https-url-map"
  project         = var.project_id
  default_service = google_compute_backend_service.autoprime_backend.id
}

# Target HTTPS Proxy com o certificado SSL atrelado
resource "google_compute_target_https_proxy" "autoprime_https_proxy" {
  name             = "autoprime-https-proxy"
  project          = var.project_id
  url_map          = google_compute_url_map.autoprime_https_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.autoprime_cert.id]
}

# Regra de encaminhamento global para HTTPS (porta 443)
resource "google_compute_global_forwarding_rule" "autoprime_https_forwarding_rule" {
  name                  = "autoprime-https-forwarding-rule"
  project               = var.project_id
  ip_protocol           = "TCP"
  port_range            = "443"
  target                = google_compute_target_https_proxy.autoprime_https_proxy.id
  ip_address            = google_compute_global_address.autoprime_lb_ip.address
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

# ---- Redirecionamento HTTP para HTTPS (S3) ----

# URL Map para redirecionar tráfego HTTP (porta 80) para HTTPS (porta 443)
resource "google_compute_url_map" "autoprime_http_redirect" {
  name    = "autoprime-http-redirect-map"
  project = var.project_id

  default_url_redirect {
    https_redirect         = true
    strip_query            = false
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
  }
}

# Target HTTP Proxy para o redirecionamento
resource "google_compute_target_http_proxy" "autoprime_http_proxy" {
  name    = "autoprime-http-proxy"
  project = var.project_id
  url_map = google_compute_url_map.autoprime_http_redirect.id
}

# Regra de encaminhamento global para HTTP (porta 80) que força o redirecionamento
resource "google_compute_global_forwarding_rule" "autoprime_http_forwarding_rule" {
  name                  = "autoprime-http-forwarding-rule"
  project               = var.project_id
  ip_protocol           = "TCP"
  port_range            = "80"
  target                = google_compute_target_http_proxy.autoprime_http_proxy.id
  ip_address            = google_compute_global_address.autoprime_lb_ip.address
  load_balancing_scheme = "EXTERNAL_MANAGED"
}
