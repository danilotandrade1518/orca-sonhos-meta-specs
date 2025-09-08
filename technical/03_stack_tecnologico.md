# Stack Tecnol�gico - Or�aSonhos

## Frontend

### Core
- **Angular 20+** - Framework principal SPA
- **TypeScript** - Linguagem de desenvolvimento
- **Angular Material + CDK** - Sistema de UI (com camada de abstra��o)
- **Angular Signals** - Gerenciamento de estado reativo

### Build & Development
- **Angular CLI** - Toolchain e build system
- **Vite** - Build tool e dev server (se aplic�vel)
- **ESLint** - Linting de c�digo
- **Prettier** - Formata��o de c�digo
- **Karma + Jasmine** - Testes unit�rios
- **Playwright** - Testes E2E

### Networking & Mocks
- **Fetch API** - Cliente HTTP (via `FetchHttpClient`)
- **MSW (Mock Service Worker)** - Mocks de API para desenvolvimento e testes

### PWA & Offline
- **Angular Service Worker** - Cache e funcionalidades PWA
- **IndexedDB** - Armazenamento local offline-first

## Backend

### Core
- **Node.js 22+** - Runtime JavaScript
- **Express.js** - Framework web
- **TypeScript** - Linguagem de desenvolvimento

### Database
- **PostgreSQL 16** - Banco de dados principal
- **SQL nativo** - Queries otimizadas (sem ORM)

### Arquitetura
- **Clean Architecture** - Separa��o em camadas
- **DDD patterns** - Aggregates, Entities, Value Objects
- **CQRS** - Separa��o Commands/Queries

### Testes
- **Jest** - Framework de testes
- **Supertest** - Testes de integra��o HTTP

## Autentica��o & Seguran�a

- **Firebase Authentication** - Provedor de identidade
- **Firebase Admin SDK** - Valida��o de tokens no backend
- **JWT** - ID Tokens para autentica��o stateless

## Ferramentas de Desenvolvimento

### Code Quality
- **ESLint** - Linting (frontend/backend)
- **Prettier** - Formata��o de c�digo
- **Husky** - Git hooks
- **TypeScript** - Verifica��o de tipos

### Monorepo/Workspace
- **Path aliases** - Imports entre camadas
- **Boundary rules** - Valida��o de depend�ncias via ESLint

## Infraestrutura & Deploy

### Containeriza��o
- **Docker** - Containeriza��o de aplica��es
- **Docker Compose** - Orquestra��o local

### CI/CD
- **GitHub Actions** - Pipeline de CI/CD
- **Automated testing** - Testes automatizados no pipeline

### Monitoramento
- **Structured logging** - Logs estruturados
- **Error tracking** - Rastreamento de erros
- **Performance metrics** - M�tricas de aplica��o

## Ambiente de Desenvolvimento

### Package Management
- **npm/pnpm** - Gerenciamento de pacotes
- **Node.js 22+** - Runtime m�nimo

### Editor/IDE
- **VS Code** - Editor recomendado
- **Angular Language Service** - Suporte Angular
- **TypeScript Language Service** - Suporte TypeScript

## Arquivos de Configura��o

- **angular.json** - Configura��o Angular
- **tsconfig.json** - Configura��o TypeScript
- **eslint.config.js** - Configura��o ESLint
- **package.json** - Depend�ncias e scripts
- **docker-compose.yml** - Orquestra��o local
- **.env** - Vari�veis de ambiente

## Observa��es

- Stack orientado para **desenvolvimento full-stack TypeScript**
- **Offline-first** e **mobile-first** como princ�pios transversais
- **Clean Architecture** aplicada tanto no frontend quanto backend
- **Testabilidade** como prioridade em todas as camadas