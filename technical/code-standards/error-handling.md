# Tratamento de Erros

## 🎯 Padrão Either Obrigatório

**OBRIGATÓRIO**: Usar padrão `Either<Error, Success>` evitando `throw/try/catch`:

### ✅ Padrão Correto
```typescript
// ✅ CORRETO - Either pattern
export class CreateTransactionUseCase {
  async execute(dto: CreateTransactionDto): Promise<Either<ApplicationError, TransactionId>> {
    // 1. Validação de entrada
    const validationResult = this.validateDto(dto);
    if (validationResult.isLeft()) {
      return Either.left(new ValidationError(validationResult.value));
    }
    
    // 2. Criação da entidade
    const transaction = Transaction.create(validationResult.value);
    if (transaction.isLeft()) {
      return Either.left(new DomainError(transaction.value.message));
    }
    
    // 3. Persistência
    const saveResult = await this.repository.execute(transaction.value);
    if (saveResult.isLeft()) {
      return Either.left(new RepositoryError('Failed to save transaction'));
    }
    
    // 4. Retorno do ID
    return Either.right(transaction.value.id);
  }
  
  private validateDto(dto: CreateTransactionDto): Either<ValidationError[], CreateTransactionDto> {
    const errors: ValidationError[] = [];
    
    if (!dto.amount || dto.amount <= 0) {
      errors.push(new ValidationError('Amount must be positive'));
    }
    
    if (!dto.description?.trim()) {
      errors.push(new ValidationError('Description is required'));
    }
    
    if (errors.length > 0) {
      return Either.left(errors);
    }
    
    return Either.right(dto);
  }
}
```

### ❌ Anti-Pattern com Exceptions
```typescript
// ❌ EVITAR - throw/try/catch
export class BadCreateTransactionUseCase {
  async execute(dto: CreateTransactionDto): Promise<TransactionId> {
    // ❌ Validação com throw
    if (!dto.amount) {
      throw new Error('Amount is required'); // Avoid throws
    }
    
    try {
      // ❌ Construtor direto sem validação
      const transaction = new Transaction(dto); // Avoid direct constructor
      
      // ❌ Repository que pode lançar exception
      await this.repository.save(transaction); // Can throw
      
      return transaction.id;
    } catch (error) {
      // ❌ Re-throwing exceptions
      throw new ApplicationError('Failed to create transaction'); // Avoid re-throw
    }
  }
}
```

## 🏗️ Hierarquia de Erros

### Base Error Classes
```typescript
// Base abstract errors
export abstract class DomainError extends Error {
  abstract readonly code: string;
  abstract readonly details?: Record<string, any>;
  
  constructor(
    message: string,
    public readonly cause?: Error
  ) {
    super(message);
    this.name = this.constructor.name;
  }
}

export abstract class ApplicationError extends Error {
  abstract readonly code: string;
  abstract readonly details?: Record<string, any>;
  
  constructor(
    message: string,
    public readonly cause?: Error
  ) {
    super(message);
    this.name = this.constructor.name;
  }
}

export abstract class InfrastructureError extends Error {
  abstract readonly code: string;
  abstract readonly details?: Record<string, any>;
  
  constructor(
    message: string,
    public readonly cause?: Error
  ) {
    super(message);
    this.name = this.constructor.name;
  }
}
```

### Domain Layer Errors
```typescript
// Domain validation errors
export class ValidationError extends DomainError {
  readonly code = 'DOMAIN_VALIDATION_ERROR';
  
  constructor(
    message: string,
    public readonly field?: string,
    public readonly details?: Record<string, any>
  ) {
    super(message);
  }
}

export class InvalidTransactionStateError extends DomainError {
  readonly code = 'INVALID_TRANSACTION_STATE';
  
  constructor(
    message: string,
    public readonly currentState?: string,
    public readonly attemptedAction?: string
  ) {
    super(message);
    this.details = { currentState, attemptedAction };
  }
}

export class AmountOverflowError extends DomainError {
  readonly code = 'AMOUNT_OVERFLOW';
  
  constructor(
    public readonly maxAmount: number,
    public readonly attemptedAmount: number
  ) {
    super(`Amount ${attemptedAmount} exceeds maximum ${maxAmount}`);
    this.details = { maxAmount, attemptedAmount };
  }
}

export class CurrencyMismatchError extends DomainError {
  readonly code = 'CURRENCY_MISMATCH';
  
  constructor(
    public readonly currency1: string,
    public readonly currency2: string
  ) {
    super(`Cannot operate with different currencies: ${currency1} and ${currency2}`);
    this.details = { currency1, currency2 };
  }
}
```

### Application Layer Errors
```typescript
// Application business errors
export class UnauthorizedError extends ApplicationError {
  readonly code = 'APPLICATION_UNAUTHORIZED';
  
  constructor(
    message: string = 'User not authorized for this operation',
    public readonly userId?: string,
    public readonly resource?: string
  ) {
    super(message);
    this.details = { userId, resource };
  }
}

export class NotFoundError extends ApplicationError {
  readonly code = 'APPLICATION_NOT_FOUND';
  
  constructor(
    public readonly resource: string,
    public readonly resourceId?: string
  ) {
    super(`${resource} not found${resourceId ? ` with id: ${resourceId}` : ''}`);
    this.details = { resource, resourceId };
  }
}

export class BusinessRuleViolationError extends ApplicationError {
  readonly code = 'BUSINESS_RULE_VIOLATION';
  
  constructor(
    public readonly rule: string,
    message?: string,
    public readonly context?: Record<string, any>
  ) {
    super(message || `Business rule violation: ${rule}`);
    this.details = { rule, context };
  }
}

export class ConcurrencyError extends ApplicationError {
  readonly code = 'APPLICATION_CONCURRENCY_ERROR';
  
  constructor(
    public readonly resource: string,
    public readonly resourceId: string,
    public readonly expectedVersion?: number,
    public readonly actualVersion?: number
  ) {
    super(`Concurrency conflict for ${resource}:${resourceId}`);
    this.details = { resource, resourceId, expectedVersion, actualVersion };
  }
}
```

### Infrastructure Layer Errors
```typescript
// Infrastructure errors
export class RepositoryError extends InfrastructureError {
  readonly code = 'REPOSITORY_ERROR';
  
  constructor(
    message: string,
    public readonly operation?: string,
    public readonly resource?: string,
    cause?: Error
  ) {
    super(message, cause);
    this.details = { operation, resource };
  }
}

export class DatabaseConnectionError extends InfrastructureError {
  readonly code = 'DATABASE_CONNECTION_ERROR';
  
  constructor(
    public readonly host: string,
    public readonly database: string,
    cause?: Error
  ) {
    super(`Failed to connect to database ${database} on ${host}`, cause);
    this.details = { host, database };
  }
}

export class HttpServiceError extends InfrastructureError {
  readonly code = 'HTTP_SERVICE_ERROR';
  
  constructor(
    public readonly service: string,
    public readonly endpoint: string,
    public readonly statusCode?: number,
    public readonly responseBody?: any,
    cause?: Error
  ) {
    super(`HTTP service error: ${service} ${endpoint}`, cause);
    this.details = { service, endpoint, statusCode, responseBody };
  }
}

export class ExternalServiceUnavailableError extends InfrastructureError {
  readonly code = 'EXTERNAL_SERVICE_UNAVAILABLE';
  
  constructor(
    public readonly service: string,
    public readonly retryAfterSeconds?: number,
    cause?: Error
  ) {
    super(`External service unavailable: ${service}`, cause);
    this.details = { service, retryAfterSeconds };
  }
}
```

## 🔄 Composição e Pipeline

### Operações Sequenciais
```typescript
export class TransferBetweenAccountsUseCase {
  async execute(dto: TransferDto, userId: string): Promise<Either<ApplicationError, void>> {
    // Pipeline de validações usando Either
    return pipe(
      // 1. Autorização
      await this.checkAuthorization(userId, dto.fromAccountId),
      Either.chain(() => this.checkAuthorization(userId, dto.toAccountId)),
      
      // 2. Validação de contas
      Either.chain(() => this.validateAccountExists(dto.fromAccountId)),
      Either.chain(() => this.validateAccountExists(dto.toAccountId)),
      
      // 3. Validação de saldo
      Either.chain(() => this.validateSufficientBalance(dto.fromAccountId, dto.amount)),
      
      // 4. Execução da transferência
      Either.chain(() => this.executeTransfer(dto))
    );
  }
  
  private async checkAuthorization(userId: string, accountId: string): Promise<Either<ApplicationError, void>> {
    const result = await this.authService.canUserAccessAccount(userId, accountId);
    return result.isLeft() 
      ? Either.left(new UnauthorizedError('User cannot access account', userId, accountId))
      : Either.right(undefined);
  }
  
  private async validateAccountExists(accountId: string): Promise<Either<ApplicationError, void>> {
    const account = await this.accountRepository.findById(accountId);
    return account.isLeft()
      ? Either.left(new NotFoundError('Account', accountId))
      : Either.right(undefined);
  }
  
  private async executeTransfer(dto: TransferDto): Promise<Either<ApplicationError, void>> {
    // UnitOfWork para transação atômica
    return this.unitOfWork.execute(async () => {
      const debitResult = await this.debitAccount(dto.fromAccountId, dto.amount);
      if (debitResult.isLeft()) return debitResult;
      
      const creditResult = await this.creditAccount(dto.toAccountId, dto.amount);
      if (creditResult.isLeft()) {
        // Rollback automático pelo UnitOfWork
        return creditResult;
      }
      
      return Either.right(undefined);
    });
  }
}
```

### Either Utilities
```typescript
// Utility functions para trabalhar com Either
export class EitherUtils {
  // Combinar múltiplos Either em um só
  static combine<E, T>(eithers: Either<E, T>[]): Either<E[], T[]> {
    const rights: T[] = [];
    const lefts: E[] = [];
    
    for (const either of eithers) {
      if (either.isLeft()) {
        lefts.push(either.value);
      } else {
        rights.push(either.value);
      }
    }
    
    return lefts.length > 0 
      ? Either.left(lefts)
      : Either.right(rights);
  }
  
  // Executar Either async com timeout
  static async withTimeout<E, T>(
    promise: Promise<Either<E, T>>, 
    timeoutMs: number,
    timeoutError: E
  ): Promise<Either<E, T>> {
    const timeoutPromise = new Promise<Either<E, T>>((resolve) => {
      setTimeout(() => resolve(Either.left(timeoutError)), timeoutMs);
    });
    
    return Promise.race([promise, timeoutPromise]);
  }
  
  // Retry com exponential backoff
  static async retry<E, T>(
    operation: () => Promise<Either<E, T>>,
    maxAttempts: number = 3,
    baseDelayMs: number = 1000
  ): Promise<Either<E, T>> {
    let lastError: E;
    
    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      const result = await operation();
      
      if (result.isRight()) {
        return result;
      }
      
      lastError = result.value;
      
      if (attempt < maxAttempts) {
        const delay = baseDelayMs * Math.pow(2, attempt - 1);
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }
    
    return Either.left(lastError!);
  }
}
```

## 🎨 Error Handling em UI (Angular)

### Component Error Handling
```typescript
@Component({
  selector: 'os-transaction-form',
  template: `
    @if (errorMessage()) {
      <os-error-banner [message]="errorMessage()" />
    }
    
    <form [formGroup]="form" (ngSubmit)="onSubmit()">
      <!-- form fields -->
      <os-button 
        type="submit" 
        [loading]="loading()" 
        [disabled]="form.invalid">
        Create Transaction
      </os-button>
    </form>
  `
})
export class TransactionFormComponent {
  readonly loading = signal(false);
  readonly errorMessage = signal<string | null>(null);
  
  private readonly createTransactionUseCase = inject(CreateTransactionUseCase);
  
  async onSubmit(): Promise<void> {
    this.loading.set(true);
    this.errorMessage.set(null);
    
    const dto = this.buildDto();
    const result = await this.createTransactionUseCase.execute(dto, this.getCurrentUserId());
    
    result.fold(
      // Error case
      (error) => {
        this.loading.set(false);
        this.errorMessage.set(this.mapErrorToUserMessage(error));
      },
      // Success case
      (transactionId) => {
        this.loading.set(false);
        this.router.navigate(['/transactions', transactionId]);
      }
    );
  }
  
  private mapErrorToUserMessage(error: ApplicationError): string {
    switch (error.code) {
      case 'DOMAIN_VALIDATION_ERROR':
        return 'Verifique os dados informados e tente novamente.';
      case 'APPLICATION_UNAUTHORIZED':
        return 'Você não tem permissão para realizar esta operação.';
      case 'APPLICATION_NOT_FOUND':
        return 'Recurso não encontrado. Verifique se ainda existe.';
      case 'REPOSITORY_ERROR':
        return 'Erro temporário. Tente novamente em alguns instantes.';
      default:
        return 'Erro inesperado. Entre em contato com o suporte.';
    }
  }
}
```

### Global Error Handler
```typescript
@Injectable()
export class GlobalErrorHandler implements ErrorHandler {
  constructor(
    private logger: LoggerService,
    private notificationService: NotificationService
  ) {}
  
  handleError(error: unknown): void {
    // Log estruturado do erro
    this.logger.error('Unhandled error', {
      error: error instanceof Error ? error.message : String(error),
      stack: error instanceof Error ? error.stack : undefined,
      timestamp: new Date().toISOString(),
      userAgent: navigator.userAgent,
      url: window.location.href
    });
    
    // Notificação ao usuário apenas para erros críticos
    if (this.isCriticalError(error)) {
      this.notificationService.showError(
        'Ocorreu um erro crítico. A página será recarregada.',
        { 
          autoClose: false,
          action: { label: 'Recarregar', callback: () => window.location.reload() }
        }
      );
    }
  }
  
  private isCriticalError(error: unknown): boolean {
    if (error instanceof InfrastructureError) {
      return ['DATABASE_CONNECTION_ERROR', 'EXTERNAL_SERVICE_UNAVAILABLE'].includes(error.code);
    }
    return false;
  }
}
```

## 🧪 Testing Error Handling

### Unit Tests para Either
```typescript
describe('CreateTransactionUseCase', () => {
  let useCase: CreateTransactionUseCase;
  let mockRepository: jest.Mocked<IAddTransactionRepository>;
  let mockAuthService: jest.Mocked<IBudgetAuthorizationService>;
  
  beforeEach(() => {
    mockRepository = createMockRepository();
    mockAuthService = createMockAuthService();
    useCase = new CreateTransactionUseCase(mockAuthService, mockRepository);
  });
  
  describe('execute', () => {
    it('should return ValidationError when amount is negative', async () => {
      // Arrange
      const dto: CreateTransactionDto = {
        amount: -100,
        description: 'Test transaction',
        budgetId: 'budget-123'
      };
      
      // Act
      const result = await useCase.execute(dto, 'user-123');
      
      // Assert
      expect(result.isLeft()).toBe(true);
      if (result.isLeft()) {
        expect(result.value).toBeInstanceOf(ValidationError);
        expect(result.value.code).toBe('DOMAIN_VALIDATION_ERROR');
        expect(result.value.message).toContain('Amount must be positive');
      }
    });
    
    it('should return UnauthorizedError when user cannot access budget', async () => {
      // Arrange
      const dto = createValidDto();
      mockAuthService.canUserAccessBudget.mockResolvedValue(Either.left(new AuthorizationError()));
      
      // Act
      const result = await useCase.execute(dto, 'unauthorized-user');
      
      // Assert
      expect(result.isLeft()).toBe(true);
      if (result.isLeft()) {
        expect(result.value).toBeInstanceOf(UnauthorizedError);
        expect(result.value.code).toBe('APPLICATION_UNAUTHORIZED');
      }
    });
    
    it('should return TransactionId when creation succeeds', async () => {
      // Arrange
      const dto = createValidDto();
      mockAuthService.canUserAccessBudget.mockResolvedValue(Either.right(undefined));
      mockRepository.execute.mockResolvedValue(Either.right(undefined));
      
      // Act
      const result = await useCase.execute(dto, 'user-123');
      
      // Assert
      expect(result.isRight()).toBe(true);
      if (result.isRight()) {
        expect(result.value).toBeInstanceOf(TransactionId);
      }
    });
  });
});
```

---

**Ver também:**
- **[Class Structure](./class-structure.md)** - Como organizar métodos que retornam Either
- **[Testing Standards](./testing-standards.md)** - Como testar error handling
- **[Angular Modern Patterns](./angular-modern-patterns.md)** - Error handling em componentes