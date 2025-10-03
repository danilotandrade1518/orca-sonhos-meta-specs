# 🎯 Padrões de Código - OrçaSonhos

Este índice organiza os padrões de código por contexto e responsabilidade, facilitando a consulta durante o desenvolvimento.

## 🏗️ Fundamentos

### **[Overview](./overview.md)**

Visão geral dos padrões, idioma obrigatório (inglês) e princípios fundamentais

### **[Naming Conventions](./naming-conventions.md)**

Convenções de nomenclatura para classes, métodos, variáveis, arquivos e estruturas de projeto

### **[Class Structure](./class-structure.md)**

Organização interna de classes, ordem de métodos e padrões de construção para Domain/Use Cases

## 🔧 Desenvolvimento

### **[Import Patterns](./import-patterns.md)**

Path aliases vs imports relativos, organização de imports e separação entre camadas

### **[Error Handling](./error-handling.md)**

Padrão Either obrigatório, hierarquia de erros e tratamento sem exceptions

### **[Code Style](./code-style.md)**

Formatação, quebras de linha, Prettier/ESLint e convenções de apresentação

### **[Comments Guidelines](./comments-guidelines.md)**

Quando NÃO comentar (regra geral), exceções permitidas e padrões JSDoc

## 🅰️ Angular Específico

### **[Angular Modern Patterns](./angular-modern-patterns.md)**

Signals, inject(), control flow nativo, componentes standalone, ChangeDetectionStrategy.OnPush e Feature-Based patterns

### **[Feature Patterns](./feature-patterns.md)**

Padrões específicos para Feature-Based Architecture, estrutura de features e comunicação entre features

### **[Design System Patterns](./design-system-patterns.md)**

Padrões do Design System com Atomic Design, componentes atoms/molecules/organisms e sistema de temas

### **[Performance Optimization](./performance-optimization.md)**

Angular Signals, computed values, lazy loading, tree shaking e otimizações

## 🏛️ Arquitetura

### **[Architectural Patterns](./architectural-patterns.md)**

Repository Pattern, Unit of Work, CQRS, Clean Architecture boundaries

### **[API Patterns](./api-patterns.md)**

Command-style endpoints, controllers RESTful e padrões de naming

### **[Security Standards](./security-standards.md)**

Validação em Value Objects, sanitização, headers seguros e token handling

## 🧪 Qualidade

### **[Testing Standards](./testing-standards.md)**

Nomenclatura de testes, estrutura AAA, mocking e padrões de asserção

### **[Validation Rules](./validation-rules.md)**

ESLint boundary rules, TypeScript strict mode e constraints arquiteturais

### **[Code Review Checklist](./code-review-checklist.md)**

Checklist completo para revisão de código organizado por categorias

---

## 🎯 Navegação por Perfil

### Para **Desenvolvedores Frontend**

🔥 **[Angular Modern Patterns](./angular-modern-patterns.md)** → **[Feature Patterns](./feature-patterns.md)** → **[Design System Patterns](./design-system-patterns.md)** → **[Naming Conventions](./naming-conventions.md)** → **[Performance Optimization](./performance-optimization.md)**

### Para **Desenvolvedores Backend**

🔥 **[Architectural Patterns](./architectural-patterns.md)** → **[Error Handling](./error-handling.md)** → **[API Patterns](./api-patterns.md)**

### Para **Tech Leads/Arquitetos**

🔥 **[Overview](./overview.md)** → **[Validation Rules](./validation-rules.md)** → **[Code Review Checklist](./code-review-checklist.md)**

### Para **QA/Testes**

🔥 **[Testing Standards](./testing-standards.md)** → **[Security Standards](./security-standards.md)** → **[Code Review Checklist](./code-review-checklist.md)**

### Para **Code Reviewers**

🔥 **[Code Review Checklist](./code-review-checklist.md)** → **[Naming Conventions](./naming-conventions.md)** → **[Class Structure](./class-structure.md)**

---

**Última atualização:** 2025-09-10  
**Estrutura:** Padrões organizados por contexto para consulta eficiente e otimização de contexto AI
