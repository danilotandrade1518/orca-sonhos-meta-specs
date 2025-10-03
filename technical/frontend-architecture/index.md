# 🎯 Índice da Arquitetura Frontend - OrçaSonhos

Este diretório contém a documentação modular da arquitetura frontend **Feature-Based**, organizada em tópicos especializados para otimizar o contexto de desenvolvimento assistido por IA.

## 🏗️ Arquitetura Core

### **[Overview](./overview.md)**

Visão geral da **Feature-Based Architecture**, princípios arquiteturais e decisões fundamentais da SPA Angular com Clean Architecture

### **[Directory Structure](./directory-structure.md)**

Organização de diretórios por **features**, separação de camadas (core, shared, features, layouts) e estrutura evolutiva

### **[Layer Responsibilities](./layer-responsibilities.md)**

Responsabilidades das camadas Clean Architecture aplicada ao frontend: Core, Shared, Features, Layouts

### **[Data Flow](./data-flow.md)**

Fluxos de Commands/Queries entre **features**, estados com Angular Signals e integração com backend CQRS

### **[Feature Organization](./feature-organization.md)**

Organização e estrutura interna das features, padrões de comunicação e isolamento de funcionalidades

## 🔌 Integração e Serviços

### **[Backend Integration](./backend-integration.md)**

Contratos de API, Ports/Adapters, HttpClient customizado e alinhamento com endpoints command-style

### **[Authentication](./authentication.md)**

Firebase Auth com fluxo redirect, tokens em memória, guardas de rota e feature flags de desenvolvimento

### **[Offline Strategy](./offline-strategy.md)**

**[POSTERGADO PARA PÓS-MVP]** Offline-first com IndexedDB, fila de comandos, sincronização e resolução de conflitos

## 🎨 UI e Design System

### **[UI System](./ui-system.md)**

Angular Material + camada de abstração, componentes os-\*, tema customizado e strategy de migração futura

### **[Design System Integration](./design-system-integration.md)**

Integração do Design System com features, padrões de uso de componentes shared e estratégia de migração

### **[State Management](./state-management.md)**

Estratégia de estado com Angular Signals, estado local vs global e padrões de cache por feature

### **[Responsive Design](./responsive-design.md)**

Mobile-first, responsividade completa, performance em rede móvel e padrões de UI adaptativa

### **[Accessibility](./accessibility.md)**

Requisitos a11y, testes de teclado/foco e tokens de design para contraste

## 🧪 Desenvolvimento e Qualidade

### **[Testing Strategy](./testing-strategy.md)**

Testes unitários, MSW para mocks de API, cobertura e estratégia E2E com Playwright

### **[Feature Testing Patterns](./feature-testing-patterns.md)**

Padrões específicos para testes de features, mocks, factories e helpers de teste

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

## 🚀 Guias de Implementação

### **[Implementation Guide](./implementation-guide.md)**

Guia passo a passo para implementar Feature-Based Architecture, configuração inicial e exemplos práticos

### **[Feature Examples](./feature-examples.md)**

Exemplos completos de features (simples, complexas, com estado) e padrões de implementação

## 📍 Guias de Uso por Contexto

### Para Desenvolvedores Frontend

1. **[Overview](./overview.md)** - Entender princípios fundamentais da Feature-Based Architecture
2. **[Implementation Guide](./implementation-guide.md)** - Guia passo a passo para implementar
3. **[Feature Examples](./feature-examples.md)** - Exemplos práticos de implementação
4. **[Directory Structure](./directory-structure.md)** + **[Layer Responsibilities](./layer-responsibilities.md)** - Organização por features
5. **[Feature Organization](./feature-organization.md)** - Estrutura interna das features
6. **[State Management](./state-management.md)** - Gerenciamento de estado com Angular Signals
7. **[UI System](./ui-system.md)** - Componentes e Design System
8. **[Feature Testing Patterns](./feature-testing-patterns.md)** - Padrões de teste para features
9. Demais arquivos conforme necessidade específica

### Para UI/UX Designers

1. **[UI System](./ui-system.md)** - Design System e componentes
2. **[Design System Integration](./design-system-integration.md)** - Integração com features
3. **[Responsive Design](./responsive-design.md)** - Mobile-first e adaptabilidade
4. **[Accessibility](./accessibility.md)** - Requisitos de acessibilidade

### Para DevOps/Infraestrutura

1. **[Performance](./performance.md)** - Build e otimizações
2. **[Environment Configuration](./environment-configuration.md)** - Configurações e deploys
3. **[Offline Strategy](./offline-strategy.md)** - PWA e Service Workers

### Para QA/Testes

1. **[Testing Strategy](./testing-strategy.md)** - Estratégias e ferramentas de teste
2. **[MSW Configuration](./msw-configuration.md)** - Mocks e dados de teste
3. **[Naming Conventions](./naming-conventions.md)** - Convenções para testes

### Para Arquitetos/Tech Leads

1. **[Overview](./overview.md)** - Princípios arquiteturais
2. **[Feature Organization](./feature-organization.md)** - Organização e comunicação entre features
3. **[Data Flow](./data-flow.md)** - Fluxos de dados e integração
4. **[State Management](./state-management.md)** - Estratégias de estado
5. Todos os demais documentos conforme necessidade específica

---

**Esta documentação modular substitui completamente o documento único original, otimizando o contexto para desenvolvimento assistido por IA.**
