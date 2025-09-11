# Visão Geral da Arquitetura Frontend

## Decisão Arquitetural Principal

O OrçaSonhos frontend é uma **Single Page Application (SPA)** em Angular com TypeScript, estruturada seguindo **Clean Architecture / Hexagonal Architecture** aplicada ao contexto frontend.

## Princípios Fundamentais

### 1. Isolamento do Core Domain
- **Regras de negócio** em TypeScript puro, sem dependências de framework
- **Domain Models** e **Value Objects** independentes de Angular
- **Business Logic** testável isoladamente

### 2. Arquitetura em Camadas
```
┌─────────────────────────────────────┐
│             UI (Angular)            │ ← Componentes, páginas, roteamento
├─────────────────────────────────────┤
│        Infra (Adapters)             │ ← HTTP, storage, auth providers  
├─────────────────────────────────────┤
│    Application (Use Cases/Queries)  │ ← Orquestração, ports/contracts
├─────────────────────────────────────┤
│        Models (Domain)              │ ← Entities, VOs, regras de negócio
└─────────────────────────────────────┘
```

### 3. Alinhamento com Backend
- **CQRS**: Separação entre Commands (mutations) e Queries (reads)
- **Command-Style Endpoints**: `POST /<context>/<action>` para mutações  
- **Domain Alignment**: Mesmo vocabulário ubíquo entre front e back

## Características Arquiteturais

### SPA com CSR (Client-Side Rendering)
- **Escopo inicial**: Apenas CSR para MVP
- **Evolução futura**: SSR/SEO com Angular Universal se necessário
- **Performance**: Lazy loading por feature/contexto

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

### Estado Local (Preferencial)
```typescript
// Por página/feature com Angular Signals
@Component({...})
export class BudgetListPage {
  private budgets = signal<Budget[]>([]);
  private loading = signal(false);
  
  // Estado computado
  protected totalBudgets = computed(() => this.budgets().length);
}
```

### Cache Application Layer
```typescript
// Cache leve em Use Cases quando faz sentido
export class GetBudgetListUseCase {
  private cache = new Map<string, Budget[]>();
  // ...
}
```

### Estado Global (Apenas se Necessário)
- **Critério**: Apenas dados verdadeiramente compartilhados
- **Exemplos válidos**: Usuário autenticado, configurações globais
- **Store**: NgRx Signals Store quando necessário (não por padrão)

## Integração com Backend

### Autenticação
- **Firebase Authentication** com fluxo redirect
- **Tokens**: Apenas em memória (session persistence)
- **Stateless Backend**: ID Token enviado em cada request

### Comunicação de Dados
- **Commands**: `POST /<aggregate>/<action>` para mutações
- **Queries**: `GET` endpoints ou queries especializadas  
- **Error Handling**: Pattern Either/Result propagado do backend

### Contratos
- **Client Generation**: OpenAPI quando disponível
- **Temporary**: Tipos e mapeadores explícitos
- **Money Values**: Trafego em centavos (integer)

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

### Médio Prazo  
- 🔄 **Design System Próprio**: Migração mantendo API dos componentes
- 🔄 **SSR/SEO**: Angular Universal para páginas públicas
- 🔄 **Advanced PWA**: Background sync, push notifications

### Longo Prazo
- 🚀 **Workspaces**: Extração de camadas para pacotes independentes
- 🚀 **Micro-Frontends**: Se necessário para escalabilidade de times

---

**Ver também:**
- [Directory Structure](./directory-structure.md) - Como organizar o código nas camadas
- [Layer Responsibilities](./layer-responsibilities.md) - O que cada camada faz
- [UI System](./ui-system.md) - Strategy do Design System e componentes