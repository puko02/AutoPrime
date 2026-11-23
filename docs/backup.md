# Plano de Backup e Política GFS — AutoPrime (Entrega 2)

**Instituição:** Uniamérica Descomplica  
**Disciplina:** Projeto Integrador  
**Professor:** Gildomiro Bairros  
**Projeto:** AutoPrime (Concessionária de Veículos)  
**Provedor de Nuvem:** Google Cloud Platform (GCP)  

---

## B1. Inventário de Ativos

Para garantir eficiência e evitar custos desnecessários, os ativos do sistema foram categorizados entre os que exigem rotina de backup e os que são reproduzíveis por código.

| Ativo | Tipo de Dado | Exige Backup? | Mecanismo Adotado | Justificativa |
|---|---|:---:|---|---|
| **Banco de Dados (MariaDB)** | Tabelas de carros, clientes, usuários, vendas e transações | **SIM** | Dump lógico comprimido (`mysqldump \| gzip`) enviado ao GCS | Dados dinâmicos de negócio. Se corrompidos ou apagados, não podem ser recriados por código. |
| **Imagens e Arquivos Estáticos** | Fotos dos veículos do catálogo | **SIM** | Armazenamento persistente / Snapshot de disco | Arquivos enviados pelos administradores que compõem o catálogo de veículos. |
| **Estado do Terraform (`tfstate`)** | Mapeamento dos recursos de nuvem | **SIM** | Bucket GCS com versionamento ativado | Garante que o estado da infraestrutura não seja perdido caso a máquina local falhe. |
| **Código-Fonte (Frontend e Backend)** | Código Java/Spring Boot e Angular | **NÃO** | Versionamento Git (GitHub) | Totalmente reproduzível a partir do repositório Git. |
| **Infraestrutura em Nuvem** | VPC, Subnets, Firewall, Load Balancer, KMS | **NÃO** | Terraform (IaC) | Totalmente reprodutível e versionada no repositório (`infra/`). |
| **Contêineres Docker** | Imagens compiladas da aplicação | **NÃO** | GitHub Container Registry (GHCR) / Dockerfile | Recompiláveis a qualquer momento através do pipeline de CI/CD. |

---

## B2. Metas de Recuperação: RPO e RTO

As metas de continuidade foram definidas com base no perfil de operação da concessionária de luxo AutoPrime:

- **RPO (Recovery Point Objective): 24 horas (na política conservadora) / 24 horas (na política mínima)**  
  *Justificativa:* O AutoPrime registra transações de venda de veículos de alto valor (volume moderado por dia, em torno de 5 a 20 negociações diárias). A perda máxima tolerável em caso de desastre catastrófico é de até 1 dia útil de transações, as quais podem ser reauditadas a partir das notas fiscais físicas e contratos físicos da concessionária.
- **RTO (Recovery Time Objective): 1 hora**  
  *Justificativa:* O tempo para providenciar uma nova instância ou container, descompactar o arquivo `.sql.gz` de backup (~50 MB a 500 MB) e executar a importação no MariaDB via CLI é inferior a 30 minutos em simulação técnica.

---

## B3. Política Conservadora: Esquema Grandfather-Father-Son (GFS)

A política conservadora é o modelo recomendado para a operação real em produção contínua, permitindo resgatar o estado do banco em qualquer dia da última semana, qualquer semana do último mês e qualquer mês do último ano.

| Geração | Frequência | Momento de Execução / Promoção | Retenção | Classe de Armazenamento | Cópias Retidas |
|---|---|---|---|---|:---:|
| **Son (Filho)** | Diária | Todo dia às 02:00 BRT (05:00 UTC) | 7 dias | Standard Storage | 7 |
| **Father (Pai)** | Semanal | Todo domingo às 03:00 BRT (promove o dump de domingo) | 4 semanas | Nearline Storage | 4 |
| **Grandfather (Avô)**| Mensal | Último domingo do mês às 04:00 BRT (promove o dump semanal) | 12 meses | Coldline / Archive | 12 |

### Mecanismo de Armazenamento e Nomenclatura no Bucket
```
gs://autoprime-db-backup/
  ├── daily/     (backup-YYYY-MM-DD-daily.sql.gz)
  ├── weekly/    (backup-YYYY-MM-DD-weekly.sql.gz)
  └── monthly/   (backup-YYYY-MM-DD-monthly.sql.gz)
```

---

## B4. Armazenamento e Segurança do Backup

1. **Localização Externa:** Os arquivos de dump residem exclusivamente no **Google Cloud Storage (GCS)**, fora da VM hospedeira. Mesmo que a VM seja destruída ou sofra ransomware, os backups permanecem íntegros.
2. **Criptografia em Repouso (Controle S6):** O bucket `autoprime-db-backup` possui criptografia explícita declarada no Terraform utilizando chave gerenciada pelo cliente (**CMEK**) gerada no **Cloud KMS** (`autoprime-storage-key`), com rotação a cada 90 dias.
3. **Menor Privilégio de Acesso (Controle S5):** A gravação do dump é realizada por uma Service Account dedicada (`autoprime-backup-sa`) que possui estritamente o papel `roles/storage.objectCreator` apenas neste bucket. O acesso público ao bucket é rigorosamente bloqueado (`public_access_prevention = "enforced"`).

---

## B5. Matriz de Responsabilidade Compartilhada

| Camada / Ativo | Responsabilidade do Provedor (GCP) | Responsabilidade do Grupo AutoPrime |
|---|---|---|
| **Armazenamento Físico e Discos** | Garantir a integridade do hardware, redundância de storage e durabilidade de 99,999999999% (11 noves) do GCS. | Escolher a região correta e configurar a classe de armazenamento adequada. |
| **Criptografia** | Prover o módulo de segurança de hardware (HSM) e execução das operações criptográficas do KMS. | Criar o KeyRing, definir a política de rotação da chave CMEK e vincular a chave ao bucket no código Terraform. |
| **Rotina de Backup** | Disponibilidade e execução dos gatilhos do Cloud Scheduler e runtime do Cloud Run Jobs. | Escrever o script de `mysqldump`, tratar erros de execução e garantir que as credenciais do banco sejam fornecidas de forma segura. |
| **Ciclo de Vida e Retenção** | Executar de forma assíncrona as regras de expiração/deleção de objetos conforme a idade configurada. | Declarar as regras de ciclo de vida (`lifecycle_rule`) no Terraform com os prazos corretos de retenção. |
| **Restauração e Testes** | Disponibilizar as APIs de download do Cloud Storage. | Realizar procedimentos periódicos de teste de restore para validar a integridade lógica dos dados. |

---

## B6. Política Mínima Configurada (Ambiente Acadêmico)

Para viabilizar a demonstração prática sem gerar custos financeiros desnecessários durante os testes e apresentação, foi configurada e aplicada a **Política Mínima**:

- **Mecanismo:** Cloud Run Job (`autoprime-db-backup-job`) acionado pelo Cloud Scheduler (`autoprime-db-backup-daily`), executando o dump lógico com `mysqldump` comprimido em gzip diretamente para o bucket GCS.
- **Retenção:** **2 dias** (definida na variável `var.backup_retention_days = 2` e aplicada via `lifecycle_rule` do Terraform), atendendo estritamente ao limite máximo de 2 dias exigido no edital para manter custo zero.
- **Criptografia:** Chave KMS CMEK ativa no bucket.

### O que a Política Mínima NÃO protege em relação à Política Conservadora:
- **Janela de histórico limitada:** Um erro de operação, exclusão acidental ou ataque que seja descoberto **mais de 48 horas após sua ocorrência não poderá ser recuperado**, pois os arquivos diários são expurgados no 2º dia.
- **Sem histórico semanal e mensal:** Não há possibilidade de auditoria retroativa de meses anteriores para fins de fechamento contábil anual da concessionária.

---

## B7. Estimativa de Custos: Política Conservadora (12 Meses) vs Política Mínima

### Premissas Adotadas:
- Volume inicial do banco: 100 MB.
- Crescimento mensal estimado de dados: 20 MB/mês.
- Tamanho médio do dump diário comprimido: ~35 MB a ~65 MB ao longo do ano.
- Preço do GCS em `us-central1`: Standard (\$0,020/GB), Nearline (\$0,010/GB), Coldline (\$0,004/GB).

### Projeção Acumulada de 12 Meses (Seção 6.4 do Edital):

| Mês | Volume da Aplicação | Cópias Retidas (Son + Father + Grandfather) | Volume Armazenado em Backup | Custo Estimado no Mês |
|:---:|:---:|:---:|:---:|:---:|
| 1 | 100 MB | 7 Son + 1 Father + 1 Grandfather (9 cópias) | ~0,32 GB | < \$0,01 |
| 2 | 120 MB | 7 Son + 4 Father + 2 Grandfather (13 cópias) | ~0,55 GB | < \$0,01 |
| 3 | 140 MB | 7 Son + 4 Father + 3 Grandfather (14 cópias) | ~0,68 GB | < \$0,01 |
| 4 | 160 MB | 7 Son + 4 Father + 4 Grandfather (15 cópias) | ~0,83 GB | \$0,01 |
| 6 | 200 MB | 7 Son + 4 Father + 6 Grandfather (17 cópias) | ~1,15 GB | \$0,02 |
| 8 | 240 MB | 7 Son + 4 Father + 8 Grandfather (19 cópias) | ~1,52 GB | \$0,02 |
| 10 | 280 MB | 7 Son + 4 Father + 10 Grandfather (21 cópias) | ~1,95 GB | \$0,03 |
| 12 | 320 MB | 7 Son + 4 Father + 12 Grandfather (23 cópias) | ~2,45 GB | \$0,04 |
| **Total Anual Estimado** | — | **23 cópias estabilizadas** | **Pico de ~2,5 GB** | **~ \$0,25 / ano** |

### Pergunta Obrigatória do Edital (Seção 6.4):
> **Qual parâmetro da política mais influencia o custo anual e o que se perderia ao reduzi-lo?**
- **Resposta Técnica:** O parâmetro que mais influencia o custo anual em sistemas com maior escala é a **retenção da geração Grandfather (retenção mensal por 12 meses)** combinada com a **frequência diária do Son**. Ao reduzir a retenção de 12 meses para, por exemplo, 3 meses, haveria economia no volume de dados acumulados a longo prazo. No entanto, **perder-se-ia a conformidade fiscal e a rastreabilidade histórica**, impossibilitando restaurar dados de balanços contábeis fechados de meses anteriores em caso de auditoria financeira ou fraude corporativa.

### Custo da Política Mínima no Período do Trabalho:
- Armazenamento de 2 cópias (~80 MB) por 7 dias no GCS: **R\$ 0,00 / \$0,0001 (gratuito dentro do free tier do Google Cloud)**.

---

## 8. Procedimento de Restauração (Disaster Recovery)

Para demonstrar a restauração em caso de falha:

1. **Localizar e baixar o dump mais recente do bucket:**
   ```bash
   gsutil ls gs://${PROJECT_ID}-autoprime-db-backup/daily/
   gsutil cp gs://${PROJECT_ID}-autoprime-db-backup/daily/backup-recente.sql.gz /tmp/
   ```

2. **Descompactar e importar para o container MariaDB:**
   ```bash
   gunzip /tmp/backup-recente.sql.gz
   sudo docker exec -i autoprime-db mysql -u root -p"$DB_PASSWORD" auto_prime < /tmp/backup-recente.sql
   ```
