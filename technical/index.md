# 🔧 Índice de Documentação Técnica - OrçaSonhos

Este diretório contém toda a documentação técnica do projeto OrçaSonhos, cobrindo arquitetura, stack, padrões e estratégias de implementação.

## 📁 Documentos Disponíveis

### [`backend-architecture/`](./backend-architecture/)

**Arquitetura do Backend**

- **[Index](./backend-architecture/index.md)** - Navegação completa por tópicos
- Clean Architecture com DDD e CQRS para Node.js/Express/TypeScript
- Domain Model, Repository Pattern, Unit of Work e Domain Services
- Autenticação Firebase, autorização multi-tenant e endpoints command-style
- SQL nativo otimizado para queries e pattern Either para erros

### [`frontend-architecture/`](./frontend-architecture/)

**Arquitetura do Frontend - Feature-Based**

- **[Index](./frontend-architecture/index.md)** - Navegação completa por tópicos e perfis
- **Feature-Based Architecture** com organização por funcionalidades de negócio
- SPA Angular com Clean Architecture (Models, Application, Infra, UI)
- Angular Material + Design System customizado, Firebase Auth e offline-first
- Mobile-first responsivo, MSW para mocks e Angular Signals para estado
- **[Implementation Guide](./frontend-architecture/implementation-guide.md)** - Guia passo a passo
- **[Feature Examples](./frontend-architecture/feature-examples.md)** - Exemplos práticos

### [`03_stack_tecnologico.md`](./03_stack_tecnologico.md)

**Stack Tecnológico Completo - Feature-Based**

- Frontend: Angular 20+, TypeScript, Angular Material, Signals, Feature-Based Architecture
- Backend: Node.js 22+, Express, PostgreSQL 16, Clean Architecture
- Ferramentas: Firebase Auth, Docker, GitHub Actions, ESLint/Prettier
- Feature Development: Lazy Loading, Feature Boundaries, Design System Integration

### [`04_estrategia_testes.md`](./04_estrategia_testes.md)

**Estratégia de Testes**

- Testes unitários (Vitest/Jest) com 80% cobertura mínima
- E2E com Playwright para fluxos críticos
- MSW para mocks de API e estratégia offline/PWA

### [`code-standards/`](./code-standards/)

**Padrões de Código e Convenções**

- **[Index](./code-standards/index.md)** - Navegação completa por contexto e perfil
- Nomenclatura (inglês obrigatório, PascalCase/camelCase/kebab-case)
- Estrutura de classes, imports e tratamento de erros com Either
- Padrões Angular modernos (Signals, inject(), control flow nativo)
- Validações, segurança, testes e checklist de code review

## 🎯 Como Usar Este Índice

### Para Desenvolvedores Backend

Consulte **[backend-architecture/index.md](./backend-architecture/index.md)** para navegação por tópicos arquiteturais, e **[code-standards/index.md](./code-standards/index.md)** para convenções específicas.

### Para Desenvolvedores Frontend

Consulte **[frontend-architecture/index.md](./frontend-architecture/index.md)** para navegação por tópicos arquiteturais, e **[code-standards/index.md](./code-standards/index.md)** para padrões Angular modernos.

### Para DevOps/Infraestrutura

Use **03_stack_tecnologico.md** para tecnologias e **04_estrategia_testes.md** para pipeline de CI/CD.

### Para Arquitetos/Tech Leads

Todos os documentos são relevantes para decisões arquiteturais e definição de padrões.

### Para QA/Testes

**04_estrategia_testes.md** define tipos de teste, ferramentas e **[code-standards/testing-standards.md](./code-standards/testing-standards.md)** contém convenções para testes.

---

**Última atualização:** 2025-09-10  
**Estrutura:** Documentação arquitetural modularizada em `backend-architecture/` e `frontend-architecture/` para otimização de contexto
