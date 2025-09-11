# Responsabilidades das Camadas

## 1. Models (Domain) - TypeScript Puro

### Responsabilidades
- **Entities**: Modelos de domínio com identidade (`Budget`, `Account`, `Transaction`)
- **Value Objects**: Objetos imutáveis sem identidade (`Money`, `Email`, `TransactionType`)
- **Business Rules**: Políticas e validações de domínio
- **Domain Services**: Lógica que envolve múltiplas entidades

### Características
- **Zero Dependencies**: Nenhuma dependência de framework ou biblioteca externa
- **Pure TypeScript**: Apenas lógica de negócio pura
- **100% Testável**: Fácil de testar isoladamente
- **Framework Agnostic**: Portável para qualquer plataforma

### Exemplos Práticos

#### Domain Entity
```typescript
// models/entities/Budget.ts
export class Budget {
  private constructor(
    private readonly _id: string,
    private _name: string,
    private _limit: Money,
    private _participants: string[]
  ) {}

  public static create(params: CreateBudgetParams): Either<DomainError, Budget> {
    const validation = this.validate(params);
    if (validation.hasError) {
      return validation;
    }

    return Either.success(new Budget(
      generateId(),
      params.name,
      Money.fromCents(params.limitInCents),
      [params.ownerId]
    ));
  }

  public addParticipant(userId: string): Either<DomainError, void> {
    if (this._participants.includes(userId)) {
      return Either.error(new DomainError('User already participant'));
    }
    
    this._participants.push(userId);
    return Either.success(undefined);
  }

  public get id(): string { return this._id; }
  public get name(): string { return this._name; }
  public get limit(): Money { return this._limit; }
}
```

#### Value Object
```typescript
// models/value-objects/Money.ts
export class Money {
  private constructor(private readonly _amountInCents: number) {}

  public static fromCents(cents: number): Money {
    if (cents < 0) {
      throw new Error('Money amount cannot be negative');
    }
    return new Money(cents);
  }

  public static fromReais(reais: number): Money {
    return new Money(Math.round(reais * 100));
  }

  public add(other: Money): Money {
    return new Money(this._amountInCents + other._amountInCents);
  }

  public get cents(): number { return this._amountInCents; }
  public get reais(): number { return this._amountInCents / 100; }
}
```

#### Domain Policy
```typescript
// models/policies/TransferPolicy.ts
export class TransferPolicy {
  public static canTransfer(
    fromAccount: Account, 
    toAccount: Account, 
    amount: Money
  ): Either<PolicyViolation, void> {
    if (fromAccount.balance.isLessThan(amount)) {
      return Either.error(new InsufficientFundsError());
    }

    if (fromAccount.isBlocked || toAccount.isBlocked) {
      return Either.error(new BlockedAccountError());
    }

    return Either.success(undefined);
  }
}
```

---

## 2. Application - Use Cases e Orquestração (TypeScript Puro)

### Responsabilidades
- **Use Cases**: Orquestração de operações de negócio (`CreateTransactionUseCase`)
- **Query Handlers**: Processamento de consultas (`GetBudgetSummaryQueryHandler`)
- **Ports Definition**: Interfaces para serviços externos (`IBudgetServicePort`)
- **DTOs**: Objetos de transferência de dados entre camadas
- **Mappers**: Conversão entre Domain Models e DTOs

### Características
- **Orchestration**: Coordena Domain Models e Policies
- **Framework Agnostic**: Sem dependências de Angular
- **Port Definitions**: Define contratos que Infra implementa
- **Business Flows**: Implementa casos de uso completos

### Exemplos Práticos

#### Use Case (Command)
```typescript
// application/use-cases/CreateTransactionUseCase.ts
export class CreateTransactionUseCase {
  constructor(
    private transactionService: ITransactionServicePort,
    private accountService: IAccountServicePort
  ) {}

  async execute(dto: CreateTransactionDto): Promise<Either<ApplicationError, void>> {
    // 1. Validar entrada
    const validation = CreateTransactionValidator.validate(dto);
    if (validation.hasError) {
      return Either.error(new ValidationError(validation.errors));
    }

    // 2. Buscar conta
    const accountResult = await this.accountService.getById(dto.accountId);
    if (accountResult.hasError) {
      return Either.error(new AccountNotFoundError(dto.accountId));
    }

    // 3. Criar transação usando Domain Model
    const transaction = Transaction.create({
      accountId: dto.accountId,
      amount: Money.fromCents(dto.amountInCents),
      description: dto.description,
      type: TransactionType.fromString(dto.type)
    });

    if (transaction.hasError) {
      return Either.error(new DomainError(transaction.error.message));
    }

    // 4. Persistir via Port
    const saveResult = await this.transactionService.create(transaction.data!);
    return saveResult;
  }
}
```

#### Query Handler  
```typescript
// application/queries/GetBudgetSummaryQueryHandler.ts
export class GetBudgetSummaryQueryHandler {
  constructor(
    private budgetService: IBudgetServicePort,
    private transactionService: ITransactionServicePort
  ) {}

  async handle(query: GetBudgetSummaryQuery): Promise<Either<QueryError, BudgetSummaryDto>> {
    try {
      // Buscar budget
      const budget = await this.budgetService.getById(query.budgetId);
      if (budget.hasError) {
        return Either.error(new BudgetNotFoundError());
      }

      // Buscar transações do período
      const transactions = await this.transactionService.getByPeriod(
        query.budgetId, 
        query.startDate, 
        query.endDate
      );

      // Calcular métricas usando Domain Services
      const summary = BudgetSummaryService.calculate(
        budget.data!, 
        transactions.data || []
      );

      // Mapear para DTO de resposta
      return Either.success(BudgetSummaryMapper.toDto(summary));
    } catch (error) {
      return Either.error(new QueryError('Failed to get budget summary'));
    }
  }
}
```

#### Port Definition
```typescript
// application/ports/IBudgetServicePort.ts
export interface IBudgetServicePort {
  getById(id: string): Promise<Either<ServiceError, Budget>>;
  getByUserId(userId: string): Promise<Either<ServiceError, Budget[]>>;
  create(budget: Budget): Promise<Either<ServiceError, void>>;
  update(budget: Budget): Promise<Either<ServiceError, void>>;
  delete(id: string): Promise<Either<ServiceError, void>>;
}
```

#### DTO
```typescript
// application/dtos/CreateTransactionDto.ts
export interface CreateTransactionDto {
  readonly accountId: string;
  readonly budgetId: string;
  readonly amountInCents: number;
  readonly description: string;
  readonly type: string; // 'income' | 'expense'
  readonly categoryId?: string;
  readonly date?: string; // ISO date
}
```

---

## 3. Infra - Adapters e Implementações

### Responsabilidades
- **HTTP Adapters**: Implementação de Ports via HTTP/API (`HttpBudgetServiceAdapter`)
- **Storage Adapters**: Persistência local (`LocalStoreAdapter` com IndexedDB)
- **Auth Adapters**: Provedores de autenticação (`FirebaseAuthAdapter`)
- **API Mappers**: Conversão entre DTOs de API e Domain Models
- **External Services**: Integrações com serviços externos

### Características
- **Port Implementations**: Implementa interfaces definidas em Application
- **External Dependencies**: Única camada que conhece APIs, storage, etc.
- **Framework Specific**: Pode usar Angular HttpClient, bibliotecas específicas
- **Error Translation**: Converte erros externos para Domain Errors

### Exemplos Práticos

#### HTTP Adapter
```typescript
// infra/adapters/http/HttpBudgetServiceAdapter.ts
@Injectable({ providedIn: 'root' })
export class HttpBudgetServiceAdapter implements IBudgetServicePort {
  constructor(private httpClient: IHttpClient) {}

  async getById(id: string): Promise<Either<ServiceError, Budget>> {
    try {
      const response = await this.httpClient.get<BudgetApiDto>(`/budget/${id}`);
      const budget = BudgetApiMapper.toDomain(response);
      return Either.success(budget);
    } catch (error) {
      if (error.status === 404) {
        return Either.error(new BudgetNotFoundError(id));
      }
      return Either.error(new ServiceError('Failed to fetch budget'));
    }
  }

  async create(budget: Budget): Promise<Either<ServiceError, void>> {
    try {
      const dto = BudgetApiMapper.fromDomain(budget);
      await this.httpClient.post('/budget/create', dto);
      return Either.success(undefined);
    } catch (error) {
      return Either.error(new ServiceError('Failed to create budget'));
    }
  }
}
```

#### Storage Adapter
```typescript
// infra/adapters/storage/LocalStoreAdapter.ts
export class LocalStoreAdapter implements ILocalStorePort {
  private db: IDBDatabase | null = null;

  async get<T>(storeName: string, key: string): Promise<T | null> {
    const transaction = this.db!.transaction([storeName], 'readonly');
    const store = transaction.objectStore(storeName);
    
    return new Promise((resolve, reject) => {
      const request = store.get(key);
      request.onsuccess = () => resolve(request.result || null);
      request.onerror = () => reject(request.error);
    });
  }

  async set<T>(storeName: string, key: string, value: T): Promise<void> {
    const transaction = this.db!.transaction([storeName], 'readwrite');
    const store = transaction.objectStore(storeName);
    
    return new Promise((resolve, reject) => {
      const request = store.put(value, key);
      request.onsuccess = () => resolve();
      request.onerror = () => reject(request.error);
    });
  }
}
```

#### API Mapper
```typescript
// infra/mappers/BudgetApiMapper.ts
export class BudgetApiMapper {
  static toDomain(dto: BudgetApiDto): Budget {
    return Budget.fromSnapshot({
      id: dto.id,
      name: dto.name,
      limitInCents: dto.limit_in_cents,
      participants: dto.participants,
      createdAt: new Date(dto.created_at)
    });
  }

  static fromDomain(budget: Budget): CreateBudgetApiDto {
    return {
      name: budget.name,
      limit_in_cents: budget.limit.cents,
      participants: budget.participants
    };
  }
}
```

---

## 4. UI (Angular) - Interface do Usuário

### Responsabilidades  
- **Components**: Componentes Angular específicos por feature
- **Pages**: Componentes roteáveis que compõem widgets
- **Routing**: Navegação e lazy loading
- **State Management**: Estado local com Angular Signals
- **Dependency Injection**: Conecta Application layer via Providers

### Características
- **Framework Specific**: Totalmente Angular
- **Reactive**: Angular Signals para estado reativo
- **Stateless**: Delega lógica para Application layer
- **Presentation**: Foco em apresentação e interação

### Exemplos Práticos

#### Page Component
```typescript
// app/features/budgets/pages/budget-list.page.ts
@Component({
  selector: 'app-budget-list',
  template: `
    <os-page-header title="Meus Orçamentos" />
    
    @if (loading()) {
      <os-skeleton-list />
    } @else if (budgets().length > 0) {
      @for (budget of budgets(); track budget.id) {
        <os-budget-card 
          [budget]="budget" 
          (onClick)="navigateToBudget(budget.id)" />
      }
    } @else {
      <os-empty-state 
        message="Nenhum orçamento encontrado"
        (onActionClick)="createBudget()" />
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class BudgetListPage {
  private getBudgetListUseCase = inject(GetBudgetListUseCase);
  private router = inject(Router);

  // Estado local com signals
  protected budgets = signal<Budget[]>([]);
  protected loading = signal(false);
  protected error = signal<string | null>(null);

  // Estado computado
  protected isEmpty = computed(() => !this.loading() && this.budgets().length === 0);

  async ngOnInit() {
    await this.loadBudgets();
  }

  protected async loadBudgets() {
    this.loading.set(true);
    
    const result = await this.getBudgetListUseCase.execute();
    
    if (result.hasError) {
      this.error.set(result.error.message);
    } else {
      this.budgets.set(result.data!);
    }
    
    this.loading.set(false);
  }

  protected navigateToBudget(budgetId: string) {
    this.router.navigate(['/budgets', budgetId]);
  }

  protected createBudget() {
    this.router.navigate(['/budgets/create']);
  }
}
```

#### Widget Component
```typescript
// app/features/budgets/components/budget-card.component.ts
@Component({
  selector: 'app-budget-card',
  template: `
    <os-card [clickable]="true" (onClick)="onClick.emit()">
      <os-card-header>
        <h3>{{ budget().name }}</h3>
        <os-badge [variant]="statusVariant()">
          {{ statusText() }}
        </os-badge>
      </os-card-header>
      
      <os-card-content>
        <div class="budget-limit">
          <span>Limite: </span>
          <os-money [amount]="budget().limit" />
        </div>
        
        <div class="participants">
          {{ participantCount() }} participante(s)
        </div>
      </os-card-content>
    </os-card>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class BudgetCardComponent {
  // Modern Angular input/output
  budget = input.required<Budget>();
  onClick = output<void>();

  // Estado computado
  protected participantCount = computed(() => this.budget().participants.length);
  
  protected statusVariant = computed(() => {
    const usage = this.budget().currentUsagePercentage;
    return usage > 90 ? 'danger' : usage > 70 ? 'warning' : 'success';
  });
  
  protected statusText = computed(() => {
    const usage = this.budget().currentUsagePercentage;
    return `${usage}% utilizado`;
  });
}
```

#### Service (DI Provider)
```typescript
// app/providers/use-cases.provider.ts
export function provideUseCases(): Provider[] {
  return [
    // Use Cases
    CreateBudgetUseCase,
    GetBudgetListUseCase,
    UpdateBudgetUseCase,
    
    // Query Handlers  
    GetBudgetSummaryQueryHandler,
    
    // Port implementations injection
    {
      provide: IBudgetServicePort,
      useClass: HttpBudgetServiceAdapter
    },
    {
      provide: ITransactionServicePort, 
      useClass: HttpTransactionServiceAdapter
    }
  ];
}
```

---

## 5. Shared/UI-Components - Design System

### Responsabilidades
- **Abstraction Layer**: Encapsula Angular Material mantendo API própria
- **Design Tokens**: Centraliza cores, espaçamentos e tipografia
- **Accessibility**: Garante padrões a11y consistentes
- **Migration Path**: Permite migração futura sem breaking changes

### Características
- **Component API**: Interface própria, não Material diretamente
- **Theming**: Customização sobre Material Design
- **Atomic Design**: Atoms, Molecules, Organisms
- **Brand Consistency**: Identidade visual do OrçaSonhos

### Exemplos Práticos

#### Atom Component
```typescript
// app/shared/ui-components/atoms/os-button/os-button.component.ts
@Component({
  selector: 'os-button',
  template: `
    <button 
      mat-button
      [color]="matColor()"
      [disabled]="disabled()"
      [attr.aria-label]="ariaLabel()"
      (click)="onClick.emit($event)">
      @if (loading()) {
        <mat-spinner diameter="16" />
      } @else {
        <ng-content />
      }
    </button>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class OsButtonComponent {
  // Public API (OrçaSonhos specific)
  variant = input<'primary' | 'secondary' | 'danger'>('primary');
  disabled = input(false);
  loading = input(false);
  ariaLabel = input<string>();
  
  onClick = output<MouseEvent>();

  // Internal Material mapping
  protected matColor = computed(() => {
    const variant = this.variant();
    return variant === 'primary' ? 'primary' :
           variant === 'danger' ? 'warn' : 'accent';
  });
}
```

---

## Fluxo de Integração Entre Camadas

### Command Flow
```
[UI Component] 
    ↓ (user action)
[Use Case] 
    ↓ (orchestration)
[Domain Models + Policies]
    ↓ (business rules)
[Port] 
    ↓ (contract)
[Adapter] 
    ↓ (implementation)
[External Service/API]
```

### Query Flow  
```
[UI Component]
    ↓ (data request)
[Query Handler]
    ↓ (query logic)
[Port]
    ↓ (contract) 
[Adapter]
    ↓ (implementation)
[External Service/Cache]
    ↓ (data)
[Mapper]
    ↓ (dto to domain)
[Domain Model]
    ↓ (presentation)
[UI Component]
```

---

**Ver também:**
- [Directory Structure](./directory-structure.md) - Organização física das camadas
- [Dependency Rules](./dependency-rules.md) - Regras de dependência entre camadas
- [Data Flow](./data-flow.md) - Fluxos de Commands e Queries detalhados