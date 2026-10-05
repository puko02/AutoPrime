# AutoPrime — Sistema de Gestão e Aluguel de Veículos de Luxo

Projeto desenvolvido para a disciplina de **Projeto Integrador: Trabalho Prático de Infraestrutura em Nuvem** da **Uniamérica Descomplica**, sob orientação do **Prof. Gildomiro Bairros**.

---

## 🚘 Sobre o Projeto

O **AutoPrime** é uma aplicação voltada para a gestão de estoques, vendas e exibição de catálogo público de uma locadora de veículos de luxo. O objetivo do sistema é permitir que o gestor mantenha a constância de vendas e controle de frota, oferecendo também um catálogo público para clientes realizarem consultas.

---

## 🏗️ Arquitetura e Tecnologias

A aplicação é estruturada em três contêineres Docker principais, distribuídos em uma arquitetura de rede em nuvem no **Google Cloud Platform (GCP)**:

- **Frontend:** Angular 19 (Servido via Nginx na sub-rede pública)
- **Backend:** Java 17 + Spring Boot 4.1.1 (Executado na sub-rede privada)
- **Banco de Dados:** MariaDB 13.0.2 (Executado na sub-rede privada)
- **Infraestrutura como Código (IaC):** Terraform

---

## 📁 Estrutura do Repositório

```text
.
├── README.md            # Identificação do grupo e visão geral do projeto
├── docs/                # Documentação técnica de arquitetura
│   ├── arquitetura.md   # Projeto de rede, segurança, instâncias e custos
│   ├── adr/             # Registros de Decisões Arquiteturais (ADRs)
│   ├── diagramas/       # Diagramas de arquitetura (imagem e arquivo editável)
│   └── custos/          # Estimativa e relatórios de custos da nuvem
└── infra/               # Scripts e arquivos do Terraform (Entrega 2)
# Declaração de Uso de Inteligência Artificial

## 1. Ferramentas Utilizadas
- **ChatGPT / Gemini / Claude** (especifique as que usaram)

## 2. Em quais partes do trabalho a IA foi aplicada
- **Pesquisa e Conceitos:** Utilizada para buscar explicações conceituais e bibliografia sobre componentes de rede (ex: funcionamento e utilidade do Cloud NAT Gateway e regras de sub-redes).
- **Estruturação de Documentação:** Auxílio na formatação e organização das seções do documento em Markdown.
- **Simulação de Perguntas para Apresentação:** Gerar possíveis questionamentos da banca/professor para treino da defesa técnica.

## 3. Verificações e Correções Realizadas pelo Grupo
- **Validação Técnica:** Todos os conceitos, sintaxes de comandos e detalhes de arquitetura gerados ou explicados pela IA foram revisados e validados na documentação oficial do Google Cloud Platform (GCP) e do Terraform.
- **Ajuste ao Contexto do Projeto:** As sugestões de custos, CIDRs e dimensionamento de instâncias foram ajustadas manualmente para refletir com exatidão a realidade da aplicação AutoPrime e as exigências do enunciado do Projeto Integrador.