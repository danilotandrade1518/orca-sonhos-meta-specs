# Repository Pattern

## Visão Geral

O padrão Repository encapsula a lógica de persistência e fornece uma interface consistente para acesso aos agregados. Adotamos uma separação específica por tipo de operação para garantir aderência ao Single Responsibility Principle.

## Princípio da Granularidade Adequada

### Repositories: Genéricos por Operação

#### IAddRepository - Criação de Entidades
- **Responsabilidade**: Persistir novos agregados (INSERT)
- **Quando usar**: Criação de entidades completamente novas
- **Use Cases típicos**: `CreateTransactionUseCase`, `CreateAccountUseCase`

```typescript
export interface IAddTransactionRepository {
  execute(transaction: Transaction): Promise<Either<RepositoryError, void>>;
}
```

#### ISaveRepository - Atualização de Entidades
- **Responsabilidade**: Atualizar agregados existentes (UPDATE)
- **Quando usar**: Modificar estado de entidades já persistidas
- **Use Cases típicos**: `MarkTransactionLateUseCase`, `UpdateAccountUseCase`

```typescript
export interface ISaveTransactionRepository {
  execute(transaction: Transaction): Promise<Either<RepositoryError, void>>;
}
```

#### IGetRepository - Busca por ID
- **Responsabilidade**: Buscar agregado específico por identificador
- **Quando usar**: Operações que precisam de uma entidade específica
- **Retorno**: Entidade completa do domínio

```typescript
export interface IGetTransactionRepository {
  execute(transactionId: string): Promise<Either<RepositoryError, Transaction>>;
}
```

#### IFindRepository - Consultas de Negócio
- **Responsabilidade**: Consultas específicas com filtros de negócio
- **Quando usar**: Busca com critérios específicos do domínio
- **Retorno**: Lista de entidades ou entidade única

```typescript
export interface IFindTransactionRepository {
  findByAccountAndPeriod(
    accountId: string, 
    startDate: Date, 
    endDate: Date
  ): Promise<Either<RepositoryError, Transaction[]>>;
  
  findScheduledTransactions(
    budgetId: string
  ): Promise<Either<RepositoryError, Transaction[]>>;
}
```

#### IDeleteRepository - Remoção de Entidades  
- **Responsabilidade**: Remover agregados (DELETE)
- **Quando usar**: Deleção física ou lógica de entidades
- **Use Cases típicos**: `DeleteAccountUseCase`, `RemoveTransactionUseCase`

```typescript
export interface IDeleteTransactionRepository {
  execute(transactionId: string): Promise<Either<RepositoryError, void>>;
}
```

## Padrão Add vs Save Refinado

### Separação de Responsabilidades

**Vantagens da separação Add/Save:**

1. **Clareza de Intenção**: Fica explícito se a operação é de criação ou atualização
2. **Single Responsibility**: Cada interface tem uma responsabilidade específica  
3. **Testabilidade**: Stubs de teste mais específicos e focados
4. **Evolução**: Permite implementações diferentes se necessário
5. **Documentação Viva**: O código serve como documentação da intenção

### Exemplo de Implementação

```typescript
// Interface para criação de novas transações
export interface IAddTransactionRepository {
  execute(transaction: Transaction): Promise<Either<RepositoryError, void>>;
}

// Interface para atualização de transações existentes
export interface ISaveTransactionRepository {
  execute(transaction: Transaction): Promise<Either<RepositoryError, void>>;
}

// Use Case de criação utiliza Add Repository
export class CreateTransactionUseCase {
  constructor(
    private readonly addTransactionRepository: IAddTransactionRepository,
  ) {}

  async execute(dto: CreateTransactionDto) {
    const transaction = Transaction.create(dto);
    await this.addTransactionRepository.execute(transaction);
  }
}

// Use Case de atualização utiliza Save Repository
export class MarkTransactionLateUseCase {
  constructor(
    private readonly getTransactionRepository: IGetTransactionRepository,
    private readonly saveTransactionRepository: ISaveTransactionRepository,
  ) {}

  async execute(dto: MarkTransactionLateDto) {
    const transactionResult = await this.getTransactionRepository.execute(
      dto.transactionId,
    );
    
    if (transactionResult.hasError) {
      return Either.error(transactionResult.errors);
    }
    
    const transaction = transactionResult.data!;
    transaction.markAsLate(); // ← Regra de domínio na entidade
    
    const saveResult = await this.saveTransactionRepository.execute(transaction);
    return saveResult;
  }
}
```

## O que EVITAR

### ❌ Repositories de Mutação Específicos

Não crie repositories para operações específicas de domínio:

```typescript
// ❌ EVITAR - Repository muito específico
export interface IMarkTransactionLateRepository {
  execute(transactionId: string): Promise<Either<RepositoryError, void>>;
}

// ❌ EVITAR - Repository assumindo lógica de domínio
export interface ICancelScheduledTransactionRepository {
  execute(
    transactionId: string,
    reason: string,
  ): Promise<Either<RepositoryError, void>>;
}
```

**Problemas:**
- Explosão de interfaces para cada operação específica
- Repository assumindo responsabilidades de domínio
- Violação do Single Responsibility Principle
- Dificuldade de manutenção e teste

### ✅ PREFERIR: Use Cases Específicos + Repositories Genéricos

```typescript
// ✅ CORRETO: Use Case específico + Repositories genéricos
export class MarkTransactionLateUseCase {
  constructor(
    private readonly getTransactionRepository: IGetTransactionRepository,
    private readonly saveTransactionRepository: ISaveTransactionRepository,
  ) {}

  async execute(dto: MarkTransactionLateDto) {
    const transaction = await this.getTransactionRepository.execute(
      dto.transactionId,
    );
    transaction.markAsLate(); // ← Regra de domínio na entidade
    await this.saveTransactionRepository.execute(transaction); // ← Persistência genérica
  }
}
```

## Implementação Concreta

### Estrutura Base do Repository
```typescript
export class PostgresAddTransactionRepository implements IAddTransactionRepository {
  constructor(
    private readonly postgresConnectionAdapter: IPostgresConnectionAdapter
  ) {}

  async execute(transaction: Transaction): Promise<Either<RepositoryError, void>> {
    try {
      const client = await this.postgresConnectionAdapter.getClient();
      const transactionDto = TransactionMapper.domainToDto(transaction);
      
      await client.query(INSERT_TRANSACTION_QUERY, [
        transactionDto.id,
        transactionDto.accountId,
        transactionDto.categoryId,
        transactionDto.amount,
        transactionDto.type,
        transactionDto.transactionDate,
        transactionDto.description,
        transactionDto.budgetId,
      ]);
      
      return Either.success(undefined);
    } catch (error) {
      return Either.error(new RepositoryError('Failed to add transaction', error));
    }
  }
}
```

### Suporte a Unit of Work
Repositories devem suportar execução com client específico para trabalhar com Unit of Work:

```typescript
export class PostgresSaveAccountRepository {
  constructor(private postgresConnectionAdapter: IPostgresConnectionAdapter) {}

  // Método padrão (obtém própria conexão)
  async execute(account: Account): Promise<Either<RepositoryError, void>> {
    const client = await this.postgresConnectionAdapter.getClient();
    return this.executeWithClient(client, account);
  }

  // Método para Unit of Work (usa conexão fornecida)
  async executeWithClient(
    client: IDatabaseClient,
    account: Account,
  ): Promise<Either<RepositoryError, void>> {
    try {
      const accountDto = AccountMapper.domainToDto(account);
      await client.query(UPDATE_ACCOUNT_QUERY, [
        accountDto.name,
        accountDto.accountType,
        accountDto.balance,
        accountDto.id,
      ]);
      return Either.success(undefined);
    } catch (error) {
      return Either.error(new RepositoryError('Failed to save account', error));
    }
  }
}
```

## Tratamento de Erros

### Pattern Either Consistente
```typescript
// Retorno padronizado de todos os repositories
async execute(entity: Entity): Promise<Either<RepositoryError, ReturnType>> {
  try {
    // Operação de persistência
    return Either.success(result);
  } catch (error) {
    return Either.error(new RepositoryError('Operation failed', error));
  }
}

// Use Case trata Either
const result = await this.repository.execute(entity);
if (result.hasError) {
  return Either.error(new ApplicationError(result.errors));
}
// Continuar com sucesso...
```

### Tipos de Erro
```typescript
export class RepositoryError extends Error {
  constructor(
    message: string,
    public readonly originalError?: Error,
    public readonly code?: string
  ) {
    super(message);
  }
}

// Erros específicos
export class EntityNotFoundError extends RepositoryError {
  constructor(entityType: string, id: string) {
    super(`${entityType} with ID ${id} not found`, undefined, 'ENTITY_NOT_FOUND');
  }
}
```

## Organização no Projeto

```
/src/infra/database/pg/repositories/
├── /transaction/
│   ├── PostgresAddTransactionRepository.ts
│   ├── PostgresSaveTransactionRepository.ts
│   ├── PostgresGetTransactionRepository.ts
│   ├── PostgresFindTransactionRepository.ts
│   └── PostgresDeleteTransactionRepository.ts
├── /account/
│   ├── PostgresAddAccountRepository.ts
│   ├── PostgresSaveAccountRepository.ts
│   └── PostgresGetAccountRepository.ts
└── /shared/
    ├── mappers/
    └── queries/
```

## Vantagens da Abordagem

- **Repositories** focam apenas em persistência
- **Use Cases** expressam claramente a operação de negócio  
- **Entidades** encapsulam as regras de domínio
- **Maior reutilização** e **menor acoplamento**
- **Testabilidade** isolada de cada responsabilidade
- **Manutenibilidade** através de interfaces específicas

---

**Ver também:**
- [Unit of Work](./unit-of-work.md) - Para operações multi-agregado
- [DAO vs Repository](./dao-vs-repository.md) - Quando usar cada padrão
- [Layer Responsibilities](./layer-responsibilities.md) - Contexto das responsabilidades