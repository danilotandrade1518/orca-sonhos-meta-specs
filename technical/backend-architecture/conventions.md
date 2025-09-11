# Convenções e Padrões de Desenvolvimento

## Padrões de Nomenclatura

### Classes
- **PascalCase** para todas as classes
- **Sufixos específicos** para identificar o tipo
  - `UseCase`: `CreateTransactionUseCase`, `MarkTransactionLateUseCase`
  - `Repository`: `PostgresAddTransactionRepository`  
  - `DomainService`: `PayCreditCardBillDomainService`
  - `QueryHandler`: `GetBudgetSummaryQueryHandler`
  - `UnitOfWork`: `TransferBetweenAccountsUnitOfWork`

### Interfaces
- **Prefixo `I`** obrigatório
- **Sufixos específicos** para clareza
  - `IAddRepository`, `ISaveRepository`, `IGetRepository`
  - `IBudgetAuthorizationService`
  - `ITransactionSummaryDao`
  - `ITransferBetweenAccountsUnitOfWork`

### Arquivos
- **PascalCase** para arquivos TypeScript
- **Mesmo nome da classe/interface** principal
  - `CreateTransactionUseCase.ts`
  - `PostgresAddTransactionRepository.ts`
  - `PayCreditCardBillDomainService.ts`

### Métodos
- **camelCase** para todos os métodos
- **Verbos específicos** que expressam a ação
  - `execute()` - Para Use Cases e Repositories
  - `handle()` - Para Query Handlers
  - `create()` - Para factory methods
  - `canAccessBudget()` - Para validações

### Pastas
- **kebab-case** obrigatório
- **Nomes descritivos** e consistentes
  - `use-cases`, `query-handlers`, `domain-services`
  - `unit-of-works`, `credit-card-bill`, `backend-architecture`

## Padrão de Imports e Path Alias

### Path Alias - Entre Camadas Diferentes
Use path alias quando importando entre camadas distintas:

```typescript
// ✅ CORRETO - Application importando Domain
import { Transaction } from '@/domain/aggregates/transaction/Transaction';
import { Money } from '@/domain/shared/value-objects/Money';
import { IAddTransactionRepository } from '@/application/contracts/repositories/IAddTransactionRepository';

// ✅ CORRETO - Infrastructure implementando Application
import { IAddTransactionRepository } from '@/application/contracts/repositories/IAddTransactionRepository';
import { Transaction } from '@/domain/aggregates/transaction/Transaction';
```

### Imports Relativos - Mesma Camada
Use imports relativos quando trabalhando dentro da mesma camada:

```typescript
// ✅ CORRETO - Dentro de use-cases
import { CreateTransactionDto } from './dtos/CreateTransactionDto';
import { MarkTransactionLateUseCase } from './MarkTransactionLateUseCase';

// ✅ CORRETO - Dentro de aggregates  
import { TransactionType } from './value-objects/TransactionType';
import { Money } from '../shared/value-objects/Money';

// ✅ CORRETO - Dentro de repositories
import { TransactionMapper } from '../shared/mappers/TransactionMapper';
import { PostgresGetTransactionRepository } from './PostgresGetTransactionRepository';
```

### Configuração de Path Alias
```json
// tsconfig.json
{
  "compilerOptions": {
    "baseUrl": "./src",
    "paths": {
      "@/domain/*": ["domain/*"],
      "@/application/*": ["application/*"],
      "@/infra/*": ["infra/*"],
      "@/interfaces/*": ["interfaces/*"],
      "@/config/*": ["config/*"]
    }
  }
}
```

## Ordenação de Métodos em Classes

### Ordem Obrigatória
Todas as classes devem seguir esta ordem de declaração:

1. **Métodos públicos** (incluindo getters/setters)
2. **Métodos estáticos** 
3. **Métodos privados**

```typescript
export class Account {
  // 1. MÉTODOS PÚBLICOS
  public debit(amount: number): Either<DomainError, void> {
    return this.validateAndDebit(amount);
  }

  public credit(amount: number): Either<DomainError, void> {
    return this.validateAndCredit(amount);
  }

  public get balance(): number {
    return this._balance;
  }

  public get availableBalance(): number {
    return this.calculateAvailableBalance();
  }

  // 2. MÉTODOS ESTÁTICOS
  public static create(dto: CreateAccountDto): Either<DomainError, Account> {
    return this.validateAndCreate(dto);
  }

  public static fromDto(dto: AccountDto): Account {
    return new Account(dto.id, dto.name, dto.balance);
  }

  // 3. MÉTODOS PRIVADOS
  private validateAndDebit(amount: number): Either<DomainError, void> {
    if (amount <= 0) {
      return Either.error(new DomainError('Amount must be positive'));
    }
    // ... lógica privada
  }

  private calculateAvailableBalance(): number {
    return this._balance - this.getReservedAmount();
  }

  private getReservedAmount(): number {
    // ... cálculo interno
  }
}
```

## Organização dos Testes

### Testes Unitários
**Localização**: Mesma pasta do arquivo testado com sufixo `.spec.ts`

```
src/domain/aggregates/transaction/Transaction.ts
src/domain/aggregates/transaction/Transaction.spec.ts

src/application/usecases/CreateTransactionUseCase.ts  
src/application/usecases/CreateTransactionUseCase.spec.ts

src/domain/shared/value-objects/Money.ts
src/domain/shared/value-objects/Money.spec.ts
```

### Testes de Integração  
**Localização**: Pasta `__tests__` dentro do módulo

```
src/application/usecases/__tests__/CreateTransactionUseCase.integration.spec.ts
src/infra/database/pg/repositories/__tests__/PostgresTransactionRepository.integration.spec.ts
```

### Testes E2E
**Localização**: Pasta `__tests__` na raiz

```
src/__tests__/e2e/transaction.e2e.spec.ts
src/__tests__/e2e/budget.e2e.spec.ts
```

### Convenções de Teste
```typescript
// Estrutura padrão de testes
describe('CreateTransactionUseCase', () => {
  // Setup comum
  let useCase: CreateTransactionUseCase;
  let mockRepository: jest.Mocked<IAddTransactionRepository>;

  beforeEach(() => {
    // Arrange comum
    mockRepository = createMockRepository();
    useCase = new CreateTransactionUseCase(mockRepository);
  });

  describe('when creating a valid transaction', () => {
    it('should create transaction successfully', async () => {
      // Arrange
      const dto = createValidTransactionDto();
      mockRepository.execute.mockResolvedValue(Either.success(undefined));

      // Act
      const result = await useCase.execute(dto);

      // Assert
      expect(result.hasError).toBe(false);
      expect(mockRepository.execute).toHaveBeenCalledTimes(1);
    });
  });

  describe('when validation fails', () => {
    it('should return error for invalid amount', async () => {
      // Test error scenarios
    });
  });

  describe('when repository fails', () => {
    it('should handle repository errors', async () => {
      // Test failure scenarios
    });
  });
});
```

## Convenções de Código

### Tratamento de Erros
- **Sempre usar Either** em métodos que podem falhar
- **Nunca usar throw/try/catch** exceto para erros inesperados do sistema
- **Erros específicos** com códigos e mensagens descritivas

```typescript
// ✅ CORRETO
public debit(amount: number): Either<DomainError, void> {
  if (amount <= 0) {
    return Either.error(new DomainError('Amount must be positive'));
  }
  
  if (this._balance < amount) {
    return Either.error(new DomainError('Insufficient balance'));
  }
  
  this._balance -= amount;
  return Either.success(undefined);
}

// ❌ EVITAR
public debit(amount: number): void {
  if (amount <= 0) {
    throw new Error('Amount must be positive'); // Não usar throw
  }
  
  this._balance -= amount;
}
```

### Validações
- **Fail-fast**: Validar parâmetros no início dos métodos
- **Erros específicos**: Mensagens claras sobre o que está incorreto
- **Either para composição**: Agregar múltiplas validações

```typescript
// ✅ CORRETO - Validação com Either
private validateTransactionData(dto: CreateTransactionDto): Either<DomainError, void> {
  const errors: DomainError[] = [];
  
  if (!dto.accountId) {
    errors.push(new DomainError('Account ID is required'));
  }
  
  if (dto.amount <= 0) {
    errors.push(new DomainError('Amount must be positive'));
  }
  
  if (!dto.categoryId) {
    errors.push(new DomainError('Category ID is required'));
  }
  
  return errors.length > 0 
    ? Either.errors(errors)
    : Either.success(undefined);
}
```

### Construtores e Factory Methods
- **Construtores privados** em Domain Entities
- **Factory methods estáticos** para criação controlada
- **Validação completa** nos factory methods

```typescript
export class Transaction {
  // Construtor privado
  private constructor(
    private readonly _id: string,
    private readonly _accountId: string,
    private readonly _amount: Money,
    // ... outros campos
  ) {}

  // Factory method público
  public static create(dto: CreateTransactionDto): Either<DomainError, Transaction> {
    const validationResult = this.validate(dto);
    if (validationResult.hasError) {
      return validationResult;
    }
    
    const transaction = new Transaction(
      generateId(),
      dto.accountId,
      Money.from(dto.amount),
      // ... outros campos
    );
    
    return Either.success(transaction);
  }

  // Validação estática
  private static validate(dto: CreateTransactionDto): Either<DomainError, void> {
    // Lógica de validação
  }
}
```

### Comments Policy
- **NÃO adicionar comentários** no código, exceto quando explicitamente solicitado
- **Código auto-documentado** através de nomes descritivos
- **Documentação em arquivos separados** (como esta estrutura)

## Linguagem e Idioma

### Regra Fundamental
- **Todo o código deve ser escrito em inglês**
- **Nomes de variáveis, métodos, classes**: Inglês  
- **Mensagens de erro, logs**: Inglês
- **Comentários (se necessário)**: Inglês
- **Documentação técnica**: Português (como esta)

```typescript
// ✅ CORRETO - Inglês
export class CreateTransactionUseCase {
  async execute(dto: CreateTransactionDto): Promise<Either<ApplicationError, void>> {
    const validationResult = this.validateInput(dto);
    if (validationResult.hasError) {
      return Either.error(new ApplicationError('Invalid transaction data'));
    }
    // ...
  }
}

// ❌ EVITAR - Português
export class CriarTransacaoUseCase {
  async executar(dto: CriarTransacaoDto): Promise<Either<ErroAplicacao, void>> {
    const resultadoValidacao = this.validarEntrada(dto);
    // ...
  }
}
```

## Git e Versionamento

### Commit Messages
```
feat: add PayCreditCardBillUseCase with domain service integration
fix: handle insufficient balance error in Account.debit method  
refactor: extract validation logic to separate domain service
docs: update repository pattern documentation
test: add integration tests for TransferBetweenAccountsUseCase
```

### Branch Naming
```
feature/pay-credit-card-bill-use-case
bugfix/account-balance-validation  
refactor/repository-pattern-separation
docs/backend-architecture-split
```

---

**Esta documentação representa as convenções estabelecidas para o projeto OrçaSonhos. Todo código deve seguir estas diretrizes para manter consistência e qualidade.**