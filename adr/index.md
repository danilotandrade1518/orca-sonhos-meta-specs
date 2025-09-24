# 📋 Índice de Documentação de Arquitetura - OrçaSonhos

---
**Metadados Estruturados para IA/RAG:**
```yaml
document_type: "architecture_decisions_index"
domain: "architecture_governance"
audience: ["architects", "developers", "tech_leads", "product_managers"]
complexity: "intermediate"
tags: ["adr", "architecture_decisions", "technical_decisions", "governance"]
related_docs: ["domain-ontology.md", "technical/index.md"]
ai_context: "Architecture Decision Records index for OrçaSonhos project governance"
decision_count: 11
chronological_range: "2024-2025"
last_updated: "2025-01-24"
```
---

Este diretório contém todos os Architecture Decision Records (ADRs) do projeto OrçaSonhos, organizados para auxiliar na compreensão das decisões arquiteturais e sua evolução.

## 📁 Documentos Disponíveis

### [`0001-definicao-stack-backend.md`](./0001-definicao-stack-backend.md)
**Definição da Stack de Backend Inicial**
- Escolha de Node.js, Express, TypeScript e Clean Architecture
- Decisão por MySQL sem ORM inicialmente
- Justificativa baseada em familiaridade da equipe e popularidade das tecnologias

### [`0002-refatoracao-testes-repositories.md`](./0002-refatoracao-testes-repositories.md)
**Refatoração de Testes nos Repositories**
- Estratégia de testes para camada de repositórios
- Padrões e práticas para garantir qualidade do código

### [`0003-escolha-eventemitter2-domain-events.md`](./0003-escolha-eventemitter2-domain-events.md)
**Escolha do EventEmitter2 para Domain Events**
- Implementação de eventos de domínio
- Justificativa para uso do EventEmitter2

### [`0004-escolha-postgresql-como-banco-de-dados.md`](./0004-escolha-postgresql-como-banco-de-dados.md)
**Escolha do PostgreSQL como Banco de Dados**
- Migração ou evolução da decisão de banco de dados
- Comparação com alternativas consideradas

### [`0005-separacao-add-save-repositories.md`](./0005-separacao-add-save-repositories.md)
**Separação entre Add e Save nos Repositories**
- Padrões de design para operações de persistência
- Separação de responsabilidades na camada de dados

### [`0006-remocao-domain-events.md`](./0006-remocao-domain-events.md)
**Remoção de Domain Events**
- Decisão de simplificar arquitetura removendo eventos de domínio
- Impactos e alternativas consideradas

### [`0007-infra-inicial-azure-appservice-postgres-b2c-keyvault.md`](./0007-infra-inicial-azure-appservice-postgres-b2c-keyvault.md)
**Infraestrutura Inicial - Azure AppService, PostgreSQL, B2C e KeyVault**
- Arquitetura de infraestrutura na nuvem Azure
- Serviços de autenticação, banco de dados e segurança

### [`0008-padrao-endpoints-mutations-post-comando.md`](./0008-padrao-endpoints-mutations-post-comando.md)
**Padrão de Endpoints - Mutations via POST com Comando**
- Padronização de APIs para operações de mutação
- Estrutura de comandos e responses

### [`0009-postergacoes-mvp-mutations-observabilidade.md`](./0009-postergacoes-mvp-mutations-observabilidade.md)
**Postergações para MVP - Mutations e Observabilidade**
- Decisões de escopo para versão inicial do produto
- Features adiadas para versões futuras

### [`0010-fluxo-autenticacao-spa-public-client.md`](./0010-fluxo-autenticacao-spa-public-client.md)
**Fluxo de Autenticação SPA - Public Client**
- Implementação de autenticação para aplicações SPA
- Integração com Azure B2C

### [`0011-postergacao-offline-first-mvp.md`](./0011-postergacao-offline-first-mvp.md)
**Postergação da Estratégia Offline-First para Pós-MVP**
- Decisão de focar em online-first para MVP
- Critérios para retomar implementação offline-first
- Estratégia de migração futura

## 🎯 Como Usar Este Índice

### Para Desenvolvedores
Consulte os ADRs de stack técnica (0001, 0004, 0007) para entender tecnologias e arquitetura, e padrões de código (0002, 0005, 0008) para implementação.

### Para Arquitetos de Software
Use os ADRs para entender evolução das decisões arquiteturais e contexto de cada escolha, especialmente 0003, 0006 para eventos de domínio.

### Para DevOps e Infraestrutura
Veja 0007 para compreender a arquitetura de infraestrutura na Azure e suas justificativas.

### Para Product Managers
Consulte 0009 e 0011 para entender decisões de escopo do MVP e features postergadas, incluindo offline-first.

---

**Última atualização:** 2025-09-24