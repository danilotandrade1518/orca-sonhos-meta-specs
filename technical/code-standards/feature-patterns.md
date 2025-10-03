# Feature Patterns - Padrões para Feature-Based Architecture

## 🏗️ Estrutura de Features

### Organização Padrão de Feature

```typescript
// /src/app/features/transactions/
// ├── transactions.module.ts
// ├── transactions.routes.ts
// ├── index.ts
// ├── /components
// │   ├── transaction-list.component.ts
// │   ├── transaction-form.component.ts
// │   ├── transaction-detail.component.ts
// │   └── /shared
// │       ├── transaction-card.component.ts
// │       └── transaction-filters.component.ts
// ├── /services
// │   ├── transaction-state.service.ts
// │   ├── transaction-api.service.ts
// │   └── transaction-validation.service.ts
// ├── /models
// │   ├── transaction.model.ts
// │   ├── transaction-filters.model.ts
// │   └── transaction-form-data.model.ts
// ├── /validators
// │   ├── transaction-form.validator.ts
// │   └── transaction-filters.validator.ts
// └── /guards
//     ├── transaction-access.guard.ts
//     └── transaction-edit.guard.ts
```

### Feature Module Pattern

```typescript
// transactions.module.ts
@NgModule({
  declarations: [],
  imports: [
    CommonModule,
    RouterModule.forChild(TRANSACTION_ROUTES),
    ReactiveFormsModule,
    SharedModule,
  ],
  providers: [
    // ✅ Feature-specific services
    TransactionStateService,
    TransactionApiService,
    TransactionValidationService,

    // ✅ Feature-specific use cases
    CreateTransactionUseCase,
    UpdateTransactionUseCase,
    DeleteTransactionUseCase,
    GetTransactionUseCase,

    // ✅ Feature-specific guards
    TransactionAccessGuard,
    TransactionEditGuard,

    // ✅ Feature-specific repositories
    {
      provide: ITransactionRepository,
      useClass: HttpTransactionRepository,
    },
  ],
})
export class TransactionsModule {}
```

### Feature Routes Pattern

```typescript
// transactions.routes.ts
export const TRANSACTION_ROUTES: Route[] = [
  {
    path: "",
    canActivate: [TransactionAccessGuard],
    children: [
      {
        path: "",
        loadComponent: () =>
          import("./components/transaction-list.component").then(
            (m) => m.TransactionListComponent
          ),
        title: "Transações",
      },
      {
        path: "create",
        loadComponent: () =>
          import("./components/transaction-form.component").then(
            (m) => m.TransactionFormComponent
          ),
        title: "Nova Transação",
        canActivate: [TransactionCreateGuard],
      },
      {
        path: ":id",
        loadComponent: () =>
          import("./components/transaction-detail.component").then(
            (m) => m.TransactionDetailComponent
          ),
        title: resolveTransactionTitle,
      },
      {
        path: ":id/edit",
        loadComponent: () =>
          import("./components/transaction-form.component").then(
            (m) => m.TransactionFormComponent
          ),
        title: "Editar Transação",
        canActivate: [TransactionEditGuard],
        data: { mode: "edit" },
      },
    ],
  },
];

// ✅ Title resolver
const resolveTransactionTitle: ResolveFn<string> = (route) => {
  const transactionService = inject(TransactionService);
  const id = route.params["id"];

  return transactionService.getById(id).pipe(
    map((result) =>
      result.fold(
        () => "Transação não encontrada",
        (transaction) => `Transação - ${transaction.description}`
      )
    )
  );
};
```

## 🎯 Feature State Management

### Feature State Service Pattern

```typescript
// transaction-state.service.ts
@Injectable({ providedIn: "root" })
export class TransactionStateService {
  // ✅ Private state signals
  private readonly _transactions = signal<Transaction[]>([]);
  private readonly _loading = signal(false);
  private readonly _error = signal<string | null>(null);
  private readonly _filters = signal<TransactionFilters>({});
  private readonly _selectedIds = signal<Set<string>>(new Set());

  // ✅ Readonly getters
  readonly transactions = this._transactions.asReadonly();
  readonly loading = this._loading.asReadonly();
  readonly error = this._error.asReadonly();
  readonly filters = this._filters.asReadonly();
  readonly selectedIds = this._selectedIds.asReadonly();

  // ✅ Computed values
  readonly filteredTransactions = computed(() => {
    const transactions = this._transactions();
    const filters = this._filters();

    return transactions.filter((t) => this.matchesFilters(t, filters));
  });

  readonly selectedCount = computed(() => this._selectedIds().size);
  readonly hasSelection = computed(() => this.selectedCount() > 0);
  readonly totalAmount = computed(() =>
    this.filteredTransactions().reduce((sum, t) => sum + t.amount, 0)
  );

  constructor(
    private readonly transactionRepository: ITransactionRepository,
    private readonly createUseCase: CreateTransactionUseCase,
    private readonly updateUseCase: UpdateTransactionUseCase,
    private readonly deleteUseCase: DeleteTransactionUseCase
  ) {}

  // ✅ Actions
  async loadTransactions(budgetId: string): Promise<void> {
    this._loading.set(true);
    this._error.set(null);

    try {
      const result = await this.transactionRepository.findByBudgetId(budgetId);
      result.fold(
        (error) => this._error.set(error.message),
        (transactions) => this._transactions.set(transactions)
      );
    } finally {
      this._loading.set(false);
    }
  }

  async createTransaction(dto: CreateTransactionDto): Promise<void> {
    const result = await this.createUseCase.execute(dto);
    result.fold(
      (error) => this._error.set(error.message),
      (transaction) => {
        this._transactions.update((transactions) => [
          ...transactions,
          transaction,
        ]);
        this.emitTransactionCreated(transaction);
      }
    );
  }

  async updateTransaction(
    id: string,
    dto: UpdateTransactionDto
  ): Promise<void> {
    const result = await this.updateUseCase.execute(id, dto);
    result.fold(
      (error) => this._error.set(error.message),
      (transaction) => {
        this._transactions.update((transactions) =>
          transactions.map((t) => (t.id === id ? transaction : t))
        );
        this.emitTransactionUpdated(transaction);
      }
    );
  }

  async deleteTransaction(id: string): Promise<void> {
    const result = await this.deleteUseCase.execute(id);
    result.fold(
      (error) => this._error.set(error.message),
      () => {
        this._transactions.update((transactions) =>
          transactions.filter((t) => t.id !== id)
        );
        this._selectedIds.update((ids) => {
          const newIds = new Set(ids);
          newIds.delete(id);
          return newIds;
        });
        this.emitTransactionDeleted(id);
      }
    );
  }

  // ✅ Filter actions
  updateFilters(filters: Partial<TransactionFilters>): void {
    this._filters.update((current) => ({ ...current, ...filters }));
  }

  clearFilters(): void {
    this._filters.set({});
  }

  // ✅ Selection actions
  toggleSelection(id: string): void {
    this._selectedIds.update((ids) => {
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
    this._selectedIds.set(new Set());
  }

  selectAll(): void {
    const allIds = new Set(this.filteredTransactions().map((t) => t.id));
    this._selectedIds.set(allIds);
  }

  // ✅ Private methods
  private matchesFilters(
    transaction: Transaction,
    filters: TransactionFilters
  ): boolean {
    if (
      filters.searchTerm &&
      !transaction.description
        .toLowerCase()
        .includes(filters.searchTerm.toLowerCase())
    ) {
      return false;
    }

    if (filters.categoryId && transaction.categoryId !== filters.categoryId) {
      return false;
    }

    if (filters.startDate && transaction.date < filters.startDate) {
      return false;
    }

    if (filters.endDate && transaction.date > filters.endDate) {
      return false;
    }

    return true;
  }

  private emitTransactionCreated(transaction: Transaction): void {
    // Emit event via FeatureCommunicationService
  }

  private emitTransactionUpdated(transaction: Transaction): void {
    // Emit event via FeatureCommunicationService
  }

  private emitTransactionDeleted(transactionId: string): void {
    // Emit event via FeatureCommunicationService
  }
}
```

## 🔄 Feature Communication

### Feature Event Bus Pattern

```typescript
// feature-event-bus.service.ts
@Injectable({ providedIn: "root" })
export class FeatureEventBus {
  private readonly events = new Subject<FeatureEvent>();

  readonly events$ = this.events.asObservable();

  emit(event: FeatureEvent): void {
    this.events.next(event);
  }

  // ✅ Typed event methods
  emitTransactionCreated(transaction: Transaction): void {
    this.emit({
      type: "TRANSACTION_CREATED",
      payload: transaction,
      source: "transactions",
      timestamp: new Date(),
    });
  }

  emitTransactionUpdated(transaction: Transaction): void {
    this.emit({
      type: "TRANSACTION_UPDATED",
      payload: transaction,
      source: "transactions",
      timestamp: new Date(),
    });
  }

  emitTransactionDeleted(transactionId: string): void {
    this.emit({
      type: "TRANSACTION_DELETED",
      payload: { transactionId },
      source: "transactions",
      timestamp: new Date(),
    });
  }

  emitBudgetUpdated(budget: Budget): void {
    this.emit({
      type: "BUDGET_UPDATED",
      payload: budget,
      source: "budgets",
      timestamp: new Date(),
    });
  }

  emitGoalUpdated(goal: Goal): void {
    this.emit({
      type: "GOAL_UPDATED",
      payload: goal,
      source: "goals",
      timestamp: new Date(),
    });
  }
}

// ✅ Feature Event Types
interface FeatureEvent {
  type: string;
  payload: any;
  source: string;
  timestamp: Date;
}

// ✅ Event Type Constants
export const FEATURE_EVENTS = {
  TRANSACTION_CREATED: "TRANSACTION_CREATED",
  TRANSACTION_UPDATED: "TRANSACTION_UPDATED",
  TRANSACTION_DELETED: "TRANSACTION_DELETED",
  BUDGET_UPDATED: "BUDGET_UPDATED",
  BUDGET_DELETED: "BUDGET_DELETED",
  GOAL_UPDATED: "GOAL_UPDATED",
  GOAL_DELETED: "GOAL_DELETED",
} as const;
```

### Feature Communication Service Pattern

```typescript
// feature-communication.service.ts
@Injectable({ providedIn: "root" })
export class FeatureCommunicationService {
  constructor(private readonly eventBus: FeatureEventBus) {}

  // ✅ Listen to specific feature events
  onTransactionCreated(): Observable<Transaction> {
    return this.eventBus.events$.pipe(
      filter((event) => event.type === FEATURE_EVENTS.TRANSACTION_CREATED),
      map((event) => event.payload)
    );
  }

  onTransactionUpdated(): Observable<Transaction> {
    return this.eventBus.events$.pipe(
      filter((event) => event.type === FEATURE_EVENTS.TRANSACTION_UPDATED),
      map((event) => event.payload)
    );
  }

  onTransactionDeleted(): Observable<{ transactionId: string }> {
    return this.eventBus.events$.pipe(
      filter((event) => event.type === FEATURE_EVENTS.TRANSACTION_DELETED),
      map((event) => event.payload)
    );
  }

  onBudgetUpdated(): Observable<Budget> {
    return this.eventBus.events$.pipe(
      filter((event) => event.type === FEATURE_EVENTS.BUDGET_UPDATED),
      map((event) => event.payload)
    );
  }

  onGoalUpdated(): Observable<Goal> {
    return this.eventBus.events$.pipe(
      filter((event) => event.type === FEATURE_EVENTS.GOAL_UPDATED),
      map((event) => event.payload)
    );
  }

  // ✅ Generic event listener
  onEvent(eventType: string): Observable<FeatureEvent> {
    return this.eventBus.events$.pipe(
      filter((event) => event.type === eventType)
    );
  }
}
```

## 🎨 Feature Component Patterns

### Feature Page Component Pattern

```typescript
// transaction-list.component.ts
@Component({
  selector: "os-transaction-list",
  standalone: true,
  imports: [
    CommonModule,
    RouterModule,
    OsButtonComponent,
    OsCardComponent,
    OsDataTableComponent,
    TransactionFiltersComponent,
  ],
  template: `
    <div class="transaction-list">
      <header class="page-header">
        <h1>Transações</h1>
        <os-button variant="primary" (click)="navigateToCreate()">
          Nova Transação
        </os-button>
      </header>

      <os-transaction-filters
        [filters]="stateService.filters()"
        (filtersChange)="stateService.updateFilters($event)"
        (clear)="stateService.clearFilters()"
      />

      <os-data-table
        [data]="stateService.filteredTransactions()"
        [loading]="stateService.loading()"
        [error]="stateService.error()"
        [selectedIds]="stateService.selectedIds()"
        (rowClick)="navigateToDetail($event)"
        (rowEdit)="navigateToEdit($event)"
        (selectionChange)="stateService.toggleSelection($event)"
        (selectAll)="stateService.selectAll()"
        (clearSelection)="stateService.clearSelection()"
      />
    </div>
  `,
})
export class TransactionListComponent {
  private readonly stateService = inject(TransactionStateService);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);
  private readonly featureComm = inject(FeatureCommunicationService);

  readonly budgetId = computed(() => this.route.snapshot.params["budgetId"]);

  constructor() {
    // ✅ Load data on init
    effect(() => {
      const budgetId = this.budgetId();
      if (budgetId) {
        this.stateService.loadTransactions(budgetId);
      }
    });

    // ✅ Listen to feature events
    this.featureComm
      .onTransactionCreated()
      .pipe(takeUntilDestroyed())
      .subscribe((transaction) => {
        // Refresh list or show notification
        this.stateService.loadTransactions(this.budgetId());
      });
  }

  navigateToCreate(): void {
    this.router.navigate(["create"], { relativeTo: this.route });
  }

  navigateToDetail(transactionId: string): void {
    this.router.navigate([transactionId], { relativeTo: this.route });
  }

  navigateToEdit(transactionId: string): void {
    this.router.navigate([transactionId, "edit"], { relativeTo: this.route });
  }
}
```

### Feature Form Component Pattern

```typescript
// transaction-form.component.ts
@Component({
  selector: "os-transaction-form",
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    OsButtonComponent,
    OsFormFieldComponent,
    OsSelectComponent,
  ],
  template: `
    <form [formGroup]="form" (ngSubmit)="onSubmit()">
      <os-form-field
        formControlName="amount"
        label="Valor"
        type="number"
        [error]="getFieldError('amount')"
        [disabled]="loading()"
      />

      <os-form-field
        formControlName="description"
        label="Descrição"
        [error]="getFieldError('description')"
        [disabled]="loading()"
      />

      <os-select
        formControlName="categoryId"
        label="Categoria"
        [options]="categoryOptions()"
        [error]="getFieldError('categoryId')"
        [disabled]="loading()"
      />

      <os-button
        type="submit"
        [disabled]="form.invalid || loading()"
        [loading]="loading()"
      >
        {{ submitButtonText() }}
      </os-button>
    </form>
  `,
})
export class TransactionFormComponent {
  private readonly fb = inject(FormBuilder);
  private readonly stateService = inject(TransactionStateService);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);

  readonly form = signal(this.createForm());
  readonly loading = signal(false);
  readonly mode = computed(() => this.route.snapshot.data["mode"] || "create");

  readonly submitButtonText = computed(() =>
    this.mode() === "edit" ? "Atualizar Transação" : "Criar Transação"
  );

  readonly categoryOptions = computed(() =>
    this.stateService.categories().map((c) => ({
      value: c.id,
      label: c.name,
      icon: c.icon,
    }))
  );

  // ✅ Input signals
  readonly initialData = input<Partial<CreateTransactionDto>>();

  // ✅ Output signals
  readonly saved = output<Transaction>();
  readonly cancelled = output<void>();

  constructor() {
    // ✅ Effect para reagir a mudanças nos inputs
    effect(() => {
      const data = this.initialData();
      if (data) {
        this.form().patchValue(data);
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
      budgetId: this.route.snapshot.params["budgetId"],
    };

    if (this.mode() === "edit") {
      const id = this.route.snapshot.params["id"];
      await this.stateService.updateTransaction(id, dto);
    } else {
      await this.stateService.createTransaction(dto);
    }

    this.loading.set(false);
    this.saved.emit(this.form().value);
    this.router.navigate(["../"], { relativeTo: this.route });
  }

  onCancel(): void {
    this.cancelled.emit();
    this.router.navigate(["../"], { relativeTo: this.route });
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
      amount: ["", [Validators.required, Validators.min(0.01)]],
      description: ["", [Validators.required, Validators.maxLength(200)]],
      categoryId: ["", [Validators.required]],
      date: [new Date(), [Validators.required]],
    });
  }

  private markAllFieldsAsTouched(): void {
    Object.keys(this.form().controls).forEach((key) => {
      this.form().get(key)?.markAsTouched();
    });
  }

  private formatFieldError(errors: ValidationErrors): string {
    // Error formatting logic
    return "Campo inválido";
  }
}
```

## 🛡️ Feature Guards

### Feature Access Guard Pattern

```typescript
// transaction-access.guard.ts
@Injectable({ providedIn: "root" })
export class TransactionAccessGuard implements CanActivate {
  constructor(
    private readonly authService: AuthService,
    private readonly budgetService: BudgetService,
    private readonly router: Router
  ) {}

  canActivate(route: ActivatedRouteSnapshot): boolean {
    const user = this.authService.getCurrentUser();
    if (!user) {
      this.router.navigate(["/login"]);
      return false;
    }

    const budgetId = route.params["budgetId"];
    if (!budgetId) {
      this.router.navigate(["/budgets"]);
      return false;
    }

    const hasAccess = this.budgetService.checkUserAccess(user.id, budgetId);
    if (!hasAccess) {
      this.router.navigate(["/forbidden"]);
      return false;
    }

    return true;
  }
}

// transaction-edit.guard.ts
@Injectable({ providedIn: "root" })
export class TransactionEditGuard implements CanActivate {
  constructor(
    private readonly authService: AuthService,
    private readonly transactionService: TransactionService,
    private readonly router: Router
  ) {}

  canActivate(route: ActivatedRouteSnapshot): boolean {
    const user = this.authService.getCurrentUser();
    if (!user) {
      this.router.navigate(["/login"]);
      return false;
    }

    const transactionId = route.params["id"];
    if (!transactionId) {
      this.router.navigate(["/transactions"]);
      return false;
    }

    const canEdit = this.transactionService.canUserEdit(user.id, transactionId);
    if (!canEdit) {
      this.router.navigate(["/forbidden"]);
      return false;
    }

    return true;
  }
}
```

## 📝 Feature Index Pattern

### Feature Index File

```typescript
// index.ts
// ✅ Export all public components
export * from "./components/transaction-list.component";
export * from "./components/transaction-form.component";
export * from "./components/transaction-detail.component";

// ✅ Export all public services
export * from "./services/transaction-state.service";
export * from "./services/transaction-api.service";

// ✅ Export all public models
export * from "./models/transaction.model";
export * from "./models/transaction-filters.model";

// ✅ Export routes and module
export * from "./transactions.routes";
export * from "./transactions.module";

// ✅ Export guards
export * from "./guards/transaction-access.guard";
export * from "./guards/transaction-edit.guard";
```

## 🚫 Anti-Patterns a Evitar

### ❌ Feature Coupling

```typescript
// ❌ EVITAR - Import direto entre features
import { BudgetService } from "@features/budgets/services/budget.service";
import { GoalService } from "@features/goals/services/goal.service";

// ✅ PREFERIR - Comunicação via Core/Shared
import { FeatureCommunicationService } from "@core/services/feature-communication.service";
```

### ❌ Shared State Between Features

```typescript
// ❌ EVITAR - Estado compartilhado entre features
export class GlobalStateService {
  transactions: Transaction[] = [];
  budgets: Budget[] = [];
  goals: Goal[] = [];
}

// ✅ PREFERIR - Estado local por feature
export class TransactionStateService {
  private readonly _transactions = signal<Transaction[]>([]);
}
```

### ❌ Feature Dependencies

```typescript
// ❌ EVITAR - Dependências diretas entre features
export class TransactionService {
  constructor(
    private readonly budgetService: BudgetService, // ❌
    private readonly goalService: GoalService // ❌
  ) {}
}

// ✅ PREFERIR - Dependências via Core
export class TransactionService {
  constructor(
    private readonly featureComm: FeatureCommunicationService // ✅
  ) {}
}
```

---

**Princípios Feature-Based obrigatórios:**

- ✅ **Feature Isolation** - Features são independentes
- ✅ **Feature Communication** - Comunicação via Core/Shared
- ✅ **Feature State Management** - Estado local por feature
- ✅ **Feature Lazy Loading** - Carregamento sob demanda
- ✅ **Feature Guards** - Controle de acesso por feature
- ✅ **Feature Index** - Exports organizados

**Próximos tópicos:**

- **[Design System Patterns](./design-system-patterns.md)** - Padrões do Design System
- **[Testing Standards](./testing-standards.md)** - Padrões de testes
