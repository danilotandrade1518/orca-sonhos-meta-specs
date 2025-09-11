# Fluxos de Dados e Interação

## Arquitetura de Fluxo de Dados

O frontend segue padrão **CQRS (Command Query Responsibility Segregation)** alinhado com o backend, separando claramente operações de escrita (Commands) e leitura (Queries).

## Fluxo de Commands (Mutações)

### Arquitetura de Command
```
[UI Component] 
    ↓ (user action)
[Use Case (Application)] 
    ↓ (business orchestration)
[Domain Models + Policies]
    ↓ (business validation)  
[Port Interface]
    ↓ (contract)
[Adapter (Infra)]
    ↓ (HTTP POST)
[Backend Command Endpoint]
```

### Implementação Prática

#### 1. Command na UI
```typescript
// app/features/transactions/pages/create-transaction.page.ts
@Component({
  selector: 'app-create-transaction',
  template: `
    <form [formGroup]="form" (ngSubmit)="onSubmit()">
      <os-form-field label="Descrição" [error]="getFieldError('description')">
        <os-input 
          formControlName="description"
          placeholder="Ex: Almoço no restaurante"
          slot="input" />
      </os-form-field>
      
      <os-form-field label="Valor" [error]="getFieldError('amount')">
        <os-money-input
          formControlName="amount"
          slot="input" />
      </os-form-field>
      
      <os-button 
        type="submit"
        variant="primary"
        [loading]="submitting()"
        [disabled]="form.invalid">
        Criar Transação
      </os-button>
    </form>
  `
})
export class CreateTransactionPage {
  private createTransactionUseCase = inject(CreateTransactionUseCase);
  private router = inject(Router);
  
  protected form = this.formBuilder.group({
    description: ['', [Validators.required, Validators.minLength(3)]],
    amount: [0, [Validators.required, Validators.min(0.01)]],
    accountId: ['', Validators.required],
    categoryId: ['']
  });
  
  protected submitting = signal(false);
  protected error = signal<string | null>(null);

  protected async onSubmit(): Promise<void> {
    if (this.form.invalid) return;
    
    this.submitting.set(true);
    this.error.set(null);
    
    const formValue = this.form.value;
    const command: CreateTransactionDto = {
      description: formValue.description!,
      amountInCents: Math.round(formValue.amount! * 100),
      accountId: formValue.accountId!,
      categoryId: formValue.categoryId || undefined,
      date: new Date().toISOString()
    };
    
    const result = await this.createTransactionUseCase.execute(command);
    
    if (result.hasError) {
      this.error.set(result.error.message);
    } else {
      // Success - navigate back
      this.router.navigate(['/transactions']);
    }
    
    this.submitting.set(false);
  }
}
```

#### 2. Use Case (Application Layer)
```typescript
// application/use-cases/CreateTransactionUseCase.ts
export interface CreateTransactionDto {
  readonly description: string;
  readonly amountInCents: number;
  readonly accountId: string;
  readonly categoryId?: string;
  readonly date: string;
}

@Injectable({ providedIn: 'root' })
export class CreateTransactionUseCase {
  constructor(
    private transactionService: ITransactionServicePort,
    private accountService: IAccountServicePort
  ) {}

  async execute(dto: CreateTransactionDto): Promise<Either<UseCaseError, void>> {
    // 1. Validação de entrada
    const validation = this.validateInput(dto);
    if (validation.hasError) {
      return Either.error(new ValidationError(validation.errors));
    }

    // 2. Verificar se conta existe
    const accountResult = await this.accountService.getById(dto.accountId);
    if (accountResult.hasError) {
      return Either.error(new AccountNotFoundError(dto.accountId));
    }

    // 3. Criar domain model com validações de negócio
    const transactionResult = Transaction.create({
      description: dto.description,
      amount: Money.fromCents(dto.amountInCents),
      accountId: dto.accountId,
      categoryId: dto.categoryId,
      date: new Date(dto.date),
      type: dto.amountInCents > 0 ? TransactionType.INCOME : TransactionType.EXPENSE
    });

    if (transactionResult.hasError) {
      return Either.error(new DomainError(transactionResult.error.message));
    }

    // 4. Persistir via Port (será implementado por Adapter HTTP)
    const transaction = transactionResult.data!;
    const saveResult = await this.transactionService.create(transaction);
    
    return saveResult;
  }

  private validateInput(dto: CreateTransactionDto): Either<ValidationError[], void> {
    const errors: string[] = [];

    if (!dto.description?.trim()) {
      errors.push('Description is required');
    }

    if (dto.amountInCents === 0) {
      errors.push('Amount must be different from zero');
    }

    if (!dto.accountId) {
      errors.push('Account ID is required');
    }

    return errors.length > 0 
      ? Either.error(errors.map(msg => new ValidationError(msg)))
      : Either.success(undefined);
  }
}
```

#### 3. Port (Interface)
```typescript
// application/ports/ITransactionServicePort.ts
export interface ITransactionServicePort {
  create(transaction: Transaction): Promise<Either<ServiceError, void>>;
  update(transaction: Transaction): Promise<Either<ServiceError, void>>;
  delete(id: string): Promise<Either<ServiceError, void>>;
  getById(id: string): Promise<Either<ServiceError, Transaction>>;
}
```

#### 4. HTTP Adapter (Infrastructure)
```typescript
// infra/adapters/http/HttpTransactionServiceAdapter.ts
@Injectable({ providedIn: 'root' })
export class HttpTransactionServiceAdapter implements ITransactionServicePort {
  constructor(private httpClient: IHttpClient) {}

  async create(transaction: Transaction): Promise<Either<ServiceError, void>> {
    try {
      // Mapear domain model para DTO de API
      const apiDto: CreateTransactionApiDto = {
        description: transaction.description,
        amount_in_cents: transaction.amount.cents,
        account_id: transaction.accountId,
        category_id: transaction.categoryId,
        transaction_date: transaction.date.toISOString(),
        transaction_type: transaction.type.value
      };

      // Command-style endpoint (POST)
      await this.httpClient.post('/transaction/create', apiDto);
      
      return Either.success(undefined);
    } catch (error) {
      if (error instanceof HttpError) {
        switch (error.status) {
          case 400:
            return Either.error(new ValidationError('Invalid transaction data'));
          case 404:
            return Either.error(new AccountNotFoundError(transaction.accountId));
          case 409:
            return Either.error(new ConflictError('Transaction already exists'));
          default:
            return Either.error(new ServiceError('Failed to create transaction'));
        }
      }
      
      return Either.error(new ServiceError('Network error'));
    }
  }
}
```

---

## Fluxo de Queries (Consultas)

### Arquitetura de Query
```
[UI Component]
    ↓ (data request)
[Query Handler (Application)]
    ↓ (query orchestration)
[Port Interface]
    ↓ (contract)
[Adapter (Infra)]
    ↓ (HTTP GET / Cache)
[Backend Query Endpoint / Local Storage]
    ↓ (data)
[Mapper (Infra)]
    ↓ (DTO → Domain)
[Domain Model]
    ↓ (presentation)
[UI Component]
```

### Implementação Prática

#### 1. Query na UI
```typescript
// app/features/budgets/pages/budget-summary.page.ts
@Component({
  selector: 'app-budget-summary',
  template: `
    @if (loading()) {
      <os-skeleton-card />
    } @else if (summary(); as data) {
      <os-card>
        <os-card-header>
          <h2>{{ data.budgetName }}</h2>
          <os-badge [variant]="usageVariant()">
            {{ data.usagePercentage }}% utilizado
          </os-badge>
        </os-card-header>
        
        <os-card-content>
          <div class="summary-metrics">
            <div class="metric">
              <span class="label">Limite</span>
              <os-money [amount]="data.limit" />
            </div>
            
            <div class="metric">
              <span class="label">Gasto</span>
              <os-money [amount]="data.totalSpent" />
            </div>
            
            <div class="metric">
              <span class="label">Disponível</span>
              <os-money [amount]="data.remaining" />
            </div>
          </div>
        </os-card-content>
      </os-card>
    } @else if (error()) {
      <os-error-state [message]="error()" (onRetry)="loadSummary()" />
    }
  `
})
export class BudgetSummaryPage {
  private getBudgetSummaryQuery = inject(GetBudgetSummaryQueryHandler);
  private route = inject(ActivatedRoute);
  
  protected summary = signal<BudgetSummaryDto | null>(null);
  protected loading = signal(false);
  protected error = signal<string | null>(null);
  
  // Computed properties
  protected usageVariant = computed(() => {
    const usage = this.summary()?.usagePercentage || 0;
    return usage > 90 ? 'danger' : usage > 70 ? 'warning' : 'success';
  });

  async ngOnInit(): Promise<void> {
    await this.loadSummary();
  }

  protected async loadSummary(): Promise<void> {
    this.loading.set(true);
    this.error.set(null);
    
    const budgetId = this.route.snapshot.params['id'];
    const query: GetBudgetSummaryQuery = {
      budgetId,
      period: 'current_month'
    };
    
    const result = await this.getBudgetSummaryQuery.handle(query);
    
    if (result.hasError) {
      this.error.set(result.error.message);
    } else {
      this.summary.set(result.data!);
    }
    
    this.loading.set(false);
  }
}
```

#### 2. Query Handler (Application Layer)
```typescript
// application/queries/GetBudgetSummaryQueryHandler.ts
export interface GetBudgetSummaryQuery {
  readonly budgetId: string;
  readonly period: 'current_month' | 'last_month' | 'current_year';
}

export interface BudgetSummaryDto {
  readonly budgetId: string;
  readonly budgetName: string;
  readonly limit: Money;
  readonly totalSpent: Money;
  readonly remaining: Money;
  readonly usagePercentage: number;
  readonly transactionCount: number;
  readonly period: string;
}

@Injectable({ providedIn: 'root' })
export class GetBudgetSummaryQueryHandler {
  constructor(
    private budgetService: IBudgetServicePort,
    private transactionService: ITransactionServicePort
  ) {}

  async handle(query: GetBudgetSummaryQuery): Promise<Either<QueryError, BudgetSummaryDto>> {
    try {
      // 1. Buscar budget
      const budgetResult = await this.budgetService.getById(query.budgetId);
      if (budgetResult.hasError) {
        return Either.error(new BudgetNotFoundError(query.budgetId));
      }

      // 2. Buscar transações do período
      const transactionsResult = await this.transactionService.getByBudgetAndPeriod(
        query.budgetId,
        query.period
      );
      
      if (transactionsResult.hasError) {
        return Either.error(new QueryError('Failed to fetch transactions'));
      }

      // 3. Calcular métricas usando Domain Services
      const budget = budgetResult.data!;
      const transactions = transactionsResult.data!;
      
      const summary = BudgetSummaryCalculator.calculate(budget, transactions);
      
      // 4. Converter para DTO de resposta
      const dto: BudgetSummaryDto = {
        budgetId: budget.id,
        budgetName: budget.name,
        limit: budget.limit,
        totalSpent: summary.totalSpent,
        remaining: summary.remaining,
        usagePercentage: summary.usagePercentage,
        transactionCount: transactions.length,
        period: this.formatPeriod(query.period)
      };
      
      return Either.success(dto);
    } catch (error) {
      return Either.error(new QueryError('Unexpected error fetching budget summary'));
    }
  }

  private formatPeriod(period: GetBudgetSummaryQuery['period']): string {
    switch (period) {
      case 'current_month': return 'Este mês';
      case 'last_month': return 'Mês passado';
      case 'current_year': return 'Este ano';
      default: return 'Período desconhecido';
    }
  }
}
```

#### 3. HTTP Adapter para Query
```typescript
// infra/adapters/http/HttpBudgetServiceAdapter.ts
@Injectable({ providedIn: 'root' })
export class HttpBudgetServiceAdapter implements IBudgetServicePort {
  constructor(private httpClient: IHttpClient) {}

  async getBudgetSummary(
    budgetId: string, 
    period: string
  ): Promise<Either<ServiceError, BudgetSummaryApiDto>> {
    try {
      // Query-style endpoint (GET with params)
      const response = await this.httpClient.get<BudgetSummaryApiDto>(
        `/budget/${budgetId}/summary?period=${period}`
      );
      
      return Either.success(response);
    } catch (error) {
      if (error instanceof HttpError) {
        switch (error.status) {
          case 404:
            return Either.error(new BudgetNotFoundError(budgetId));
          case 403:
            return Either.error(new UnauthorizedError('access budget'));
          default:
            return Either.error(new ServiceError('Failed to fetch budget summary'));
        }
      }
      
      return Either.error(new ServiceError('Network error'));
    }
  }
}
```

---

## Estado no Cliente (Angular Signals)

### Estado Local por Página/Feature

```typescript
// Estado isolado por componente
@Component({...})
export class TransactionListPage {
  // Estado primário
  private transactions = signal<Transaction[]>([]);
  private loading = signal(false);
  private error = signal<string | null>(null);
  
  // Filtros
  private filters = signal<TransactionFilters>({
    category: null,
    dateRange: null,
    minAmount: null,
    maxAmount: null
  });
  
  // Estado computado
  protected filteredTransactions = computed(() => {
    const transactions = this.transactions();
    const filters = this.filters();
    
    return transactions.filter(transaction => {
      if (filters.category && transaction.categoryId !== filters.category) {
        return false;
      }
      
      if (filters.minAmount && transaction.amount.cents < filters.minAmount * 100) {
        return false;
      }
      
      // ... outros filtros
      return true;
    });
  });
  
  protected totalAmount = computed(() => {
    return this.filteredTransactions()
      .reduce((sum, t) => sum.add(t.amount), Money.zero());
  });
  
  protected isEmpty = computed(() => 
    !this.loading() && this.transactions().length === 0
  );
}
```

### Cache em Application Layer

```typescript
// Cache leve para dados de uso imediato
@Injectable({ providedIn: 'root' })
export class BudgetCacheService {
  private budgetCache = new Map<string, { data: Budget; expiresAt: number }>();
  private readonly TTL = 5 * 60 * 1000; // 5 minutos

  getCachedBudget(id: string): Budget | null {
    const cached = this.budgetCache.get(id);
    
    if (!cached) return null;
    
    if (Date.now() > cached.expiresAt) {
      this.budgetCache.delete(id);
      return null;
    }
    
    return cached.data;
  }

  setCachedBudget(budget: Budget): void {
    this.budgetCache.set(budget.id, {
      data: budget,
      expiresAt: Date.now() + this.TTL
    });
  }

  invalidateCache(budgetId?: string): void {
    if (budgetId) {
      this.budgetCache.delete(budgetId);
    } else {
      this.budgetCache.clear();
    }
  }
}
```

### Estado Global (Apenas se Necessário)

```typescript
// Apenas para dados verdadeiramente compartilhados
@Injectable({ providedIn: 'root' })
export class GlobalStateService {
  // Usuário autenticado
  private _currentUser = signal<AuthUser | null>(null);
  readonly currentUser = this._currentUser.asReadonly();
  
  // Configurações globais
  private _appConfig = signal<AppConfig | null>(null);
  readonly appConfig = this._appConfig.asReadonly();
  
  // Budget ativo (contexto atual)
  private _activeBudget = signal<Budget | null>(null);
  readonly activeBudget = this._activeBudget.asReadonly();
  
  setCurrentUser(user: AuthUser | null): void {
    this._currentUser.set(user);
  }
  
  setActiveBudget(budget: Budget | null): void {
    this._activeBudget.set(budget);
    
    // Invalidar caches relacionados quando contexto muda
    this.invalidateRelatedCaches(budget?.id);
  }
}
```

---

## Error Handling nos Fluxos

### Error Boundary para Commands
```typescript
// application/errors/CommandErrorHandler.ts
@Injectable({ providedIn: 'root' })
export class CommandErrorHandler {
  handleCommandError(error: UseCaseError): UserFacingError {
    if (error instanceof ValidationError) {
      return new UserFacingError(
        'Dados inválidos',
        error.message,
        'warning'
      );
    }
    
    if (error instanceof UnauthorizedError) {
      return new UserFacingError(
        'Acesso negado',
        'Você não tem permissão para esta operação',
        'error'
      );
    }
    
    if (error instanceof ConflictError) {
      return new UserFacingError(
        'Conflito de dados',
        'Os dados foram modificados por outro usuário',
        'warning'
      );
    }
    
    // Error genérico
    return new UserFacingError(
      'Erro inesperado',
      'Ocorreu um erro. Tente novamente em alguns instantes',
      'error'
    );
  }
}
```

### Error Boundary para Queries
```typescript
// application/errors/QueryErrorHandler.ts
@Injectable({ providedIn: 'root' })
export class QueryErrorHandler {
  handleQueryError(error: QueryError): UserFacingError {
    if (error instanceof NotFoundError) {
      return new UserFacingError(
        'Não encontrado',
        'Os dados solicitados não foram encontrados',
        'info'
      );
    }
    
    if (error instanceof NetworkError) {
      return new UserFacingError(
        'Sem conexão',
        'Verificando dados locais...',
        'warning'
      );
    }
    
    return new UserFacingError(
      'Erro ao carregar',
      'Não foi possível carregar os dados',
      'error'
    );
  }
}
```

---

## Padrões de Loading e Estados

### Loading States
```typescript
// Padrão para estados de loading granulares
@Component({...})
export class BudgetDashboard {
  // Loading states específicos
  protected loadingStates = {
    summary: signal(false),
    transactions: signal(false),
    charts: signal(false)
  };
  
  // Computed loading state geral
  protected isLoading = computed(() => 
    Object.values(this.loadingStates).some(loading => loading())
  );
  
  async loadData(): Promise<void> {
    // Carregar dados em paralelo com loading states independentes
    await Promise.all([
      this.loadSummary(),
      this.loadTransactions(),  
      this.loadCharts()
    ]);
  }
  
  private async loadSummary(): Promise<void> {
    this.loadingStates.summary.set(true);
    // ... load summary
    this.loadingStates.summary.set(false);
  }
}
```

---

**Ver também:**
- [Layer Responsibilities](./layer-responsibilities.md) - Detalhes das responsabilidades de cada camada
- [Backend Integration](./backend-integration.md) - Como integrar com APIs command-style
- [Offline Strategy](./offline-strategy.md) - Fluxos quando offline