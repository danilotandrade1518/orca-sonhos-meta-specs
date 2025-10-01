# Organização de Diretórios

## Estrutura Proposta (DTO-First Architecture)

A estrutura segue DTO-First Architecture, eliminando a camada de Models e priorizando DTOs como base de toda comunicação:

```
/src
  /dtos                   # 🔵 Contratos de API (TypeScript interfaces)
    /budget               # Budget-related DTOs
      /request            # CreateBudgetRequestDto, UpdateBudgetRequestDto
      /response           # BudgetResponseDto, BudgetListResponseDto
    /transaction          # Transaction-related DTOs
      /request            # CreateTransactionRequestDto, UpdateTransactionRequestDto
      /response           # TransactionResponseDto, TransactionListResponseDto
    /account              # Account-related DTOs
      /request            # CreateAccountRequestDto, UpdateAccountRequestDto
      /response           # AccountResponseDto, AccountListResponseDto
    /credit-card          # Credit Card-related DTOs
      /request            # CreateCreditCardRequestDto, UpdateCreditCardRequestDto
      /response           # CreditCardResponseDto, CreditCardListResponseDto
    /goal                 # Goal-related DTOs
      /request            # CreateGoalRequestDto, UpdateGoalRequestDto
      /response           # GoalResponseDto, GoalListResponseDto
    /shared               # Types compartilhados
      /Money.ts           # type Money = number (centavos)
      /DateString.ts      # type DateString = string (ISO)
      /TransactionType.ts # type TransactionType = 'INCOME' | 'EXPENSE'
      /BaseEntity.ts      # interface BaseEntityDto

  /application            # 🟡 Use cases simplificados
    /commands             # Commands organizados por contexto (padrão Command)
      /budget             # CreateBudgetCommand, UpdateBudgetCommand, DeleteBudgetCommand
      /transaction        # CreateTransactionCommand, UpdateTransactionCommand, DeleteTransactionCommand
      /account            # CreateAccountCommand, UpdateAccountCommand, DeleteAccountCommand
      /credit-card        # CreateCreditCardCommand, UpdateCreditCardCommand, DeleteCreditCardCommand
      /goal               # CreateGoalCommand, UpdateGoalCommand, DeleteGoalCommand
    /queries              # Query handlers organizados por contexto (padrão Command)
      /budget             # GetBudgetByIdQuery, GetBudgetListQuery, GetBudgetSummaryQuery
      /transaction        # GetTransactionByIdQuery, GetTransactionListQuery, GetTransactionByPeriodQuery
      /account            # GetAccountByIdQuery, GetAccountListQuery, GetAccountBalanceQuery
      /credit-card        # GetCreditCardByIdQuery, GetCreditCardListQuery, GetCreditCardBillsQuery
      /goal               # GetGoalByIdQuery, GetGoalListQuery, GetGoalProgressQuery
    /validators           # Validações client-side básicas
      /budget             # CreateBudgetValidator, UpdateBudgetValidator
      /transaction        # CreateTransactionValidator, UpdateTransactionValidator
      /account            # CreateAccountValidator, UpdateAccountValidator
      /credit-card        # CreateCreditCardValidator, UpdateCreditCardValidator
      /goal               # CreateGoalValidator, UpdateGoalValidator
    /transformers         # Transformações leves de dados
      /budget             # BudgetTransformer
      /transaction        # TransactionTransformer
      /account            # AccountTransformer
      /credit-card        # CreditCardTransformer
      /goal               # GoalTransformer
    /ports                # Interfaces para infra (1 interface por operação)
      /mutations          # Ports para operações de escrita
        /budget
          /ICreateBudgetPort.ts
          /IUpdateBudgetPort.ts
          /IDeleteBudgetPort.ts
        /transaction
          /ICreateTransactionPort.ts
          /IUpdateTransactionPort.ts
          /IDeleteTransactionPort.ts
        /account
          /ICreateAccountPort.ts
          /IUpdateAccountPort.ts
          /IDeleteAccountPort.ts
        /credit-card
          /ICreateCreditCardPort.ts
          /IUpdateCreditCardPort.ts
          /IDeleteCreditCardPort.ts
        /goal
          /ICreateGoalPort.ts
          /IUpdateGoalPort.ts
          /IDeleteGoalPort.ts
      /queries            # Ports para operações de leitura
        /budget
          /IGetBudgetByIdPort.ts
          /IGetBudgetListPort.ts
          /IGetBudgetSummaryPort.ts
        /transaction
          /IGetTransactionByIdPort.ts
          /IGetTransactionListPort.ts
          /IGetTransactionByPeriodPort.ts
        /account
          /IGetAccountByIdPort.ts
          /IGetAccountListPort.ts
          /IGetAccountBalancePort.ts
        /credit-card
          /IGetCreditCardByIdPort.ts
          /IGetCreditCardListPort.ts
          /IGetCreditCardBillsPort.ts
        /goal
          /IGetGoalByIdPort.ts
          /IGetGoalListPort.ts
          /IGetGoalProgressPort.ts

  /infra                  # 🟠 Adapters HTTP e Storage
    /http                 # HTTP clients e interceptors
      /adapters           # HTTP adapters organizados por operação (1 adapter por port)
        /mutations        # Adapters para operações de escrita
          /budget
            /HttpCreateBudgetAdapter.ts
            /HttpUpdateBudgetAdapter.ts
            /HttpDeleteBudgetAdapter.ts
          /transaction
            /HttpCreateTransactionAdapter.ts
            /HttpUpdateTransactionAdapter.ts
            /HttpDeleteTransactionAdapter.ts
          /account
            /HttpCreateAccountAdapter.ts
            /HttpUpdateAccountAdapter.ts
            /HttpDeleteAccountAdapter.ts
          /credit-card
            /HttpCreateCreditCardAdapter.ts
            /HttpUpdateCreditCardAdapter.ts
            /HttpDeleteCreditCardAdapter.ts
          /goal
            /HttpCreateGoalAdapter.ts
            /HttpUpdateGoalAdapter.ts
            /HttpDeleteGoalAdapter.ts
        /queries          # Adapters para operações de leitura
          /budget
            /HttpGetBudgetByIdAdapter.ts
            /HttpGetBudgetListAdapter.ts
            /HttpGetBudgetSummaryAdapter.ts
          /transaction
            /HttpGetTransactionByIdAdapter.ts
            /HttpGetTransactionListAdapter.ts
            /HttpGetTransactionByPeriodAdapter.ts
          /account
            /HttpGetAccountByIdAdapter.ts
            /HttpGetAccountListAdapter.ts
            /HttpGetAccountBalanceAdapter.ts
          /credit-card
            /HttpGetCreditCardByIdAdapter.ts
            /HttpGetCreditCardListAdapter.ts
            /HttpGetCreditCardBillsAdapter.ts
          /goal
            /HttpGetGoalByIdAdapter.ts
            /HttpGetGoalListAdapter.ts
            /HttpGetGoalProgressAdapter.ts
      /interceptors       # AuthInterceptor, ErrorInterceptor
    /storage              # LocalStorage/IndexedDB adapters
      /LocalStoreAdapter.ts
    /auth                 # Firebase Auth adapter
      /FirebaseAuthAdapter.ts
    /mappers              # Conversões apenas quando necessário
      /DateMapper.ts      # Apenas quando formato difere

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

  /mocks                  # 🔴 MSW mocks
    /context              # Handlers por contexto de negócio
      /budget             # Budget-related mocks
        /budgetHandlers.ts
        /budgetMocks.ts
      /transaction        # Transaction-related mocks
        /transactionHandlers.ts
        /transactionMocks.ts
      /account            # Account-related mocks
        /accountHandlers.ts
        /accountMocks.ts
      /credit-card        # Credit Card-related mocks
        /creditCardHandlers.ts
        /creditCardMocks.ts
      /goal               # Goal-related mocks
        /goalHandlers.ts
        /goalMocks.ts
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

### `/dtos` - Contratos de API (TypeScript Puro)

- **Nenhuma dependência** de Angular ou bibliotecas externas
- **Organização por contexto**: Cada entidade tem sua própria pasta (budget, transaction, account, etc.)
- **Request DTOs**: Estruturas para dados enviados ao backend, organizadas por contexto
- **Response DTOs**: Estruturas para dados recebidos do backend, organizadas por contexto
- **Shared Types**: Tipos compartilhados (Money, DateString, Enums) na pasta `/shared`
- **Características**: 100% alinhado com API, sem lógica de negócio

### `/application` - Use Cases Simplificados (TypeScript Puro)

- **Orquestração** de chamadas HTTP e validações básicas
- **Organização por contexto**: Cada entidade tem sua própria pasta (budget, transaction, account, etc.)
- **Commands**: Operações de escrita seguindo padrão Command (`CreateBudgetCommand`, `UpdateTransactionCommand`)
- **Queries**: Operações de leitura seguindo padrão Command (`GetBudgetByIdQuery`, `GetTransactionListQuery`)
- **Validators**: Validações client-side para UX, organizadas por contexto
- **Transformers**: Transformações leves quando necessário, organizadas por contexto
- **Ports**: 1 interface por operação, separadas em mutations e queries (`ICreateBudgetPort`, `IGetBudgetByIdPort`)
- **Não conhece**: Angular, HTTP, storage específico

### `/infra` - Infrastructure Layer

- **Adapters concretos** para Ports definidos em Application
- **1 Adapter por Port**: Cada interface tem sua implementação específica
- **Organização por operação**: Adapters separados em mutations e queries
- **HTTP Clients**: `HttpCreateBudgetAdapter`, `HttpGetBudgetByIdAdapter`, `HttpCreateTransactionAdapter`
- **Storage**: `LocalStoreAdapter` (IndexedDB), `CacheAdapter`
- **Auth**: `FirebaseAuthAdapter`
- **Mappers**: Conversão apenas quando formato difere (na maioria dos casos, DTOs fluem diretamente)

### `/app` - UI Layer (Angular)

- **Componentes** Angular específicos por feature
- **Roteamento** e navegação
- **Lazy Loading** por contexto de negócio
- **Dependency Injection** conectando Application layer via Ports
- **Estado local** com Angular Signals usando DTOs diretamente

### `/shared/ui-components` - Design System

- **Atoms**: Componentes básicos (`os-button`, `os-input`)
- **Molecules**: Composições (`os-form-field`, `os-card`)
- **Organisms**: Componentes complexos (`os-data-table`, `os-modal`)
- **Abstração**: Encapsula Angular Material mantendo API própria

### `/mocks` - Development Support

- **Context Handlers**: Mocks organizados por contexto/entidade (budget, transaction, account, etc.)
- **Realistic Data**: Alinhado com DTOs e contratos reais
- **Development**: Enabled via `MSW_ENABLED` flag
- **Testing**: Auto-initialized em test setup
- **DTO-Based**: Retorna DTOs diretamente, sem conversões

## Padrão Command Implementado

### Estrutura de Commands e Queries

Tanto Commands quanto Queries seguem o padrão Command, onde cada operação tem:

- **1 Interface Port** com método `execute()`
- **1 Command/Query** que implementa a lógica
- **1 Adapter** que implementa a interface

#### Exemplo de Command (Mutation)

```typescript
// Port Interface
export interface ICreateBudgetPort {
  execute(request: CreateBudgetRequestDto): Promise<Either<ServiceError, void>>;
}

// Command Implementation
export class CreateBudgetCommand {
  constructor(private port: ICreateBudgetPort) {}

  async execute(
    request: CreateBudgetRequestDto
  ): Promise<Either<ServiceError, void>> {
    // Validação + chamada do port
    return this.port.execute(request);
  }
}

// Adapter Implementation
export class HttpCreateBudgetAdapter implements ICreateBudgetPort {
  async execute(
    request: CreateBudgetRequestDto
  ): Promise<Either<ServiceError, void>> {
    // HTTP call
  }
}
```

#### Exemplo de Query

```typescript
// Port Interface
export interface IGetBudgetByIdPort {
  execute(id: string): Promise<Either<ServiceError, BudgetResponseDto>>;
}

// Query Implementation
export class GetBudgetByIdQuery {
  constructor(private port: IGetBudgetByIdPort) {}

  async execute(id: string): Promise<Either<ServiceError, BudgetResponseDto>> {
    return this.port.execute(id);
  }
}

// Adapter Implementation
export class HttpGetBudgetByIdAdapter implements IGetBudgetByIdPort {
  async execute(id: string): Promise<Either<ServiceError, BudgetResponseDto>> {
    // HTTP call
  }
}
```

## Convenções de Nomenclatura

### Arquivos

- **DTOs/Application**: PascalCase (`CreateTransactionRequestDto.ts`)
- **Angular UI**: kebab-case (`transaction-list.component.ts`)
- **Shared**: kebab-case (`os-button.component.ts`)

### Pastas

- **Todas**: kebab-case (`use-cases`, `query-handlers`, `ui-components`)
- **Features**: Contexto de negócio (`budgets`, `transactions`)

### Classes

- **PascalCase**: `CreateBudgetCommand`, `GetBudgetByIdQuery`
- **Sufixos específicos**: `Command`, `Query`, `Adapter`, `Port`

### Interfaces e Types

- **Prefixo `I`**: `ICreateBudgetPort`, `IGetBudgetByIdPort`
- **DTOs**: `CreateTransactionRequestDto`, `BudgetResponseDto`
- **Shared Types**: `Money`, `DateString`, `TransactionType`

## Path Aliases (tsconfig.json)

```json
{
  "compilerOptions": {
    "baseUrl": "./src",
    "paths": {
      "@dtos/*": ["dtos/*"],
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
// ✅ Application importando DTOs organizados por contexto
import { CreateTransactionRequestDto } from "@dtos/transaction/request/CreateTransactionRequestDto";
import { BudgetResponseDto } from "@dtos/budget/response/BudgetResponseDto";
import { Money } from "@dtos/shared/Money";

// ✅ Infra implementando Application (1 interface por operação)
import { ICreateBudgetPort } from "@application/ports/mutations/budget/ICreateBudgetPort";
import { IGetBudgetByIdPort } from "@application/ports/queries/budget/IGetBudgetByIdPort";
import { CreateBudgetRequestDto } from "@dtos/budget/request/CreateBudgetRequestDto";

// ✅ UI consumindo Application (padrão Command)
import { CreateBudgetCommand } from "@application/commands/budget/CreateBudgetCommand";
import { GetBudgetByIdQuery } from "@application/queries/budget/GetBudgetByIdQuery";
```

### Mesma Camada (Imports Relativos)

```typescript
// ✅ Dentro de commands/budget
import { CreateBudgetRequestDto } from "@dtos/budget/request/CreateBudgetRequestDto";
import { ICreateBudgetPort } from "../../ports/mutations/budget/ICreateBudgetPort";
import { CreateBudgetValidator } from "../../validators/budget/CreateBudgetValidator";

// ✅ Dentro de queries/budget
import { BudgetResponseDto } from "@dtos/budget/response/BudgetResponseDto";
import { IGetBudgetByIdPort } from "../../ports/queries/budget/IGetBudgetByIdPort";

// ✅ Dentro de components
import { BudgetCardComponent } from "./budget-card.component";
```

## Evoluções Planejadas

### Workspaces (Futuro)

```
packages/
├── @orcasonhos/dtos/       # DTOs + Application
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
