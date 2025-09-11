# Visão Geral da Arquitetura

## Introdução

Este documento apresenta a arquitetura do backend do projeto OrçaSonhos, baseado em Node.js, Express, TypeScript, Clean Architecture e PostgreSQL.

## Fundamentos Arquiteturais

### Domain-Driven Design (DDD)

Utilizamos conceitos fundamentais do DDD:

- **Aggregates**: Cluster de entidades e value objects tratados como unidade
- **Entities**: Objetos com identidade única e ciclo de vida próprio
- **Value Objects**: Objetos imutáveis definidos por seus atributos
- **Repositories**: Abstração para persistência de agregados

### Command Query Responsibility Segregation (CQRS)

Separação clara entre operações de escrita e leitura:

- **Commands (Mutações)**: Tratados em Use Cases + Domain Services
- **Queries (Consultas)**: Tratados em Query Handlers dedicados
- **Sem Projeções Iniciais**: Consultas diretas ao banco transacional
- **Performance**: Query Handlers utilizam SQL nativo otimizado

### Clean Architecture

Organização em camadas com dependências apontando para o domínio:

```
┌─────────────────────────────────────┐
│           Interfaces (Web)          │  ← Controllers HTTP
├─────────────────────────────────────┤
│     Application (Use Cases)         │  ← Orquestração
├─────────────────────────────────────┤
│         Domain (Business)           │  ← Regras de negócio
├─────────────────────────────────────┤
│       Infrastructure               │  ← Persistência & Externos
└─────────────────────────────────────┘
```

## Separação de Responsabilidades

### Mutações vs Consultas

**Para Mutações de Estado:**
```
[Request] → [Controller] → [Use Case] → [Domain Service] → [Repository/UoW] → [Database]
```

**Para Consultas (Views):**
```
[Request] → [Controller] → [Query Handler] → [DAO] → [Database]
```

### Granularidade dos Componentes

**Use Cases**: Específicos por regra de negócio
- `CreateTransactionUseCase`
- `MarkTransactionLateUseCase`  
- `CancelScheduledTransactionUseCase`

**Repositories**: Genéricos por tipo de operação
- `IAddRepository` - Criação (INSERT)
- `ISaveRepository` - Atualização (UPDATE)  
- `IGetRepository` - Busca por ID
- `IFindRepository` - Consultas específicas
- `IDeleteRepository` - Remoção (DELETE)

## Tecnologias Core

- **Runtime**: Node.js + TypeScript
- **Framework**: Express.js
- **Database**: PostgreSQL
- **Authentication**: Firebase Auth
- **Error Handling**: Either Pattern (sem throw/try/catch)

## Princípios de Design

1. **Separation of Concerns**: Cada camada com responsabilidade específica
2. **Dependency Inversion**: Dependências apontam para abstrações
3. **Single Responsibility**: Componentes com propósito único e claro
4. **Explicit Intent**: Nomes expressam claramente a intenção de negócio

## Evolução e Manutenibilidade

Esta arquitetura foi desenhada para:
- **Escalabilidade**: Adição de novos agregados e operações
- **Testabilidade**: Isolamento e mocking facilitados  
- **Performance**: SQL otimizado + consultas eficientes
- **Clareza**: Expressão do domínio através do código

---

**Ver também:**
- [Directory Structure](./directory-structure.md) - Organização física dos arquivos
- [Layer Responsibilities](./layer-responsibilities.md) - Detalhes de cada camada
- [Domain Model](./domain-model.md) - Agregados e regras de negócio