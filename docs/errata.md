# Errata — Entrega 1 x Entrega 2

Divergências e ajustes entre a arquitetura projetada na Entrega 1 e a infraestrutura efetivamente implantada na Entrega 2 do projeto **AutoPrime**, com seus respectivos motivos e vinculação aos Registros de Decisão de Arquitetura (ADRs).

---

## 1. Tabela Comparativa de Divergências

| Item | Entrega 1 (Projetado) | Entrega 2 (Implantado) | Motivo Técnico / Decisão | ADR Afetado |
|---|---|---|---|---|
| **Região do GCP** | `us-west1` | `us-central1` | A pedido do professor, o grupo estimou custos comparativos entre regiões. A implantação foi consolidada em `us-central1` (Iowa) por apresentar o menor custo de computação, rede e storage no GCP. | - |
| **Topologia de VMs** | 4 VMs separadas (Bastion, Frontend, Backend e Banco) | **2 VMs:** 1 Bastion (`e2-micro`) na sub-rede pública + 1 VM privada (`e2-medium`) com os três contêineres Docker | Otimização drástica de custos para os estudantes, mantendo o isolamento exigido no edital (R5 e R6): o Bastion faz a ponte administrativa segura e a VM privada não possui IP público. | **ADR-004** (substitui formalmente o **ADR-003**; o **ADR-001** do Bastion permanece ativo) |
| **Tipo de Instâncias** | Quatro instâncias heterogêneas | Bastion `e2-micro` + App VM `e2-medium` (2 vCPUs, 4 GB RAM) | Adequação da VM privada para suportar com folga de memória a JVM Spring Boot, o Nginx e o MariaDB, mantendo o Bastion no menor tamanho possível (`e2-micro`) para custo mínimo. | **ADR-004** |
| **Localização do Backend e Banco** | Sub-rede privada sem IP público | VM na sub-rede privada, sem IP público, com saída exclusiva via Cloud NAT | Atende rigorosamente aos requisitos **R4** (NAT gerenciado) e **R5** (recurso computacional privado sem IP público), além da demonstração prática **D4**. | **ADR-004** |
| **Acesso Administrativo** | Host Bastion (Jump Host) | Mantido Host Bastion na sub-rede pública com conexão `ssh -J` | O acesso administrativo segue o princípio do menor privilégio: porta 22 restrita por firewall ao IP do grupo (**R7**), sem senha e sem root (**S1**). | **ADR-001** (Aceita) |
| **Banco de Dados** | VM dedicada com MariaDB | Contêiner Docker MariaDB com volume persistente na VM privada | Eliminação de custos de uma VM dedicada a banco. Facilidade de deploy e reprodutibilidade total via Docker Compose. | **ADR-003** (Substituída pelo **ADR-004**) |
| **Balanceamento e HTTPS** | Sem Load Balancer | Google Cloud Load Balancer com terminação HTTPS | Implementação obrigatória do controle **S3** da Entrega 2: terminação TLS, certificado gerenciado pelo Google e redirecionamento forçado de HTTP (porta 80) para HTTPS (porta 443). | - |
| **Criptografia e Backup** | Padrão do provedor / Sem automação | Cloud KMS (CMEK), Bucket GCS, Cloud Run Job e Cloud Scheduler | Implementação dos controles **S6** (criptografia explícita de discos e bucket) e Parte D (rotina diária de backup automatizada com menor privilégio S5). | **ADR-006** (Aceita) |
| **Tratamento de Segredos (Incidente)** | Variáveis em arquivos | Remoção completa do histórico, `.gitignore` e injeção por secrets | O scan automatizado com **Gitleaks** (S7) detectou senhas em texto claro em commits anteriores (`docker-compose.yml` e `pipeline.yml`). As credenciais foram imediatamente revogadas, eliminadas do código e migradas para variáveis de ambiente protegidas e GitHub Secrets. | - |

---

## 2. Detalhamento das Decisões e Impacto Arquitetural

### 2.1 Consolidação da Aplicação em VM Privada Conteinerizada (ADR-003 -> ADR-004)
Na Entrega 1, planejava-se instâncias Compute Engine separadas para Frontend, Backend e Banco de Dados. Na Entrega 2, o grupo consolidou esses 3 serviços em contêineres Docker dentro de uma VM `e2-medium` isolada na sub-rede privada. Essa decisão:
1. Elimina custos de duas VMs adicionais.
2. Cumpre com rigor o requisito **R5** (recurso na sub-rede privada sem IP público) e o requisito **R4** (comprovação de saída de internet da VM privada pelo IP do Cloud NAT através de `curl -s https://ifconfig.me`).
3. Mantém o Bastion (`e2-micro`) na sub-rede pública com IP estático (**R6**), viabilizando o roteiro da demonstração técnica **D3** (`ssh -J usuario@IP_BASTION usuario@IP_PRIVADO_APP`).

### 2.2 Tratamento do Incidente de Segurança (Credenciais no Git)
Conforme orienta a Seção 7.2 e Seção 12 do edital:
- **Incidente:** Detecção de credenciais expostas no Git (`MYSQL_ROOT_PASSWORD: fabio123` e `JWT_SECRET: AUDI_KEY`).
- **Ação Imediata:** Revogação das credenciais antigas, geração de novas chaves aleatórias seguras, atualização do `.gitignore` para proibir arquivos `.env`, `*.tfvars` e chaves privadas, e migração para injeção via `TF_VAR_db_password` e GitHub Actions Secrets.
