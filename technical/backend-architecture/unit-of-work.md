# Unit of Work Pattern

## Conceito

O padrão **Unit of Work** mantém uma lista de objetos afetados por uma transação de negócio e coordena a escrita das mudanças, resolvendo problemas de concorrência. Em nosso contexto, é especialmente útil para operações que envolvem múltiplos agregados ou múltiplas operações que devem ser executadas atomicamente.

## REGRA FUNDAMENTAL: Quando Utilizar

### ✅ USE Unit of Work EXCLUSIVAMENTE quando:

**Necessário salvar MAIS DE 1 AGREGADO ao mesmo tempo**

Cenários específicos:
- **Múltiplos Agregados**: Modificações em diferentes agregados que precisam ser consistentes
- **Operações de Transferência**: Transferências entre contas (débito + crédito)
- **Operações Atômicas Complexas**: Múltiplas escritas que devem ser executadas como uma única transação
- **Rollback Automático**: Necessário garantir que falhas revertam todas as operações

### ❌ NÃO USE Unit of Work quando:

**SEMPRE que for necessário salvar APENAS 1 AGREGADO, utilize Repository**

Evite Unit of Work quando:
- **Operações com Um Único Agregado**: Use Repository diretamente
- **Apenas Leitura**: Use Query Handlers 
- **Operações Independentes**: Quando não há necessidade de atomicidade
- **CRUD Simples**: Criação, atualização ou remoção de uma única entidade

## Implementação

### Interface Base

```typescript
export interface IUnitOfWork {
  executeTransfer(
    params: TransferParams,
  ): Promise<Either<TransferExecutionError, void>>;
}
```

### Implementação Concreta

```typescript
export class TransferBetweenAccountsUnitOfWork implements IUnitOfWork {
  private saveAccountRepository: SaveAccountRepository;
  private addTransactionRepository: AddTransactionRepository;

  constructor(private postgresConnectionAdapter: IPostgresConnectionAdapter) {
    this.saveAccountRepository = new SaveAccountRepository(
      postgresConnectionAdapter,
    );
    this.addTransactionRepository = new AddTransactionRepository(
      postgresConnectionAdapter,
    );
  }

  async executeTransfer(
    params: TransferParams,
  ): Promise<Either<TransferExecutionError, void>> {
    let client: IDatabaseClient | undefined;

    try {
      // 1. Obter conexão e iniciar transação
      client = await this.postgresConnectionAdapter.getClient();
      await client.beginTransaction();

      // 2. Executar operações usando a mesma conexão
      const saveFromResult = await this.saveAccountRepository.executeWithClient(
        client,
        params.fromAccount,
      );
      if (saveFromResult.hasError)
        throw new Error('Failed to save source account');

      const saveToResult = await this.saveAccountRepository.executeWithClient(
        client,
        params.toAccount,
      );
      if (saveToResult.hasError)
        throw new Error('Failed to save target account');

      const addDebitResult =
        await this.addTransactionRepository.executeWithClient(
          client,
          params.debitTransaction,
        );
      if (addDebitResult.hasError)
        throw new Error('Failed to add debit transaction');

      const addCreditResult =
        await this.addTransactionRepository.executeWithClient(
          client,
          params.creditTransaction,
        );
      if (addCreditResult.hasError)
        throw new Error('Failed to add credit transaction');

      // 3. Commit da transação
      await client.commitTransaction();
      return Either.success(undefined);
    } catch (error) {
      // 4. Rollback em caso de erro
      if (client) {
        try {
          await client.rollbackTransaction();
        } catch (rollbackError) {
          // Log rollback error but don't mask original error
        }
      }
      return Either.error(new TransferExecutionError(error.message, error));
    }
  }
}
```

## Integração com Repositories

### Suporte a Client Específico

Os repositories devem suportar execução com client específico:

```typescript
export class SaveAccountRepository {
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
        accountDto.id,
      ]);
      return Either.success(undefined);
    } catch (error) {
      return Either.error(new RepositoryError('Failed to save account', error));
    }
  }
}
```

## Uso em Use Cases

### Exemplo: Transferência Entre Contas

```typescript
export class TransferBetweenAccountsUseCase {
  constructor(
    private unitOfWork: TransferBetweenAccountsUnitOfWork,
    private getAccountRepository: IGetAccountRepository,
  ) {}

  async execute(
    dto: TransferBetweenAccountsDto,
  ): Promise<Either<ApplicationError, void>> {
    // 1. Buscar contas (podem ser do mesmo agregado ou diferentes)
    const fromAccountResult = await this.getAccountRepository.execute(dto.fromAccountId);
    const toAccountResult = await this.getAccountRepository.execute(dto.toAccountId);
    
    if (fromAccountResult.hasError || toAccountResult.hasError) {
      return Either.error(new ApplicationError('Failed to fetch accounts'));
    }
    
    const fromAccount = fromAccountResult.data!;
    const toAccount = toAccountResult.data!;

    // 2. Aplicar regras de negócio
    fromAccount.debit(dto.amount);
    toAccount.credit(dto.amount);

    // 3. Criar transações relacionadas
    const debitTransaction = Transaction.createDebit({
      accountId: dto.fromAccountId,
      amount: dto.amount,
      description: `Transfer to ${toAccount.name}`,
      budgetId: dto.budgetId,
      categoryId: dto.transferCategoryId,
    });
    
    const creditTransaction = Transaction.createCredit({
      accountId: dto.toAccountId,
      amount: dto.amount,
      description: `Transfer from ${fromAccount.name}`,
      budgetId: dto.budgetId,
      categoryId: dto.transferCategoryId,
    });

    // 4. Executar com Unit of Work (operação atômica)
    const result = await this.unitOfWork.executeTransfer({
      fromAccount,
      toAccount,
      debitTransaction,
      creditTransaction,
    });

    return result;
  }
}
```

### Exemplo: Operação com Um Único Agregado (Use Repository)

```typescript
export class CreateAccountUseCase {
  constructor(
    private addAccountRepository: IAddAccountRepository
  ) {}
  
  async execute(dto: CreateAccountDto): Promise<Either<ApplicationError, void>> {
    // Apenas 1 agregado - Use Repository diretamente
    const account = Account.create(dto);
    const result = await this.addAccountRepository.execute(account);
    return result;
  }
}
```

## Vantagens

- **Atomicidade**: Garante que todas as operações sejam executadas ou nenhuma
- **Consistência**: Mantém o estado consistente mesmo em operações complexas
- **Isolamento**: Usa transações de banco para garantir isolamento
- **Rollback Automático**: Falhas em qualquer etapa revertem toda a operação
- **Reutilização**: Unit of Works podem ser reutilizados em diferentes Use Cases

## Organização no Projeto

```
/src/infra/database/pg/unit-of-works/
├── transfer-between-accounts/
│   ├── TransferBetweenAccountsUnitOfWork.ts
│   └── TransferBetweenAccountsUnitOfWork.spec.ts
├── bulk-transaction-import/
│   ├── BulkTransactionImportUnitOfWork.ts
│   └── BulkTransactionImportUnitOfWork.spec.ts
└── pay-credit-card-bill/
    ├── PayCreditCardBillUnitOfWork.ts
    └── PayCreditCardBillUnitOfWork.spec.ts
```

## Testes

### Cenários de Teste Obrigatórios

Unit of Works devem ter cobertura completa de testes:

```typescript
describe('TransferBetweenAccountsUnitOfWork', () => {
  it('should execute transfer successfully', async () => {
    // Arrange
    mockSaveAccountRepository.executeWithClient.mockResolvedValue(
      Either.success(undefined),
    );
    mockAddTransactionRepository.executeWithClient.mockResolvedValue(
      Either.success(undefined),
    );

    // Act
    const result = await unitOfWork.executeTransfer(transferParams);

    // Assert
    expect(result.hasError).toBe(false);
    expect(mockClient.commitTransaction).toHaveBeenCalled();
  });

  it('should rollback when repository fails', async () => {
    // Arrange
    mockSaveAccountRepository.executeWithClient.mockResolvedValueOnce(
      Either.error(new RepositoryError('Database error')),
    );

    // Act
    const result = await unitOfWork.executeTransfer(transferParams);

    // Assert
    expect(result.hasError).toBe(true);
    expect(mockClient.rollbackTransaction).toHaveBeenCalled();
  });
  
  it('should verify order of operations', async () => {
    // Verificar que operações são executadas na ordem correta
  });
  
  it('should handle connection failures gracefully', async () => {
    // Testar falhas de conexão
  });
});
```

### Tipos de Teste

- **Cenários de Sucesso**: Verificação de execução completa
- **Cenários de Falha**: Simulação de falhas em cada etapa
- **Rollback**: Verificação de rollback automático
- **Ordem de Execução**: Validação da sequência correta das operações

## Padrões de Nomenclatura

- **Classes**: Sufixo `UnitOfWork` (ex: `TransferBetweenAccountsUnitOfWork`)
- **Interfaces**: Prefixo `I` + sufixo `UnitOfWork` (ex: `ITransferBetweenAccountsUnitOfWork`)
- **Métodos**: `execute[Operation]` (ex: `executeTransfer`)
- **Arquivos**: `[Operation]UnitOfWork.ts`

## Diferença Fundamental: Repository vs Unit of Work

| Cenário | Padrão | Justificativa |
|---------|--------|---------------|
| Criar 1 transação | Repository | Apenas 1 agregado |
| Atualizar 1 conta | Repository | Apenas 1 agregado |  
| Transferir entre contas | Unit of Work | 2+ agregados (contas + transações) |
| Pagar fatura cartão | Unit of Work | 2+ agregados (conta + fatura + transação) |
| Importar lote de transações | Unit of Work | Múltiplas operações atômicas |

---

**Ver também:**
- [Repository Pattern](./repository-pattern.md) - Para operações de agregado único
- [Domain Services](./domain-services.md) - Coordenação de regras de negócio
- [Layer Responsibilities](./layer-responsibilities.md) - Contexto das responsabilidades