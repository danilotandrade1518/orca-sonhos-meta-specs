# Convenções de Nomenclatura

## 🎯 Classes e Arquivos

### Backend
```typescript
// Classes: PascalCase
export class CreateTransactionUseCase { }
export class TransactionRepository { }
export class BudgetAuthorizationService { }

// Arquivos: PascalCase
CreateTransactionUseCase.ts
TransactionRepository.ts
BudgetAuthorizationService.ts
TransferBetweenAccountsUnitOfWork.ts
```

### Frontend
```typescript
// Classes: PascalCase
export class CreateTransactionUseCase { }
export class TransactionServiceAdapter { }

// Arquivos Angular: kebab-case
create-transaction.page.ts
transaction-list.component.ts
budget-overview.widget.ts

// Arquivos Models/Application: PascalCase
CreateTransactionUseCase.ts
TransactionServiceAdapter.ts
```

## 🔧 Métodos e Variáveis

```typescript
// Métodos e variáveis: camelCase
public createTransaction() { }
public findByAccountId() { }
private validateAmount() { }

const transactionAmount = Money.fromCents(1000);
const userAccountList = [];
const isValidTransaction = true;
```

## 📏 Constantes

```typescript
// SCREAMING_SNAKE_CASE para constantes globais
const MAX_RETRY_ATTEMPTS = 3;
const DEFAULT_TIMEOUT_MS = 5000;
const API_BASE_URL = '/api';
const TRANSACTION_STATUS = {
  PENDING: 'pending',
  COMPLETED: 'completed',
  CANCELLED: 'cancelled'
} as const;

// camelCase para constantes locais/contextuais
const defaultBudgetSettings = {
  currency: 'BRL',
  initialBalance: 0
};

const transactionFormConfig = {
  maxAmountDigits: 10,
  allowNegative: false
};
```

## 🔗 Interfaces e Contratos

```typescript
// Interfaces: prefixo "I"
interface ITransactionRepository {
  findById(id: TransactionId): Promise<Transaction | null>;
  save(transaction: Transaction): Promise<Either<RepositoryError, void>>;
}

interface IBudgetServicePort {
  createBudget(budget: Budget): Promise<Either<ServiceError, void>>;
  findByUserId(userId: string): Promise<Either<ServiceError, Budget[]>>;
}

interface IUnitOfWork {
  execute<T>(operation: () => Promise<T>): Promise<T>;
  rollback(): Promise<void>;
}

// Types: PascalCase sem prefixo
type TransactionStatus = 'pending' | 'completed' | 'cancelled';
type CreateTransactionDto = {
  amount: number;
  description: string;
  budgetId: string;
};

type BudgetSummary = {
  totalIncome: number;
  totalExpenses: number;
  balance: number;
};
```

## 📁 Pastas e Estruturas

```bash
# Pastas: kebab-case
/use-cases
/aggregates
/value-objects
/unit-of-works
/ui-components
/http-clients

# Contextos de negócio: kebab-case
/credit-cards
/credit-card-bills
/budget-management
/account-transfers
/financial-goals

# Features Angular: kebab-case
/transaction-management
/budget-overview
/account-settings
/user-profile
```

## 🅰️ Componentes Angular

### Seletores
```typescript
// Seletores: prefixo "os-" (OrçaSonhos)
@Component({
  selector: 'os-transaction-form'  // Componente específico
})

@Component({
  selector: 'os-button'           // Design System component
})

@Component({
  selector: 'os-card'             // Layout component
})

@Component({
  selector: 'os-data-table'       // Generic component
})
```

### Classes e Tipos
```typescript
// Classes de componentes: sufixo Component/Page/Widget
export class TransactionFormComponent { }
export class BudgetOverviewPage { }
export class AccountSummaryWidget { }
export class UserProfileCardComponent { }

// Services: sufixo Service
export class TransactionService { }
export class AuthStateService { }
export class LocalStorageService { }

// Guards: sufixo Guard
export class AuthGuard { }
export class BudgetOwnerGuard { }

// Resolvers: sufixo Resolver
export class BudgetDataResolver { }
export class UserPreferencesResolver { }
```

## 🏷️ Domain-Specific Naming

### Aggregates e Entities
```typescript
// Aggregates: Substantivos principais do domínio
export class Budget { }
export class Transaction { }
export class CreditCard { }
export class CreditCardBill { }
export class FinancialGoal { }

// Value Objects: Características ou medidas
export class Money { }
export class TransactionId { }
export class BudgetId { }
export class UserId { }
export class Email { }
export class DateRange { }
```

### Use Cases
```typescript
// Pattern: [Verb][Noun][UseCase]
export class CreateTransactionUseCase { }
export class UpdateBudgetLimitUseCase { }
export class TransferBetweenAccountsUseCase { }
export class MarkTransactionAsLateUseCase { }
export class CalculateBudgetSummaryUseCase { }
export class DeleteFinancialGoalUseCase { }
```

### Repositories
```typescript
// Pattern: [I][Noun][Action]Repository
interface IAddTransactionRepository { }
interface ISaveTransactionRepository { }
interface IFindTransactionRepository { }
interface IGetBudgetRepository { }
interface IListBudgetsRepository { }
interface IDeleteTransactionRepository { }
```

### Ports (Application Layer)
```typescript
// Pattern: [I][Service/Component][Port]
interface ITransactionServicePort { }
interface IBudgetValidationPort { }
interface INotificationPort { }
interface IEmailServicePort { }
interface IFileStoragePort { }
interface IAuthorizationPort { }
```

## 📝 DTOs e Data Transfer

```typescript
// DTOs: [Action][Entity]Dto
type CreateTransactionDto = {
  amount: number;
  description: string;
  categoryId: string;
  budgetId: string;
};

type UpdateBudgetDto = {
  name?: string;
  limitInCents?: number;
  description?: string;
};

// Response DTOs: [Entity][Response]Dto
type TransactionResponseDto = {
  id: string;
  amount: number;
  description: string;
  createdAt: string;
  status: TransactionStatus;
};

// Query DTOs: [Action]QueryDto ou [Entity]FiltersDto
type ListTransactionsQueryDto = {
  budgetId: string;
  startDate?: string;
  endDate?: string;
  status?: TransactionStatus;
  limit?: number;
  offset?: number;
};
```

## 🚫 Padrões a Evitar

### ❌ Nomes Genéricos
```typescript
// ❌ EVITAR - Muito genérico
class Manager { }
class Handler { }
class Processor { }
class Utility { }

// ✅ PREFERIR - Específico e claro
class BudgetAuthorizationService { }
class TransactionValidationHandler { }
class PaymentProcessor { }
class DateUtility { }
```

### ❌ Abreviações Desnecessárias
```typescript
// ❌ EVITAR - Abreviações não óbvias
const txn = transaction;         // transaction
const usr = user;               // user
const cfg = configuration;      // configuration
const proc = process;           // process

// ✅ PREFERIR - Nomes completos
const transaction = getTransaction();
const user = getCurrentUser();
const configuration = loadConfig();
const result = processPayment();
```

### ❌ Prefixos Desnecessários
```typescript
// ❌ EVITAR - Prefixos redundantes
class TransactionTransactionService { }  // Redundante
class BudgetBudgetRepository { }         // Redundante

// ✅ PREFERIR - Sufixos descritivos
class TransactionService { }
class BudgetRepository { }
```

## ✅ Exemplos Completos

### Domain Layer
```typescript
// Aggregate
export class Budget {
  private constructor(
    public readonly id: BudgetId,
    public readonly name: string,
    private limitAmount: Money,
    public readonly ownerId: UserId
  ) {}
  
  public static create(params: CreateBudgetParams): Either<DomainError, Budget> { }
  public updateLimit(newLimit: Money): Either<DomainError, void> { }
  public isOwner(userId: UserId): boolean { }
}

// Value Object
export class Money {
  private constructor(private readonly cents: number) {}
  
  public static fromCents(cents: number): Either<ValidationError, Money> { }
  public static fromReais(reais: number): Either<ValidationError, Money> { }
  public add(other: Money): Money { }
  public subtract(other: Money): Money { }
}
```

### Application Layer
```typescript
// Use Case
export class CreateBudgetUseCase {
  constructor(
    private readonly authService: IBudgetAuthorizationService,
    private readonly repository: IAddBudgetRepository
  ) {}
  
  public async execute(
    dto: CreateBudgetDto,
    userId: string
  ): Promise<Either<ApplicationError, BudgetId>> { }
}

// Port
interface IBudgetServicePort {
  createBudget(budget: Budget): Promise<Either<ServiceError, void>>;
  findByOwner(ownerId: UserId): Promise<Either<ServiceError, Budget[]>>;
  updateBudget(budget: Budget): Promise<Either<ServiceError, void>>;
}
```

### Infrastructure Layer
```typescript
// Repository Implementation
export class PostgresBudgetRepository implements IAddBudgetRepository, ISaveBudgetRepository {
  constructor(private readonly dbConnection: DatabaseConnection) {}
  
  public async execute(budget: Budget): Promise<Either<RepositoryError, void>> { }
}

// Service Adapter
export class HttpBudgetServiceAdapter implements IBudgetServicePort {
  constructor(private readonly httpClient: IHttpClient) {}
  
  public async createBudget(budget: Budget): Promise<Either<ServiceError, void>> { }
}
```

### UI Layer (Angular)
```typescript
// Component
@Component({
  selector: 'os-budget-form',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @if (loading()) {
      <os-spinner />
    } @else {
      <form [formGroup]="form" (ngSubmit)="onSubmit()">
        <os-form-field
          label="Budget Name"
          [control]="form.controls.name"
          [required]="true"
        />
        <os-button type="submit" [loading]="saving()">
          Create Budget
        </os-button>
      </form>
    }
  `
})
export class BudgetFormComponent {
  readonly loading = signal(false);
  readonly saving = signal(false);
  readonly form = this.createForm();
  
  private readonly createBudgetUseCase = inject(CreateBudgetUseCase);
  
  readonly budgetData = input<Budget>();
  readonly created = output<Budget>();
}
```

---

**Ver também:**
- **[Class Structure](./class-structure.md)** - Organização interna de classes
- **[Import Patterns](./import-patterns.md)** - Como importar entre camadas
- **[Angular Modern Patterns](./angular-modern-patterns.md)** - Padrões específicos do Angular