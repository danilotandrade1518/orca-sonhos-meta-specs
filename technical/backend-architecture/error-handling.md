# Tratamento de Erros

## Pattern Either - Fundamento

O tratamento de erros utiliza o padrão `Either`, evitando o uso de `throw/try/catch` exceto em situações explicitamente necessárias (ex: falhas inesperadas do sistema). Os métodos retornam objetos do tipo `Either<Erro, Sucesso>`, facilitando o controle de fluxo e a previsibilidade dos resultados.

## Implementação do Either

### Estrutura Base
```typescript
export class Either<E, S> {
  constructor(
    private readonly _hasError: boolean,
    private readonly _errors: E[],
    private readonly _data: S | null
  ) {}

  static success<E, S>(data: S): Either<E, S> {
    return new Either<E, S>(false, [], data);
  }

  static error<E, S>(error: E): Either<E, S> {
    return new Either<E, S>(true, [error], null);
  }

  static errors<E, S>(errors: E[]): Either<E, S> {
    return new Either<E, S>(true, errors, null);
  }

  get hasError(): boolean {
    return this._hasError;
  }

  get errors(): E[] {
    return this._errors;
  }

  get data(): S | null {
    return this._data;
  }
}
```

### Métodos de Conveniência
```typescript
export class Either<E, S> {
  // Transformação de dados em caso de sucesso
  map<T>(fn: (data: S) => T): Either<E, T> {
    if (this.hasError) {
      return Either.errors<E, T>(this.errors);
    }
    return Either.success<E, T>(fn(this.data!));
  }

  // Transformação de erros
  mapError<T>(fn: (error: E) => T): Either<T, S> {
    if (this.hasError) {
      return Either.errors<T, S>(this.errors.map(fn));
    }
    return Either.success<T, S>(this.data!);
  }

  // Encadeamento de operações que retornam Either
  flatMap<T>(fn: (data: S) => Either<E, T>): Either<E, T> {
    if (this.hasError) {
      return Either.errors<E, T>(this.errors);
    }
    return fn(this.data!);
  }
}
```

## Hierarquia de Erros

### Erros Base
```typescript
export abstract class BaseError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly originalError?: Error
  ) {
    super(message);
    this.name = this.constructor.name;
  }
}
```

### Erros de Domínio
```typescript
export class DomainError extends BaseError {
  constructor(message: string, originalError?: Error) {
    super(message, 'DOMAIN_ERROR', originalError);
  }
}

export class InvariantViolationError extends DomainError {
  constructor(invariant: string, entity: string) {
    super(`Invariant violation in ${entity}: ${invariant}`, 'INVARIANT_VIOLATION');
  }
}

export class BusinessRuleViolationError extends DomainError {
  constructor(rule: string, context?: string) {
    super(`Business rule violation: ${rule}${context ? ` (${context})` : ''}`, 'BUSINESS_RULE_VIOLATION');
  }
}
```

### Erros de Aplicação
```typescript
export class ApplicationError extends BaseError {
  constructor(message: string, code: string = 'APPLICATION_ERROR', originalError?: Error) {
    super(message, code, originalError);
  }
}

export class UseCaseError extends ApplicationError {
  constructor(useCase: string, operation: string, originalError?: Error) {
    super(`Error in ${useCase} during ${operation}`, 'USE_CASE_ERROR', originalError);
  }
}
```

### Erros de Infraestrutura
```typescript
export class RepositoryError extends BaseError {
  constructor(message: string, originalError?: Error) {
    super(message, 'REPOSITORY_ERROR', originalError);
  }
}

export class DatabaseError extends RepositoryError {
  constructor(operation: string, originalError?: Error) {
    super(`Database error during ${operation}`, originalError);
  }
}

export class ConnectionError extends RepositoryError {
  constructor(originalError?: Error) {
    super('Database connection failed', originalError);
  }
}
```

### Erros de Autorização
```typescript
export class AuthorizationError extends BaseError {
  constructor(
    message: string, 
    public readonly userId?: string,
    public readonly resourceId?: string
  ) {
    super(message, 'AUTHORIZATION_ERROR');
  }
}

export class UnauthorizedError extends AuthorizationError {
  constructor(operation?: string) {
    super(`Unauthorized${operation ? ` to ${operation}` : ''}`, 'UNAUTHORIZED');
  }
}

export class ForbiddenError extends AuthorizationError {
  constructor(resource: string, userId?: string) {
    super(`Access forbidden to ${resource}`, 'FORBIDDEN', userId);
  }
}
```

## Uso em Diferentes Camadas

### Domain Layer
```typescript
export class Account {
  debit(amount: number): Either<DomainError, void> {
    if (amount <= 0) {
      return Either.error(
        new InvariantViolationError('Amount must be positive', 'Account')
      );
    }
    
    if (this.balance < amount) {
      return Either.error(
        new BusinessRuleViolationError('Insufficient balance', `Account ${this.id}`)
      );
    }
    
    this._balance -= amount;
    return Either.success(undefined);
  }
}
```

### Application Layer (Use Cases)
```typescript
export class CreateTransactionUseCase {
  async execute(dto: CreateTransactionDto): Promise<Either<ApplicationError, void>> {
    try {
      // 1. Buscar conta
      const accountResult = await this.getAccountRepository.execute(dto.accountId);
      if (accountResult.hasError) {
        return Either.error(
          new UseCaseError('CreateTransaction', 'fetch account', accountResult.errors[0])
        );
      }
      
      // 2. Aplicar regra de domínio
      const account = accountResult.data!;
      const debitResult = account.debit(dto.amount);
      if (debitResult.hasError) {
        return Either.error(
          new ApplicationError(debitResult.errors[0].message, 'BUSINESS_RULE_VIOLATION')
        );
      }
      
      // 3. Criar transação
      const transaction = Transaction.create(dto);
      const saveResult = await this.addTransactionRepository.execute(transaction);
      if (saveResult.hasError) {
        return Either.error(
          new UseCaseError('CreateTransaction', 'save transaction', saveResult.errors[0])
        );
      }
      
      return Either.success(undefined);
    } catch (error) {
      // Captura apenas erros inesperados
      return Either.error(
        new ApplicationError('Unexpected error in CreateTransaction', 'UNEXPECTED_ERROR', error)
      );
    }
  }
}
```

### Infrastructure Layer (Repositories)
```typescript
export class PostgresAddTransactionRepository implements IAddTransactionRepository {
  async execute(transaction: Transaction): Promise<Either<RepositoryError, void>> {
    try {
      const client = await this.connectionAdapter.getClient();
      const transactionDto = TransactionMapper.domainToDto(transaction);
      
      await client.query(INSERT_TRANSACTION_QUERY, [
        transactionDto.id,
        transactionDto.accountId,
        transactionDto.amount,
        // ... outros campos
      ]);
      
      return Either.success(undefined);
    } catch (error) {
      // Mapear erros específicos do banco
      if (error.code === '23505') { // Unique constraint violation
        return Either.error(
          new RepositoryError('Transaction with this ID already exists', error)
        );
      }
      
      if (error.code === '23503') { // Foreign key constraint violation
        return Either.error(
          new RepositoryError('Referenced account or category does not exist', error)
        );
      }
      
      return Either.error(
        new DatabaseError('INSERT transaction', error)
      );
    }
  }
}
```

### Web Layer (Controllers)
```typescript
export class TransactionController {
  async createTransaction(req: Request, res: Response): Promise<void> {
    try {
      const dto = this.mapRequestToDto(req.body);
      const result = await this.createTransactionUseCase.execute(dto);
      
      if (result.hasError) {
        this.handleErrorResponse(res, result.errors[0]);
        return;
      }
      
      res.status(201).json({
        success: true,
        message: 'Transaction created successfully'
      });
    } catch (error) {
      // Log erro inesperado
      this.logger.error('Unexpected error in TransactionController', error);
      res.status(500).json({
        success: false,
        error: 'Internal server error',
        code: 'INTERNAL_ERROR'
      });
    }
  }
  
  private handleErrorResponse(res: Response, error: BaseError): void {
    const errorMappings = {
      'DOMAIN_ERROR': { status: 400, message: 'Invalid operation' },
      'BUSINESS_RULE_VIOLATION': { status: 400, message: 'Business rule violated' },
      'INVARIANT_VIOLATION': { status: 400, message: 'Invalid data' },
      'UNAUTHORIZED': { status: 401, message: 'Authentication required' },
      'FORBIDDEN': { status: 403, message: 'Access denied' },
      'REPOSITORY_ERROR': { status: 500, message: 'Data access error' },
      'APPLICATION_ERROR': { status: 500, message: 'Application error' },
    };
    
    const mapping = errorMappings[error.code] || { status: 500, message: 'Internal error' };
    
    res.status(mapping.status).json({
      success: false,
      error: mapping.message,
      code: error.code,
      details: error.message
    });
  }
}
```

## Composição de Erros

### Agregação de Múltiplos Erros
```typescript
export class ValidationService {
  validateCreateTransaction(dto: CreateTransactionDto): Either<DomainError, void> {
    const errors: DomainError[] = [];
    
    if (!dto.accountId) {
      errors.push(new DomainError('Account ID is required'));
    }
    
    if (!dto.amount || dto.amount <= 0) {
      errors.push(new DomainError('Amount must be positive'));
    }
    
    if (!dto.categoryId) {
      errors.push(new DomainError('Category ID is required'));
    }
    
    if (errors.length > 0) {
      return Either.errors(errors);
    }
    
    return Either.success(undefined);
  }
}
```

### Encadeamento de Operações
```typescript
export class ComplexOperationUseCase {
  async execute(dto: ComplexOperationDto): Promise<Either<ApplicationError, Result>> {
    return this.validateInput(dto)
      .flatMap(() => this.fetchRequiredData(dto))
      .flatMap((data) => this.applyBusinessRules(data))
      .flatMap((processedData) => this.persistChanges(processedData));
  }
  
  private validateInput(dto: ComplexOperationDto): Either<ApplicationError, void> {
    // Validações
  }
  
  private async fetchRequiredData(dto: ComplexOperationDto): Promise<Either<ApplicationError, Data>> {
    // Buscar dados necessários
  }
  
  // ... outras operações
}
```

## Logging e Monitoramento

### Logging Estruturado de Erros
```typescript
export class ErrorLogger {
  logError(error: BaseError, context: string): void {
    const logData = {
      timestamp: new Date().toISOString(),
      context,
      errorType: error.constructor.name,
      code: error.code,
      message: error.message,
      stack: error.stack,
      originalError: error.originalError ? {
        name: error.originalError.name,
        message: error.originalError.message,
        stack: error.originalError.stack
      } : undefined
    };
    
    if (this.isCriticalError(error)) {
      this.logger.error('Critical error occurred', logData);
      // Pode disparar alertas
    } else {
      this.logger.warn('Business error occurred', logData);
    }
  }
  
  private isCriticalError(error: BaseError): boolean {
    return [
      'DATABASE_ERROR',
      'CONNECTION_ERROR', 
      'UNEXPECTED_ERROR'
    ].includes(error.code);
  }
}
```

## Testes com Either

### Testes de Cenários de Sucesso e Falha
```typescript
describe('CreateTransactionUseCase', () => {
  it('should create transaction successfully', async () => {
    // Arrange
    mockGetAccountRepository.execute.mockResolvedValue(
      Either.success(mockAccount)
    );
    mockAddTransactionRepository.execute.mockResolvedValue(
      Either.success(undefined)
    );
    
    // Act
    const result = await useCase.execute(validDto);
    
    // Assert
    expect(result.hasError).toBe(false);
    expect(result.data).toBeUndefined(); // void success
  });
  
  it('should fail when account has insufficient balance', async () => {
    // Arrange
    const accountWithLowBalance = Account.create({ balance: 10 });
    mockGetAccountRepository.execute.mockResolvedValue(
      Either.success(accountWithLowBalance)
    );
    
    const dto = { ...validDto, amount: 100 };
    
    // Act
    const result = await useCase.execute(dto);
    
    // Assert
    expect(result.hasError).toBe(true);
    expect(result.errors[0].message).toContain('Insufficient balance');
  });
  
  it('should handle repository errors gracefully', async () => {
    // Arrange
    mockGetAccountRepository.execute.mockResolvedValue(
      Either.error(new RepositoryError('Database connection failed'))
    );
    
    // Act
    const result = await useCase.execute(validDto);
    
    // Assert
    expect(result.hasError).toBe(true);
    expect(result.errors[0]).toBeInstanceOf(UseCaseError);
  });
});
```

## Benefícios da Abordagem

- **Previsibilidade**: Todos os erros são explícitos no tipo de retorno
- **Composabilidade**: Operações podem ser encadeadas facilmente
- **Testabilidade**: Cenários de erro são testáveis de forma determinística
- **Rastreabilidade**: Stack trace completa de erros é preservada
- **Tipo-segurança**: TypeScript força tratamento de erros
- **Performance**: Não há overhead de exceções

---

**Ver também:**
- [Data Flow](./data-flow.md) - Como erros fluem pelas camadas
- [Repository Pattern](./repository-pattern.md) - Tratamento de erros em repositories
- [Domain Services](./domain-services.md) - Erros de domínio em services