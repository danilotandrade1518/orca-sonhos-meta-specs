# Fluxos de Dados e Interação

## Arquitetura de Fluxo de Dados

O frontend segue padrão **CQRS (Command Query Responsibility Segregation)** alinhado com o backend, separando claramente operações de escrita (Commands) e leitura (Queries). A arquitetura DTO-First garante que os dados fluam diretamente entre as camadas sem transformações complexas.

## Fluxo de Commands (Mutações)

### Arquitetura de Command
```
[UI Component] 
    ↓ (user action - DTO)
[Command (Application)] 
    ↓ (validação básica + orquestração)
[Port Interface]
    ↓ (contract)
[HTTP Adapter (Infra)]
    ↓ (HTTP POST com DTO)
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
  private createTransactionCommand = inject(CreateTransactionCommand);
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
    const request: CreateTransactionRequestDto = {
      description: formValue.description!,
      amountInCents: Math.round(formValue.amount! * 100),
      accountId: formValue.accountId!,
      categoryId: formValue.categoryId || undefined,
      date: new Date().toISOString()
    };
    
    const result = await this.createTransactionCommand.execute(request);
    
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

#### 2. Command (Application Layer)
```typescript
// application/commands/transaction/CreateTransactionCommand.ts
import { CreateTransactionRequestDto } from '@dtos/transaction/request/CreateTransactionRequestDto';
import { ICreateTransactionPort } from '@application/ports/mutations/transaction/ICreateTransactionPort';

@Injectable({ providedIn: 'root' })
export class CreateTransactionCommand {
  constructor(private port: ICreateTransactionPort) {}

  async execute(request: CreateTransactionRequestDto): Promise<Either<ApplicationError, void>> {
    // 1. Validação client-side básica (para UX)
    const validation = CreateTransactionValidator.validate(request);
    if (validation.hasError) {
      return Either.error(new ValidationError(validation.errors));
    }

    // 2. Chamar port (que implementa a operação)
    return this.port.execute(request);
  }
}

// application/validators/transaction/CreateTransactionValidator.ts
export class CreateTransactionValidator {
  static validate(dto: CreateTransactionRequestDto): ValidationResult {
    const errors: string[] = [];

    if (!dto.description?.trim()) {
      errors.push('Descrição é obrigatória');
    }

    if (!dto.amountInCents || dto.amountInCents <= 0) {
      errors.push('Valor deve ser maior que zero');
    }

    if (!dto.accountId?.trim()) {
      errors.push('Conta é obrigatória');
    }

    if (!dto.budgetId?.trim()) {
      errors.push('Orçamento é obrigatório');
    }

    if (!dto.type || !['INCOME', 'EXPENSE'].includes(dto.type)) {
      errors.push('Tipo deve ser INCOME ou EXPENSE');
    }

    return {
      hasError: errors.length > 0,
      errors,
    };
  }
}
```

#### 3. Port (Interface)
```typescript
// application/ports/mutations/transaction/ICreateTransactionPort.ts
import { CreateTransactionRequestDto } from '@dtos/transaction/request/CreateTransactionRequestDto';

export interface ICreateTransactionPort {
  execute(request: CreateTransactionRequestDto): Promise<Either<ServiceError, void>>;
}
```

#### 4. HTTP Adapter (Infrastructure)
```typescript
// infra/http/adapters/mutations/transaction/HttpCreateTransactionAdapter.ts
@Injectable({ providedIn: 'root' })
export class HttpCreateTransactionAdapter implements ICreateTransactionPort {
  constructor(private httpClient: IHttpClient) {}

  async execute(request: CreateTransactionRequestDto): Promise<Either<ServiceError, void>> {
    try {
      // Command-style endpoint (POST) - DTOs fluem diretamente
      await this.httpClient.post('/transaction/create', request);
      
      return Either.success(undefined);
    } catch (error) {
      if (error instanceof HttpError) {
        switch (error.status) {
          case 400:
            return Either.error(new ValidationError('Dados inválidos'));
          case 404:
            return Either.error(new AccountNotFoundError(request.accountId));
          case 409:
            return Either.error(new ConflictError('Transação já existe'));
          default:
            return Either.error(new ServiceError('Falha ao criar transação'));
        }
      }
      
      return Either.error(new ServiceError('Erro de rede'));
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
[Query (Application)]
    ↓ (query orchestration)
[Port Interface]
    ↓ (contract)
[HTTP Adapter (Infra)]
    ↓ (HTTP GET / Cache)
[Backend Query Endpoint / Local Storage]
    ↓ (Response DTO)
[UI Component] (exibe DTO diretamente)
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
              <os-money [amountInCents]="data.limitInCents" />
            </div>
            
            <div class="metric">
              <span class="label">Gasto</span>
              <os-money [amountInCents]="data.currentUsageInCents" />
            </div>
            
            <div class="metric">
              <span class="label">Disponível</span>
              <os-money [amountInCents]="data.remainingInCents" />
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
  private getBudgetSummaryQuery = inject(GetBudgetSummaryQuery);
  private route = inject(ActivatedRoute);
  
  protected summary = signal<BudgetSummaryResponseDto | null>(null);
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
    const request: GetBudgetSummaryRequest = {
      budgetId,
      period: 'current_month'
    };
    
    const result = await this.getBudgetSummaryQuery.execute(request);
    
    if (result.hasError) {
      this.error.set(result.error.message);
    } else {
      this.summary.set(result.data!);
    }
    
    this.loading.set(false);
  }
}
```

#### 2. Query (Application Layer)
```typescript
// application/queries/budget/GetBudgetSummaryQuery.ts
import { BudgetSummaryResponseDto } from '@dtos/budget/response/BudgetSummaryResponseDto';
import { IGetBudgetSummaryPort } from '@application/ports/queries/budget/IGetBudgetSummaryPort';

export interface GetBudgetSummaryRequest {
  readonly budgetId: string;
  readonly period: 'current_month' | 'last_month' | 'current_year';
}

@Injectable({ providedIn: 'root' })
export class GetBudgetSummaryQuery {
  constructor(private port: IGetBudgetSummaryPort) {}

  async execute(request: GetBudgetSummaryRequest): Promise<Either<QueryError, BudgetSummaryResponseDto>> {
    try {
      // Chamar port (que implementa a operação)
      return this.port.execute(request);
    } catch (error) {
      return Either.error(new QueryError('Falha ao buscar resumo do orçamento'));
    }
  }
}
```

#### 3. HTTP Adapter para Query
```typescript
// infra/http/adapters/queries/budget/HttpGetBudgetSummaryAdapter.ts
@Injectable({ providedIn: 'root' })
export class HttpGetBudgetSummaryAdapter implements IGetBudgetSummaryPort {
  constructor(private httpClient: IHttpClient) {}

  async execute(request: GetBudgetSummaryRequest): Promise<Either<ServiceError, BudgetSummaryResponseDto>> {
    try {
      // Query-style endpoint (GET with params) - DTOs fluem diretamente
      const response = await this.httpClient.get<BudgetSummaryResponseDto>(
        `/budget/${request.budgetId}/summary?period=${request.period}`
      );
      
      return Either.success(response);
    } catch (error) {
      if (error instanceof HttpError) {
        switch (error.status) {
          case 404:
            return Either.error(new BudgetNotFoundError(request.budgetId));
          case 403:
            return Either.error(new UnauthorizedError('acessar orçamento'));
          default:
            return Either.error(new ServiceError('Falha ao buscar resumo do orçamento'));
        }
      }
      
      return Either.error(new ServiceError('Erro de rede'));
    }
  }
}
```

---

## Estado no Cliente (Angular Signals)

### Estado Local por Página/Feature

```typescript
// Estado isolado por componente usando DTOs diretamente
@Component({...})
export class TransactionListPage {
  // Estado primário com DTOs
  private transactions = signal<TransactionResponseDto[]>([]);
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
      
      if (filters.minAmount && transaction.amountInCents < filters.minAmount * 100) {
        return false;
      }
      
      // ... outros filtros
      return true;
    });
  });
  
  protected totalAmount = computed(() => {
    return this.filteredTransactions()
      .reduce((sum, t) => sum + t.amountInCents, 0);
  });
  
  protected isEmpty = computed(() => 
    !this.loading() && this.transactions().length === 0
  );
}
```

### Cache em Application Layer

```typescript
// Cache leve para dados de uso imediato usando DTOs
@Injectable({ providedIn: 'root' })
export class BudgetCacheService {
  private budgetCache = new Map<string, { data: BudgetResponseDto; expiresAt: number }>();
  private readonly TTL = 5 * 60 * 1000; // 5 minutos

  getCachedBudget(id: string): BudgetResponseDto | null {
    const cached = this.budgetCache.get(id);
    
    if (!cached) return null;
    
    if (Date.now() > cached.expiresAt) {
      this.budgetCache.delete(id);
      return null;
    }
    
    return cached.data;
  }

  setCachedBudget(budget: BudgetResponseDto): void {
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
// Apenas para dados verdadeiramente compartilhados usando DTOs
@Injectable({ providedIn: 'root' })
export class GlobalStateService {
  // Usuário autenticado
  private _currentUser = signal<AuthUserResponseDto | null>(null);
  readonly currentUser = this._currentUser.asReadonly();
  
  // Configurações globais
  private _appConfig = signal<AppConfigResponseDto | null>(null);
  readonly appConfig = this._appConfig.asReadonly();
  
  // Budget ativo (contexto atual)
  private _activeBudget = signal<BudgetResponseDto | null>(null);
  readonly activeBudget = this._activeBudget.asReadonly();
  
  setCurrentUser(user: AuthUserResponseDto | null): void {
    this._currentUser.set(user);
  }
  
  setActiveBudget(budget: BudgetResponseDto | null): void {
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
  handleCommandError(error: ApplicationError): UserFacingError {
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
// Padrão para estados de loading granulares usando DTOs
@Component({...})
export class BudgetDashboard {
  // Loading states específicos
  protected loadingStates = {
    summary: signal(false),
    transactions: signal(false),
    charts: signal(false)
  };
  
  // Estado com DTOs
  protected summary = signal<BudgetSummaryResponseDto | null>(null);
  protected transactions = signal<TransactionResponseDto[]>([]);
  protected charts = signal<ChartDataResponseDto | null>(null);
  
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
    // ... load summary usando DTOs
    this.loadingStates.summary.set(false);
  }
}
```

---

**Ver também:**
- [Layer Responsibilities](./layer-responsibilities.md) - Detalhes das responsabilidades de cada camada
- [Backend Integration](./backend-integration.md) - Como integrar com APIs usando DTOs
- [DTO-First Principles](./dto-first-principles.md) - Princípios fundamentais da arquitetura
- [Offline Strategy](./offline-strategy.md) - Fluxos quando offline