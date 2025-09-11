# 🎯 Índice da Arquitetura Frontend - OrçaSonhos

Este diretório contém a documentação modular da arquitetura frontend, organizada em tópicos especializados para otimizar o contexto de desenvolvimento assistido por IA.

## 🏗️ Arquitetura Core

### **[Overview](./overview.md)**
Visão geral, princípios arquiteturais e decisões fundamentais da SPA Angular com Clean Architecture

### **[Directory Structure](./directory-structure.md)** 
Organização de diretórios, separação de camadas (models, application, infra, app) e estrutura evolutiva

### **[Layer Responsibilities](./layer-responsibilities.md)**
Responsabilidades das camadas Clean Architecture aplicada ao frontend: Models, Application, Infra, UI

### **[Data Flow](./data-flow.md)**
Fluxos de Commands/Queries, estados com Angular Signals e integração com backend CQRS

## 🔌 Integração e Serviços

### **[Backend Integration](./backend-integration.md)**
Contratos de API, Ports/Adapters, HttpClient customizado e alinhamento com endpoints command-style

### **[Authentication](./authentication.md)**
Firebase Auth com fluxo redirect, tokens em memória, guardas de rota e feature flags de desenvolvimento

### **[Offline Strategy](./offline-strategy.md)**
Offline-first com IndexedDB, fila de comandos, sincronização e resolução de conflitos

## 🎨 UI e Design System

### **[UI System](./ui-system.md)**
Angular Material + camada de abstração, componentes os-*, tema customizado e strategy de migração futura

### **[Responsive Design](./responsive-design.md)**
Mobile-first, responsividade completa, performance em rede móvel e padrões de UI adaptativa

### **[Accessibility](./accessibility.md)**
Requisitos a11y, testes de teclado/foco e tokens de design para contraste

## 🧪 Desenvolvimento e Qualidade

### **[Testing Strategy](./testing-strategy.md)**
Testes unitários, MSW para mocks de API, cobertura e estratégia E2E com Playwright

### **[MSW Configuration](./msw-configuration.md)**
Mock Service Worker: organização de handlers, inicialização e convenções de desenvolvimento

### **[Performance](./performance.md)**
Build otimizado, lazy loading, tree-shaking, Angular Signals e estratégias de performance

## 📋 Padrões e Convenções

### **[Naming Conventions](./naming-conventions.md)**
Nomenclatura em inglês, padrões de arquivos/classes/interfaces e convenções Angular modernas

### **[Dependency Rules](./dependency-rules.md)** 
Boundaries entre camadas, ESLint rules e path aliases para isolamento arquitetural

### **[Environment Configuration](./environment-configuration.md)**
Variáveis de ambiente, feature flags e configurações de desenvolvimento

## 🔄 Funcionalidades Avançadas

### **[Modules and Features](./modules-features.md)**
Organização por contexto de negócio, lazy loading e estrutura de páginas/widgets

### **[Internationalization](./internationalization.md)**
i18n strategy, formatação de dados e neutralidade de Domain/Application

## 📍 Guias de Uso por Contexto

### Para Desenvolvedores Frontend
1. **[Overview](./overview.md)** - Entender princípios fundamentais
2. **[Directory Structure](./directory-structure.md)** + **[Layer Responsibilities](./layer-responsibilities.md)** - Organização do código
3. **[UI System](./ui-system.md)** - Componentes e Design System
4. Demais arquivos conforme necessidade específica

### Para UI/UX Designers
1. **[UI System](./ui-system.md)** - Design System e componentes
2. **[Responsive Design](./responsive-design.md)** - Mobile-first e adaptabilidade
3. **[Accessibility](./accessibility.md)** - Requisitos de acessibilidade

### Para DevOps/Infraestrutura
1. **[Performance](./performance.md)** - Build e otimizações
2. **[Environment Configuration](./environment-configuration.md)** - Configurações e deploys
3. **[Offline Strategy](./offline-strategy.md)** - PWA e Service Workers

### Para QA/Testes
1. **[Testing Strategy](./testing-strategy.md)** - Estratégias e ferramentas de teste
2. **[MSW Configuration](./msw-configuration.md)** - Mocks e dados de teste
3. **[Naming Conventions](./naming-conventions.md)** - Convenções para testes

### Para Arquitetos/Tech Leads
Todos os documentos são relevantes para decisões arquiteturais e padrões do frontend.

---

**Esta documentação modular substitui completamente o documento único original, otimizando o contexto para desenvolvimento assistido por IA.**