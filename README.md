# AutoPrime — Infraestrutura em Nuvem

Projeto Integrador: Trabalho Prático de Infraestrutura em Nuvem
Uniamérica Descomplica · Prof. Gildomiro Bairros

## 1. Sobre o projeto

O **AutoPrime** é um sistema de gestão para uma concessionária de veículos de luxo. Ele controla estoque, clientes e vendas e oferece um catálogo público para consulta.

A aplicação é composta por três contêineres Docker:

- **Frontend:** Angular, servido pelo Nginx.
- **Backend:** Java com Spring Boot.
- **Banco de dados:** MariaDB.

Toda a infraestrutura roda no **Google Cloud Platform (GCP)**, na região `us-central1`, e é criada por código com **Terraform**.

### Integrantes

- Alexandro Augusto Ferreira Santos
- Debora Ferreira Groto
- Fabio Augusto Lorencini
- Guillermo del Toro Trillo
- Polyana Eduarda Neuland

## 2. Aviso de custos

⚠️ **Este projeto gera custos reais**, pagos pelo grupo. A instituição não oferece créditos de nuvem.

Alguns recursos são cobrados **por hora, mesmo sem nenhum uso**:

- Cloud NAT;
- IPs públicos fixos (da VM e do balanceador);
- Balanceador de carga;
- Conector VPC.

Para evitar gastos desnecessários:

1. Antes do primeiro `terraform apply`, configure um alerta de orçamento no console do GCP (Faturamento > Orçamentos e alertas).
2. Ao terminar os testes, rode `terraform destroy`.
3. Após a apresentação, destrua o ambiente em até 24 horas e confirme no console que não restou nenhum NAT, IP, disco, snapshot ou bucket.

## 3. Pré-requisitos

Para criar a infraestrutura, é preciso ter:

- **Conta no Google Cloud** com faturamento ativo e MFA habilitado — onde a infraestrutura é criada.
- **Google Cloud CLI (`gcloud`)** — para fazer login e consultar os recursos.
- **Terraform 1.3.0 ou superior** — para criar a infraestrutura a partir do código.
- **Git** — para baixar o repositório.
- **Cliente SSH e um par de chaves** — para acessar a VM.
- **Um domínio próprio** — para emitir o certificado HTTPS do balanceador.

O provider do Google usado é a versão **5.45.2**, fixada no arquivo `.terraform.lock.hcl`.

## 4. Configuração das variáveis

Os valores que mudam de um ambiente para outro (projeto, região, IP autorizado etc.) ficam em variáveis, definidas no arquivo `infra/variables.tf`.

**Passo 1 — Gerar a chave SSH do grupo** (a chave privada nunca vai para o Git):

```bash
ssh-keygen -t ed25519 -f ~/.ssh/chave-grupo
```

**Passo 2 — Criar o arquivo de variáveis a partir do exemplo:**

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
```

O arquivo `terraform.tfvars` não é enviado para o Git, porque contém dados do ambiente.

**Passo 3 — Preencher o `terraform.tfvars` com os valores do seu ambiente:**

- `project_id` — ID do projeto no GCP.
- `region` — região dos recursos (padrão: `us-central1`).
- `zone` — zona da VM (padrão: `us-central1-a`).
- `machine_type` — tipo da VM (padrão: `e2-medium`).
- `vm_image` — sistema operacional da VM (Ubuntu 22.04).
- `allowed_ssh_cidr` — o seu IP público com `/32` (exemplo: `187.54.12.33/32`). **Nunca usar `0.0.0.0/0`.** Para descobrir o seu IP: `curl -s https://ifconfig.me`
- `ssh_user` — usuário para o SSH (padrão: `autoprime`).
- `ssh_public_key` — conteúdo do arquivo `~/.ssh/chave-grupo.pub`.
- `domain_name` — domínio que aponta para o IP do balanceador.
- `db_host`, `db_name`, `db_user` — dados de conexão do banco, usados pelo backup.
- `backup_retention_days` — dias de retenção dos backups (máximo 2).

**Passo 4 — Informar a senha do banco por variável de ambiente** (ela nunca fica em arquivo):

```bash
export TF_VAR_db_password="senha_do_banco"
```

## 5. Como criar a infraestrutura (Terraform)

**Passo 1 — Fazer login no Google Cloud** (as credenciais ficam no computador, nunca no código):

```bash
gcloud auth application-default login
gcloud config set project ID_DO_PROJETO
```

**Passo 2 — Dentro da pasta `infra`, rodar os comandos na ordem:**

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

- `terraform init` — baixa o provider do Google na versão fixada no `.terraform.lock.hcl`.
- `terraform fmt -check` — confere se o código está formatado corretamente.
- `terraform validate` — confere se o código não tem erros.
- `terraform plan` — mostra o que será criado, alterado ou destruído, sem fazer nada ainda.
- `terraform apply` — cria os recursos. Digite `yes` para confirmar.

A criação do Cloud NAT e do certificado HTTPS pode levar alguns minutos.

**Passo 3 — Ver as informações da infraestrutura criada:**

```bash
terraform output
```

Os principais resultados são:

- `bastion_public_ip` — IP público da VM Bastion Ubuntu (`bastion-ubuntu` na sub-rede pública, R6).
- `nat_public_ip` — IP público do Cloud NAT (saída de internet da sub-rede privada, R4).
- `vm_private_ip` — IP privado da VM da aplicação na sub-rede privada (sem IP público, R5).
- `load_balancer_ip` — IP do balanceador HTTPS (para onde o domínio aponta, S3).
- `application_url` — endereço da aplicação em HTTPS (S3).
- `backup_bucket_name` — nome do bucket de backup criptografado (B6, S6).

## 6. Instalação da aplicação

A aplicação roda em contêineres Docker dentro da VM privada (`autoprime-app-vm`). O acesso administrativo é feito passando pelo Bastion Ubuntu (`bastion-ubuntu`, jump host). Ambas as instâncias rodam com **Ubuntu 22.04 LTS**. O Docker é instalado automaticamente pelo script de inicialização via Cloud NAT.

**Passo 1 — Conectar na VM privada através do Bastion:**

```bash
# Conexão direta utilizando a flag -J (Jump Host) do SSH:
ssh -i ~/.ssh/chave-grupo -J autoprime@IP_PUBLICO_BASTION autoprime@IP_PRIVADO_APP
```

**Passo 2 — Confirmar que o Docker está instalado:**

```bash
docker --version
```

**Passo 3 — Baixar o código (Backend e Frontend):**

```bash
# Clonar repositório do Backend e do Frontend lado a lado
git clone https://github.com/puko02/AutoPrime.git
git clone https://github.com/Fabio-Augusto-Lorencini19/AutoPrimeF.git
```

**Passo 4 — Criar o arquivo `.env` com os segredos** (eles não ficam no Git). Os comandos abaixo pedem as senhas sem mostrar na tela:

```bash
cd AutoPrime
read -s -p "Senha do banco: " DB_PASSWORD; echo
read -s -p "Segredo do JWT: " JWT_SECRET; echo
printf "DB_PASSWORD=%s\nJWT_SECRET=%s\nJWT_EXPIRATION=3600000\n" "$DB_PASSWORD" "$JWT_SECRET" > .env
chmod 600 .env
```

**Passo 5 — Subir os três contêineres:**

```bash
sudo docker compose up -d --build
```

**Passo 6 — Verificar se estão rodando:**

```bash
sudo docker ps
curl -s http://localhost:8080/api/car/findAll
```

O primeiro comando deve mostrar os três contêineres como "Up". O segundo deve devolver a lista de carros.

**Passo 7 — Testar pelo navegador:** abrir `https://SEU_DOMINIO` e usar o catálogo com certificado SSL ativo.

## 7. Demonstrações da apresentação

A apresentação tem 10 minutos rígidos. Cada integrante conduz pelo menos uma demonstração, operando o terminal e explicando o que está sendo mostrado.

| Etapa | Tempo | Conteúdo | Responsável |
|---|---|---|---|
| D1 | 0,5 min | `terraform plan` sem alterações pendentes e `terraform output` | Guillermo |
| D2 | 1 min | Acesso à aplicação por HTTPS (S3), executando funcionalidade verificável | Polyana |
| D3 | 1,5 min | SSH ao bastion, acesso à instância privada via bastion (`ssh -J`) e recusa de senha (S1) | Augusto |
| D4 | 0,5 min | Saída da instância privada pelo IP do NAT (`curl -s ifconfig.me`), sem IP público e SSH restrito | Guillermo |
| D5 | 1 min | Segredos fora do código (S4) e relatório de segurança com achado corrigido e aceito (S7) | Augusto |
| D6 | 1,5 min | Política mínima de backup configurada e demonstrada, e custo anual do plano GFS | Fábio |
| D7 | 1,5 min | Diagrama da proposta de alta disponibilidade e análise de custos fundamentada | Débora |
| Defesa técnica | 2,5 min | Perguntas do professor a integrantes sorteados | Todos |

## 8. Como destruir o ambiente

Ao terminar os testes, e obrigatoriamente em até 24 horas após a apresentação, destrua toda a infraestrutura.

**Passo 1 — Dentro da pasta `infra`, rodar:**

```bash
terraform destroy
```

Digite `yes` para confirmar. O bucket de backup é apagado junto, mesmo com arquivos dentro, porque está configurado com `force_destroy`.

**Passo 2 — Confirmar que não sobrou nada que gere custo.** Todos os comandos devem voltar vazios:

```bash
gcloud compute instances list
gcloud compute addresses list
gcloud compute routers list
gcloud compute disks list
gcloud compute snapshots list
gcloud storage buckets list
```

**Passo 3 —** Salvar a saída desses comandos (ou capturas de tela) na pasta `docs/evidencias/`, como prova da destruição.

> **Observação:** o keyring do Cloud KMS não pode ser apagado no Google Cloud, por regra do próprio Google. O Terraform destrói as chaves, mas o keyring continua aparecendo no console. Ele não gera custo.
