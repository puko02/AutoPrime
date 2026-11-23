# Declaração do Uso de Inteligência Artificial

**Instituição:** Uniamérica Descomplica  
**Disciplina:** Projeto Integrador: Trabalho Prático de Infraestrutura em Nuvem  
**Professor:** Gildomiro Bairros  
**Projeto:** AutoPrime  

---

## 1. Ferramentas de IA Utilizadas

Nesta Entrega 2, o grupo utilizou ferramentas de assistência de Inteligência Artificial para apoiar o desenvolvimento da infraestrutura como código (IaC), modelagem de segurança e elaboração da documentação técnica.

- **Ferramentas:** Google Antigravity / Gemini / Claude.

---

## 2. Atividades em que a IA foi Utilizada

| Área / Tarefa | Como a IA foi utilizada | O que foi revisado / validado pelos integrantes |
|---|---|---|
| **Infraestrutura como Código (Terraform)** | Sugestão e validação da sintaxe dos recursos do GCP (`google_compute_instance`, `google_compute_firewall`, `google_compute_managed_ssl_certificate`, `google_kms_crypto_key`). | O grupo revisou parâmetros de CIDR, regiões, tipos de máquinas e executou `terraform validate` e `terraform plan`. |
| **Controles de Segurança (S1 a S8)** | Auxílio na estruturação dos scripts de hardening de SSH (`PasswordAuthentication no`, `PermitRootLogin no`) e regras de firewall de saída restrita (Egress). | O grupo testou manualmente a conectividade SSH por chave e validou o bloqueio de portas externas. |
| **Modelagem de Ameaças e Achados (S7)** | Identificação de ameaças concretas à arquitetura da aplicação e estruturação da matriz de riscos residuais em `docs/seguranca.md`. | O grupo validou os achados frente ao código real e eliminou segredos expostos no repositório. |
| **Plano de Backup (GFS - Parte D)** | Estruturação da tabela de retenção acumulada de 12 meses e cálculo das métricas de RPO e RTO. | O grupo validou a viabilidade das janelas de dump e a compatibilidade do volume de dados da concessionária. |
| **Registros de Decisão (ADRs)** | Padronização textual do formato Y-statement nos ADRs de alta disponibilidade e backup. | As decisões de negócio (uso de VM única para redução de custo e descarte de Cloud SQL) foram de autoria do grupo. |

---

## 3. Postura Crítica e Responsabilidade

Todas as saídas geradas por IA foram submetidas à verificação de conformidade com o edital do professor Gildomiro Bairros. Decisões arquiteturais, assunção de riscos, commits, credenciais de nuvem e testes práticos de execução foram realizados exclusivamente pelos integrantes humanos do grupo.
