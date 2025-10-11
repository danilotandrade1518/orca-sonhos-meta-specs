# Stack Tecnológico - OrçaSonhos

---

**Metadados Estruturados para IA/RAG:**

```yaml
document_type: "technical_stack"
domain: "technology_architecture"
audience: ["developers", "architects", "devops", "tech_leads"]
complexity: "intermediate"
tags:
  [
    "technology_stack",
    "frontend",
    "backend",
    "infrastructure",
    "tools",
    "dependencies",
  ]
related_docs:
  [
    "backend-architecture/index.md",
    "frontend-architecture/index.md",
    "04_estrategia_testes.md",
  ]
ai_context: "Complete technology stack and tools used in OrçaSonhos project"
stack_layers: ["frontend", "backend", "database", "infrastructure", "devops"]
last_updated: "2025-01-24"
```

---

## Frontend

### Core

- **Angular 20+** - Framework principal SPA
- **TypeScript** - Linguagem de desenvolvimento
- **Angular Material + CDK** - Sistema de UI (com camada de abstração)
- **Angular Signals** - Gerenciamento de estado reativo

### Arquitetura

- **Feature-Based Architecture** - Organização por funcionalidades de negócio
- **DTO-First Architecture** - DTOs como cidadãos de primeira classe
- **Lazy Loading** - Features carregadas sob demanda
- **Clean Boundaries** - Separação clara entre features e shared

### Build & Development

- **Angular CLI** - Toolchain e build system
- **Vite** - Build tool e dev server (se aplicável)
- **ESLint** - Linting de código
- **Prettier** - Formatação de código
- **Vitest** - Testes unitários
- **Playwright** - Testes E2E

### Networking & Mocks

- **Fetch API** - Cliente HTTP (via `FetchHttpClient`)
- **MSW (Mock Service Worker)** - Mocks de API para desenvolvimento e testes

### PWA & Offline

- **Angular Service Worker** - Cache e funcionalidades PWA
- **IndexedDB** - Armazenamento local offline-first

### Feature-Based Development

- **Angular Modules** - Organização modular por features
- **Lazy Loading Routes** - Carregamento sob demanda de features
- **Feature Guards** - Proteção de rotas por feature
- **Feature Services** - Serviços específicos por feature
- **Shared Services** - Serviços compartilhados entre features
- **Design System Integration** - Componentes reutilizáveis por feature

## Backend

### Core

- **Node.js 22+** - Runtime JavaScript
- **Express.js** - Framework web
- **TypeScript** - Linguagem de desenvolvimento

### Database

- **PostgreSQL 16** - Banco de dados principal
- **SQL nativo** - Queries otimizadas (sem ORM)

### Arquitetura

- **Clean Architecture** - Separação em camadas
- **DDD patterns** - Aggregates, Entities, Value Objects
- **CQRS** - Separação Commands/Queries

### Testes

- **Jest** - Framework de testes
- **Supertest** - Testes de integração HTTP

## Autenticação & Segurança

- **Firebase Authentication** - Provedor de identidade
- **Firebase Admin SDK** - Validação de tokens no backend
- **JWT** - ID Tokens para autenticação stateless

## Ferramentas de Desenvolvimento

### Code Quality

- **ESLint** - Linting (frontend/backend)
- **Prettier** - Formatação de código
- **Husky** - Git hooks
- **TypeScript** - Verificação de tipos

### Monorepo/Workspace

- **Path aliases** - Imports entre camadas e features
- **Boundary rules** - Validação de dependências via ESLint
- **Feature boundaries** - Validação de dependências entre features
- **Import restrictions** - Regras de import entre features e shared

## Infraestrutura & Deploy

### Containerização

- **Docker** - Containerização de aplicações
- **Docker Compose** - Orquestração local

### CI/CD

- **GitHub Actions** - Pipeline de CI/CD
- **Automated testing** - Testes automatizados no pipeline

### Monitoramento

- **Structured logging** - Logs estruturados
- **Error tracking** - Rastreamento de erros
- **Performance metrics** - Métricas de aplicação

## Ambiente de Desenvolvimento

### Package Management

- **npm/pnpm** - Gerenciamento de pacotes
- **Node.js 22+** - Runtime mínimo

### Editor/IDE

- **VS Code** - Editor recomendado
- **Angular Language Service** - Suporte Angular
- **TypeScript Language Service** - Suporte TypeScript

## Arquivos de Configuração

- **angular.json** - Configuração Angular
- **tsconfig.json** - Configuração TypeScript
- **eslint.config.js** - Configuração ESLint
- **package.json** - Dependências e scripts
- **docker-compose.yml** - Orquestração local
- **.env** - Variáveis de ambiente

### Configurações Feature-Based

- **tsconfig.paths.json** - Path aliases para features e shared
- **eslint.feature-boundaries.js** - Regras de dependência entre features
- **angular-lazy-loading.json** - Configuração de lazy loading por feature
- **feature-modules.config.js** - Configuração de módulos por feature

## Observações

- Stack orientado para **desenvolvimento full-stack TypeScript**
- **Offline-first** e **mobile-first** como princípios transversais
- **Clean Architecture** aplicada tanto no frontend quanto backend
- **Testabilidade** como prioridade em todas as camadas
- **Feature-Based Architecture** para melhor escalabilidade e manutenibilidade
- **DTO-First** mantido como princípio fundamental
- **Lazy Loading** para otimização de performance
- **Design System** isolado para reutilização entre features
