# Estratégia de Queries e Performance

## Decisão Arquitetural: SQL Nativo

**Decisão**: Não utilizaremos ORM para queries
**Implementação**: SQL nativo via Query Handlers + DAOs

### Benefícios da Abordagem SQL Nativa
- **Performance otimizada** para casos específicos
- **Controle total** sobre queries complexas
- **Facilita relatórios** que cruzam múltiplos agregados
- **Transparência** total sobre o que é executado no banco

## Implementação de Query Handlers

### Estrutura Base

```typescript
export class GetBudgetSummaryQueryHandler {
  constructor(private budgetSummaryDao: IBudgetSummaryDao) {}
  
  async handle(query: GetBudgetSummaryQuery): Promise<Either<QueryError, BudgetSummaryDto>> {
    try {
      const result = await this.budgetSummaryDao.getBudgetSummary(
        query.budgetId,
        query.month
      );
      
      return Either.success(result);
    } catch (error) {
      return Either.error(new QueryError('Failed to get budget summary', error));
    }
  }
}
```

### DAO Implementation

```typescript
export class PostgresBudgetSummaryDao implements IBudgetSummaryDao {
  constructor(private client: IDatabaseClient) {}

  async getBudgetSummary(budgetId: string, month: string): Promise<BudgetSummaryDto> {
    const result = await this.client.query(`
      SELECT 
        b.name as budget_name,
        b.created_at,
        COUNT(DISTINCT a.id) as account_count,
        COALESCE(SUM(a.balance), 0) as total_balance,
        COUNT(DISTINCT t.id) FILTER (
          WHERE t.transaction_date >= $2::date 
          AND t.transaction_date < ($2::date + INTERVAL '1 month')
        ) as transaction_count,
        COALESCE(SUM(t.amount) FILTER (
          WHERE t.type = 'INCOME' 
          AND t.transaction_date >= $2::date 
          AND t.transaction_date < ($2::date + INTERVAL '1 month')
        ), 0) as total_income,
        COALESCE(SUM(t.amount) FILTER (
          WHERE t.type = 'EXPENSE' 
          AND t.transaction_date >= $2::date 
          AND t.transaction_date < ($2::date + INTERVAL '1 month')
        ), 0) as total_expenses
      FROM budgets b
      LEFT JOIN accounts a ON b.id = a.budget_id
      LEFT JOIN transactions t ON a.id = t.account_id
      WHERE b.id = $1
      GROUP BY b.id, b.name, b.created_at
    `, [budgetId, month]);
    
    if (result.rows.length === 0) {
      throw new Error('Budget not found');
    }
    
    return this.mapToBudgetSummaryDto(result.rows[0]);
  }

  private mapToBudgetSummaryDto(row: any): BudgetSummaryDto {
    return {
      budgetName: row.budget_name,
      accountCount: parseInt(row.account_count),
      totalBalance: parseFloat(row.total_balance),
      transactionCount: parseInt(row.transaction_count),
      totalIncome: parseFloat(row.total_income),
      totalExpenses: parseFloat(row.total_expenses),
      netIncome: parseFloat(row.total_income) - parseFloat(row.total_expenses),
    };
  }
}
```

## Consultas Complexas e Otimização

### JOINs Eficientes
Para relatórios que cruzam múltiplos agregados:
- **Query Handlers específicos** por caso de uso
- **JOINs otimizados** diretamente no SQL
- **Índices estratégicos** para performance

### Exemplo: Relatório de Gastos por Categoria
```typescript
export class GetCategoryExpensesDao implements IGetCategoryExpensesDao {
  async getCategoryExpenses(
    budgetId: string,
    startDate: Date,
    endDate: Date
  ): Promise<CategoryExpenseDto[]> {
    const result = await this.client.query(`
      SELECT 
        c.id,
        c.name as category_name,
        c.type as category_type,
        COUNT(t.id) as transaction_count,
        SUM(t.amount) as total_amount,
        AVG(t.amount) as average_amount,
        MIN(t.amount) as min_amount,
        MAX(t.amount) as max_amount,
        -- Comparação com mês anterior
        (
          SELECT COALESCE(SUM(t2.amount), 0)
          FROM transactions t2
          WHERE t2.category_id = c.id
          AND t2.transaction_date >= $3::date - INTERVAL '1 month'
          AND t2.transaction_date < $2::date - INTERVAL '1 month'
        ) as previous_month_total
      FROM categories c
      LEFT JOIN transactions t ON c.id = t.category_id
        AND t.transaction_date >= $2::date
        AND t.transaction_date <= $3::date
        AND t.type = 'EXPENSE'
      WHERE c.budget_id = $1
      GROUP BY c.id, c.name, c.type
      ORDER BY total_amount DESC NULLS LAST
    `, [budgetId, startDate, endDate]);

    return result.rows.map(row => ({
      categoryId: row.id,
      categoryName: row.category_name,
      categoryType: row.category_type,
      transactionCount: parseInt(row.transaction_count) || 0,
      totalAmount: parseFloat(row.total_amount) || 0,
      averageAmount: parseFloat(row.average_amount) || 0,
      minAmount: parseFloat(row.min_amount) || 0,
      maxAmount: parseFloat(row.max_amount) || 0,
      previousMonthTotal: parseFloat(row.previous_month_total) || 0,
      percentageChange: this.calculatePercentageChange(
        parseFloat(row.total_amount) || 0,
        parseFloat(row.previous_month_total) || 0
      ),
    }));
  }

  private calculatePercentageChange(current: number, previous: number): number {
    if (previous === 0) return current > 0 ? 100 : 0;
    return ((current - previous) / previous) * 100;
  }
}
```

## Paginação Eficiente

### Implementação com OFFSET/LIMIT
```typescript
export interface PaginationParams {
  page: number;
  limit: number;
  orderBy?: string;
  orderDirection?: 'ASC' | 'DESC';
}

export interface PaginatedResult<T> {
  data: T[];
  pagination: {
    currentPage: number;
    totalPages: number;
    totalItems: number;
    hasNext: boolean;
    hasPrevious: boolean;
  };
}

export class GetTransactionsDao implements IGetTransactionsDao {
  async getTransactionsPaginated(
    budgetId: string,
    filters: TransactionFilters,
    pagination: PaginationParams
  ): Promise<PaginatedResult<TransactionSummaryDto>> {
    const offset = (pagination.page - 1) * pagination.limit;
    const orderBy = pagination.orderBy || 'transaction_date';
    const orderDirection = pagination.orderDirection || 'DESC';
    
    // Query principal com dados
    const dataQuery = `
      SELECT 
        t.id,
        t.amount,
        t.type,
        t.transaction_date,
        t.description,
        a.name as account_name,
        c.name as category_name,
        c.type as category_type
      FROM transactions t
      JOIN accounts a ON t.account_id = a.id
      JOIN categories c ON t.category_id = c.id
      WHERE a.budget_id = $1
        ${filters.accountId ? 'AND t.account_id = $2' : ''}
        ${filters.categoryId ? 'AND t.category_id = $3' : ''}
        ${filters.startDate ? 'AND t.transaction_date >= $4' : ''}
        ${filters.endDate ? 'AND t.transaction_date <= $5' : ''}
      ORDER BY ${orderBy} ${orderDirection}
      LIMIT $6 OFFSET $7
    `;
    
    // Query de contagem total
    const countQuery = `
      SELECT COUNT(*) as total
      FROM transactions t
      JOIN accounts a ON t.account_id = a.id
      WHERE a.budget_id = $1
        ${filters.accountId ? 'AND t.account_id = $2' : ''}
        ${filters.categoryId ? 'AND t.category_id = $3' : ''}
        ${filters.startDate ? 'AND t.transaction_date >= $4' : ''}
        ${filters.endDate ? 'AND t.transaction_date <= $5' : ''}
    `;
    
    const [dataResult, countResult] = await Promise.all([
      this.client.query(dataQuery, [...filterParams, pagination.limit, offset]),
      this.client.query(countQuery, filterParams)
    ]);
    
    const totalItems = parseInt(countResult.rows[0].total);
    const totalPages = Math.ceil(totalItems / pagination.limit);
    
    return {
      data: dataResult.rows.map(row => this.mapToTransactionSummaryDto(row)),
      pagination: {
        currentPage: pagination.page,
        totalPages,
        totalItems,
        hasNext: pagination.page < totalPages,
        hasPrevious: pagination.page > 1,
      },
    };
  }
}
```

## Sem Projeções Iniciais

### Estratégia Atual
- **Consultas diretas** ao banco de dados transacional
- **Views materializadas** apenas se performance exigir no futuro
- **Foco em queries otimizadas** via índices e SQL eficiente

### Índices Estratégicos
```sql
-- Índices para performance de queries frequentes
CREATE INDEX idx_transactions_budget_date ON transactions (budget_id, transaction_date);
CREATE INDEX idx_transactions_account_type ON transactions (account_id, type);
CREATE INDEX idx_transactions_category_date ON transactions (category_id, transaction_date);
CREATE INDEX idx_accounts_budget ON accounts (budget_id);
CREATE INDEX idx_categories_budget ON categories (budget_id);

-- Índices compostos para queries específicas
CREATE INDEX idx_transactions_budget_date_type ON transactions (budget_id, transaction_date, type);
CREATE INDEX idx_transactions_account_date_amount ON transactions (account_id, transaction_date, amount);
```

## Tratamento de Erros em Queries

### Pattern Either Consistente
```typescript
export class QueryHandler {
  async handle(query: Query): Promise<Either<QueryError, ResultDto>> {
    try {
      const result = await this.dao.executeQuery(query);
      return Either.success(result);
    } catch (error) {
      if (error.code === 'ENTITY_NOT_FOUND') {
        return Either.error(new QueryError('Entity not found', error));
      }
      
      return Either.error(new QueryError('Query execution failed', error));
    }
  }
}
```

## Performance Monitoring

### Métricas Importantes
- **Tempo de resposta** das queries mais frequentes
- **Número de rows** processadas vs retornadas
- **Uso de índices** (EXPLAIN ANALYZE)
- **Queries lentas** (log de queries > 100ms)

### Otimização Contínua
```typescript
export class QueryPerformanceMonitor {
  async executeWithMetrics<T>(
    queryName: string,
    queryFn: () => Promise<T>
  ): Promise<T> {
    const startTime = Date.now();
    
    try {
      const result = await queryFn();
      const duration = Date.now() - startTime;
      
      // Log métricas
      this.logger.info('Query executed', {
        queryName,
        duration,
        status: 'success'
      });
      
      // Alertar se query lenta
      if (duration > 1000) {
        this.logger.warn('Slow query detected', { queryName, duration });
      }
      
      return result;
    } catch (error) {
      const duration = Date.now() - startTime;
      this.logger.error('Query failed', {
        queryName,
        duration,
        error: error.message
      });
      throw error;
    }
  }
}
```

## Organização dos DAOs

```
/src/infra/database/pg/daos/
├── /budget/
│   ├── PostgresBudgetSummaryDao.ts
│   └── PostgresBudgetReportDao.ts
├── /transaction/
│   ├── PostgresGetTransactionsDao.ts
│   └── PostgresTransactionAnalyticsDao.ts
├── /account/
│   └── PostgresAccountSummaryDao.ts
└── /shared/
    ├── QueryPerformanceMonitor.ts
    └── PaginationHelper.ts
```

---

**Ver também:**
- [DAO vs Repository](./dao-vs-repository.md) - Quando usar cada padrão
- [Data Flow](./data-flow.md) - Contexto dos fluxos de query vs command