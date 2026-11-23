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

As estimativas abaixo foram extraídas dos CSVs exportados da Google Cloud Pricing Calculator em **22/11/2026**. Os valores estão em dólares americanos (USD).

### 3.1 Proposta de HA — operação contínua (730 horas/mês)

| Componente | `us-central1` (Iowa) | `southamerica-east1` (São Paulo) |
|---|---:|---:|
| Compute Engine (instâncias de aplicação/conectividade e Bastion) | US$ 68,35 | US$ 101,23 |
| Cloud SQL for MySQL (vCPU, RAM, armazenamento e backups) | US$ 102,10 | US$ 153,15 |
| Cloud Load Balancing | US$ 18,25 | US$ 18,25 |
| Cloud NAT (uptime, processamento e IP) | US$ 5,92 | US$ 5,92 |
| Cloud KMS | US$ 0,18 | US$ 0,18 |
| Cloud Storage | US$ 0,00 | US$ 0,04 |
| IPs e demais itens sem cobrança na estimativa | US$ 0,00 | US$ 0,00 |
| **Total mensal estimado** | **US$ 194,92** | **US$ 249,09** |

A estimativa de `us-central1` contém duas instâncias de aplicação (2.920 horas de vCPU/RAM somadas), duas instâncias de conector VPC, uma instância Bastion considerada por 182,5 horas e Cloud SQL regional. A alternativa de São Paulo também considera duas instâncias de aplicação, duas instâncias na segunda região, Bastion por 182,5 horas e Cloud SQL regional.

### 3.2 Estimativa de uso limitado — arquivo `calculadora cloudsql.csv`

O terceiro CSV não representa operação contínua de um mês: as VMs foram estimadas por **5 horas** e o Cloud SQL por **120 horas**. O total exportado é **US$ 51,11** para esse período estimado. Portanto, esse valor não deve ser comparado diretamente aos totais mensais de operação contínua nem apresentado como custo mensal.

| Grupo de recursos | Total no período estimado |
|---|---:|
| Compute Engine (instâncias de aplicação, duas instâncias auxiliares e Bastion) | US$ 11,06 |
| Cloud SQL for MySQL (120 horas, incluindo armazenamento e backups) | US$ 16,78 |
| Cloud Load Balancing | US$ 18,25 |
| Cloud NAT | US$ 4,90 |
| Cloud KMS | US$ 0,12 |
| Cloud Storage, IPs e demais itens | US$ 0,00 |
| **Total do período** | **US$ 51,11** |

### 3.3 Comparação e interpretação

Para a proposta de HA em operação contínua, a calculadora indica **US$ 194,92/mês em `us-central1`** e **US$ 249,09/mês em `southamerica-east1`**. A alternativa em São Paulo custa aproximadamente **27,8% a mais** que a estimativa em Iowa:

\[
\frac{249,09 - 194,92}{194,92}\times 100 \approx 27,8\%
\]

O principal componente de custo nos dois cenários é o **Cloud SQL regional**: aproximadamente US$ 102,10/mês em Iowa e US$ 153,15/mês em São Paulo. O Compute Engine é o segundo maior grupo de despesas.

**Limitação da comparação com a arquitetura implantada:** os CSVs fornecidos não apresentam uma estimativa equivalente, em operação contínua de 730 horas, para o cenário A implantado na Entrega 2. O arquivo `calculadora cloudsql.csv` tem durações parciais (5 e 120 horas), por isso não é tecnicamente correto usá-lo como base mensal para calcular a variação percentual da proposta de HA. Para cumprir a comparação exigida na seção 5.2 do enunciado, é necessário exportar também a calculadora do cenário A com as mesmas premissas de operação mensal, ou informar explicitamente que a comparação percentual não foi calculada por falta dessa base equivalente.

### O custo se justifica para o perfil de uso da concessionária?

**Resposta fundamentada:** **não se justifica no estágio atual do negócio**, considerando o perfil descrito no projeto. A arquitetura de HA oferece maior resiliência contra falhas de instância e de zona, mas eleva o custo fixo mensal para aproximadamente US$ 194,92 em Iowa ou US$ 249,09 em São Paulo. Para uma concessionária com operação comercial em horário comercial e volume moderado de acessos simultâneos, o benefício de disponibilidade precisa ser ponderado frente a esse custo recorrente. A decisão pode ser revista caso a indisponibilidade passe a representar perda financeira relevante.

> **Observação:** estimativas da Google Cloud Pricing Calculator são aproximadas, em USD, e podem variar conforme uso real, tráfego, configuração, descontos, impostos e alterações de preço. Os totais acima reproduzem os valores dos CSVs enviados; não representam uma cotação vinculante.
