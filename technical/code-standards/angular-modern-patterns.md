# Angular Modern Patterns - Padrões Angular Modernos

## 🅰️ Angular Específico - Padrões Modernos

### Componentes Modernos (Obrigatório)

```typescript
// ✅ Padrões obrigatórios para todos os componentes
@Component({
  selector: 'os-transaction-form',
  // standalone: true é padrão (não declarar explicitamente)
  changeDetection: ChangeDetectionStrategy.OnPush, // ← SEMPRE OnPush
  imports: [CommonModule, ReactiveFormsModule], // ← Import explícito
  template: `
    @if (loading()) {
      <os-loading />
    } @else {
      <form [formGroup]="form" (ngSubmit)="onSubmit()">
        @for (field of formFields(); track field.id) {
          <os-form-field [field]="field" />
        }
        <button type="submit" [disabled]="form.invalid">
          Save Transaction
        </button>
      </form>
    }
  `
})
export class TransactionFormComponent {
  // ✅ Usar function-based APIs
  readonly loading = signal(false);
  readonly form = signal(this.createForm());
  readonly formFields = computed(() => this.generateFields());
  
  // ✅ Usar inject() ao invés de constructor injection
  private readonly useCase = inject(CreateTransactionUseCase);
  private readonly router = inject(Router);
  private readonly destroyRef = inject(DestroyRef);
  
  // ✅ input()/output() functions
  readonly transaction = input<Transaction>();
  readonly budgetId = input.required<string>();
  readonly save = output<TransactionId>();
  
  async onSubmit(): Promise<void> {
    if (this.form().invalid) return;
    
    this.loading.set(true);
    
    const result = await this.useCase.execute(
      this.form().value,
      this.budgetId()
    );
    
    result.fold(
      error => this.handleError(error),
      transactionId => {
        this.save.emit(transactionId);
        this.router.navigate(['/transactions', transactionId]);
      }
    );
    
    this.loading.set(false);
  }
  
  private createForm(): FormGroup {
    return new FormGroup({
      amount: new FormControl('', [Validators.required, Validators.min(0.01)]),
      description: new FormControl('', [Validators.required]),
      categoryId: new FormControl('', [Validators.required])
    });
  }
}
```

### Control Flow Nativo (Obrigatório)

```typescript
@Component({
  template: `
    <!-- ✅ @if com alias para reutilização -->
    @if (user(); as currentUser) {
      <div class="user-info">
        <h2>Olá, {{ currentUser.name }}</h2>
        <p>{{ currentUser.email }}</p>
      </div>
    } @else {
      <os-login-form />
    }
    
    <!-- ✅ @for com track para performance -->
    @for (transaction of transactions(); track transaction.id) {
      <os-transaction-card 
        [transaction]="transaction"
        [class.selected]="isSelected(transaction.id)"
        (click)="selectTransaction(transaction.id)"
      />
    } @empty {
      <div class="empty-state">
        <p>Nenhuma transação encontrada</p>
        <os-button (click)="createTransaction()">
          Criar primeira transação
        </os-button>
      </div>
    }
    
    <!-- ✅ @switch para estados múltiplos -->
    @switch (status()) {
      @case ('loading') { 
        <os-spinner text="Carregando transações..." />
      }
      @case ('error') { 
        <os-error-message 
          [error]="error()" 
          (retry)="reload()" 
        />
      }
      @case ('empty') {
        <os-empty-state 
          icon="receipt"
          title="Sem transações"
          message="Comece criando sua primeira transação"
        />
      }
      @default { 
        <os-transaction-list [transactions]="transactions()" />
      }
    }
    
    <!-- ✅ Bindings diretos ao invés de ngClass/ngStyle -->
    <button 
      type="button"
      [class.btn-primary]="isPrimary()"
      [class.btn-disabled]="disabled()"
      [class.btn-loading]="loading()"
      [style.width.px]="buttonWidth()"
      [style.background-color]="themeColor()">
      {{ buttonText() }}
    </button>
  `
})
export class ModernComponentExample { }
```

### Signals para Estado Reativo

```typescript
export class TransactionListComponent {
  // ✅ Signals para estado local
  readonly transactions = signal<Transaction[]>([]);
  readonly selectedIds = signal<Set<string>>(new Set());
  readonly searchTerm = signal('');
  readonly sortBy = signal<'date' | 'amount' | 'description'>('date');
  readonly sortDirection = signal<'asc' | 'desc'>('desc');
  
  // ✅ Computed para derivações
  readonly filteredTransactions = computed(() => {
    const transactions = this.transactions();
    const searchTerm = this.searchTerm().toLowerCase();
    
    return transactions
      .filter(t => t.description.toLowerCase().includes(searchTerm))
      .sort((a, b) => this.compareTransactions(a, b));
  });
  
  readonly selectedCount = computed(() => this.selectedIds().size);
  readonly hasSelection = computed(() => this.selectedCount() > 0);
  readonly totalAmount = computed(() => 
    this.filteredTransactions()
      .reduce((sum, t) => sum.add(t.amount), Money.zero())
  );
  
  // ✅ Effects para side effects
  constructor() {
    // Persist search term to localStorage
    effect(() => {
      const searchTerm = this.searchTerm();
      if (searchTerm) {
        localStorage.setItem('transaction-search', searchTerm);
      }
    });
    
    // Log selection changes (debug only)
    effect(() => {
      const count = this.selectedCount();
      console.debug(`Selected transactions: ${count}`);
    });
  }
  
  // ✅ Métodos que atualizam signals
  updateSearchTerm(term: string): void {
    this.searchTerm.set(term);
  }
  
  toggleTransaction(id: string): void {
    this.selectedIds.update(ids => {
      const newIds = new Set(ids);
      if (newIds.has(id)) {
        newIds.delete(id);
      } else {
        newIds.add(id);
      }
      return newIds;
    });
  }
  
  clearSelection(): void {
    this.selectedIds.set(new Set());
  }
  
  private compareTransactions(a: Transaction, b: Transaction): number {
    const direction = this.sortDirection() === 'asc' ? 1 : -1;
    const sortBy = this.sortBy();
    
    switch (sortBy) {
      case 'date':
        return direction * (a.date.getTime() - b.date.getTime());
      case 'amount':
        return direction * (a.amount.cents - b.amount.cents);
      case 'description':
        return direction * a.description.localeCompare(b.description);
      default:
        return 0;
    }
  }
}
```

### Serviços e Dependency Injection

```typescript
// ✅ Serviços modernos com inject()
@Injectable({ providedIn: 'root' })
export class TransactionService {
  // ✅ Usar inject() ao invés de constructor injection
  private readonly httpClient = inject(HttpClient);
  private readonly authService = inject(AuthService);
  private readonly errorHandler = inject(ErrorHandlerService);
  private readonly configService = inject(ConfigService);
  
  // ✅ Signals para estado do serviço
  private readonly _loading = signal(false);
  private readonly _error = signal<ServiceError | null>(null);
  
  // ✅ Readonly getters para expor estado
  readonly loading = this._loading.asReadonly();
  readonly error = this._error.asReadonly();
  
  // ✅ Métodos retornam Either
  async createTransaction(dto: CreateTransactionDto): Promise<Either<ServiceError, Transaction>> {
    this._loading.set(true);
    this._error.set(null);
    
    try {
      const token = await this.authService.getToken();
      if (!token) {
        const error = new UnauthorizedError('No valid token');
        this._error.set(error);
        return Either.left(error);
      }
      
      const response = await this.httpClient.post<TransactionDto>(
        `${this.configService.apiUrl}/transaction/create-transaction`,
        dto,
        {
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          }
        }
      ).toPromise();
      
      const transaction = this.mapToTransaction(response);
      return Either.right(transaction);
      
    } catch (httpError) {
      const error = this.errorHandler.handleHttpError(httpError);
      this._error.set(error);
      return Either.left(error);
    } finally {
      this._loading.set(false);
    }
  }
  
  private mapToTransaction(dto: TransactionDto): Transaction {
    return Transaction.reconstruct({
      id: dto.id,
      amount: Money.fromCents(dto.amountCents),
      description: dto.description,
      date: new Date(dto.date),
      categoryId: dto.categoryId
    });
  }
}
```

### Formulários Reativos Modernos

```typescript
@Component({
  selector: 'os-advanced-transaction-form',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <form [formGroup]="form" (ngSubmit)="onSubmit()">
      <!-- Amount field with validation -->
      <os-money-input
        formControlName="amount"
        label="Valor"
        [error]="getFieldError('amount')"
        [disabled]="loading()"
      />
      
      <!-- Dynamic category selection -->
      <os-select
        formControlName="categoryId"
        label="Categoria"
        [options]="categoryOptions()"
        [loading]="categoriesLoading()"
        [error]="getFieldError('categoryId')"
      />
      
      <!-- Smart description field -->
      <os-text-input
        formControlName="description"
        label="Descrição"
        [suggestions]="descriptionSuggestions()"
        [error]="getFieldError('description')"
      />
      
      <!-- Submit button with loading state -->
      <os-button
        type="submit"
        [disabled]="form.invalid || loading()"
        [loading]="loading()"
      >
        {{ submitButtonText() }}
      </os-button>
    </form>
  `
})
export class AdvancedTransactionFormComponent {
  // ✅ FormBuilder com inject()
  private readonly fb = inject(FormBuilder);
  private readonly categoryService = inject(CategoryService);
  private readonly transactionService = inject(TransactionService);
  
  // ✅ Form como signal computed
  readonly form = signal(this.createForm());
  
  // ✅ Loading states
  readonly loading = signal(false);
  readonly categoriesLoading = this.categoryService.loading;
  
  // ✅ Computed values
  readonly categoryOptions = computed(() => 
    this.categoryService.categories().map(c => ({
      value: c.id,
      label: c.name,
      icon: c.icon
    }))
  );
  
  readonly submitButtonText = computed(() => 
    this.loading() ? 'Salvando...' : 'Salvar Transação'
  );
  
  readonly descriptionSuggestions = computed(() => {
    const categoryId = this.form().get('categoryId')?.value;
    return this.getDescriptionSuggestionsForCategory(categoryId);
  });
  
  // ✅ Input signals
  readonly initialData = input<Partial<CreateTransactionDto>>();
  readonly budgetId = input.required<string>();
  
  // ✅ Output signals
  readonly save = output<Transaction>();
  readonly cancel = output<void>();
  
  constructor() {
    // ✅ Effect para reagir a mudanças nos inputs
    effect(() => {
      const data = this.initialData();
      if (data) {
        this.form().patchValue(data);
      }
    });
    
    // ✅ Effect para validação em tempo real
    effect(() => {
      const amount = this.form().get('amount')?.value;
      const categoryId = this.form().get('categoryId')?.value;
      
      if (amount && categoryId) {
        this.validateTransactionLimits(amount, categoryId);
      }
    });
  }
  
  async onSubmit(): Promise<void> {
    if (this.form().invalid) {
      this.markAllFieldsAsTouched();
      return;
    }
    
    this.loading.set(true);
    
    const dto: CreateTransactionDto = {
      ...this.form().value,
      budgetId: this.budgetId()
    };
    
    const result = await this.transactionService.createTransaction(dto);
    
    result.fold(
      error => this.handleSubmitError(error),
      transaction => {
        this.save.emit(transaction);
        this.resetForm();
      }
    );
    
    this.loading.set(false);
  }
  
  getFieldError(fieldName: string): string | null {
    const field = this.form().get(fieldName);
    if (field?.errors && field.touched) {
      return this.formatFieldError(field.errors);
    }
    return null;
  }
  
  private createForm(): FormGroup {
    return this.fb.group({
      amount: ['', [Validators.required, this.positiveAmountValidator]],
      description: ['', [Validators.required, Validators.maxLength(200)]],
      categoryId: ['', [Validators.required]],
      date: [new Date(), [Validators.required]]
    });
  }
  
  private positiveAmountValidator(control: AbstractControl): ValidationErrors | null {
    const value = parseFloat(control.value);
    return value > 0 ? null : { positiveAmount: true };
  }
}
```

### Guards e Interceptors Modernos

```typescript
// ✅ Guard funcional (recomendado)
export const budgetAccessGuard: CanActivateFn = (route, state) => {
  const authService = inject(AuthService);
  const budgetService = inject(BudgetService);
  const router = inject(Router);
  
  return authService.getCurrentUser().pipe(
    switchMap(user => {
      if (!user) {
        router.navigate(['/login']);
        return of(false);
      }
      
      const budgetId = route.params['budgetId'];
      return budgetService.checkUserAccess(user.id, budgetId);
    }),
    map(hasAccess => {
      if (!hasAccess) {
        router.navigate(['/forbidden']);
        return false;
      }
      return true;
    }),
    catchError(() => {
      router.navigate(['/error']);
      return of(false);
    })
  );
};

// ✅ Interceptor funcional
export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const authService = inject(AuthService);
  const router = inject(Router);
  
  return authService.getToken().pipe(
    switchMap(token => {
      const authReq = token 
        ? req.clone({
            setHeaders: {
              'Authorization': `Bearer ${token}`,
              'X-Requested-With': 'XMLHttpRequest'
            }
          })
        : req;
      
      return next(authReq).pipe(
        catchError(error => {
          if (error.status === 401) {
            authService.clearSession();
            router.navigate(['/login']);
          }
          return throwError(() => error);
        })
      );
    })
  );
};
```

### Roteamento Moderno

```typescript
// ✅ Rotas com lazy loading e guards funcionais
export const TRANSACTION_ROUTES: Route[] = [
  {
    path: '',
    canActivate: [budgetAccessGuard],
    children: [
      {
        path: '',
        loadComponent: () => import('./transaction-list.page').then(m => m.TransactionListPage),
        title: 'Transações'
      },
      {
        path: 'create',
        loadComponent: () => import('./transaction-form.page').then(m => m.TransactionFormPage),
        title: 'Nova Transação'
      },
      {
        path: ':id',
        loadComponent: () => import('./transaction-detail.page').then(m => m.TransactionDetailPage),
        title: resolveTransactionTitle
      },
      {
        path: ':id/edit',
        loadComponent: () => import('./transaction-form.page').then(m => m.TransactionFormPage),
        title: 'Editar Transação',
        data: { mode: 'edit' }
      }
    ]
  }
];

// ✅ Title resolver
const resolveTransactionTitle: ResolveFn<string> = (route) => {
  const transactionService = inject(TransactionService);
  const id = route.params['id'];
  
  return transactionService.getById(id).pipe(
    map(result => result.fold(
      () => 'Transação não encontrada',
      transaction => `Transação - ${transaction.description}`
    ))
  );
};
```

---

**Resumo dos padrões obrigatórios:**
- ✅ `ChangeDetectionStrategy.OnPush` em todos os componentes
- ✅ `inject()` ao invés de constructor injection
- ✅ Signals para estado reativo
- ✅ Control flow nativo (@if, @for, @switch)
- ✅ input()/output() functions
- ✅ Guards e interceptors funcionais
- ✅ Lazy loading por features

**Próximos tópicos:**
- **[Performance Optimization](./performance-optimization.md)** - Otimização de performance
- **[Testing Standards](./testing-standards.md)** - Padrões de testes