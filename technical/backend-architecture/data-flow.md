# Fluxo de Dados

## Visão Geral

O sistema utiliza o padrão CQRS (Command Query Responsibility Segregation) para separar claramente as operações de escrita (commands/mutations) das operações de leitura (queries/consultas).

## Mutação de Estado (Commands)

### Fluxo Completo
```
[HTTP Request] → [Controller] → [Use Case] → [Domain Services] → [Repository/Unit of Work] → [Database]
                           ↓
                    [HTTP Response]
```

### Detalhamento das Etapas

#### 1. HTTP Request
- Requisição chega pela camada web (controller Express)
- Validação básica de entrada (formato, tipos, etc.)
- Extração de dados do header Authorization (Firebase token)

#### 2. Controller
- Adapta dados HTTP para DTOs de aplicação
- Chama o Use Case apropriado
- Trata erros e formata resposta HTTP

#### 3. Use Case
- **Orquestra** a operação usando Domain Services e Repositories
- **Aplica autorização** via `IBudgetAuthorizationService`
- **Coordena** múltiplas operações se necessário
- **Gerencia transações** via Unit of Work quando apropriado

#### 4. Domain Services (quando necessário)
- **Executa regras de negócio complexas** entre múltiplas entidades
- **Valida invariantes** que cruzam agregados
- **Cria entidades derivadas** necessárias para a operação

#### 5. Repository/Unit of Work
- **Repository**: Para operações com 1 agregado apenas
- **Unit of Work**: Para operações com múltiplos agregados
- **Garante atomicidade** quando necessário

#### 6. Database
- Mudanças são persistidas no PostgreSQL
- Transações garantem consistência

#### 7. Response
- Retorno via cadeia até o usuário
- Formato padronizado via `DefaultResponseBuilder`

### Exemplo: Pagamento de Fatura

```typescript
// 1. Controller recebe request
POST /credit-card-bill/pay-credit-card-bill
Authorization: Bearer <firebase_token>
Body: { billId, accountId, amount, paymentCategoryId }

// 2. Controller → Use Case
const result = await this.payCreditCardBillUseCase.execute(dto, userId);

// 3. Use Case coordena operação
async execute(dto: PayCreditCardBillDto, userId: string) {
  // 3.1. Autorização
  await this.authService.canUserAccessBudget(userId, dto.budgetId);
  
  // 3.2. Buscar entidades
  const bill = await this.getBillRepository.execute(dto.billId);
  const account = await this.getAccountRepository.execute(dto.accountId);
  
  // 3.3. Domain Service aplica regras de negócio
  const operation = this.domainService.createPaymentOperation(
    bill, account, dto.amount, dto.paymentCategoryId
  );
  
  // 3.4. Persistir mudanças
  await this.addTransactionRepository.execute(operation.debitTransaction);
  await this.saveBillRepository.execute(bill);
}
```

## Consultas (Queries)

### Fluxo Simplificado
```
[HTTP Request] → [Controller] → [Query Handler] → [DAO] → [Database]
                           ↓
                    [HTTP Response]
```

### Detalhamento das Etapas

#### 1. HTTP Request
- Requisição de consulta (geralmente GET)
- Parâmetros de filtros, paginação, ordenação

#### 2. Controller
- Adapta parâmetros HTTP para Query DTOs
- Chama Query Handler apropriado

#### 3. Query Handler
- **Consulta o banco** através dos DAOs apropriados
- **Aplica transformações** específicas para a view
- **Não aplica regras de negócio** - apenas busca e formata dados

#### 4. DAO (Data Access Object)
- **SQL nativo otimizado** para performance
- **JOINs eficientes** quando necessário
- **Retorna DTOs** específicos para views (não entidades de domínio)

#### 5. Database
- PostgreSQL executa queries otimizadas
- Índices garantem performance

#### 6. Response
- Dados formatados retornam ao cliente
- Paginação e metadados incluídos quando apropriado

### Exemplo: Consulta de Resumo do Orçamento

```typescript
// 1. Request
GET /budget/123/summary?month=2024-03

// 2. Controller → Query Handler  
const result = await this.getBudgetSummaryQueryHandler.handle({
  budgetId: '123',
  month: '2024-03'
});

// 3. Query Handler → DAO
async handle(query: GetBudgetSummaryQuery) {
  return await this.budgetSummaryDao.getBudgetSummary(
    query.budgetId, 
    query.month
  );
}

// 4. DAO executa SQL nativo
async getBudgetSummary(budgetId: string, month: string) {
  const result = await this.client.query(`
    SELECT 
      b.name as budget_name,
      COUNT(DISTINCT a.id) as account_count,
      SUM(a.balance) as total_balance,
      COUNT(DISTINCT t.id) as transaction_count,
      SUM(CASE WHEN t.type = 'INCOME' THEN t.amount ELSE 0 END) as total_income,
      SUM(CASE WHEN t.type = 'EXPENSE' THEN t.amount ELSE 0 END) as total_expenses
    FROM budgets b
    LEFT JOIN accounts a ON b.id = a.budget_id
    LEFT JOIN transactions t ON a.id = t.account_id 
      AND t.transaction_date >= $2::date 
      AND t.transaction_date < ($2::date + INTERVAL '1 month')
    WHERE b.id = $1
    GROUP BY b.id, b.name
  `, [budgetId, month]);
  
  return this.mapToBudgetSummaryDto(result.rows[0]);
}
```

## Diferenças Fundamentais

### Commands vs Queries

| Aspecto | Commands (Mutations) | Queries (Consultas) |
|---------|---------------------|-------------------|
| **Propósito** | Alterar estado do sistema | Buscar informações |
| **Complexidade** | Alta (regras de negócio) | Baixa (transformação) |
| **Entidades** | Carrega entidades completas | DTOs específicos |
| **Transações** | Sempre (atomicidade) | Raramente |
| **Validações** | Regras de negócio complexas | Apenas formato/existência |
| **Performance** | Consistência > Performance | Performance > Consistência |
| **SQL** | Via repositories/ORM | SQL nativo otimizado |

## Autorização

### Em Commands
```typescript
async execute(dto: CreateTransactionDto, userId: string) {
  // Validação obrigatória em toda mutação
  const canAccess = await this.authService.canUserAccessBudget(
    userId, 
    dto.budgetId
  );
  if (!canAccess) throw new UnauthorizedError();
  
  // Prosseguir com a operação...
}
```

### Em Queries
```typescript
async handle(query: GetBudgetSummaryQuery, userId: string) {
  // Validação também aplicada em consultas sensíveis
  const canAccess = await this.authService.canUserAccessBudget(
    userId, 
    query.budgetId
  );
  if (!canAccess) throw new UnauthorizedError();
  
  // Buscar dados...
}
```

## Tratamento de Erros

### Pattern Either
Tanto Commands quanto Queries utilizam o pattern Either para tratamento consistente:

```typescript
// Use Case retorna Either
async execute(dto: CreateTransactionDto): Promise<Either<ApplicationError, void>> {
  const result = await this.repository.execute(transaction);
  if (result.hasError) {
    return Either.error(new ApplicationError(result.errors));
  }
  return Either.success(undefined);
}

// Controller trata Either
const result = await this.useCase.execute(dto);
if (result.hasError) {
  return res.status(400).json(result.errors);
}
res.status(201).json(result.data);
```

---

**Ver também:**
- [Repository Pattern](./repository-pattern.md) - Detalhes sobre persistência em Commands
- [Query Strategy](./query-strategy.md) - SQL nativo e otimizações para Queries  
- [Unit of Work](./unit-of-work.md) - Transações em operações complexas