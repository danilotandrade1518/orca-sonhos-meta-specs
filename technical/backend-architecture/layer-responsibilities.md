# Responsabilidades das Camadas

## Visão Geral

Cada camada da aplicação possui responsabilidades bem definidas, seguindo o princípio de Separação de Responsabilidades (Separation of Concerns) e a Arquitetura Limpa.

## Domain Layer

### Responsabilidades
- **Agregados e Entidades**: Modelagem do negócio e encapsulamento de invariantes
- **Value Objects**: Conceitos imutáveis do domínio (Money, Email, etc.)
- **Regras de Negócio Puras**: Sem dependências externas ou de infraestrutura
- **Domain Services**: Operações complexas entre múltiplas entidades

### O que DEVE conter
- Entities com comportamentos ricos
- Value Objects imutáveis
- Invariantes e validações de domínio
- Domain Services para coordenação entre entidades
- Enums e constantes de domínio

### O que NÃO deve conter
- Dependências de infraestrutura (banco, APIs, etc.)
- Lógica de aplicação (orquestração)
- Detalhes de persistência
- Regras de apresentação ou formatação

### Exemplo
```typescript
// ✅ CORRETO - Domain Entity
export class Account {
  private constructor(
    private readonly _id: string,
    private _name: string,
    private _balance: Money,
    private readonly _budgetId: string
  ) {}

  public debit(amount: number): void {
    if (amount <= 0) {
      throw new DomainError('Amount must be positive');
    }
    if (this._balance.value < amount) {
      throw new DomainError('Insufficient balance');
    }
    this._balance = this._balance.subtract(amount);
  }
}
```

## Application Layer

### Use Cases - Orquestração de Regras de Negócio

#### Responsabilidades
- **Coordenar** entidades e serviços para executar casos de uso específicos
- **Aplicar regras de negócio** através do domínio
- **Gerenciar transações** e persistência via Repositories ou Unit of Work

#### Quando usar Repositories vs Unit of Work

**Use Repositories quando:**
- Operação envolve **APENAS 1 AGREGADO**
- CRUD simples (criação, atualização, remoção de uma entidade)
- Não há necessidade de atomicidade entre múltiplas operações

```typescript
export class CreateAccountUseCase {
  constructor(
    private addAccountRepository: IAddAccountRepository
  ) {}
  
  async execute(dto: CreateAccountDto) {
    const account = Account.create(dto);
    await this.addAccountRepository.execute(account);
  }
}
```

**Use Unit of Work quando:**
- Operação envolve **MAIS DE 1 AGREGADO**
- Necessário garantir atomicidade entre múltiplas operações
- Operações complexas como transferências entre contas

```typescript
export class TransferBetweenAccountsUseCase {
  constructor(
    private unitOfWork: ITransferBetweenAccountsUnitOfWork
  ) {}
  
  async execute(dto: TransferDto) {
    // Múltiplas operações que devem ser atômicas
    await this.unitOfWork.executeTransfer({
      fromAccount,
      toAccount,
      debitTransaction,
      creditTransaction
    });
  }
}
```

### Query Handlers - Consultas Otimizadas

#### Responsabilidades
- **Buscar dados** de forma otimizada para views específicas
- **Utilizar DAOs** para acesso direto ao banco com SQL nativo
- **Não aplicar regras de negócio** - apenas transformação de dados

#### Características
- SQL nativo otimizado
- Retorna DTOs específicos para cada view
- Não carrega entidades de domínio completas

```typescript
export class GetBudgetSummaryQueryHandler {
  constructor(private budgetSummaryDao: IBudgetSummaryDao) {}
  
  async handle(query: GetBudgetSummaryQuery): Promise<BudgetSummaryDto> {
    return await this.budgetSummaryDao.getBudgetSummary(query.budgetId);
  }
}
```

## Web Layer (Interfaces)

### Responsabilidades
- **Pontos de entrada/saída HTTP** via controllers Express
- **Adaptação de dados** entre HTTP e Application layer  
- **Validação de entrada** e formatação de resposta
- **Mapeamento** de DTOs HTTP para DTOs de aplicação

### O que DEVE conter
- Controllers HTTP
- Middlewares de validação
- DTOs de request/response
- Mapeamento HTTP ↔ Application

### O que NÃO deve conter
- Regras de negócio
- Lógica de persistência
- Processamento complexo de dados

```typescript
export class BudgetController {
  constructor(private createBudgetUseCase: CreateBudgetUseCase) {}
  
  async createBudget(req: Request, res: Response) {
    const dto = BudgetMapper.httpToUseCaseDto(req.body);
    const result = await this.createBudgetUseCase.execute(dto);
    
    if (result.hasError) {
      return res.status(400).json(result.errors);
    }
    
    res.status(201).json(result.data);
  }
}
```

## Infrastructure Layer

### Responsabilidades
- **Implementação de repositórios** e persistência
- **Integrações externas** (APIs, serviços de terceiros)
- **Configurações** de banco de dados e conexões
- **Mapeamento** entre domínio e persistência

### Repositories
Implementam contratos definidos na Application layer:
```typescript
export class PostgresAddAccountRepository implements IAddAccountRepository {
  async execute(account: Account): Promise<Either<RepositoryError, void>> {
    const client = await this.connectionAdapter.getClient();
    const accountDto = AccountMapper.domainToDto(account);
    
    await client.query(INSERT_ACCOUNT_QUERY, [
      accountDto.id,
      accountDto.name,
      accountDto.balance,
      accountDto.budgetId
    ]);
    
    return Either.success(undefined);
  }
}
```

### DAOs (Data Access Objects)
Focados em consultas otimizadas:
```typescript
export class PostgresBudgetSummaryDao implements IBudgetSummaryDao {
  async getBudgetSummary(budgetId: string): Promise<BudgetSummaryDto> {
    const result = await this.client.query(`
      SELECT 
        b.name,
        COUNT(a.id) as account_count,
        SUM(a.balance) as total_balance
      FROM budgets b
      LEFT JOIN accounts a ON b.id = a.budget_id
      WHERE b.id = $1
      GROUP BY b.id, b.name
    `, [budgetId]);
    
    return this.mapToBudgetSummaryDto(result.rows[0]);
  }
}
```

## Princípio da Granularidade Adequada

### Repositories: Genéricos por Operação
- **IAddRepository**: Criação de entidades (INSERT)
- **ISaveRepository**: Atualização de entidades (UPDATE)
- **IGetRepository**: Busca por ID específico
- **IFindRepository**: Consultas específicas de negócio
- **IDeleteRepository**: Remoção de entidades (DELETE)

### Use Cases: Específicos por Regra de Negócio
- **CreateTransactionUseCase**: Criar nova transação
- **MarkTransactionLateUseCase**: Marcar transação como atrasada
- **CancelScheduledTransactionUseCase**: Cancelar transação agendada
- **ReconcileAccountUseCase**: Reconciliar saldo da conta

## Benefícios da Separação

Esta separação garante que:
- **Repositories** focam apenas em persistência
- **Use Cases** expressam claramente a operação de negócio
- **Entidades** encapsulam as regras de domínio
- **Maior reutilização** e **menor acoplamento**
- **Testabilidade** isolada de cada camada

---

**Ver também:**
- [Repository Pattern](./repository-pattern.md) - Detalhes do padrão Repository
- [Unit of Work](./unit-of-work.md) - Quando e como usar Unit of Work
- [Domain Services](./domain-services.md) - Coordenação entre entidades