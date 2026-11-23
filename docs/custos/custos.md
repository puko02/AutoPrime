# Estimativas e Controle de Custos — Projeto AutoPrime

**Instituição:** Uniamérica Descomplica  
**Disciplina:** Projeto Integrador  
**Professor:** Gildomiro Bairros  
**Provedor:** Google Cloud Platform (GCP)  
**Moeda:** dólares americanos (USD), salvo indicação em contrário

---

## 1. Comparativo de Cenários de Custo

Conforme solicitado no edital da Entrega 2, esta seção reúne as estimativas dos cenários do projeto. Os valores dos cenários da Entrega 1 e da Entrega 2 foram mantidos conforme a versão anterior deste documento; os CSVs enviados posteriormente detalham principalmente a proposta de alta disponibilidade (HA).

### 1.1 Cenários anteriores

| Componente | Entrega 1 (Cenário Projetado) | Entrega 2 (Cenário A - Implantado) |
|---|:---:|:---:|
| **Computação** | 4x instâncias (`e2-micro`/`small`) ~ US$ 45,00/mês | 1x `bastion-ubuntu` (`e2-micro`) ~ US$ 7,50 + 1x `autoprime-app-vm` (`e2-medium`) ~ US$ 25,00 |
| **Banco de Dados** | VM própria (incluída na estimativa de computação) | MariaDB conteinerizado na VM privada (sem custo adicional de serviço gerenciado) |
| **Balanceador de Carga** | Não utilizado | External HTTP(S) Load Balancer com SSL ~ US$ 18,50/mês |
| **Cloud NAT e Rede** | Sem NAT gerenciado | 1x Cloud NAT com IP estático ~ US$ 32,00/mês |
| **Storage e Backup** | Sem backup automatizado | Política mínima, com retenção de até 2 dias; valor inferior a US$ 0,01/mês na estimativa anterior |
| **Criptografia (KMS)** | Criptografia padrão do GCP | KeyRing CMEK (2 chaves com rotação) ~ US$ 0,12/mês |
| **Total mensal informado anteriormente** | **~ US$ 45,00/mês** | **~ US$ 83,12/mês** |

> **Nota de rastreabilidade:** os valores acima para Entrega 1 e Entrega 2 foram preservados do documento original. Os três CSVs recebidos não constituem uma nova exportação mensal completa e equivalente desses dois cenários; portanto, esses totais não foram recalculados nem validados por eles.

### 1.2 Proposta de Alta Disponibilidade — operação contínua (730 horas/mês)

Os CSVs `calculadora us-central1.csv` e `calculadora southamerica-east1.csv` apresentam estimativas para a arquitetura HA em duas localizações. Os totais abaixo reproduzem os valores exportados e agrupam os itens por serviço.

| Componente | `us-central1` (Iowa) | `southamerica-east1` (São Paulo) |
|---|---:|---:|
| **Compute Engine** (instâncias de aplicação/conectividade e Bastion) | US$ 68,35/mês | US$ 101,23/mês |
| **Cloud SQL for MySQL** (vCPU, RAM, armazenamento e backups) | US$ 102,10/mês | US$ 153,15/mês |
| **Cloud Load Balancing** | US$ 18,25/mês | US$ 18,25/mês |
| **Cloud NAT** (uptime, processamento e IP) | US$ 5,92/mês | US$ 5,92/mês |
| **Cloud KMS** | US$ 0,18/mês | US$ 0,18/mês |
| **Cloud Storage** | US$ 0,00/mês | US$ 0,04/mês |
| **IPs e demais itens sem cobrança na estimativa** | US$ 0,00/mês | US$ 0,00/mês |
| **Total mensal estimado de HA** | **US$ 194,92/mês** | **US$ 249,09/mês** |

A estimativa de `us-central1` considera duas instâncias de aplicação, duas instâncias de conector VPC, uma instância Bastion estimada por 182,5 horas e Cloud SQL regional. A alternativa de São Paulo considera duas instâncias de aplicação, duas instâncias na segunda região, Bastion estimado por 182,5 horas e Cloud SQL regional, conforme os itens dos respectivos CSVs.

A opção de São Paulo apresenta custo aproximadamente **27,8% maior** que a opção de Iowa:

\[
\frac{249,09 - 194,92}{194,92}\times 100 \approx 27,8\%
\]

O Cloud SQL regional é o maior componente de custo nos dois cenários: aproximadamente US$ 102,10/mês em Iowa e US$ 153,15/mês em São Paulo.

### 1.3 Estimativa de uso limitado — `calculadora cloudsql.csv`

O terceiro CSV não representa um mês completo de operação. Nele, as VMs foram estimadas por **5 horas** e o Cloud SQL por **120 horas**. O total de **US$ 51,11** corresponde somente ao período configurado na calculadora e não deve ser apresentado como custo mensal.

| Grupo de recursos | Total no período estimado |
|---|---:|
| Compute Engine (instâncias de aplicação, auxiliares e Bastion) | US$ 11,06 |
| Cloud SQL for MySQL (120 horas, incluindo armazenamento e backups) | US$ 16,78 |
| Cloud Load Balancing | US$ 18,25 |
| Cloud NAT | US$ 4,90 |
| Cloud KMS | US$ 0,12 |
| Cloud Storage, IPs e demais itens | US$ 0,00 |
| **Total do período** | **US$ 51,11** |

Esse cenário de duração parcial é útil para representar uma janela limitada de testes, mas não pode ser comparado diretamente com os totais de 730 horas/mês.

### 1.4 Comparação e interpretação

Para a proposta de HA em operação contínua, a calculadora indica **US$ 194,92/mês em Iowa** e **US$ 249,09/mês em São Paulo**. A escolha da região de São Paulo aumenta a estimativa em aproximadamente 27,8% em relação a Iowa.

Não foi recalculado um percentual de aumento da arquitetura implantada para a proposta de HA: os CSVs fornecidos não apresentam uma exportação do cenário A com as mesmas premissas de 730 horas. O CSV de uso limitado contém durações diferentes (5 e 120 horas) e, por isso, não serve como base mensal equivalente. Para obter uma variação percentual tecnicamente comparável, é necessário exportar também o cenário A com as mesmas premissas mensais.

---

## 2. Projeção de Custos da Política Conservadora de Backup (12 Meses)

A projeção abaixo foi mantida conforme a versão anterior deste documento. Os três CSVs recebidos não trazem uma nova simulação anual completa da política GFS; portanto, esses valores não foram recalculados.

Estimativa de crescimento de armazenamento do esquema GFS no Cloud Storage:

- Mês 1 (9 cópias): ~ US$ 0,01
- Mês 3 (14 cópias): ~ US$ 0,01
- Mês 6 (17 cópias): ~ US$ 0,02
- Mês 12 (23 cópias estabilizadas em ~2,5 GB): ~ US$ 0,04/mês
- **Custo anual total estimado do backup GFS:** **~ US$ 0,25/ano**

> Esses valores são uma projeção anterior, separada das estimativas de HA. Para atualizar o custo anual com precisão, será necessária uma exportação específica da política GFS com volume, classe de armazenamento, operações e retenção definidos.

---

## 3. Custo Real Observado (Pós-Apresentação)

> *Esta seção será preenchida após a apresentação com os dados reais faturados no Console GCP (Faturamento > Relatórios). As estimativas da calculadora não substituem os valores efetivamente faturados.*

- **Data do `apply`:** [Preencher]
- **Data do `destroy`:** [Preencher]
- **Tempo total de ambiente ligado:** [Preencher] horas
- **Custo total real faturado no painel do GCP:** R$ [Preencher]

---

## 4. Observações sobre as Estimativas

- Os valores da Calculadora Google Cloud são estimativas em USD e podem variar conforme configuração, região, tráfego, uso efetivo, descontos, impostos e alterações de preço.
- Os totais mensais de HA correspondem aos CSVs de 730 horas e devem ser tratados como cenários alternativos de localização, não somados entre si.
- O total de US$ 51,11 do CSV `calculadora cloudsql.csv` é referente a um período parcial e não a um mês completo.
- Os custos históricos da Entrega 1, Entrega 2 e da política GFS foram mantidos como estavam no documento anterior, pois os novos CSVs não fornecem bases equivalentes para recalculá-los.
