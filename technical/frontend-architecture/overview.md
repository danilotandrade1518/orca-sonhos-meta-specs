# Visão Geral da Arquitetura Frontend

---

**Metadados Estruturados para IA/RAG:**

```yaml
document_type: "technical_architecture"
domain: "frontend_architecture"
audience: ["frontend_developers", "architects", "tech_leads"]
complexity: "intermediate"
tags:
  [
    "angular",
    "spa",
    "dto_first",
    "feature_based",
    "typescript",
    "architecture_patterns",
  ]
related_docs:
  [
    "domain-ontology.md",
    "directory-structure.md",
    "layer-responsibilities.md",
    "feature-organization.md",
  ]
ai_context: "Frontend architecture overview for Angular-based OrçaSonhos application using Feature-Based Architecture with DTO-First principles"
technologies: ["Angular", "TypeScript", "RxJS", "Angular Material", "Firebase"]
patterns:
  [
    "Feature-Based Architecture",
    "DTO-First Architecture",
    "CQRS",
    "Offline-First",
    "HTTP Adapters",
  ]
last_updated: "2025-01-24"
```

---

## Decisão Arquitetural Principal

O OrçaSonhos frontend é uma **Single Page Application (SPA)** em Angular com TypeScript, estruturada seguindo **Feature-Based Architecture** com princípios **DTO-First** para máxima simplicidade, alinhamento com o backend e escalabilidade.

## Princípios Fundamentais

### 1. Organização por Features

- **Features** são módulos independentes de funcionalidades de negócio
- **Lazy Loading** por feature para otimização de performance
- **Isolamento** de código relacionado em uma única localização
- **Escalabilidade** através de desenvolvimento paralelo de features

### 2. DTOs como Cidadãos de Primeira Classe

- **DTOs** representam contratos diretos com o backend
- **Estado da aplicação** trabalha diretamente com DTOs
- **Componentes** recebem e exibem DTOs sem transformações complexas
- **Simplicidade** através de estruturas de dados diretas

### 3. Arquitetura Feature-Based com DTO-First

```
┌─────────────────────────────────────┐
│              /src/app               │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐│
│  │/features│/shared   │/core      ││
│  │         │ │         │ │         ││
│  │┌───────┐│ │┌───────┐│ │┌───────┐││
│  ││budgets││ ││ui-comp││ ││services│││
│  ││transac││ ││theme  ││ ││guards  │││
│  ││goals  ││ ││utils  ││ ││interc  │││
│  │└───────┘│ │└───────┘│ │└───────┘││
│  └─────────┘ └─────────┘ └─────────┘│
└─────────────────────────────────────┘
```

### 4. Estrutura Interna das Features

Cada feature mantém a arquitetura DTO-First em camadas:

```
┌─────────────────────────────────────┐
│             UI (Components)         │ ← Componentes da feature
├─────────────────────────────────────┤
│        Infra (HTTP Adapters)        │ ← HTTP clients específicos
├─────────────────────────────────────┤
│    Application (Use Cases)          │ ← Orquestração da feature
├─────────────────────────────────────┤
│           DTOs (Contratos)          │ ← DTOs específicos da feature
└─────────────────────────────────────┘
```

### 5. Alinhamento Total com Backend via DTOs

- **CQRS**: Separação entre Commands (mutations) e Queries (reads)
- **Command-Style Endpoints**: `POST /<context>/<action>` para mutações
- **Contratos Diretos**: DTOs espelham exatamente a API do backend
- **Backend como Fonte da Verdade**: Todas as regras de negócio centralizadas no servidor

## Características Arquiteturais

### SPA com CSR (Client-Side Rendering)

- **Escopo inicial**: Apenas CSR para MVP
- **Evolução futura**: SSR/SEO com Angular Universal se necessário
- **Performance**: Lazy loading por feature para otimização de bundle

### Feature-Based Organization

- **Features Independentes**: Cada funcionalidade é um módulo isolado
- **Lazy Loading**: Features carregadas sob demanda
- **Desenvolvimento Paralelo**: Múltiplas features podem ser desenvolvidas simultaneamente
- **Manutenibilidade**: Código relacionado agrupado em uma localização

### UI System Strategy

- **Base**: Angular Material + Angular CDK
- **Abstração**: Camada de componentes `os-*` para reduzir coupling
- **Tema**: Customização com Design System próprio
- **Migração**: Path preparado para Design System independente

### Diretrizes Transversais (Obrigatórias)

#### Offline-First

- Toda aplicação deve operar **sem conexão**
- **Leitura** a partir de cache local (IndexedDB)
- **Escritas** enfileiradas para sincronização quando rede voltar
- **Experiência** consistente independente do estado da rede

#### Mobile-First e Responsividade

- **Prioridade**: Design para telas pequenas primeiro
- **Adaptação**: Fluente para diferentes breakpoints
- **Performance**: Otimizada para redes móveis
- **Gestos**: Naturais e acessíveis

## Stack Tecnológica Core

### Framework e Linguagem

- **Angular** (versão atual do projeto)
- **TypeScript** para todo o código
- **RxJS** apenas onde Angular exige (HTTP, routing)

### Angular Features Utilizadas

- **Standalone Components** (evitar NgModules)
- **Angular Signals** para estado reativo
- **Modern Angular**: `input()`, `output()`, `@if/@for/@switch`
- **ChangeDetection**: OnPush strategy por padrão
- **Dependency Injection**: `inject()` function preferível a constructor

### UI e Styling

- **Angular Material** como base de componentes
- **Angular CDK** para funcionalidades avançadas
- **SCSS** para customização de tema
- **CSS Custom Properties** para design tokens

## Padrões de Estado

### Estado Local com DTOs (Preferencial)

```typescript
// Por página/feature com Angular Signals usando DTOs diretamente
@Component({...})
export class BudgetListPage {
  private budgets = signal<BudgetResponseDto[]>([]);
  private loading = signal(false);

  // Estado computado
  protected totalBudgets = computed(() => this.budgets().length);
}
```

### Cache Application Layer

```typescript
// Cache leve em Commands/Queries trabalhando com DTOs
export class GetBudgetListQuery {
  private cache = new Map<string, BudgetResponseDto[]>();
  // ...
}
```

### Estado Global (Apenas se Necessário)

- **Critério**: Apenas dados verdadeiramente compartilhados
- **Exemplos válidos**: Usuário autenticado, configurações globais
- **Store**: NgRx Signals Store quando necessário (não por padrão)
- **DTOs**: Estado global também usa DTOs diretamente

## Integração com Backend

### Autenticação

- **Firebase Authentication** com fluxo redirect
- **Tokens**: Apenas em memória (session persistence)
- **Stateless Backend**: ID Token enviado em cada request

### Comunicação de Dados

- **Commands**: `POST /<aggregate>/<action>` para mutações
- **Queries**: `GET` endpoints ou queries especializadas
- **Error Handling**: Pattern Either/Result propagado do backend
- **DTOs Diretos**: Sem mapeamentos complexos, DTOs fluem diretamente

### Contratos

- **Client Generation**: OpenAPI quando disponível
- **DTOs TypeScript**: Interfaces que espelham exatamente a API
- **Money Values**: `number` em centavos (R$ 10,50 = 1050)
- **Datas**: `string` ISO (2024-01-15T10:30:00.000Z)
- **Enums**: `string` literals ("INCOME" | "EXPENSE")

## Mock e Desenvolvimento

### MSW (Mock Service Worker)

- **Desenvolvimento**: Mocks realistas interceptando fetch
- **Testes**: Workers inicializados automaticamente
- **Organização**: Handlers por contexto de negócio
- **Assets**: `public/mockServiceWorker.js` servido com app

### Feature Flags

- **AUTH_DISABLED**: Desabilita Firebase Auth para desenvolvimento
- **MSW_ENABLED**: Habilita mocks de API
- **Flexibilidade**: Desenvolvimento independente do backend

## Evoluções Planejadas

### Curto Prazo (MVP)

- ✅ Angular Material com abstração `os-*`
- ✅ Firebase Auth + Offline-first
- ✅ MSW para mocks realistas
- ✅ DTO-First Architecture implementada
- 🔄 **Feature-Based Architecture**: Migração em andamento

### Médio Prazo

- 🔄 **Design System Próprio**: Migração mantendo API dos componentes
- 🔄 **SSR/SEO**: Angular Universal para páginas públicas
- 🔄 **Advanced PWA**: Background sync, push notifications
- 🔄 **OpenAPI Integration**: Geração automática de DTOs
- 🔄 **Feature Maturity**: Features completamente isoladas e testáveis

### Longo Prazo

- 🚀 **Workspaces**: Extração de features para pacotes independentes
- 🚀 **Micro-Frontends**: Features como micro-frontends independentes
- 🚀 **Type-Safe APIs**: Contratos compartilhados entre frontend e backend
- 🚀 **Feature Marketplace**: Reutilização de features entre projetos

---

**Ver também:**

- [Directory Structure](./directory-structure.md) - Como organizar o código por features
- [Layer Responsibilities](./layer-responsibilities.md) - O que cada camada faz
- [Feature Organization](./feature-organization.md) - Como organizar features independentes
- [UI System](./ui-system.md) - Strategy do Design System e componentes
- [State Management](./state-management.md) - Estratégia de estado com Angular Signals
