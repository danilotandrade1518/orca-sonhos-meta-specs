# Organização de Diretórios

## Estrutura Proposta (Evolutiva)

A estrutura mantém o projeto Angular atual e adiciona camadas puras ao lado de `src/app`, seguindo Clean Architecture:

```
/src
  /models                 # 🔵 Regras de negócio puras (TS)
    /entities             # Domain entities (Budget, Account, Transaction)
    /value-objects        # Money, TransactionType, AccountType
    /policies             # Business rules e validações
    
  /application            # 🟡 Use cases e orquestração
    /use-cases            # Commands (CreateTransactionUseCase)
    /queries              # Query handlers (GetBudgetSummaryQuery) 
    /dtos                 # Data Transfer Objects
    /ports                # Interfaces para infra (IBudgetServicePort)
    /mappers              # Domain ↔ DTO conversions
    
  /infra                  # 🟠 Adapters e implementações
    /adapters             # HTTP, storage, auth providers
      /http               # HttpBudgetServiceAdapter
      /storage            # LocalStoreAdapter (IndexedDB)
      /auth               # FirebaseAuthAdapter
    /mappers              # API ↔ Domain conversions
    
  /app                    # 🟢 Angular UI Layer
    /features             # Páginas/fluxos por contexto (lazy-loaded)
      /budgets            # Budget management feature
      /transactions       # Transaction management 
      /accounts           # Account management
      /credit-cards       # Credit card management
      /goals              # Goals and savings
      /dashboard          # Main dashboard
    /shared               # Componentes e utilitários compartilhados
      /ui-components      # Abstração sobre Angular Material
        /atoms            # os-button, os-input, os-icon
        /molecules        # os-form-field, os-card, os-search-box
        /organisms        # os-data-table, os-navigation, os-modal
      /theme              # Customizações de tema Material
        /_tokens.scss     # Design tokens
        /_material-theme.scss # Angular Material theme
        /_globals.scss    # Global styles
        /theme.scss       # Entry point
      /guards             # Route guards
      /pipes              # Custom pipes
      /directives         # Custom directives
      /layouts            # Layout components
    
  /mocks                  # 🔴 MSW configuration
    /context              # Handlers por contexto de negócio
      /budgetHandlers.ts  # Budget-related mocks
      /transactionHandlers.ts # Transaction mocks
      /accountHandlers.ts # Account mocks
    /handlers.ts          # Aggregated handlers
    /browser.ts           # Browser worker setup
    
  /test-setup.ts          # Bootstrap MSW no ambiente de testes
```

## Assets e Configuração

```
/public
  /mockServiceWorker.js   # MSW service worker (gerado via msw init)
  
/angular.json             # Build configuration
/tsconfig.json            # Path aliases para camadas
```

## Detalhamento por Camada

### `/models` - Domain Layer (TypeScript Puro)
- **Nenhuma dependência** de Angular ou bibliotecas externas
- **Entities**: `Budget`, `Account`, `Transaction`, `Goal`, `CreditCard`
- **Value Objects**: `Money`, `TransactionType`, `AccountType`, `Email`
- **Policies**: Regras de negócio como `TransferPolicy`, `BudgetLimitPolicy`
- **Características**: 100% testável, portável, reutilizável

### `/application` - Use Cases Layer (TypeScript Puro)
- **Orquestração** de regras de negócio
- **Use Cases**: `CreateTransactionUseCase`, `TransferBetweenAccountsUseCase`
- **Query Handlers**: `GetBudgetSummaryQueryHandler`, `GetTransactionListQueryHandler`
- **Ports**: Interfaces que definem contratos para infra (`IBudgetServicePort`)
- **DTOs**: Objetos para transferência de dados entre camadas
- **Não conhece**: Angular, HTTP, storage específico

### `/infra` - Infrastructure Layer
- **Adapters concretos** para Ports definidos em Application
- **HTTP Clients**: `HttpBudgetServiceAdapter`, `HttpTransactionServiceAdapter`
- **Storage**: `LocalStoreAdapter` (IndexedDB), `CacheAdapter`
- **Auth**: `FirebaseAuthAdapter` 
- **Mappers**: Conversão entre DTOs de API e Domain Models

### `/app` - UI Layer (Angular)
- **Componentes** Angular específicos por feature
- **Roteamento** e navegação
- **Lazy Loading** por contexto de negócio
- **Dependency Injection** conectando Application layer via Ports
- **Estado local** com Angular Signals

### `/shared/ui-components` - Design System
- **Atoms**: Componentes básicos (`os-button`, `os-input`)
- **Molecules**: Composições (`os-form-field`, `os-card`)  
- **Organisms**: Componentes complexos (`os-data-table`, `os-modal`)
- **Abstração**: Encapsula Angular Material mantendo API própria

### `/mocks` - Development Support
- **Context Handlers**: Mocks organizados por domínio
- **Realistic Data**: Alinhado com DTOs e contratos reais
- **Development**: Enabled via `MSW_ENABLED` flag
- **Testing**: Auto-initialized em test setup

## Convenções de Nomenclatura

### Arquivos
- **Models/Application**: PascalCase (`CreateTransactionUseCase.ts`)
- **Angular UI**: kebab-case (`transaction-list.component.ts`)
- **Shared**: kebab-case (`os-button.component.ts`)

### Pastas  
- **Todas**: kebab-case (`use-cases`, `query-handlers`, `ui-components`)
- **Features**: Contexto de negócio (`budgets`, `transactions`)

### Classes
- **PascalCase**: `CreateTransactionUseCase`, `BudgetSummaryQueryHandler`
- **Sufixos específicos**: `UseCase`, `QueryHandler`, `Adapter`, `Port`

### Interfaces  
- **Prefixo `I`**: `IBudgetServicePort`, `ITransactionServicePort`

## Path Aliases (tsconfig.json)

```json
{
  "compilerOptions": {
    "baseUrl": "./src",
    "paths": {
      "@models/*": ["models/*"],
      "@application/*": ["application/*"], 
      "@infra/*": ["infra/*"],
      "@app/*": ["app/*"],
      "@shared/*": ["app/shared/*"],
      "@mocks/*": ["mocks/*"]
    }
  }
}
```

## Regras de Importação

### Entre Camadas Diferentes (Path Aliases)
```typescript
// ✅ Application importando Domain
import { Budget } from '@models/entities/Budget';
import { Money } from '@models/value-objects/Money';

// ✅ Infra implementando Application  
import { IBudgetServicePort } from '@application/ports/IBudgetServicePort';
import { CreateBudgetDto } from '@application/dtos/CreateBudgetDto';

// ✅ UI consumindo Application
import { CreateBudgetUseCase } from '@application/use-cases/CreateBudgetUseCase';
```

### Mesma Camada (Imports Relativos)
```typescript
// ✅ Dentro de use-cases
import { CreateBudgetDto } from '../dtos/CreateBudgetDto';
import { BudgetMapper } from '../mappers/BudgetMapper';

// ✅ Dentro de components
import { BudgetCardComponent } from './budget-card.component';
```

## Evoluções Planejadas

### Workspaces (Futuro)
```
packages/
├── @orcasonhos/domain/     # Models + Application
├── @orcasonhos/infra/      # Infrastructure adapters  
├── @orcasonhos/ui-kit/     # Design System
└── @orcasonhos/web-app/    # Angular app shell
```

### Micro-Frontends (Se Necessário)
```
apps/
├── shell/                  # Main app shell
├── budget-management/      # Budget feature app
├── transactions/           # Transactions feature app
└── shared-ui/             # Shared components library
```

---

**Ver também:**
- [Layer Responsibilities](./layer-responsibilities.md) - Detalhes das responsabilidades de cada camada
- [Dependency Rules](./dependency-rules.md) - Regras de importação entre camadas
- [Naming Conventions](./naming-conventions.md) - Convenções detalhadas de nomenclatura