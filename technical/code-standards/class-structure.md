# Estrutura de Classes e Métodos

## 📋 Ordem de Declaração

**Todas as classes** devem seguir esta ordem obrigatória:

1. **Propriedades públicas** (incluindo getters/setters)
2. **Propriedades privadas**
3. **Construtor**
4. **Métodos públicos**
5. **Métodos estáticos**
6. **Métodos privados**

```typescript
export class TransactionService {
  // 1. Propriedades públicas
  public readonly config: TransactionConfig;
  public readonly isActive = true;
  
  // 2. Propriedades privadas
  private readonly repository: ITransactionRepository;
  private readonly logger: ILogger;
  private transactionCache: Map<string, Transaction> = new Map();
  
  // 3. Construtor
  constructor(
    repository: ITransactionRepository,
    logger: ILogger,
    config: TransactionConfig
  ) {
    this.repository = repository;
    this.logger = logger;
    this.config = config;
  }
  
  // 4. Métodos públicos
  public async createTransaction(dto: CreateTransactionDto): Promise<Either<Error, Transaction>> {
    const validation = this.validateTransactionData(dto);
    if (validation.isLeft()) {
      return validation;
    }
    
    return this.executeTransactionCreation(dto);
  }
  
  public async getTransactionById(id: string): Promise<Either<Error, Transaction>> {
    const cached = this.transactionCache.get(id);
    if (cached) {
      return Either.right(cached);
    }
    
    return this.repository.findById(id);
  }
  
  // 5. Métodos estáticos
  public static fromConfig(config: ServiceConfig): TransactionService {
    const repository = new PostgresTransactionRepository(config.database);
    const logger = new FileLogger(config.logging);
    return new TransactionService(repository, logger, config.transaction);
  }
  
  public static createDefault(): TransactionService {
    return TransactionService.fromConfig(DefaultConfig);
  }
  
  // 6. Métodos privados
  private validateTransactionData(dto: CreateTransactionDto): Either<ValidationError, void> {
    if (!dto.amount || dto.amount <= 0) {
      return Either.left(new ValidationError('Invalid amount'));
    }
    if (!dto.description?.trim()) {
      return Either.left(new ValidationError('Description is required'));
    }
    return Either.right(undefined);
  }
  
  private async executeTransactionCreation(dto: CreateTransactionDto): Promise<Either<Error, Transaction>> {
    this.logTransactionEvent('creation_started', dto);
    
    const transaction = Transaction.create(dto);
    if (transaction.isLeft()) {
      return transaction;
    }
    
    const result = await this.repository.save(transaction.value);
    if (result.isLeft()) {
      this.logTransactionEvent('creation_failed', dto);
      return result;
    }
    
    this.transactionCache.set(transaction.value.id.value, transaction.value);
    this.logTransactionEvent('creation_completed', dto);
    
    return Either.right(transaction.value);
  }
  
  private logTransactionEvent(event: string, context?: any): void {
    this.logger.info(`Transaction ${event}`, { context, timestamp: new Date() });
  }
}
```

## 🏗️ Padrões de Construção

### Domain Entities

```typescript
export class Transaction {
  // 1. Propriedades públicas readonly
  public readonly id: TransactionId;
  public readonly amount: Money;
  public readonly budgetId: BudgetId;
  public readonly createdAt: Date;
  
  // 2. Propriedades privadas mutáveis
  private status: TransactionStatus;
  private description: string;
  
  // 3. Construtor privado (factory pattern obrigatório)
  private constructor(
    id: TransactionId,
    amount: Money,
    budgetId: BudgetId,
    description: string,
    status: TransactionStatus = TransactionStatus.PENDING,
    createdAt: Date = new Date()
  ) {
    this.id = id;
    this.amount = amount;
    this.budgetId = budgetId;
    this.description = description;
    this.status = status;
    this.createdAt = createdAt;
  }
  
  // 4. Métodos públicos - behaviors
  public markAsCompleted(): Either<DomainError, void> {
    if (this.status === TransactionStatus.CANCELLED) {
      return Either.left(new InvalidTransactionStateError('Cannot complete cancelled transaction'));
    }
    
    this.status = TransactionStatus.COMPLETED;
    return Either.right(undefined);
  }
  
  public updateDescription(newDescription: string): Either<DomainError, void> {
    const validation = this.validateDescription(newDescription);
    if (validation.isLeft()) {
      return validation;
    }
    
    this.description = newDescription;
    return Either.right(undefined);
  }
  
  public isCompleted(): boolean {
    return this.status === TransactionStatus.COMPLETED;
  }
  
  public getStatus(): TransactionStatus {
    return this.status;
  }
  
  public getDescription(): string {
    return this.description;
  }
  
  // 5. Métodos estáticos - factory methods
  public static create(dto: CreateTransactionDto): Either<DomainError, Transaction> {
    const validation = Transaction.validateCreationData(dto);
    if (validation.isLeft()) {
      return validation;
    }
    
    const id = TransactionId.generate();
    const amount = Money.fromCents(dto.amountInCents);
    const budgetId = BudgetId.fromString(dto.budgetId);
    
    if (amount.isLeft()) return amount;
    if (budgetId.isLeft()) return budgetId;
    
    return Either.right(new Transaction(
      id,
      amount.value,
      budgetId.value,
      dto.description
    ));
  }
  
  public static reconstruct(data: TransactionData): Transaction {
    return new Transaction(
      TransactionId.fromString(data.id).getOrThrow(),
      Money.fromCents(data.amountInCents).getOrThrow(),
      BudgetId.fromString(data.budgetId).getOrThrow(),
      data.description,
      TransactionStatus.fromString(data.status).getOrThrow(),
      new Date(data.createdAt)
    );
  }
  
  // 6. Métodos privados - validações internas
  private validateDescription(description: string): Either<ValidationError, void> {
    if (!description?.trim()) {
      return Either.left(new ValidationError('Description cannot be empty'));
    }
    if (description.length > 255) {
      return Either.left(new ValidationError('Description too long'));
    }
    return Either.right(undefined);
  }
  
  private static validateCreationData(dto: CreateTransactionDto): Either<DomainError, void> {
    if (!dto.amountInCents || dto.amountInCents <= 0) {
      return Either.left(new ValidationError('Amount must be positive'));
    }
    if (!dto.budgetId?.trim()) {
      return Either.left(new ValidationError('Budget ID is required'));
    }
    if (!dto.description?.trim()) {
      return Either.left(new ValidationError('Description is required'));
    }
    return Either.right(undefined);
  }
}
```

### Use Cases

```typescript
export class CreateTransactionUseCase {
  // 1. Propriedades públicas (raramente usadas em Use Cases)
  
  // 2. Propriedades privadas - dependencies
  private readonly authService: IBudgetAuthorizationService;
  private readonly addRepository: IAddTransactionRepository;
  private readonly getBudgetRepository: IGetBudgetRepository;
  private readonly logger: ILogger;
  
  // 3. Construtor - dependency injection
  constructor(
    authService: IBudgetAuthorizationService,
    addRepository: IAddTransactionRepository,
    getBudgetRepository: IGetBudgetRepository,
    logger: ILogger
  ) {
    this.authService = authService;
    this.addRepository = addRepository;
    this.getBudgetRepository = getBudgetRepository;
    this.logger = logger;
  }
  
  // 4. Métodos públicos - main business logic
  public async execute(
    dto: CreateTransactionDto, 
    userId: string
  ): Promise<Either<ApplicationError, TransactionId>> {
    // 1. Log início da operação
    this.logOperationStart('create_transaction', { userId, budgetId: dto.budgetId });
    
    // 2. Autorização
    const authResult = await this.checkUserAuthorization(dto.budgetId, userId);
    if (authResult.isLeft()) {
      return authResult;
    }
    
    // 3. Validação de dados
    const validationResult = this.validateTransactionData(dto);
    if (validationResult.isLeft()) {
      return validationResult;
    }
    
    // 4. Verificar se budget existe e está ativo
    const budgetResult = await this.validateBudgetExists(dto.budgetId);
    if (budgetResult.isLeft()) {
      return budgetResult;
    }
    
    // 5. Criar entidade de domínio
    const transaction = Transaction.create(dto);
    if (transaction.isLeft()) {
      return Either.left(new ApplicationError(transaction.value.message));
    }
    
    // 6. Persistir
    const saveResult = await this.addRepository.execute(transaction.value);
    if (saveResult.isLeft()) {
      this.logOperationError('create_transaction', saveResult.value);
      return Either.left(new ApplicationError('Failed to save transaction'));
    }
    
    // 7. Log sucesso e retorno
    this.logOperationSuccess('create_transaction', { transactionId: transaction.value.id.value });
    return Either.right(transaction.value.id);
  }
  
  // 5. Métodos estáticos (raramente usados em Use Cases)
  
  // 6. Métodos privados - steps e validations
  private async checkUserAuthorization(budgetId: string, userId: string): Promise<Either<ApplicationError, void>> {
    const authResult = await this.authService.canUserAccessBudget(budgetId, userId);
    if (authResult.isLeft()) {
      return Either.left(new UnauthorizedError('User not authorized for this budget'));
    }
    return Either.right(undefined);
  }
  
  private validateTransactionData(dto: CreateTransactionDto): Either<ApplicationError, void> {
    if (!dto.amountInCents || dto.amountInCents <= 0) {
      return Either.left(new ValidationError('Amount must be positive'));
    }
    if (!dto.description?.trim()) {
      return Either.left(new ValidationError('Description is required'));
    }
    return Either.right(undefined);
  }
  
  private async validateBudgetExists(budgetId: string): Promise<Either<ApplicationError, void>> {
    const budget = await this.getBudgetRepository.execute(budgetId);
    if (budget.isLeft()) {
      return Either.left(new NotFoundError('Budget not found'));
    }
    return Either.right(undefined);
  }
  
  private logOperationStart(operation: string, context: any): void {
    this.logger.info(`${operation}_started`, context);
  }
  
  private logOperationSuccess(operation: string, context: any): void {
    this.logger.info(`${operation}_completed`, context);
  }
  
  private logOperationError(operation: string, error: any): void {
    this.logger.error(`${operation}_failed`, { error: error.message, stack: error.stack });
  }
}
```

### Value Objects

```typescript
export class Money {
  // 1. Propriedades públicas
  public readonly cents: number;
  public readonly currency: string;
  
  // 2. Propriedades privadas
  private static readonly DEFAULT_CURRENCY = 'BRL';
  private static readonly MAX_CENTS = 999999999999; // ~10 milhões de reais
  
  // 3. Construtor privado
  private constructor(cents: number, currency: string = Money.DEFAULT_CURRENCY) {
    this.cents = cents;
    this.currency = currency;
  }
  
  // 4. Métodos públicos - operations
  public add(other: Money): Either<DomainError, Money> {
    if (this.currency !== other.currency) {
      return Either.left(new CurrencyMismatchError('Cannot add different currencies'));
    }
    
    const resultCents = this.cents + other.cents;
    if (resultCents > Money.MAX_CENTS) {
      return Either.left(new AmountOverflowError('Amount exceeds maximum value'));
    }
    
    return Either.right(new Money(resultCents, this.currency));
  }
  
  public subtract(other: Money): Either<DomainError, Money> {
    if (this.currency !== other.currency) {
      return Either.left(new CurrencyMismatchError('Cannot subtract different currencies'));
    }
    
    const resultCents = this.cents - other.cents;
    return Either.right(new Money(resultCents, this.currency));
  }
  
  public multiply(factor: number): Either<DomainError, Money> {
    if (factor < 0) {
      return Either.left(new ValidationError('Cannot multiply by negative factor'));
    }
    
    const resultCents = Math.round(this.cents * factor);
    if (resultCents > Money.MAX_CENTS) {
      return Either.left(new AmountOverflowError('Amount exceeds maximum value'));
    }
    
    return Either.right(new Money(resultCents, this.currency));
  }
  
  public isPositive(): boolean {
    return this.cents > 0;
  }
  
  public isNegative(): boolean {
    return this.cents < 0;
  }
  
  public isZero(): boolean {
    return this.cents === 0;
  }
  
  public toReais(): number {
    return this.cents / 100;
  }
  
  public equals(other: Money): boolean {
    return this.cents === other.cents && this.currency === other.currency;
  }
  
  public toString(): string {
    return `${this.currency} ${(this.cents / 100).toFixed(2)}`;
  }
  
  // 5. Métodos estáticos - factory methods
  public static fromCents(cents: number, currency?: string): Either<ValidationError, Money> {
    const validation = Money.validateCents(cents);
    if (validation.isLeft()) {
      return validation;
    }
    
    return Either.right(new Money(Math.round(cents), currency));
  }
  
  public static fromReais(reais: number, currency?: string): Either<ValidationError, Money> {
    if (!Number.isFinite(reais)) {
      return Either.left(new ValidationError('Amount must be a finite number'));
    }
    
    const cents = Math.round(reais * 100);
    return Money.fromCents(cents, currency);
  }
  
  public static zero(currency?: string): Money {
    return new Money(0, currency);
  }
  
  // 6. Métodos privados - validation
  private static validateCents(cents: number): Either<ValidationError, void> {
    if (!Number.isInteger(cents)) {
      return Either.left(new ValidationError('Cents must be an integer'));
    }
    if (cents > Money.MAX_CENTS) {
      return Either.left(new ValidationError('Amount exceeds maximum value'));
    }
    if (!Number.isFinite(cents)) {
      return Either.left(new ValidationError('Amount must be finite'));
    }
    return Either.right(undefined);
  }
}
```

### Repository Implementations

```typescript
export class PostgresTransactionRepository 
  implements IAddTransactionRepository, ISaveTransactionRepository, IGetTransactionRepository {
  
  // 1. Propriedades públicas
  public readonly connectionInfo: string;
  
  // 2. Propriedades privadas
  private readonly dbConnection: DatabaseConnection;
  private readonly transactionMapper: TransactionMapper;
  private readonly logger: ILogger;
  
  // 3. Construtor
  constructor(
    dbConnection: DatabaseConnection,
    transactionMapper: TransactionMapper,
    logger: ILogger
  ) {
    this.dbConnection = dbConnection;
    this.transactionMapper = transactionMapper;
    this.logger = logger;
    this.connectionInfo = dbConnection.toString();
  }
  
  // 4. Métodos públicos - interface implementations
  public async execute(transaction: Transaction): Promise<Either<RepositoryError, void>> {
    try {
      const transactionData = this.transactionMapper.toPersistence(transaction);
      const query = this.buildInsertQuery();
      const params = this.extractQueryParams(transactionData);
      
      await this.dbConnection.execute(query, params);
      this.logSuccess('transaction_added', { id: transaction.id.value });
      
      return Either.right(undefined);
    } catch (error) {
      this.logError('transaction_add_failed', error);
      return Either.left(new RepositoryError('Failed to add transaction', error));
    }
  }
  
  public async findById(id: string): Promise<Either<RepositoryError, Transaction>> {
    try {
      const query = this.buildSelectByIdQuery();
      const result = await this.dbConnection.queryOne(query, [id]);
      
      if (!result) {
        return Either.left(new NotFoundError('Transaction not found'));
      }
      
      const transaction = this.transactionMapper.toDomain(result);
      this.logSuccess('transaction_found', { id });
      
      return Either.right(transaction);
    } catch (error) {
      this.logError('transaction_find_failed', error);
      return Either.left(new RepositoryError('Failed to find transaction', error));
    }
  }
  
  // 5. Métodos estáticos
  public static create(config: DatabaseConfig): PostgresTransactionRepository {
    const connection = new PostgresConnection(config);
    const mapper = new TransactionMapper();
    const logger = new DatabaseLogger(config.logging);
    
    return new PostgresTransactionRepository(connection, mapper, logger);
  }
  
  // 6. Métodos privados - SQL queries e helpers
  private buildInsertQuery(): string {
    return `
      INSERT INTO transactions (id, amount_cents, budget_id, description, status, created_at)
      VALUES ($1, $2, $3, $4, $5, $6)
    `;
  }
  
  private buildSelectByIdQuery(): string {
    return `
      SELECT id, amount_cents, budget_id, description, status, created_at
      FROM transactions
      WHERE id = $1 AND deleted_at IS NULL
    `;
  }
  
  private extractQueryParams(data: TransactionPersistenceData): any[] {
    return [
      data.id,
      data.amountCents,
      data.budgetId,
      data.description,
      data.status,
      data.createdAt
    ];
  }
  
  private logSuccess(operation: string, context: any): void {
    this.logger.info(`postgres_repository_${operation}`, context);
  }
  
  private logError(operation: string, error: any): void {
    this.logger.error(`postgres_repository_${operation}`, {
      error: error.message,
      stack: error.stack
    });
  }
}
```

## 🚫 Anti-Patterns

### ❌ Ordem Incorreta
```typescript
// ❌ EVITAR - Ordem incorreta
export class BadTransactionService {
  // Métodos privados no início (INCORRETO)
  private validateData() { }
  
  // Construtor no meio (INCORRETO)
  constructor() { }
  
  // Propriedades no final (INCORRETO)
  private repository: ITransactionRepository;
  public config: TransactionConfig;
  
  // Métodos públicos misturados (INCORRETO)
  public create() { }
  private helper() { }
  public update() { }
}
```

### ❌ Construtores Públicos em Entities
```typescript
// ❌ EVITAR - Construtor público em Domain Entity
export class Transaction {
  public constructor(
    public id: string,        // Permite criação inválida
    public amount: number     // Sem validação
  ) {}
}

// ✅ CORRETO - Factory pattern
export class Transaction {
  private constructor(id: TransactionId, amount: Money) { }
  
  public static create(dto: CreateTransactionDto): Either<DomainError, Transaction> {
    // Validação obrigatória antes da criação
  }
}
```

### ❌ Métodos Muito Grandes
```typescript
// ❌ EVITAR - Método fazendo muita coisa
public async execute(dto: CreateTransactionDto): Promise<Either<Error, TransactionId>> {
  // 50+ linhas de código
  // Múltiplas responsabilidades
  // Sem decomposição em métodos privados
}

// ✅ CORRETO - Métodos focados com helpers privados
public async execute(dto: CreateTransactionDto): Promise<Either<Error, TransactionId>> {
  const authResult = await this.checkAuthorization(dto, userId);
  if (authResult.isLeft()) return authResult;
  
  const validation = this.validateData(dto);
  if (validation.isLeft()) return validation;
  
  return this.createAndSaveTransaction(dto);
}
```

---

**Ver também:**
- **[Naming Conventions](./naming-conventions.md)** - Como nomear classes e métodos
- **[Error Handling](./error-handling.md)** - Padrão Either para métodos
- **[Architectural Patterns](./architectural-patterns.md)** - Repository e Use Case patterns