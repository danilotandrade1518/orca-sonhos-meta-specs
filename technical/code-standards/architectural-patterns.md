# Architectural Patterns - Padrões Arquiteturais

## 🏛️ Padrões de Arquitetura

### Repository Pattern

```typescript
// ✅ Separação Add vs Save vs Get vs Find
interface IAddTransactionRepository {
  execute(transaction: Transaction): Promise<Either<RepositoryError, void>>;
}

interface ISaveTransactionRepository {
  execute(transaction: Transaction): Promise<Either<RepositoryError, void>>;
}

interface IGetTransactionRepository {
  execute(
    id: TransactionId
  ): Promise<Either<RepositoryError, Transaction | null>>;
}

interface IFindTransactionRepository {
  execute(
    criteria: TransactionCriteria
  ): Promise<Either<RepositoryError, Transaction[]>>;
}

// ✅ Use Cases específicos com repositories específicos
export class CreateTransactionUseCase {
  constructor(
    private readonly addRepository: IAddTransactionRepository,
    private readonly authService: IBudgetAuthorizationService
  ) {}

  async execute(
    dto: CreateTransactionDto,
    userId: string
  ): Promise<Either<ApplicationError, TransactionId>> {
    // 1. Authorization check
    const authResult = await this.authService.canManageTransactions(
      userId,
      dto.budgetId
    );
    if (authResult.isLeft()) {
      return Either.left(
        new UnauthorizedError("Cannot manage transactions in this budget")
      );
    }

    // 2. Create domain entity
    const transactionResult = Transaction.create(dto);
    if (transactionResult.isLeft()) {
      return Either.left(new DomainError(transactionResult.value.message));
    }

    // 3. Persist
    const saveResult = await this.addRepository.execute(
      transactionResult.value
    );
    return saveResult.map(() => transactionResult.value.id);
  }
}

export class MarkTransactionLateUseCase {
  constructor(
    private readonly getRepository: IGetTransactionRepository,
    private readonly saveRepository: ISaveTransactionRepository,
    private readonly authService: IBudgetAuthorizationService
  ) {}

  async execute(
    id: TransactionId,
    userId: string
  ): Promise<Either<ApplicationError, void>> {
    // 1. Get existing transaction
    const transactionResult = await this.getRepository.execute(id);
    if (transactionResult.isLeft()) {
      return Either.left(new NotFoundError("Transaction not found"));
    }

    const transaction = transactionResult.value;
    if (!transaction) {
      return Either.left(new NotFoundError("Transaction not found"));
    }

    // 2. Authorization check
    const authResult = await this.authService.canManageTransactions(
      userId,
      transaction.budgetId
    );
    if (authResult.isLeft()) {
      return Either.left(
        new UnauthorizedError("Cannot manage this transaction")
      );
    }

    // 3. Apply domain logic
    const markResult = transaction.markAsLate();
    if (markResult.isLeft()) {
      return Either.left(new DomainError(markResult.value.message));
    }

    // 4. Save changes
    return this.saveRepository.execute(transaction);
  }
}

// ✅ Repository implementation
export class PostgresTransactionRepository
  implements
    IAddTransactionRepository,
    ISaveTransactionRepository,
    IGetTransactionRepository,
    IFindTransactionRepository
{
  constructor(private readonly db: IDatabase) {}

  async execute(
    transaction: Transaction
  ): Promise<Either<RepositoryError, void>> {
    try {
      const sql = `
        INSERT INTO transactions (id, amount_cents, description, budget_id, category_id, created_at)
        VALUES ($1, $2, $3, $4, $5, $6)
      `;

      await this.db.none(sql, [
        transaction.id.value,
        transaction.amount.cents,
        transaction.description,
        transaction.budgetId.value,
        transaction.categoryId?.value,
        transaction.createdAt,
      ]);

      return Either.right(void 0);
    } catch (error) {
      return Either.left(
        new RepositoryError("Failed to add transaction", error)
      );
    }
  }
}
```

### Unit of Work Pattern

```typescript
// ✅ Nomenclatura consistente para Unit of Work
export interface IUnitOfWork {
  commit(): Promise<Either<UnitOfWorkError, void>>;
  rollback(): Promise<Either<UnitOfWorkError, void>>;
}

export class TransferBetweenAccountsUnitOfWork implements IUnitOfWork {
  constructor(
    private readonly db: IDatabase,
    private readonly fromAccountRepository: IGetAccountRepository &
      ISaveAccountRepository,
    private readonly toAccountRepository: IGetAccountRepository &
      ISaveAccountRepository,
    private readonly transactionRepository: IAddTransactionRepository
  ) {}

  async executeTransfer(
    params: TransferBetweenAccountsParams
  ): Promise<Either<TransferError, void>> {
    const transaction = await this.db.tx(async (tx) => {
      // 1. Get source account
      const fromAccountResult = await this.fromAccountRepository.execute(
        params.fromAccountId
      );
      if (fromAccountResult.isLeft() || !fromAccountResult.value) {
        throw new Error("Source account not found");
      }

      // 2. Get target account
      const toAccountResult = await this.toAccountRepository.execute(
        params.toAccountId
      );
      if (toAccountResult.isLeft() || !toAccountResult.value) {
        throw new Error("Target account not found");
      }

      // 3. Validate transfer
      const fromAccount = fromAccountResult.value;
      const toAccount = toAccountResult.value;

      const debitResult = fromAccount.debit(params.amount);
      if (debitResult.isLeft()) {
        throw new Error(debitResult.value.message);
      }

      const creditResult = toAccount.credit(params.amount);
      if (creditResult.isLeft()) {
        throw new Error(creditResult.value.message);
      }

      // 4. Save account changes
      await this.fromAccountRepository.execute(fromAccount);
      await this.toAccountRepository.execute(toAccount);

      // 5. Create transfer transactions
      const debitTransaction = Transaction.createDebit({
        accountId: params.fromAccountId,
        amount: params.amount,
        description: `Transfer to ${toAccount.name}`,
        budgetId: params.budgetId,
      });

      const creditTransaction = Transaction.createCredit({
        accountId: params.toAccountId,
        amount: params.amount,
        description: `Transfer from ${fromAccount.name}`,
        budgetId: params.budgetId,
      });

      await this.transactionRepository.execute(debitTransaction.value);
      await this.transactionRepository.execute(creditTransaction.value);

      return Either.right(void 0);
    });

    return transaction.fold(
      (error) => Either.left(new TransferError(error.message)),
      (result) => result
    );
  }

  async commit(): Promise<Either<UnitOfWorkError, void>> {
    // Handled by database transaction
    return Either.right(void 0);
  }

  async rollback(): Promise<Either<UnitOfWorkError, void>> {
    // Handled by database transaction
    return Either.right(void 0);
  }
}

// ✅ Organização por contexto
// /src/infrastructure/database/pg/unit-of-works/
// ├── transfer-between-accounts/
// │   ├── TransferBetweenAccountsUnitOfWork.ts
// │   ├── TransferBetweenAccountsUnitOfWork.spec.ts
// │   └── TransferBetweenAccountsParams.ts
// ├── pay-credit-card-bill/
// │   ├── PayCreditCardBillUnitOfWork.ts
// │   └── PayCreditCardBillUnitOfWork.spec.ts
```

### CQRS Pattern

```typescript
// ✅ Command vs Query separation
export interface ICommand {
  readonly type: string;
}

export interface IQuery {
  readonly type: string;
}

// Commands - para mutação
export class CreateTransactionCommand implements ICommand {
  readonly type = "CREATE_TRANSACTION";

  constructor(
    public readonly dto: CreateTransactionDto,
    public readonly userId: string
  ) {}
}

export class MarkTransactionLateCommand implements ICommand {
  readonly type = "MARK_TRANSACTION_LATE";

  constructor(
    public readonly transactionId: TransactionId,
    public readonly userId: string
  ) {}
}

// Queries - para leitura
export class GetTransactionByIdQuery implements IQuery {
  readonly type = "GET_TRANSACTION_BY_ID";

  constructor(
    public readonly id: TransactionId,
    public readonly userId: string
  ) {}
}

export class FindTransactionsByBudgetQuery implements IQuery {
  readonly type = "FIND_TRANSACTIONS_BY_BUDGET";

  constructor(
    public readonly budgetId: BudgetId,
    public readonly criteria: TransactionCriteria,
    public readonly userId: string
  ) {}
}

// ✅ Command Handler
export class CreateTransactionCommandHandler {
  constructor(private readonly useCase: CreateTransactionUseCase) {}

  async handle(
    command: CreateTransactionCommand
  ): Promise<Either<ApplicationError, TransactionId>> {
    return this.useCase.execute(command.dto, command.userId);
  }
}

// ✅ Query Handler
export class GetTransactionByIdQueryHandler {
  constructor(
    private readonly repository: IGetTransactionRepository,
    private readonly authService: IBudgetAuthorizationService
  ) {}

  async handle(
    query: GetTransactionByIdQuery
  ): Promise<Either<ApplicationError, Transaction | null>> {
    // 1. Get transaction
    const result = await this.repository.execute(query.id);
    if (result.isLeft()) {
      return Either.left(new NotFoundError("Transaction not found"));
    }

    const transaction = result.value;
    if (!transaction) {
      return Either.right(null);
    }

    // 2. Authorization check
    const authResult = await this.authService.canViewTransactions(
      query.userId,
      transaction.budgetId
    );
    if (authResult.isLeft()) {
      return Either.left(new UnauthorizedError("Cannot view this transaction"));
    }

    return Either.right(transaction);
  }
}

// ✅ Command/Query Bus
@Injectable({ providedIn: "root" })
export class CommandBus {
  private readonly handlers = new Map<string, any>();

  registerHandler<T extends ICommand>(commandType: string, handler: any): void {
    this.handlers.set(commandType, handler);
  }

  async execute<T extends ICommand, R>(command: T): Promise<R> {
    const handler = this.handlers.get(command.type);
    if (!handler) {
      throw new Error(`No handler registered for command: ${command.type}`);
    }

    return handler.handle(command);
  }
}

@Injectable({ providedIn: "root" })
export class QueryBus {
  private readonly handlers = new Map<string, any>();

  registerHandler<T extends IQuery>(queryType: string, handler: any): void {
    this.handlers.set(queryType, handler);
  }

  async execute<T extends IQuery, R>(query: T): Promise<R> {
    const handler = this.handlers.get(query.type);
    if (!handler) {
      throw new Error(`No handler registered for query: ${query.type}`);
    }

    return handler.handle(query);
  }
}
```

### Clean Architecture Boundaries

```typescript
// ✅ Domain Layer - Pure TypeScript
export class Transaction {
  private constructor(
    public readonly id: TransactionId,
    public readonly amount: Money,
    public readonly description: string,
    private _status: TransactionStatus,
    public readonly budgetId: BudgetId,
    public readonly createdAt: Date
  ) {}

  public static create(
    dto: CreateTransactionDto
  ): Either<DomainError, Transaction> {
    // Domain validation and construction
    const id = TransactionId.generate();
    const amount = Money.fromCents(dto.amountCents);

    if (amount.isZeroOrNegative()) {
      return Either.left(new InvalidAmountError("Amount must be positive"));
    }

    if (!dto.description.trim()) {
      return Either.left(
        new InvalidDescriptionError("Description is required")
      );
    }

    return Either.right(
      new Transaction(
        id,
        amount,
        dto.description.trim(),
        TransactionStatus.PENDING,
        new BudgetId(dto.budgetId),
        new Date()
      )
    );
  }

  public markAsLate(): Either<DomainError, void> {
    // Business rule: only pending transactions can be marked late
    if (this._status !== TransactionStatus.PENDING) {
      return Either.left(
        new InvalidTransactionStateError(
          "Only pending transactions can be marked late"
        )
      );
    }

    this._status = TransactionStatus.LATE;
    return Either.right(void 0);
  }

  public get status(): TransactionStatus {
    return this._status;
  }
}

// ✅ Application Layer - Orchestration
export class CreateTransactionUseCase {
  constructor(
    private readonly repository: IAddTransactionRepository,
    private readonly authService: IBudgetAuthorizationService,
    private readonly eventDispatcher: IDomainEventDispatcher
  ) {}

  async execute(
    dto: CreateTransactionDto,
    userId: string
  ): Promise<Either<ApplicationError, TransactionId>> {
    // 1. Authorization (Application concern)
    const authResult = await this.authService.canManageTransactions(
      userId,
      dto.budgetId
    );
    if (authResult.isLeft()) {
      return Either.left(new UnauthorizedError());
    }

    // 2. Domain logic
    const transactionResult = Transaction.create(dto);
    if (transactionResult.isLeft()) {
      return Either.left(new DomainError(transactionResult.value.message));
    }

    // 3. Persistence (Infrastructure concern)
    const saveResult = await this.repository.execute(transactionResult.value);
    if (saveResult.isLeft()) {
      return Either.left(new PersistenceError());
    }

    // 4. Events (Application concern)
    await this.eventDispatcher.dispatch(
      new TransactionCreatedEvent(transactionResult.value)
    );

    return Either.right(transactionResult.value.id);
  }
}

// ✅ Infrastructure Layer - External concerns
export class PostgresTransactionRepository
  implements IAddTransactionRepository
{
  constructor(private readonly db: IDatabase) {}

  async execute(
    transaction: Transaction
  ): Promise<Either<RepositoryError, void>> {
    try {
      // SQL and database specific logic
      const result = await this.db.one(
        `
        INSERT INTO transactions (id, amount_cents, description, status, budget_id, created_at)
        VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING id
      `,
        [
          transaction.id.value,
          transaction.amount.cents,
          transaction.description,
          transaction.status,
          transaction.budgetId.value,
          transaction.createdAt,
        ]
      );

      return Either.right(void 0);
    } catch (error) {
      return Either.left(new RepositoryError("Database error", error));
    }
  }
}

// ✅ UI Layer - Angular specific
@Component({
  selector: "os-create-transaction",
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <form [formGroup]="form" (ngSubmit)="onSubmit()">
      <!-- UI specific template -->
    </form>
  `,
})
export class CreateTransactionComponent {
  private readonly useCase = inject(CreateTransactionUseCase);

  readonly form = signal(this.createForm());
  readonly loading = signal(false);

  async onSubmit(): Promise<void> {
    // UI orchestration
    this.loading.set(true);

    const result = await this.useCase.execute(
      this.form().value,
      this.getCurrentUserId()
    );

    result.fold(
      (error) => this.handleError(error),
      (transactionId) => this.handleSuccess(transactionId)
    );

    this.loading.set(false);
  }
}
```

### Feature-Based Architecture Patterns

```typescript
// ✅ Feature Module Organization
// /src/app/features/transactions/
// ├── transactions.module.ts
// ├── transactions.routes.ts
// ├── components/
// │   ├── transaction-list/
// │   ├── transaction-form/
// │   └── transaction-detail/
// ├── services/
// │   ├── transaction-state.service.ts
// │   └── transaction-api.service.ts
// ├── models/
// │   ├── transaction.model.ts
// │   └── transaction-filters.model.ts
// └── index.ts

// ✅ Feature Module com Dependency Injection
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

    // ✅ Feature-specific use cases
    CreateTransactionUseCase,
    UpdateTransactionUseCase,
    DeleteTransactionUseCase,

    // ✅ Feature-specific repositories
    {
      provide: ITransactionRepository,
      useClass: HttpTransactionRepository,
    },
  ],
})
export class TransactionsModule {}

// ✅ Feature Service Layer
@Injectable({ providedIn: "root" })
export class TransactionStateService {
  private readonly _transactions = signal<Transaction[]>([]);
  private readonly _loading = signal(false);
  private readonly _error = signal<string | null>(null);

  readonly transactions = this._transactions.asReadonly();
  readonly loading = this._loading.asReadonly();
  readonly error = this._error.asReadonly();

  constructor(
    private readonly transactionRepository: ITransactionRepository,
    private readonly createUseCase: CreateTransactionUseCase,
    private readonly updateUseCase: UpdateTransactionUseCase
  ) {}

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
      }
    );
  }
}
```

### Feature Communication Patterns

```typescript
// ✅ Feature Event Bus
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

  emitBudgetUpdated(budget: Budget): void {
    this.emit({
      type: "BUDGET_UPDATED",
      payload: budget,
      source: "budgets",
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

// ✅ Feature Communication Service
@Injectable({ providedIn: "root" })
export class FeatureCommunicationService {
  constructor(private readonly eventBus: FeatureEventBus) {}

  // ✅ Listen to specific feature events
  onTransactionCreated(): Observable<Transaction> {
    return this.eventBus.events$.pipe(
      filter((event) => event.type === "TRANSACTION_CREATED"),
      map((event) => event.payload)
    );
  }

  onBudgetUpdated(): Observable<Budget> {
    return this.eventBus.events$.pipe(
      filter((event) => event.type === "BUDGET_UPDATED"),
      map((event) => event.payload)
    );
  }
}
```

### Feature State Management

```typescript
// ✅ Feature State Store
@Injectable({ providedIn: "root" })
export class FeatureStateStore {
  private readonly state = signal<FeatureState>({
    transactions: [],
    budgets: [],
    goals: [],
    loading: false,
    error: null,
  });

  readonly state$ = this.state.asReadonly();

  // ✅ Feature-specific state updates
  updateTransactions(transactions: Transaction[]): void {
    this.state.update((current) => ({
      ...current,
      transactions,
    }));
  }

  updateBudgets(budgets: Budget[]): void {
    this.state.update((current) => ({
      ...current,
      budgets,
    }));
  }

  setLoading(loading: boolean): void {
    this.state.update((current) => ({
      ...current,
      loading,
    }));
  }

  setError(error: string | null): void {
    this.state.update((current) => ({
      ...current,
      error,
    }));
  }
}

// ✅ Feature State Types
interface FeatureState {
  transactions: Transaction[];
  budgets: Budget[];
  goals: Goal[];
  loading: boolean;
  error: string | null;
}
```

### Dependency Injection Containers

```typescript
// ✅ Domain Services Registration
export const DOMAIN_SERVICES = [
  {
    provide: IBudgetAuthorizationService,
    useClass: BudgetAuthorizationService,
  },
  {
    provide: ITransactionValidationService,
    useClass: TransactionValidationService,
  },
];

// ✅ Use Case Registration
export const USE_CASES = [
  CreateTransactionUseCase,
  MarkTransactionLateUseCase,
  GetTransactionByIdUseCase,
  FindTransactionsByBudgetUseCase,
];

// ✅ Repository Registration
export const REPOSITORIES = [
  {
    provide: IAddTransactionRepository,
    useClass: PostgresTransactionRepository,
  },
  {
    provide: ISaveTransactionRepository,
    useClass: PostgresTransactionRepository,
  },
  {
    provide: IGetTransactionRepository,
    useClass: PostgresTransactionRepository,
  },
];

// ✅ Infrastructure Services
export const INFRASTRUCTURE_SERVICES = [
  {
    provide: IDatabase,
    useFactory: createDatabaseConnection,
    deps: [DatabaseConfig],
  },
  {
    provide: IEventDispatcher,
    useClass: InMemoryEventDispatcher,
  },
];

// ✅ Feature Services
export const FEATURE_SERVICES = [
  FeatureEventBus,
  FeatureCommunicationService,
  FeatureStateStore,
];

// ✅ Application Module
@NgModule({
  providers: [
    ...DOMAIN_SERVICES,
    ...USE_CASES,
    ...REPOSITORIES,
    ...INFRASTRUCTURE_SERVICES,
    ...FEATURE_SERVICES,
  ],
})
export class ApplicationModule {}
```

---

**Princípios arquiteturais obrigatórios:**

- ✅ **Repository Pattern** com separação Add/Save/Get/Find
- ✅ **Unit of Work** para operações transacionais
- ✅ **CQRS** para separação Command/Query
- ✅ **Clean Architecture** com boundaries claros
- ✅ **Dependency Inversion** em todas as camadas
- ✅ **Domain-Driven Design** para modelagem
- ✅ **Either Pattern** para tratamento de erros
- ✅ **Feature-Based Architecture** para organização modular
- ✅ **Feature Communication** com event bus
- ✅ **Feature State Management** com services dedicados
- ✅ **Lazy Loading** por features

**Próximos tópicos:**

- **[API Patterns](./api-patterns.md)** - Padrões de API
- **[Security Standards](./security-standards.md)** - Padrões de segurança
