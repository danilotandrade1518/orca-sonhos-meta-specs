# DAO vs Repository

## Diferenças Fundamentais

### Repository - Para Mutações e Persistência de Agregados
**Responsabilidade**: Representa uma coleção de agregados (entidades) e encapsula regras de negócio relacionadas à persistência.

**Características**:
- Utilizado principalmente em operações de **mutação** (criação, atualização, remoção)
- Segue contratos definidos na camada de domínio
- Trabalha com **entidades completas** do domínio
- Mantém invariantes e consistência dos agregados

**Quando usar**:
- Use Cases que modificam estado (commands)
- Operações CRUD de agregados
- Necessidade de carregar entidades completas
- Aplicação de regras de domínio durante persistência

### DAO - Para Consultas Otimizadas
**Responsabilidade**: Focado em consultas (queries) e otimizado para leitura de dados.

**Características**:
- Utilizado em **Query Handlers** para buscar informações
- Acesso direto ao PostgreSQL com **SQL nativo**
- Retorna **DTOs específicos** para views (não entidades de domínio)
- Otimizado para performance de leitura

**Quando usar**:
- Query Handlers (consultas)
- Relatórios e dashboards
- Listagens paginadas
- Agregações e análises de dados

## Exemplos Práticos

### Repository - Persistência de Agregado
```typescript
// Interface de domínio
export interface IAddTransactionRepository {
  execute(transaction: Transaction): Promise<Either<RepositoryError, void>>;
}

// Implementação de infraestrutura
export class PostgresAddTransactionRepository implements IAddTransactionRepository {
  async execute(transaction: Transaction): Promise<Either<RepositoryError, void>> {
    try {
      // Trabalha com entidade completa do domínio
      const transactionDto = TransactionMapper.domainToDto(transaction);
      
      // Validações de consistência podem ser aplicadas
      if (!this.isValidTransaction(transactionDto)) {
        return Either.error(new RepositoryError('Invalid transaction data'));
      }
      
      await this.client.query(INSERT_TRANSACTION_QUERY, [
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
  
  private isValidTransaction(transaction: TransactionDto): boolean {
    // Validações específicas do repository
    return transaction.amount > 0 && 
           transaction.accountId && 
           transaction.categoryId;
  }
}
```

### DAO - Consulta Otimizada
```typescript
// Interface específica para consulta
export interface ITransactionSummaryDao {
  getTransactionsSummary(
    budgetId: string,
    period: DateRange
  ): Promise<TransactionSummaryDto[]>;
}

// Implementação focada em performance
export class PostgresTransactionSummaryDao implements ITransactionSummaryDao {
  async getTransactionsSummary(
    budgetId: string,
    period: DateRange
  ): Promise<TransactionSummaryDto[]> {
    // SQL nativo otimizado - foco na performance
    const result = await this.client.query(`
      SELECT 
        t.id,
        t.amount,
        t.type,
        t.transaction_date,
        t.description,
        a.name as account_name,
        a.type as account_type,
        c.name as category_name,
        c.type as category_type,
        -- Cálculos agregados no banco
        SUM(t.amount) OVER (
          PARTITION BY t.account_id 
          ORDER BY t.transaction_date 
          ROWS UNBOUNDED PRECEDING
        ) as running_balance,
        COUNT(*) OVER (PARTITION BY c.id) as category_transaction_count
      FROM transactions t
      JOIN accounts a ON t.account_id = a.id
      JOIN categories c ON t.category_id = c.id
      WHERE a.budget_id = $1
        AND t.transaction_date >= $2
        AND t.transaction_date <= $3
      ORDER BY t.transaction_date DESC, t.created_at DESC
    `, [budgetId, period.startDate, period.endDate]);
    
    // Retorna DTOs específicos para a view (não entidades)
    return result.rows.map(row => ({
      id: row.id,
      amount: parseFloat(row.amount),
      type: row.type,
      date: row.transaction_date,
      description: row.description,
      accountName: row.account_name,
      accountType: row.account_type,
      categoryName: row.category_name,
      categoryType: row.category_type,
      runningBalance: parseFloat(row.running_balance),
      categoryTransactionCount: parseInt(row.category_transaction_count),
    }));
  }
}
```

## Uso em Use Cases vs Query Handlers

### Repository em Use Case (Command)
```typescript
export class CreateTransactionUseCase {
  constructor(
    private addTransactionRepository: IAddTransactionRepository,
    private getAccountRepository: IGetAccountRepository,
  ) {}
  
  async execute(dto: CreateTransactionDto): Promise<Either<ApplicationError, void>> {
    // 1. Busca entidade completa via Repository
    const accountResult = await this.getAccountRepository.execute(dto.accountId);
    if (accountResult.hasError) {
      return Either.error(new ApplicationError('Account not found'));
    }
    
    // 2. Aplica regras de domínio na entidade
    const account = accountResult.data!;
    const transaction = account.createTransaction(dto);
    
    // 3. Persiste entidade completa via Repository
    const saveResult = await this.addTransactionRepository.execute(transaction);
    return saveResult;
  }
}
```

### DAO em Query Handler (Query)
```typescript
export class GetTransactionsSummaryQueryHandler {
  constructor(
    private transactionSummaryDao: ITransactionSummaryDao
  ) {}
  
  async handle(
    query: GetTransactionsSummaryQuery
  ): Promise<Either<QueryError, TransactionSummaryDto[]>> {
    try {
      // Acesso direto e otimizado via DAO
      const summary = await this.transactionSummaryDao.getTransactionsSummary(
        query.budgetId,
        query.period
      );
      
      return Either.success(summary);
    } catch (error) {
      return Either.error(new QueryError('Failed to get transactions summary', error));
    }
  }
}
```

## Características de Implementação

### Repository Characteristics
| Aspecto | Repository |
|---------|------------|
| **Entradas** | Entidades de domínio |
| **Saídas** | Entidades de domínio ou void |
| **SQL** | Queries simples (CRUD) |
| **Mapeamento** | Domain ↔ DTO bidirecionial |
| **Validação** | Invariantes de agregado |
| **Performance** | Consistência > Performance |
| **Transações** | Suporte a Unit of Work |

### DAO Characteristics
| Aspecto | DAO |
|---------|-----|
| **Entradas** | Parâmetros primitivos |
| **Saídas** | DTOs específicos para view |
| **SQL** | Queries complexas otimizadas |
| **Mapeamento** | DB → DTO (unidirecional) |
| **Validação** | Apenas formato/tipo |
| **Performance** | Performance > Consistência |
| **Transações** | Read-only (normalmente) |

## Diretrizes de Decisão

### Use Repository quando:
- ✅ **Modificando estado** (Create, Update, Delete)
- ✅ **Precisar da entidade completa** para aplicar regras
- ✅ **Manter invariantes** do agregado
- ✅ **Unit of Work** é necessário
- ✅ **Use Cases** de command/mutation

### Use DAO quando:
- ✅ **Apenas lendo dados** para views
- ✅ **Performance é crítica** 
- ✅ **Agregações complexas** são necessárias
- ✅ **Relatórios e dashboards**
- ✅ **Query Handlers** de consulta

## Padrões de Nomenclatura

### Repository
```typescript
// Interfaces
IAddTransactionRepository
ISaveTransactionRepository
IGetTransactionRepository
IFindTransactionRepository
IDeleteTransactionRepository

// Implementações
PostgresAddTransactionRepository
PostgresSaveTransactionRepository
PostgresGetTransactionRepository
PostgresFindTransactionRepository
PostgresDeleteTransactionRepository
```

### DAO
```typescript
// Interfaces
ITransactionSummaryDao
IBudgetReportDao
ICategoryAnalyticsDao
IAccountBalanceDao

// Implementações
PostgresTransactionSummaryDao
PostgresBudgetReportDao
PostgresCategoryAnalyticsDao
PostgresAccountBalanceDao
```

## Organização no Projeto

```
/src/infra/database/pg/
├── /repositories/          # Para mutações
│   ├── /transaction/
│   ├── /account/
│   └── /budget/
├── /daos/                 # Para consultas
│   ├── /transaction/
│   ├── /budget/
│   └── /analytics/
└── /shared/
    ├── /mappers/          # Domain ↔ DTO (repositories)
    └── /connections/      # Database connections
```

## Anti-patterns a Evitar

### ❌ Repository fazendo consultas complexas
```typescript
// ❌ EVITAR - Repository não deve fazer relatórios
export class TransactionRepository {
  async getComplexReport(budgetId: string) {
    // Queries complexas com múltiplos JOINs e agregações
    // Isso deveria estar em um DAO
  }
}
```

### ❌ DAO fazendo persistência
```typescript
// ❌ EVITAR - DAO não deve modificar estado
export class TransactionDao {
  async saveTransaction(transaction: TransactionDto) {
    // Persistência deveria estar em Repository
  }
}
```

### ❌ Repository retornando DTOs de view
```typescript
// ❌ EVITAR - Repository deve retornar entidades
export class TransactionRepository {
  async getTransaction(id: string): Promise<TransactionSummaryDto> {
    // Deveria retornar Transaction entity, não DTO
  }
}
```

---

**Ver também:**
- [Repository Pattern](./repository-pattern.md) - Detalhes sobre repositories
- [Query Strategy](./query-strategy.md) - Estratégia de consultas com DAOs
- [Data Flow](./data-flow.md) - Contexto dos fluxos command vs query