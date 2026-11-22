# Proposta de Arquitetura de Alta Disponibilidade (HA) — AutoPrime (Parte C)

**Status:** Apenas Projetada (Não implantada, para evitar custos acadêmicos)  
**Referência:** Requisitos H1 a H7 e ADR-005  
**Provedor:** Google Cloud Platform (GCP)  
**Região:** `us-central1` (Zonas `us-central1-a` e `us-central1-b`)  

---

## 1. Visão Geral da Arquitetura Projetada

Na Entrega 2, a arquitetura implantada consolidou os serviços em uma única VM por motivos de custo. Para operar a aplicação em produção de verdade com resiliência contra falhas zonais e de instâncias, projeta-se uma evolução para **Alta Disponibilidade (HA)** distribuída em múltiplas zonas.

---

## 2. Atendimento aos Requisitos (H1 a H7)

### H1. Distribuição Multizona e Novo Plano de Endereçamento
Os recursos computacionais são distribuídos entre duas zonas da mesma região (`us-central1-a` e `us-central1-b`):

| Sub-rede | Zona / Escopo | Bloco CIDR | Finalidade |
|---|---|---|---|
| `autoprime-subnet-public-a` | `us-central1-a` | `10.0.1.0/24` | Bastion e balanceamento inicial |
| `autoprime-subnet-public-b` | `us-central1-b` | `10.0.2.0/24` | Recursos públicos auxiliares |
| `autoprime-subnet-app-a` | `us-central1-a` | `10.0.10.0/24` | Instância App 1 (Backend + Frontend) sem IP público |
| `autoprime-subnet-app-b` | `us-central1-b` | `10.0.20.0/24` | Instância App 2 (Backend + Frontend) sem IP público |
| `autoprime-subnet-db` | Regional (VPC Peering) | `10.0.100.0/24` | Cloud SQL (Primário na Zona A e Réplica na Zona B) |

### H2. Balanceamento de Carga e Health Check
- **Componente:** Google Cloud External Application Load Balancer (HTTP/HTTPS global).
- **Distribuição:** Grupo de instâncias gerenciado regional (**MIG - Managed Instance Group**) distribuído entre as zonas `us-central1-a` e `us-central1-b`, com no mínimo 2 instâncias ativas (autoescalonamento de 2 a 6 instâncias baseado em 70% de CPU).
- **Health Check:** Sonda HTTP na porta `8080` (path `/actuator/health` ou `/api/car/findAll`), intervalo de 5s, timeout de 3s e 2 sucessos consecutivos para considerar saudável.

### H3. Estratégia de NAT
- **Decisão:** **Cloud NAT Compartilhado Regional** (um Cloud Router e um Cloud NAT associados à VPC para a região `us-central1`).
- **Consequência da Escolha:** Menor custo financeiro comparado a provisionar instâncias de NAT por zona. Como o Cloud NAT do GCP é um serviço gerenciado SDN (Software Defined Networking) com alta disponibilidade inerente ao plano de controle do Google, ele suporta falhas de zona sem downtime.

### H4. Estratégia para o Banco de Dados
- **Decisão:** Migração do MariaDB conteinerizado para **Cloud SQL para MySQL (Edição Enterprise)** configurado em **Alta Disponibilidade Regional**.
- **Funcionamento:** Instância primária alocada em `us-central1-a` com replicação síncrona de armazenamento para uma instância standby em `us-central1-b`. Em caso de falha física ou indisponibilidade na zona A, o failover automático para a zona B ocorre em menos de 60 segundos com preservação de dados e mesmo endpoint DNS interno.
- **Consequência aceita:** O Cloud SQL não oferece engine nativa MariaDB, exigindo migração para MySQL 8.0 (100% compatível com a modelagem do Spring Boot/Hibernate do AutoPrime).

### H5. Estado da Aplicação Fora das Instâncias (Stateless)
- **Sessões de Usuário:** A autenticação do AutoPrime utiliza **JWT (JSON Web Tokens)** assinados de forma stateless. Qualquer instância do backend valida a assinatura do token sem necessidade de replicação de memória de sessão.
- **Arquivos e Fotos de Veículos:** Uploads de catálogo são direcionados diretamente para um bucket multi-regional do **Cloud Storage (GCS)**, tornando o disco das VMs efêmero e descartável.

### H6. Tratamento dos Pontos Únicos de Falha (SPOFs)

| SPOF Identificado na Entrega 1 | Tratamento na Proposta de HA | Status |
|---|---|---|
| **VM única da Aplicação** | Substituída por MIG multizona com pelo menos 2 instâncias distribuídas | **Eliminado** |
| **Banco MariaDB em disco local** | Substituído por Cloud SQL regional com failover automático entre zonas | **Eliminado** |
| **Ponto único de entrada web** | External HTTP(S) Load Balancer Anycast com múltiplos pontos de presença globais | **Eliminado** |
| **Host Bastion** | Mantido como máquina única ou substituído por **Cloud IAP (Identity-Aware Proxy)** com túnel SSH sem IP público | **Aceito / Mitigado** |

### H7. Redesenho dos Fluxos Operacionais
1. **Fluxo do Cliente (HTTPS):** Cliente -> DNS Anycast -> Cloud Load Balancer (terminação SSL S3) -> VM saudável no MIG (Zona A ou B) -> Conexão interna privada -> Cloud SQL Primário.
2. **Fluxo de Acesso Administrativo:** Desenvolvedor autenticado -> Cloud IAP / Bastion -> SSH via chave pública (S1) -> Instâncias privadas na VPC.

---

## 3. Estimativa de Custos: Arquitetura Implantada vs Proposta de HA

| Componente | Cenário A (Implantado na Entrega 2) | Proposta de Alta Disponibilidade (Operação Contínua) | Variação (%) |
|---|:---:|:---:|:---:|
| **Computação (VMs)** | 1x `e2-medium` (~ \$25/mês) | 2x `e2-medium` no MIG (~ \$50/mês) | + 100% |
| **Banco de Dados** | Incluso na VM única (\$0 adicional) | Cloud SQL MySQL HA (db-custom-2-8, Regional) (~ \$140/mês) | + 100% (Novo) |
| **Load Balancer** | Global Forwarding Rules (~ \$18/mês) | Global Application Load Balancer (~ \$25/mês) | + 38% |
| **Armazenamento e Backup** | GCS Standard 2 dias (~ \$0,05/mês) | Cloud SQL Backup + GCS Regional (~ \$15/mês) | + 300% |
| **Rede e Cloud NAT** | 1x Cloud NAT (~ \$32/mês) | 1x Cloud NAT Regional + tráfego interzonal (~ \$45/mês) | + 40% |
| **Total Mensal Estimado** | **~ \$75,00 / mês** | **~ \$275,00 / mês** | **+ 266%** |

### O custo se justifica para o perfil de uso da concessionária?
**Resposta Fundamentada:** **NÃO se justifica no estágio atual do negócio.**  
*Justificativa:* O AutoPrime atende a uma concessionária de veículos de luxo com operação comercial em horário comercial e volume moderado de acessos simultâneos (catálogo público e painel interno de vendedores). Um downtime eventual fora do horário comercial não acarreta perdas financeiras catastróficas que compensem um aumento de **mais de 260% no custo fixo mensal de nuvem** (de ~\$75 para ~\$275 mensais). A arquitetura conteinerizada atual com política de backup bem estruturada atende aos objetivos de negócio com excelente eficiência de capital.
