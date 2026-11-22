# Estimativas e Controle de Custos — Projeto AutoPrime

**Instituição:** Uniamérica Descomplica  
**Disciplina:** Projeto Integrador  
**Professor:** Gildomiro Bairros  
**Provedor:** Google Cloud Platform (GCP) — Região `us-central1`  

---

## 1. Comparativo de Cenários de Custo

Conforme solicitado no edital da Entrega 2, a tabela abaixo consolida as estimativas obtidas na Calculadora Oficial do Google Cloud para os diferentes cenários do projeto.

| Componente | Entrega 1 (Cenário Projetado) | Entrega 2 (Cenário A - Implantado) | Proposta de Alta Disponibilidade (Parte C) |
|---|:---:|:---:|:---:|
| **Computação** | 4x instâncias (`e2-micro`/`small`) ~ \$45,00/mês | 1x `bastion-ubuntu` (`e2-micro`) ~ \$7,50<br>1x `autoprime-app-vm` (`e2-medium`) ~ \$25,00 | 2x `e2-medium` no MIG regional ~ \$50,00/mês |
| **Banco de Dados** | VM própria (~ incluso) | Conteinerizado na VM privada (\$0 adicional) | Cloud SQL MySQL HA (db-custom-2-8) ~ \$140,00/mês |
| **Balanceador de Carga** | Sem balanceador (\$0) | External HTTP(S) Load Balancer com SSL ~ \$18,50/mês | Regional Application Load Balancer ~ \$25,00/mês |
| **Cloud NAT e Rede** | Sem NAT gerenciado (\$0) | 1x Cloud NAT com IP estático ~ \$32,00/mês | 1x Cloud NAT Regional + tráfego interzonal ~ \$45,00/mês |
| **Storage e Backup (GFS)** | Sem backup automatizado (\$0) | Política Mínima (2 dias de retenção) < \$0,01/mês | Política GFS (12 meses com Coldline) ~ \$0,25/ano |
| **Criptografia (KMS)** | Padrão do GCP (\$0) | KeyRing CMEK (2 chaves com rotação) ~ \$0,12/mês | Cloud KMS CMEK multizona ~ \$0,20/mês |
| **Total Mensal Estimado** | **~ \$45,00 / mês** | **~ \$83,12 / mês** | **~ \$260,45 / mês (+213%)** |

---

## 2. Projeção de Custos da Política Conservadora de Backup (12 Meses)

Estimativa de crescimento de armazenamento do esquema GFS no Cloud Storage:

- Mês 1 (9 cópias): ~ \$0,01
- Mês 3 (14 cópias): ~ \$0,01
- Mês 6 (17 cópias): ~ \$0,02
- Mês 12 (23 cópias estabilizadas em ~2,5 GB): ~ \$0,04 / mês
- **Custo Anual Total do Backup GFS:** **~ \$0,25 / ano**

---

## 3. Custo Real Observado (Pós-Apresentação)

> *Esta seção será preenchida em até 48 horas após a apresentação com os dados reais faturados no Console GCP (Faturamento > Relatórios).*

- **Data do `apply`:** [Preencher na apresentação]
- **Data do `destroy`:** [Preencher após a apresentação]
- **Tempo total de ambiente ligado:** ~ [X] horas
- **Custo total real faturado no painel do GCP:** R\$ [XX,XX]
