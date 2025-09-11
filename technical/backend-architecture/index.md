# Backend Architecture Index

Este índice organiza toda a documentação arquitetural do backend OrçaSonhos para facilitar navegação e otimizar contexto para desenvolvimento com IA.

## Core Architecture

### Fundamentos
- **[Overview](./overview.md)** - Clean Architecture, DDD, CQRS e conceitos base
- **[Directory Structure](./directory-structure.md)** - Organização de diretórios e responsabilidades
- **[Layer Responsibilities](./layer-responsibilities.md)** - Domain, Application, Web e Infra
- **[Data Flow](./data-flow.md)** - Fluxos de mutação vs query patterns

## Domain & Business Logic

### Modelagem e Regras
- **[Domain Model](./domain-model.md)** - Agregados, relacionamentos e invariantes de negócio
- **[Domain Services](./domain-services.md)** - Coordenação entre entidades e regras complexas
- **[Error Handling](./error-handling.md)** - Pattern Either para tratamento consistente

## Data Access Patterns

### Persistência e Consultas
- **[Repository Pattern](./repository-pattern.md)** - Add, Save, Get, Find, Delete com granularidade adequada
- **[Unit of Work](./unit-of-work.md)** - Operações multi-agregado com atomicidade
- **[DAO vs Repository](./dao-vs-repository.md)** - Quando usar cada padrão
- **[Query Strategy](./query-strategy.md)** - SQL nativo otimizado para performance

## API & Security

### Interfaces e Autenticação
- **[API Endpoints](./api-endpoints.md)** - Padrão command-style para mutations
- **[Authentication](./authentication.md)** - Firebase Auth com fluxo SPA stateless
- **[Authorization](./authorization.md)** - Multi-tenancy por Budget

## Development Guidelines

### Convenções e Padrões
- **[Conventions](./conventions.md)** - Nomenclatura, imports, testes e organização

---

## Como Usar Este Índice

### Para Implementação Focada
Use arquivos específicos quando trabalhando em:
- **CRUD operations** → `repository-pattern.md`
- **Complex business rules** → `domain-services.md`  
- **Multi-aggregate operations** → `unit-of-work.md`
- **Query optimization** → `query-strategy.md`

### Para Contexto Amplo
Combine arquivos relacionados quando precisar de visão abrangente:
- **Data layer** → `repository-pattern.md` + `unit-of-work.md` + `query-strategy.md`
- **Domain layer** → `domain-model.md` + `domain-services.md`
- **API layer** → `api-endpoints.md` + `authentication.md` + `authorization.md`

### Para Onboarding
Sequência recomendada para novos desenvolvedores:
1. `overview.md` - Conceitos fundamentais
2. `directory-structure.md` + `layer-responsibilities.md` - Organização
3. `domain-model.md` - Entendimento do negócio
4. Demais arquivos conforme necessidade específica

---

**Esta documentação modular substitui completamente o documento único original, otimizando o contexto para desenvolvimento assistido por IA.**