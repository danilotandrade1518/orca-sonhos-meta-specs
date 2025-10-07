# Organização de Diretórios

## Estrutura Proposta (Feature-Based Architecture com DTO-First)

A estrutura segue **Feature-Based Architecture** com princípios **DTO-First**, organizando o código por funcionalidades de negócio para melhor escalabilidade e manutenibilidade:

```
/src
  /app                    # 🟢 Angular Application
    /core                 # Serviços singleton e configurações globais
      /services           # Serviços globais (Auth, Config, etc.)
      /interceptors       # HTTP interceptors globais
      /guards             # Route guards globais
      /core.module.ts     # Core module (se necessário)

    /shared               # Componentes e utilitários compartilhados
      /ui-components      # Design System (abstração Angular Material)
        /atoms            # os-button, os-input, os-icon
        /molecules        # os-form-field, os-card, os-search-box
        /organisms        # os-data-table, os-navigation, os-modal
        /ui-components.module.ts
      /theme              # Customizações de tema Material
        /_tokens.scss     # Design tokens
        /_material-theme.scss # Angular Material theme
        /_globals.scss    # Global styles
        /theme.scss       # Entry point
      /pipes              # Custom pipes compartilhados
      /directives         # Custom directives compartilhadas
      /utils              # Utilitários compartilhados
      /shared.module.ts   # Shared module

    /features             # Módulos de funcionalidades (lazy-loaded)
      /dashboard          # Dashboard principal
        /components       # Componentes específicos do dashboard
        /services         # Serviços específicos do dashboard
      /budgets            # Gestão de orçamentos
        /components       # Componentes de orçamento
        /services         # Serviços de orçamento
      /transactions       # Gestão de transações
        /components       # Componentes de transação
        /services         # Serviços de transação
      /goals              # Gestão de metas
        /components       # Componentes de metas
        /services         # Serviços de metas
      /accounts           # Gestão de contas
        /components       # Componentes de contas
        /services         # Serviços de contas
      /credit-cards       # Gestão de cartões de crédito
        /components       # Componentes de cartões
        /services         # Serviços de cartões
      /reports            # Relatórios e análises
        /components       # Componentes de relatórios
        /services         # Serviços de relatórios
      /onboarding         # Fluxo de onboarding
        /components       # Componentes de onboarding
        /services         # Serviços de onboarding

    /layouts              # Layouts da aplicação
      /main-layout        # Layout principal da aplicação
      /auth-layout        # Layout para páginas de autenticação
      /layouts.module.ts  # Layouts module

    /dtos                 # Contratos de API (DTO-First)
      /budget             # DTOs de orçamento
        /request          # CreateBudgetRequestDto, UpdateBudgetRequestDto
        /response         # BudgetResponseDto, BudgetListResponseDto
      /transaction        # DTOs de transação
        /request          # CreateTransactionRequestDto, UpdateTransactionRequestDto
        /response         # TransactionResponseDto, TransactionListResponseDto
      /goal               # DTOs de metas
        /request          # CreateGoalRequestDto, UpdateGoalRequestDto
        /response         # GoalResponseDto, GoalListResponseDto
      /account            # DTOs de contas
        /request          # CreateAccountRequestDto, UpdateAccountRequestDto
        /response         # AccountResponseDto, AccountListResponseDto
      /credit-card        # DTOs de cartões de crédito
        /request          # CreateCreditCardRequestDto, UpdateCreditCardRequestDto
        /response         # CreditCardResponseDto, CreditCardListResponseDto
      /shared             # Types compartilhados
        /Money.ts         # type Money = number (centavos)
        /DateString.ts    # type DateString = string (ISO)
        /TransactionType.ts # type TransactionType = 'INCOME' | 'EXPENSE'
        /BaseEntity.ts    # interface BaseEntityDto

    /services             # Serviços de aplicação
      /api                # Serviços de API
      /state              # Gerenciamento de estado global
      /validation         # Validações globais

    /app-routing.module.ts
    /app.component.ts
    /app.module.ts

  /assets                 # Assets estáticos
  /environments           # Configurações de ambiente

  /mocks                  # 🔴 MSW mocks (desenvolvimento)
    /features             # Handlers por feature
      /budget             # Budget-related mocks
        /budgetHandlers.ts
        /budgetMocks.ts
      /transaction        # Transaction-related mocks
        /transactionHandlers.ts
        /transactionMocks.ts
      /goal               # Goal-related mocks
        /goalHandlers.ts
        /goalMocks.ts
      /account            # Account-related mocks
        /accountHandlers.ts
        /accountMocks.ts
      /credit-card        # Credit Card-related mocks
        /creditCardHandlers.ts
        /creditCardMocks.ts
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

## Detalhamento por Estrutura

### `/app/core` - Serviços Globais

- **Singleton Services**: Serviços que existem uma única vez na aplicação
- **Global Configuration**: Configurações que afetam toda a aplicação
- **HTTP Interceptors**: Interceptadores globais para autenticação, logging, etc.
- **Route Guards**: Guards globais para autenticação e autorização
- **Características**: Inicializados uma única vez, compartilhados entre features

### `/app/shared` - Componentes e Utilitários Compartilhados

- **UI Components**: Design System com abstração sobre Angular Material
  - **Atoms**: Componentes básicos (`os-button`, `os-input`, `os-icon`)
  - **Molecules**: Composições (`os-form-field`, `os-card`, `os-search-box`)
  - **Organisms**: Componentes complexos (`os-data-table`, `os-navigation`, `os-modal`)
- **Theme**: Customizações de tema Material Design
- **Pipes**: Pipes compartilhados entre features
- **Directives**: Directives compartilhadas entre features
- **Utils**: Utilitários e helpers compartilhados
- **Características**: Reutilizáveis, sem dependências de features específicas

### `/app/features` - Módulos de Funcionalidades

Cada feature é um módulo independente com:

- **Components**: Componentes específicos da feature
- **Services**: Serviços específicos da feature
- **Module**: Módulo Angular da feature
- **Routing**: Roteamento específico da feature
- **Lazy Loading**: Carregamento sob demanda
- **Isolamento**: Dependências mínimas entre features

#### Estrutura Interna de uma Feature

```
/features/budgets
├── /components           # Componentes da feature
│   ├── budget-list.component.ts
│   ├── budget-form.component.ts
│   └── budget-card.component.ts
├── /services            # Serviços da feature
│   ├── budget.service.ts
│   └── budget-state.service.ts
├── /dtos               # DTOs específicos da feature (se necessário)
│   ├── request/
│   └── response/
├── budgets.module.ts   # Módulo da feature
└── budgets-routing.module.ts # Roteamento da feature
```

### `/app/layouts` - Layouts da Aplicação

- **Main Layout**: Layout principal com navegação, header, sidebar
- **Auth Layout**: Layout para páginas de autenticação
- **Responsive**: Adaptação para diferentes tamanhos de tela
- **Características**: Estrutura visual compartilhada entre features

### `/app/dtos` - Contratos de API (DTO-First)

- **Nenhuma dependência** de Angular ou bibliotecas externas
- **Organização por contexto**: Cada entidade tem sua própria pasta
- **Request DTOs**: Estruturas para dados enviados ao backend
- **Response DTOs**: Estruturas para dados recebidos do backend
- **Shared Types**: Tipos compartilhados (Money, DateString, Enums)
- **Características**: 100% alinhado com API, sem lógica de negócio

### `/app/services` - Serviços de Aplicação

- **API Services**: Serviços de comunicação com backend
- **State Services**: Gerenciamento de estado global (quando necessário)
- **Validation Services**: Validações globais
- **Características**: Serviços compartilhados entre features

### `/mocks` - Development Support

- **Feature Handlers**: Mocks organizados por feature
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
      "@app/*": ["app/*"],
      "@core/*": ["app/core/*"],
      "@shared/*": ["app/shared/*"],
      "@features/*": ["app/features/*"],
      "@layouts/*": ["app/layouts/*"],
      "@dtos/*": ["app/dtos/*"],
      "@services/*": ["app/services/*"],
      "@mocks/*": ["mocks/*"]
    }
  }
}
```

## Regras de Importação

### Entre Features e Shared (Path Aliases)

```typescript
// ✅ Feature importando DTOs
import { CreateTransactionRequestDto } from "@dtos/transaction/request/CreateTransactionRequestDto";
import { BudgetResponseDto } from "@dtos/budget/response/BudgetResponseDto";
import { Money } from "@dtos/shared/Money";

// ✅ Feature importando componentes shared
import { OsButtonComponent } from "@shared/ui-components/atoms/os-button.component";
import { OsCardComponent } from "@shared/ui-components/molecules/os-card.component";
import { OsDataTableComponent } from "@shared/ui-components/organisms/os-data-table.component";

// ✅ Feature importando serviços globais
import { AuthService } from "@core/services/auth.service";
import { ApiService } from "@services/api/api.service";
```

### Dentro de uma Feature (Imports Relativos)

```typescript
// ✅ Dentro de features/budgets/components
import { BudgetCardComponent } from "./budget-card.component";
import { BudgetFormComponent } from "./budget-form.component";

// ✅ Dentro de features/budgets/services
import { BudgetService } from "./budget.service";
import { BudgetStateService } from "./budget-state.service";

// ✅ Feature importando DTOs específicos
import { CreateBudgetRequestDto } from "@dtos/budget/request/CreateBudgetRequestDto";
import { BudgetResponseDto } from "@dtos/budget/response/BudgetResponseDto";
```

### Entre Features (Evitar)

```typescript
// ❌ EVITAR: Importação direta entre features
import { BudgetCardComponent } from "@features/budgets/components/budget-card.component";

// ✅ PREFERIR: Usar shared components ou services globais
import { OsCardComponent } from "@shared/ui-components/molecules/os-card.component";
import { ApiService } from "@services/api/api.service";
```

## Evoluções Planejadas

### Feature Maturity (Médio Prazo)

```
/app/features/
├── /budgets/              # Feature madura e isolada
│   ├── /components/       # Componentes específicos
│   ├── /services/         # Serviços específicos
│   ├── /dtos/            # DTOs específicos (se necessário)
│   └── /tests/           # Testes específicos da feature
```

### Workspaces (Longo Prazo)

```
packages/
├── @orcasonhos/shared/     # Shared components e utils
├── @orcasonhos/dtos/       # DTOs compartilhados
├── @orcasonhos/ui-kit/     # Design System
└── @orcasonhos/web-app/    # Angular app shell
```

### Micro-Frontends (Se Necessário)

```
apps/
├── shell/                  # Main app shell
├── budget-management/      # Budget feature como micro-frontend
├── transactions/           # Transactions feature como micro-frontend
└── shared-ui/             # Shared components library
```

---

**Ver também:**

- [Layer Responsibilities](./layer-responsibilities.md) - Detalhes das responsabilidades de cada camada
- [Feature Organization](./feature-organization.md) - Como organizar features independentes
- [Dependency Rules](./dependency-rules.md) - Regras de importação entre features
- [Naming Conventions](./naming-conventions.md) - Convenções detalhadas de nomenclatura
