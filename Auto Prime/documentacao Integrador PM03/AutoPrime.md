# A aplicação

    A aplicação é uma ferramenta de aluguel de carros de luxo que serve para o trabalhador manter uma constância das vendas, uma aplicação de gerenciamento. As funcionalidades principais são manter o estoque, as vendas e um catálogo público dos veículos da locadora.

Os componentes são simples: Temos o sistema dividido em três contêineres no Docker: um para o front-end feito com Angular, um para o back-end feito com Spring Boot, e um para o banco de dados MariaDB. 

Pois é um sistema de gerenciamento, não é esperado muitos usuários ao mesmo tempo. Isto significa que não é necessário ter muita capacidade operacional, pois poucas pessoas estarão logadas e usuários sem conta só podem ver o catálogo, reduzindo as requisições por minuto.

# Plano de endereçamento IP

| Tipo de Rede | Nome da Rede | CIDR | Natureza da rede | Zona | Funcionalidade |
| ----- | ----- | ----- | ----- | ----- | ----- |
| Rede Virtual | vcp  | 10.0.0.0/16  | — — — — \- | us-west1 | Rede do Projeto |
| Sub-Rede | Open-1 | 10.0.1.0/24  | pública  | us-west1 | Bastion, Front-end, NAT Gateway |
| Sub-Rede | Closed-1 | 10.0.2.0/24 | privada  | us-west1 | Back-end API, Banco de Datos |

### Justificativas do tamanho:

- A Rede Virtual é /16 pois isso permite uma quantidade alta de IPs disponíveis caso seja necessário aumentar o tamanho das redes privadas ou públicas, o que deixa a quantidade de Máquinas Virtuais possíveis maior do utilizado atualmente.  
- As sub-redes utilizam /24 pois é mais limitado e reduz o custo. 

# Tabelas de rota

Se não existisse a rota para o Cloud NAT Gateway na tabela de rotas de sub-rede as instâncias do back-end e da database ficariam isoladas do tráfego de saída para a internet, o que resultaria em falhas de instalação e atualização de pacotes e a  impossibilidade de comunicação com APIs externas, mas a comunicação interna do front-end com o back-end e database continuaria funcionando através da rota local. 

# 

# Matriz de regras de segurança 

| Grupo de segurança | Direção | Protocolo | Porta | Origem/Destino | Justificativa |
| :---: | :---: | :---: | :---: | :---: | ----- |
| Bastion | Ingress (entrada) | TCP | 22 | IP Admin / Sub-rede pública  | Permite acesso remoto seguro (SSH) exclusivamente para administração da infraestrutura via bastion host |
| Front-end / Proxy | Ingress (entrada) | TCP | 80 / 443 | 0.0.0.0/0 (Internet) / Sub-rede pública | Permite que usuários acessem a interface web da aplicação via tráfego HTTP/HTTPS  |
| Back-end | Ingress (entrada) | TCP | 8080 / 22 | Sub-rede do Front-end / Nginx / Bastion Host | Permite requisições de API (porta 8080\) vindas apenas do Front-end/Nginx e acesso SSH (porta 22\) exclusivo via Bastion Host |
| Banco dados | Ingress (entrada) | TCP | 3306 | Sub-rede do Back-end  | O Banco de Dados é mantido em sub-rede privada e aceita conexões unicamente vindas da camada de Back-end |

# 

# Tecnologias

| Camada | Tecnologia | Versão | Justificativa |
| :---- | :---- | :---- | :---- |
| Provedor e Região | GCP na região Oregon us-west1 | M151 / 1.16.10 | Preço, possuí o menor valor, mesmo que sacrifique a latência  |
| Sistema Operacional | Ubuntu | ubuntu-2204-jammy-v20260731 | distribuição amplamente consolidada no mercado, oferecendo suporte de longo prazo (LTS), alta estabilidade e segurança  |
| Runtime/linguagem | Java, Springboot, Angular. | Java 17, Angular 19, Springboot 4.1.1 | Java 17 tem uma versão LTS  moderna, que tem um bom desempenho e melhorias em gerenciamento de memória e novos recursos de linguagem, que garante a estabilidade do backend. SpringBoot 4.1.1 tem um framework robusto pro desenvolvimento de microsserviços e APIs REST que acelera o desenvolvimento, possui recursos nativos de segurança e facilidade de integração. O Angular 19 tem o framework SPA (Single Page Application) moderno e fácil de usar mantido pelo Google e possui uma sólida arquitetura baseada em componentes, forte tipagem com TypeScript e otimizações de renderização do front  |
| Servidor web / proxy | Nginx | 1.30.5 | Servidor de altíssima performance, com baixo consumo de memória e alta capacidade de concorrência  |
| Banco de Dados | MariaDB | 13.0.2 | Sistema Gerenciador de Banco de Dados Relacional (SGBDR) open-source, altamente confiável e compatível com o MySQL |
| Infraestrutura como código | Terraform | 1.16.4 | Ferramenta líder de mercado para provisionamento de infraestrutura declarativa e automatizada  |
| Provider de Terraform | Google Cloud | 8.5.0 | Plugin oficial mantido para interação direta entre o Terraform e as APIs do GCP |
| Instalação da Aplicação | Virtual Machine | e2-medium | oferece um equilíbrio excelente entre custo e desempenho  |

# 

# 

# 

# 

#  Dimensionamento das instâncias

| Componente | Família | Tipo | vCPU | Memória | Disco(tipo e tamanho | Sub-rede | Justificativa |
| :---: | :---: | :---: | :---: | :---: | ----- | :---: | :---: |
| Bastion | E2 | e2-micro | 0,5 | 1gb | Standard persistent disk 10GB | pub | Bastion não precisa de muito processamento. |
| Aplicação | E2 | e2-small | 0,5 | 2gb | Standard persistent disk 10GB | Priv | A aplicação precisa de mais processamento pois os usuários estarão acessando. |
| Banco de Dados | E2 | e2-small | 0,5 | 2gb | Standard persistent disk 20GB | Priv | Precisa ter mais processamento pois será constantemente. |

Todos foram considerados na base do menor custo possível. 

# Registros de Decisão Arquitetural (ADRs)

Escolhemos o Bastion para lidar com o acesso administrativo não somente pelo custo, mas também pela experiência de utilizar tecnologias novas. Abrimos mão de facilidade e praticidade para abrir a porta do aprendizado.   
Utilizamos o NAT gerenciado porque, além de ser obrigatório pela entrega, ele é o mais prático, e possibilita uma escalabilidade mais fácil de gerenciar. NAT em instância teria o custo de uma VM nova, junto com todo o gerenciamento manual dela, o que é mais trabalhoso, e a ausência de saída não é muito interessante pois precisamos que as VMs consigam se conectar com a internet.   
O banco de dados foi feito na instância porque, além de ter conhecimento de como fazer isso, traz uma maior liberdade na hora de configurar, manipular e utilizar em geral o banco de dados. 

# Estimativa de custos

### A: operação contínua 

[Link Calculadora](https://cloud.google.com/products/calculator?dl=CjhDaVF6Wm1ObVlXTTFNQzB3TldZeUxUUTVaR1l0T0dFMlpDMWxOVEk0WWpFMk9UY3lOR1lRQVE9PRAIGiQ2NTA0RTVFOC0wODVGLTQwMjktQTgxRi1BRDRFNUE2MjEyQzk)

Os custos são:

-  Front-end: 36,27  
- Back-end: 72,53  
- Database. 72,53  
- Bastion: 36.27  
- NAT Gateway: 36,44

Os mais caros são o Database e o Back-end, com valores iguais. Foi discutido sobre como reduzir esses valores, mas a única forma de fazer isso é reduzir sua potência e suas capacidades de espaço. Sendo a parte mais crucial, e o espaço a parte mais importante em um sistema de gerenciamento de vendas, essas opções de redução de custo são inviáveis para nossa situação. Nossa solução para reduzir os custos é desligar as VMs quando não forem utilizadas, como poderia ser fora do horário de serviço da locadora.

### B: trabalho 

[Link Calculadora](https://cloud.google.com/products/calculator?dl=CjhDaVEzWVRRMk5UVmxOaTFsWkRKaUxUUTBNMll0T0RrNU5TMDRPVFUyT0RRMlpEY3hOeklRQVE9PRAIGiQ1OTA3NEMzNy04MDVBLTQ3NjUtQTUxQy1BNzZBM0Y1Njg3Q0U) 

Os custos são:

-  Front-end: 2,38  
- Back-end: 4,77  
- Database. 4,77  
- Bastion: 2,38  
- NAT Gateway: 36,44

O NAT Gateway é o mais caro agora pelo fato de ser gerenciado pela provedora; uma maneira de reduzir esse custo é diminuir o armazenamento ou mudar para o NAT em instância. Problemas são que preferimos ter o custo do armazenamento para ter certeza que não aconteçam gargalos ou caídas por falta de memória, e preferimos a facilidade e praticidade do NAT Gerenciado.

# Riscos e limitações

O sistema é monolítico, portanto, se uma VM cair, tudo cai junto. Não temos um balanceador de carga, o que limita a resistência a ataques DDoS e sobrecargas de sistema em dias extremamente movimentados, e por último, como está tudo em uma única zona (US-west), usuários em outras partes do mundo terão um aumento de latência.

# Declaração de uso de IA ( IA.md )

Utilizamos a IA para encontrar certas explicações de temas, como por exemplo NAT Gateway, onde pedimos a ela a bibliografia para poder estudar sobre isso.   
Por exemplo [este link da AWS que fala de NAT Gateway](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html).

—-----------------------------------—-----------------------------------—-----------------------------------

# Pequenas informações úteis

Nat Gateway: você define quantidade de ips publicos que serão utilizados, ele serve para conectar o back-end e a db que fica na sub-rede privada a internet, e define que o ip do front será público, 

Rede virtual é a camada superior, onde há as sub-redes

CIDR seria o / do ip tipo /24 tem 255 ips disponíveis e o /16 tem tipo 60k e por aí vai. Normalmente é interessante colocar o /16 na rede virtual e /24 nas sub-redes  
