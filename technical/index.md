# 🔧 Índice de Documentação Técnica - OrçaSonhos

Este diretório contém toda a documentação técnica do projeto OrçaSonhos, cobrindo arquitetura, stack, padrões e estratégias de implementação.

## 📁 Documentos Disponíveis

### [`01_visao-arquitetural-backend.md`](./01_visao-arquitetural-backend.md)
**Arquitetura do Backend**
- Clean Architecture com DDD e CQRS para Node.js/Express/TypeScript
- Organização em agregados, use cases, repositories e unit of work
- Padrão Either para tratamento de erros e autorização por Firebase Auth
- Endpoints orientados a comando (POST) e estratégia de queries SQL nativo

### [`02_visao-arquitetural-frontend.md`](./02_visao-arquitetural-frontend.md) 
**Arquitetura do Frontend**
- SPA Angular com arquitetura em camadas (Models, Application, Infra, UI)
- Angular Material + CDK com camada de abstração customizada
- Offline-first com IndexedDB e mobile-first responsivo
- MSW para mocks, Angular Signals para estado e autenticação Firebase

### [`03_stack_tecnologico.md`](./03_stack_tecnologico.md)
**Stack Tecnológico Completo**
- Frontend: Angular 20+, TypeScript, Angular Material, Signals
- Backend: Node.js 22+, Express, PostgreSQL 16, Clean Architecture
- Ferramentas: Firebase Auth, Docker, GitHub Actions, ESLint/Prettier

### [`04_estrategia_testes.md`](./04_estrategia_testes.md)
**Estratégia de Testes**
- Testes unitários (Karma+Jasmine/Jest) com 80% cobertura mínima
- E2E com Playwright para fluxos críticos
- MSW para mocks de API e estratégia offline/PWA

### [`05_padroes_codigo.md`](./05_padroes_codigo.md)
**Padrões de Código e Convenções**
- Nomenclatura (inglês obrigatório, PascalCase/camelCase/kebab-case)
- Estrutura de classes, imports e tratamento de erros com Either
- Padrões Angular modernos (Signals, inject(), control flow nativo)

## 🎯 Como Usar Este Índice

### Para Desenvolvedores Backend
Consulte **01_visao-arquitetural-backend.md** para entender agregados e use cases, e **05_padroes_codigo.md** para convenções específicas.

### Para Desenvolvedores Frontend  
Veja **02_visao-arquitetural-frontend.md** para camadas e componentes, e **05_padroes_codigo.md** para padrões Angular modernos.

### Para DevOps/Infraestrutura
Use **03_stack_tecnologico.md** para tecnologias e **04_estrategia_testes.md** para pipeline de CI/CD.

### Para Arquitetos/Tech Leads
Todos os documentos são relevantes para decisões arquiteturais e definição de padrões.

### Para QA/Testes
**04_estrategia_testes.md** define tipos de teste, ferramentas e **05_padroes_codigo.md** contém convenções para testes.

---

**Última atualização:** 2025-09-08