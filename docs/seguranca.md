# Relatório de Segurança — Projeto AutoPrime (Entrega 2)

**Instituição:** Uniamérica Descomplica  
**Disciplina:** Projeto Integrador  
**Professor:** Gildomiro Bairros  
**Projeto:** AutoPrime (Backend Spring Boot + Frontend Angular + MariaDB)  
**Provedor de Nuvem:** Google Cloud Platform (GCP)  
**Código IaC:** Terraform v1.16+  

---

## 1. Controles Obrigatórios de Segurança (S1 a S8)

Abaixo estão descritos como cada um dos 8 controles exigidos na Entrega 2 foi implementado e como pode ser auditado e comprovado.

| Controle | Descrição | Status | Onde está implementado / Como auditar |
|---|---|---|---|
| **S1 — Endurecimento do SSH** | Autenticação por senha desativada e login direto como `root` desativado em todas as instâncias. | **Implementado** | No arquivo `network.tf` através de `metadata { enable-oslogin = "TRUE" }` e script em `metadata_startup_script` configurando `PasswordAuthentication no` e `PermitRootLogin no` no `/etc/ssh/sshd_config`. |
| **S2 — Saída Restrita (Egress)** | Regras de saída (egress) restritas ao estritamente necessário (DNS, HTTP/HTTPS para pacotes/registries, NTP). | **Implementado** | No arquivo `network.tf`: regra `autoprime-deny-all-egress` (prioridade 65534) bloqueando tudo, complementada por regras de permissão explícita para portas 53 (DNS), 80 (HTTP), 443 (HTTPS) e 123 (NTP). |
| **S3 — HTTPS para a Aplicação** | Aplicação atende por HTTPS com redirecionamento forçado de HTTP para HTTPS. | **Implementado** | No arquivo `loadbalancer.tf`: Google-managed SSL Certificate (`google_compute_managed_ssl_certificate`), Target HTTPS Proxy na porta 443 e URL Map de redirecionamento automático permanente (HTTP 80 -> HTTPS 443). |
| **S4 — Gestão de Segredos** | Credenciais fora do código-fonte e dos arquivos versionados. | **Implementado** | Senhas parametrizadas no Terraform com `sensitive = true` (ex: `var.db_password`), injetadas via GitHub Secrets / variáveis de ambiente (`TF_VAR_db_password`), sem credenciais gravadas nos arquivos `.tf` ou no Git. |
| **S5 — Menor Privilégio para as Instâncias** | Service Accounts dedicadas com escopo estrito de permissão para cada recurso. | **Implementado** | No arquivo `iam.tf`: Service Account `autoprime-backup-sa` criada com papel restrito `roles/storage.objectCreator` apenas no bucket específico de backup, e `roles/run.invoker` para o Cloud Run. |
| **S6 — Criptografia em Repouso** | Discos de boot, snapshots e bucket de backup com criptografia declarada explicitamente no código via CMEK. | **Implementado** | Nos arquivos `kms.tf`, `network.tf` e `bucket.tf`: Cloud KMS KeyRing e CryptoKeys com rotação de 90 dias aplicadas explicitamente em `boot_disk.kms_key_self_link` e `google_storage_bucket.encryption`. |
| **S7 — Análise Automatizada** | Análise estática de IaC (Trivy / Checkov) e busca de segredos no histórico (Gitleaks). | **Implementado** | Execução e tratamento documentados na Seção 2 e Seção 3 deste relatório. |
| **S8 — Proteção da Conta (MFA)** | Autenticação multifator ativada na conta Google Cloud utilizada pelo grupo. | **Evidenciado** | Comprovação fotográfica sem dados sensíveis anexada em `docs/evidencias/mfa-gcp.png` e detalhada na Seção 5. |

---

## 2. Comandos de Verificação e Demonstração

Para os testes e a apresentação técnica de 10 minutos (etapas D2, D3, D4 e D5):

### 2.1 Validação do S1 (Bloqueio de SSH por Senha)
Para comprovar que o servidor recusa autenticação por senha e só aceita chaves SSH:
```bash
ssh -o PubkeyAuthentication=no -o PreferredAuthentications=password usuario@<IP_PUBLICO_VM>
```
*Resultado esperado:* `Permission denied (publickey)`.

### 2.2 Validação do S2 (Egress Restrito)
Dentro da VM, consultar a saída permitida e testar bloqueio de saída arbitrária:
```bash
# Deve funcionar (HTTPS na porta 443):
curl -I https://google.com

# Deve dar timeout/bloqueado pelo firewall (porta 23 / 8081 arbitrária externa):
curl --connect-timeout 5 telnet://portquiz.net:8081
```

### 2.3 Validação do S3 (HTTPS e Redirecionamento)
```bash
# Inspecionar negociação TLS:
curl -vk https://<DOMINIO_OU_IP_LB>

# Validar redirecionamento automático de HTTP para HTTPS (status 301 / 308):
curl -I http://<DOMINIO_OU_IP_LB>
```

---

## 3. Tratamento dos Achados de Análise Automatizada (S7)

Foram executadas análises de segurança no repositório e no código Terraform utilizando **Gitleaks** (detecção de segredos em histórico) e **Checkov / Trivy** (análise estática de IaC). Conforme a Seção 4.3 do edital, todo achado de severidade Alta ou Crítica foi analisado e tratado com decisão formal:

| ID | Ferramenta | Achado | Severidade | Recurso Afetado | Decisão | Justificativa Técnica |
|---|---|---|---|---|---|---|
| **ACH-01** | Gitleaks | Senha de banco de dados e chave JWT em texto claro no `docker-compose.yml` (`fabio123` e `AUDI_KEY`) | **Crítica** | `AutoPrimeBack/docker-compose.yml` | **Corrigido** | Credenciais foram removidas do arquivo e migradas para injeção via variáveis de ambiente (`.env` protegido pelo `.gitignore`) e GitHub Actions Secrets em tempo de deploy. |
| **ACH-02** | Checkov | Regra de Firewall com saída liberada para qualquer destino (`destination_ranges = ["0.0.0.0/0"]`) | **Alta** | `google_compute_firewall` | **Corrigido** | Implementado o controle S2 no `network.tf`: criada a regra default `autoprime-deny-all-egress` com prioridade 65534 e liberadas apenas portas de saída estritamente necessárias (53, 80, 443, 123). |
| **ACH-03** | Checkov | Bucket de armazenamento sem logs de auditoria de acesso ativados | **Média** | `google_storage_bucket.db_backup` | **Aceito** | O bucket destina-se exclusivamente a backups transitórios com retenção máxima de 2 dias (B6) para atender ao critério de custo zero. A ativação de logs geraria custos adicionais de armazenamento e escrita desproporcionais ao escopo acadêmico. Risco residual mitigado pelo controle de acesso IAM estrito (S5) e CMEK (S6). |
| **ACH-04** | Trivy | Disco de boot de VM sem criptografia gerenciada pelo cliente | **Alta** | `google_compute_instance.autoprime_vm` | **Corrigido** | Implementado o controle S6 no `kms.tf` e `network.tf`: criada chave Cloud KMS (`autoprime_disk_key`) e vinculada via `kms_key_self_link` no boot disk da VM. |
| **ACH-05** | Checkov | SSH acessível para a internet irrestrita (`0.0.0.0/0`) | **Alta** | `google_compute_firewall.autoprime_allow_ssh` | **Corrigido** | Restringido via variável `allowed_ssh_cidr` ao bloco CIDR específico dos IPs autorizados dos integrantes do grupo (R7), com bloqueio de senha (S1). |
| **ACH-06** | Trivy | Instância com IP externo associado diretamente na interface de rede | **Média** | `google_compute_instance.autoprime_vm` | **Aceito** | A instância atua como ponto de acesso transitório inicial e execução dos contêineres Docker antes da terminação completa do Load Balancer em ambiente de apresentação. Risco residual mitigado por regras estritas de firewall de entrada (apenas portas 80/8080 e SSH restrito por CIDR). |

---

## 4. Análise de Ameaças Concretas à Arquitetura (Mínimo de 5)

Ameaças modeladas com base no fluxo real de dados e na topologia de nuvem do projeto AutoPrime:

| # | Ameaça Concreta | Ativo Afetado | Controle Aplicado | Risco Residual e Mitigação |
|---|---|---|---|---|
| **AM-01** | **Ataque de Força Bruta e Dicionário via SSH:** Tentativa automatizada de adivinhação de senhas contra a porta 22 exposta da VM. | VM da Aplicação (`autoprime-app-vm`) | **S1** (Autenticação por senha desabilitada, `enable-oslogin = TRUE`) e **R7** (Firewall permitindo SSH apenas do CIDR autorizado do grupo). | Comprometimento ou extravio da chave privada SSH de um dos integrantes do grupo. Mitigado pelo uso de passphrases nas chaves locais e rotação periódica. |
| **AM-02** | **Interceptação e Eavesdropping de Credenciais de Usuário em Trânsito:** Captura de credenciais e tokens JWT entre o navegador Angular do cliente e o backend. | Tráfego web da aplicação | **S3** (HTTPS com terminação TLS no Load Balancer, certificado SSL gerenciado pelo Google e redirecionamento obrigatório de HTTP 80 para HTTPS 443). | Comprometimento por instalação de autoridade certificadora maliciosa no dispositivo cliente final (fora do perímetro de controle da nuvem). |
| **AM-03** | **Exfiltração de Dados em Caso de Comprometimento da Aplicação (C&C Reverse Shell):** Invasor obtém execução remota via vulnerabilidade em biblioteca Java e tenta abrir shell reversa ou transferir dados para servidor externo. | Dados do MariaDB e ambiente da VM | **S2** (Regras de firewall de egress bloqueando qualquer tráfego de saída por padrão, permitindo apenas portas 53, 80, 443 e 123). | Invasor utilizar túnel DNS (porta 53) ou protocolo HTTPS legítimo (porta 443) para exfiltração lenta. Mitigado por monitoramento de logs de fluxo VPC (`log_config`). |
| **AM-04** | **Vazamento e Acesso Não Autorizado a Backups do Banco de Dados no Storage:** Terceiro não autorizado tenta ler arquivos de despejo (`.sql.gz`) com dados da aplicação. | Bucket GCS (`autoprime-db-backup`) | **S5** (Service Account exclusiva com permissão mínima de gravação `roles/storage.objectCreator`, sem leitura pública) e **S6** (Criptografia CMEK com chave KMS). | Acesso indevido ao console GCP por credenciais do projeto. Mitigado por MFA obrigatório na conta do provedor (S8) e retenção restrita a 2 dias (B6). |
| **AM-05** | **Exposição de Segredos e Chaves de Acesso no Versionamento do Git:** Inclusão inadvertida de senhas do banco de dados ou tokens de deploy nos commits do repositório público/privado. | Repositório Git e Banco MariaDB | **S4** (Variáveis marcadas com `sensitive = true`, parâmetros via Secrets do GitHub/env vars) e **S7** (Gitleaks rodando no pipeline CI/CD). | Desenvolvedor commitar credencial em branch local não rastreada antes do push. Mitigado por pre-commit hook com verificação local do Gitleaks. |

---

## 5. Proteção da Conta do Provedor GCP (S8 — MFA)

Conforme a Seção 4.1 (S8) do edital, a conta Google Cloud utilizada pelo grupo para o provisionamento e operação da infraestrutura possui **Verificação em Duas Etapas (MFA / 2FA)** obrigatoriamente ativada.

### Evidência de Configuração
- **Status:** Ativo
- **Métodos Configurados:** Aplicativo autenticador (Google Authenticator) / Chave de segurança FIDO2 e Prompt do Google.
- **Local da Evidência:** A captura de tela comprobatória (sem dados sensíveis ou endereços de e-mail expostos) encontra-se armazenada no repositório no caminho:  
  📁 `docs/evidencias/mfa-gcp.png`

---

## 6. Checklist de Validação para Apresentação Técnica

- [x] S1: SSH configurado sem senha e sem root (validado com `ssh -o PubkeyAuthentication=no`)
- [x] S2: Regras de firewall com saída restrita e deny-all configurado
- [x] S3: Load Balancer HTTPS com certificado configurado e redirecionamento HTTP->HTTPS
- [x] S4: Segredos extraídos para variáveis sensíveis
- [x] S5: Service Account com menor privilégio configurada
- [x] S6: Discos e bucket configurados com criptografia KMS (CMEK)
- [x] S7: Relatório de achados Checkov/Trivy e Gitleaks preenchido com decisões
- [x] S8: Evidência de MFA pronta para apresentação
