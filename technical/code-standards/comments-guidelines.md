# Comments Guidelines - Diretrizes para Comentários

## 🚫 Quando NÃO Comentar (Regra Geral)

**IMPORTANTE**: **NÃO adicionar comentários** a menos que explicitamente solicitado.

### Comentários Óbvios (EVITAR)

```typescript
// ❌ Evitar comentários óbvios
export class TransactionService {
  // Creates a new transaction - DESNECESSÁRIO
  public createTransaction(dto: CreateTransactionDto) {}

  // Gets transaction by ID - DESNECESSÁRIO
  public getById(id: string) {}

  // Deletes a transaction - DESNECESSÁRIO
  public delete(id: string) {}
}

// ✅ Código auto-explicativo (SEM comentários)
export class TransactionService {
  public createTransaction(dto: CreateTransactionDto) {}
  public getById(id: string) {}
  public delete(id: string) {}
}
```

### Comentários Redundantes (EVITAR)

```typescript
// ❌ Comentário que repete o código
export class BudgetCalculator {
  // Calculate the total amount
  calculateTotal(transactions: Transaction[]): Money {
    return transactions.reduce((sum, t) => sum.add(t.amount), Money.zero());
  }

  // Check if budget is valid
  isValid(budget: Budget): boolean {
    return budget.amount.isPositive() && budget.name.length > 0;
  }
}

// ✅ Código claro sem comentários
export class BudgetCalculator {
  calculateTotal(transactions: Transaction[]): Money {
    return transactions.reduce((sum, t) => sum.add(t.amount), Money.zero());
  }

  isValid(budget: Budget): boolean {
    return budget.amount.isPositive() && budget.name.length > 0;
  }
}
```

## ✅ Quando Comentar (Exceções)

Apenas quando **explicitamente solicitado** ou para casos específicos:

### 1. Regras de Negócio Complexas

```typescript
// ✅ Regras de negócio não óbvias (quando solicitado)
export class Transaction {
  public markAsLate(): Either<DomainError, void> {
    // Business rule: only pending transactions older than 5 days can be marked late
    if (this.status !== "pending" || this.daysSinceCreation() < 5) {
      return Either.left(new InvalidTransactionStateError());
    }

    this.status = "late";
    return Either.right(void 0);
  }

  public calculateInterest(): Money {
    // Financial rule: compound interest applied daily after due date
    // Formula: P * (1 + r)^t where r=0.001 (0.1% daily)
    const daysPastDue = this.daysPastDueDate();
    return this.principal.multiply(Math.pow(1.001, daysPastDue));
  }
}
```

### 2. Algoritmos Não Óbvios

```typescript
// ✅ Algoritmos complexos (quando solicitado)
private calculateCompoundInterest(principal: number, rate: number, time: number): number {
  // Formula: A = P(1 + r)^t
  // A = final amount, P = principal, r = annual interest rate, t = time in years
  return principal * Math.pow(1 + rate, time);
}

// ✅ Lógica matemática específica (quando solicitado)
private calculateProRatedAmount(amount: Money, startDate: Date, endDate: Date): Money {
  // Pro-rate calculation: amount * (actual_days / total_month_days)
  const totalDays = this.getDaysInMonth(startDate);
  const actualDays = this.getDaysBetween(startDate, endDate);
  return amount.multiply(actualDays / totalDays);
}
```

### 3. Workarounds Temporários

```typescript
// ✅ Workarounds que precisam ser explicados (quando solicitado)
export class PaymentProcessor {
  async processPayment(payment: Payment): Promise<Either<Error, void>> {
    // WORKAROUND: External API returns 200 with error in body
    // TODO: Remove when API v2 is available (expected Q2 2025)
    const response = await this.paymentGateway.charge(payment);
    if (response.status === 200 && response.body.error) {
      return Either.left(new PaymentError(response.body.error));
    }

    return Either.right(void 0);
  }
}
```

### 4. Configurações Específicas

```typescript
// ✅ Configurações que precisam de contexto (quando solicitado)
export class DatabaseConfig {
  // Connection pool sized for expected concurrent users (500-1000)
  // Based on load testing results from 2024-12-15
  readonly maxConnections = 50;

  // Timeout set to prevent hanging queries during peak hours
  readonly queryTimeout = 30_000; // 30 seconds
}
```

### Enums e Types Complexos

```typescript
/**
 * Transaction status representing the lifecycle state
 *
 * @enum TransactionStatus
 */
export enum TransactionStatus {
  /** Initial state after creation */
  PENDING = "pending",
  /** Successfully processed */
  COMPLETED = "completed",
  /** Processing failed */
  FAILED = "failed",
  /** Cancelled by user before processing */
  CANCELLED = "cancelled",
  /** Past due date without payment */
  LATE = "late",
}
```

## 🚨 Anti-Padrões de Comentários

### 1. Comentários Desatualizados

```typescript
// ❌ NUNCA deixar comentários desatualizados
export class TransactionService {
  // This method validates AND saves the transaction  ← MENTIRA!
  public validateTransaction(dto: CreateTransactionDto): Either<Error, void> {
    // Só faz validação, não salva!
    return this.validator.validate(dto);
  }
}
```

### 2. Comentários de Debug

```typescript
// ❌ NUNCA deixar comentários de debug
export class PaymentProcessor {
  async processPayment(payment: Payment): Promise<void> {
    // console.log('Processing payment:', payment);  ← REMOVER
    // debugger;  ← REMOVER

    await this.gateway.charge(payment);
  }
}
```

### 3. Código Comentado

```typescript
// ❌ NUNCA deixar código comentado
export class TransactionCalculator {
  calculateTotal(transactions: Transaction[]): Money {
    return transactions.reduce((sum, t) => sum.add(t.amount), Money.zero());

    // const total = 0;  ← DELETAR
    // for (const transaction of transactions) {  ← DELETAR
    //   total += transaction.amount.cents;  ← DELETAR
    // }  ← DELETAR
    // return Money.fromCents(total);  ← DELETAR
  }
}
```

### 4. Comentários Autorais

```typescript
// ❌ NUNCA adicionar comentários autorais
export class BudgetService {
  // Created by João Silva - 2024-12-15  ← REMOVER
  // Modified by Maria Santos - 2024-12-20  ← REMOVER
  public createBudget(dto: CreateBudgetDto): Either<Error, Budget> {
    // implementation
  }
}
```

## ✨ Código Auto-Explicativo

### Nomes Descritivos

```typescript
// ✅ Nomes que eliminam necessidade de comentários
export class TransactionValidator {
  public validateAmountIsPositive(
    amount: Money
  ): Either<ValidationError, void> {
    // Nome do método já explica o que faz
  }

  public ensureUserCanAccessBudget(
    userId: string,
    budgetId: string
  ): Either<AuthorizationError, void> {
    // Intenção clara pelo nome
  }

  private checkIfTransactionExceedsBudgetLimit(
    transaction: Transaction,
    budget: Budget
  ): boolean {
    // Lógica evidente pelo nome do método
  }
}
```

### Extrair Métodos para Clareza

```typescript
// ✅ Extrair lógica complexa em métodos bem nomeados
export class BudgetCalculator {
  public calculateRemainingAmount(budget: Budget): Money {
    const totalSpent = this.calculateTotalSpentAmount(budget);
    const totalAllocated = this.calculateTotalAllocatedAmount(budget);
    return totalAllocated.subtract(totalSpent);
  }

  private calculateTotalSpentAmount(budget: Budget): Money {
    // Método específico elimina necessidade de comentário
  }

  private calculateTotalAllocatedAmount(budget: Budget): Money {
    // Método específico elimina necessidade de comentário
  }
}
```

---

**Regra de ouro:** Se você precisa de um comentário para explicar o que o código faz, provavelmente o código pode ser melhorado para ser auto-explicativo.

**Próximos tópicos:**

- **[Angular Modern Patterns](./angular-modern-patterns.md)** - Padrões Angular modernos
- **[Testing Standards](./testing-standards.md)** - Padrões de testes
