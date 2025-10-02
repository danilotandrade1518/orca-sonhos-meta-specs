# Organização de Features

## Princípios de Organização

A arquitetura **Feature-Based** organiza o código por funcionalidades de negócio, mantendo os princípios **DTO-First** e Clean Architecture. Cada feature é um módulo independente e isolado, facilitando manutenção, escalabilidade e trabalho em equipe.

## Estrutura Interna de Features

### Template Padrão de Feature

```
/app/features/{feature-name}/
├── /components/                    # Componentes específicos da feature
│   ├── /atoms/                    # Componentes atômicos
│   ├── /molecules/                # Componentes moleculares
│   └── /organisms/                # Componentes complexos
├── /pages/                        # Páginas da feature
├── /services/                     # Serviços específicos da feature
│   ├── /commands/                 # Commands (mutações)
│   ├── /queries/                  # Queries (consultas)
│   └── /ports/                    # Interfaces de portas
├── /state/                        # Estado local da feature
├── /types/                        # Tipos específicos da feature
├── /utils/                        # Utilitários específicos
├── /guards/                       # Guards específicos da feature
├── /resolvers/                    # Resolvers específicos
├── {feature-name}.routing.ts      # Roteamento da feature
├── {feature-name}.module.ts       # Módulo da feature
└── index.ts                       # Exports públicos da feature
```

## Features Identificadas

### 1. Dashboard

**Responsabilidade**: Visão geral do sistema, métricas principais e navegação rápida

```
/app/features/dashboard/
├── /components/
│   ├── /atoms/
│   │   ├── metric-card/
│   │   └── quick-action-button/
│   ├── /molecules/
│   │   ├── budget-summary/
│   │   ├── recent-transactions/
│   │   └── spending-chart/
│   └── /organisms/
│       ├── dashboard-grid/
│       └── overview-widgets/
├── /pages/
│   ├── dashboard-home/
│   └── dashboard-analytics/
├── /services/
│   ├── /queries/
│   │   ├── get-dashboard-summary.query.ts
│   │   └── get-recent-activity.query.ts
│   └── /ports/
│       └── dashboard.port.ts
├── /state/
│   └── dashboard.state.ts
└── dashboard.module.ts
```

### 2. Budgets

**Responsabilidade**: Criação, edição e gerenciamento de orçamentos

```
/app/features/budgets/
├── /components/
│   ├── /atoms/
│   │   ├── budget-card/
│   │   ├── category-badge/
│   │   └── progress-bar/
│   ├── /molecules/
│   │   ├── budget-form/
│   │   ├── category-selector/
│   │   └── budget-list-item/
│   └── /organisms/
│       ├── budget-details/
│       ├── budget-list/
│       └── budget-creation-wizard/
├── /pages/
│   ├── budget-list/
│   ├── budget-details/
│   ├── create-budget/
│   └── edit-budget/
├── /services/
│   ├── /commands/
│   │   ├── create-budget.command.ts
│   │   ├── update-budget.command.ts
│   │   └── delete-budget.command.ts
│   ├── /queries/
│   │   ├── get-budget-list.query.ts
│   │   ├── get-budget-details.query.ts
│   │   └── get-budget-summary.query.ts
│   └── /ports/
│       └── budget.port.ts
├── /state/
│   └── budget.state.ts
└── budgets.module.ts
```

### 3. Transactions

**Responsabilidade**: Registro, edição e categorização de transações

```
/app/features/transactions/
├── /components/
│   ├── /atoms/
│   │   ├── transaction-card/
│   │   ├── amount-display/
│   │   └── category-chip/
│   ├── /molecules/
│   │   ├── transaction-form/
│   │   ├── transaction-filters/
│   │   └── transaction-list-item/
│   └── /organisms/
│       ├── transaction-list/
│       ├── transaction-details/
│       └── bulk-actions/
├── /pages/
│   ├── transaction-list/
│   ├── transaction-details/
│   ├── create-transaction/
│   └── edit-transaction/
├── /services/
│   ├── /commands/
│   │   ├── create-transaction.command.ts
│   │   ├── update-transaction.command.ts
│   │   ├── delete-transaction.command.ts
│   │   └── bulk-update-transactions.command.ts
│   ├── /queries/
│   │   ├── get-transaction-list.query.ts
│   │   ├── get-transaction-details.query.ts
│   │   └── search-transactions.query.ts
│   └── /ports/
│       └── transaction.port.ts
├── /state/
│   └── transaction.state.ts
└── transactions.module.ts
```

### 4. Goals

**Responsabilidade**: Definição e acompanhamento de metas financeiras

```
/app/features/goals/
├── /components/
│   ├── /atoms/
│   │   ├── goal-card/
│   │   ├── progress-circle/
│   │   └── deadline-badge/
│   ├── /molecules/
│   │   ├── goal-form/
│   │   ├── goal-progress/
│   │   └── goal-list-item/
│   └── /organisms/
│       ├── goal-dashboard/
│       ├── goal-list/
│       └── goal-creation-wizard/
├── /pages/
│   ├── goal-list/
│   ├── goal-details/
│   ├── create-goal/
│   └── edit-goal/
├── /services/
│   ├── /commands/
│   │   ├── create-goal.command.ts
│   │   ├── update-goal.command.ts
│   │   └── delete-goal.command.ts
│   ├── /queries/
│   │   ├── get-goal-list.query.ts
│   │   ├── get-goal-details.query.ts
│   │   └── get-goal-progress.query.ts
│   └── /ports/
│       └── goal.port.ts
├── /state/
│   └── goal.state.ts
└── goals.module.ts
```

### 5. Accounts

**Responsabilidade**: Gerenciamento de contas bancárias e cartões

```
/app/features/accounts/
├── /components/
│   ├── /atoms/
│   │   ├── account-card/
│   │   ├── balance-display/
│   │   └── account-type-badge/
│   ├── /molecules/
│   │   ├── account-form/
│   │   ├── account-selector/
│   │   └── account-list-item/
│   └── /organisms/
│       ├── account-list/
│       ├── account-details/
│       └── account-creation-wizard/
├── /pages/
│   ├── account-list/
│   ├── account-details/
│   ├── create-account/
│   └── edit-account/
├── /services/
│   ├── /commands/
│   │   ├── create-account.command.ts
│   │   ├── update-account.command.ts
│   │   └── delete-account.command.ts
│   ├── /queries/
│   │   ├── get-account-list.query.ts
│   │   ├── get-account-details.query.ts
│   │   └── get-account-balance.query.ts
│   └── /ports/
│       └── account.port.ts
├── /state/
│   └── account.state.ts
└── accounts.module.ts
```

### 6. Credit Cards

**Responsabilidade**: Gerenciamento de cartões de crédito e faturas

```
/app/features/credit-cards/
├── /components/
│   ├── /atoms/
│   │   ├── credit-card-display/
│   │   ├── limit-indicator/
│   │   └── due-date-badge/
│   ├── /molecules/
│   │   ├── credit-card-form/
│   │   ├── invoice-summary/
│   │   └── credit-card-list-item/
│   └── /organisms/
│       ├── credit-card-list/
│       ├── credit-card-details/
│       └── invoice-management/
├── /pages/
│   ├── credit-card-list/
│   ├── credit-card-details/
│   ├── create-credit-card/
│   └── invoice-details/
├── /services/
│   ├── /commands/
│   │   ├── create-credit-card.command.ts
│   │   ├── update-credit-card.command.ts
│   │   └── pay-invoice.command.ts
│   ├── /queries/
│   │   ├── get-credit-card-list.query.ts
│   │   ├── get-credit-card-details.query.ts
│   │   └── get-invoice-details.query.ts
│   └── /ports/
│       └── credit-card.port.ts
├── /state/
│   └── credit-card.state.ts
└── credit-cards.module.ts
```

### 7. Reports

**Responsabilidade**: Relatórios, análises e visualizações de dados

```
/app/features/reports/
├── /components/
│   ├── /atoms/
│   │   ├── chart-container/
│   │   ├── report-card/
│   │   └── date-range-picker/
│   ├── /molecules/
│   │   ├── spending-chart/
│   │   ├── category-breakdown/
│   │   └── trend-indicator/
│   └── /organisms/
│       ├── report-dashboard/
│       ├── report-builder/
│       └── export-options/
├── /pages/
│   ├── report-dashboard/
│   ├── spending-analysis/
│   ├── budget-performance/
│   └── custom-reports/
├── /services/
│   ├── /queries/
│   │   ├── get-spending-report.query.ts
│   │   ├── get-budget-performance.query.ts
│   │   └── get-category-analysis.query.ts
│   └── /ports/
│       └── report.port.ts
├── /state/
│   └── report.state.ts
└── reports.module.ts
```

### 8. Onboarding

**Responsabilidade**: Fluxo de primeiro acesso e configuração inicial

```
/app/features/onboarding/
├── /components/
│   ├── /atoms/
│   │   ├── step-indicator/
│   │   ├── progress-bar/
│   │   └── welcome-message/
│   ├── /molecules/
│   │   ├── step-form/
│   │   ├── feature-intro/
│   │   └── skip-button/
│   └── /organisms/
│       ├── onboarding-wizard/
│       ├── feature-tour/
│       └── setup-complete/
├── /pages/
│   ├── welcome/
│   ├── profile-setup/
│   ├── budget-setup/
│   ├── account-setup/
│   └── onboarding-complete/
├── /services/
│   ├── /commands/
│   │   ├── complete-onboarding.command.ts
│   │   └── skip-step.command.ts
│   ├── /queries/
│   │   └── get-onboarding-progress.query.ts
│   └── /ports/
│       └── onboarding.port.ts
├── /state/
│   └── onboarding.state.ts
└── onboarding.module.ts
```

## Padrões de Comunicação entre Features

### 1. Event Bus (Loose Coupling)

```typescript
// shared/services/event-bus.service.ts
@Injectable({ providedIn: "root" })
export class EventBusService {
  private eventSubject = new Subject<FeatureEvent>();

  emit(event: string, data?: any): void {
    this.eventSubject.next({
      type: event,
      data,
      timestamp: Date.now(),
      source: this.getCurrentFeature(),
    });
  }

  on(eventType: string): Observable<FeatureEvent> {
    return this.eventSubject.pipe(filter((event) => event.type === eventType));
  }

  private getCurrentFeature(): string {
    // Implementar lógica para identificar feature atual
    return "unknown";
  }
}

// Exemplo de uso
// Feature Transactions
this.eventBus.emit("transaction.created", {
  transactionId,
  budgetId,
  amount,
});

// Feature Budgets
this.eventBus.on("transaction.created").subscribe((event) => {
  this.invalidateBudgetCache(event.data.budgetId);
  this.updateBudgetUsage(event.data.budgetId, event.data.amount);
});
```

### 2. Shared State (Tight Coupling)

```typescript
// shared/services/shared-state.service.ts
@Injectable({ providedIn: "root" })
export class SharedStateService {
  private _activeBudget = signal<BudgetResponseDto | null>(null);
  readonly activeBudget = this._activeBudget.asReadonly();

  private _userProfile = signal<UserProfileResponseDto | null>(null);
  readonly userProfile = this._userProfile.asReadonly();

  setActiveBudget(budget: BudgetResponseDto | null): void {
    this._activeBudget.set(budget);
    this.eventBus.emit("budget.changed", budget);
  }

  setUserProfile(profile: UserProfileResponseDto | null): void {
    this._userProfile.set(profile);
    this.eventBus.emit("user.profile.changed", profile);
  }
}
```

### 3. Shared Services (Service Layer)

```typescript
// shared/services/shared-cache.service.ts
@Injectable({ providedIn: "root" })
export class SharedCacheService {
  private cache = new Map<string, CacheEntry>();

  get<T>(key: string): T | null {
    const entry = this.cache.get(key);
    if (!entry || Date.now() > entry.expiresAt) {
      this.cache.delete(key);
      return null;
    }
    return entry.data;
  }

  set<T>(key: string, data: T, ttl: number = 300000): void {
    this.cache.set(key, {
      data,
      expiresAt: Date.now() + ttl,
    });
  }

  invalidate(pattern: string): void {
    for (const key of this.cache.keys()) {
      if (key.includes(pattern)) {
        this.cache.delete(key);
      }
    }
  }
}
```

## Regras de Isolamento

### 1. Dependências Permitidas

```typescript
// ✅ Permitido: Feature pode depender de
import { SharedStateService } from '@shared/services/shared-state.service';
import { EventBusService } from '@shared/services/event-bus.service';
import { SharedCacheService } from '@shared/services/shared-cache.service';
import { DTOs } from '@dtos';
import { Core Services } from '@core/services';

// ❌ Proibido: Feature NÃO pode depender de
import { OtherFeatureService } from '@features/other-feature/services';
import { OtherFeatureComponent } from '@features/other-feature/components';
```

### 2. Exports Públicos

```typescript
// features/budgets/index.ts
export * from "./components/atoms/budget-card/budget-card.component";
export * from "./components/molecules/budget-form/budget-form.component";
export * from "./pages/budget-list/budget-list.page";
export * from "./services/commands/create-budget.command";
export * from "./services/queries/get-budget-list.query";
export * from "./types/budget.types";
```

### 3. Lazy Loading

```typescript
// app-routing.module.ts
const routes: Routes = [
  {
    path: "budgets",
    loadChildren: () =>
      import("./features/budgets/budgets.module").then((m) => m.BudgetsModule),
  },
  {
    path: "transactions",
    loadChildren: () =>
      import("./features/transactions/transactions.module").then(
        (m) => m.TransactionsModule
      ),
  },
];
```

## Convenções de Nomenclatura

### 1. Estrutura de Arquivos

```
feature-name/
├── components/
│   ├── atoms/
│   │   └── {component-name}/
│   │       ├── {component-name}.component.ts
│   │       ├── {component-name}.component.html
│   │       ├── {component-name}.component.scss
│   │       └── {component-name}.component.spec.ts
│   ├── molecules/
│   └── organisms/
├── pages/
│   └── {page-name}/
│       ├── {page-name}.page.ts
│       ├── {page-name}.page.html
│       ├── {page-name}.page.scss
│       └── {page-name}.page.spec.ts
├── services/
│   ├── commands/
│   │   └── {command-name}.command.ts
│   ├── queries/
│   │   └── {query-name}.query.ts
│   └── ports/
│       └── {port-name}.port.ts
└── {feature-name}.module.ts
```

### 2. Nomenclatura de Classes

```typescript
// Components
export class BudgetCardComponent {}
export class BudgetFormComponent {}
export class BudgetListPage {}

// Services
export class CreateBudgetCommand {}
export class GetBudgetListQuery {}
export class BudgetPort {}

// Types
export interface BudgetFormData {}
export type BudgetStatus = "active" | "inactive" | "archived";
```

## Boas Práticas

### 1. Isolamento de Features

- Cada feature deve ser independente e testável isoladamente
- Comunicação entre features apenas via Event Bus ou Shared Services
- Não importar componentes ou serviços de outras features diretamente

### 2. Reutilização de Código

- Componentes reutilizáveis devem estar em `/shared/ui-components`
- Utilitários comuns devem estar em `/shared/utils`
- DTOs compartilhados devem estar em `/dtos`

### 3. Performance

- Lazy loading para todas as features
- OnPush change detection para componentes
- Signals para estado reativo
- Cache inteligente com TTL

### 4. Testabilidade

- Testes unitários para cada componente e serviço
- Mocks para dependências externas
- Testes de integração para fluxos completos
- MSW para simulação de APIs

---

**Ver também:**

- [Directory Structure](./directory-structure.md) - Estrutura completa de diretórios
- [Layer Responsibilities](./layer-responsibilities.md) - Responsabilidades das camadas
- [Data Flow](./data-flow.md) - Fluxos de dados entre features
- [State Management](./state-management.md) - Gerenciamento de estado
