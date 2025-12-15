# Modelo de Domínio - Agregados OrçaSonhos

## Visão Geral

O OrçaSonhos é modelado com agregados independentes, todos conectados por referências de identidade ao **Budget**, que funciona como o container principal e unidade de multi-tenancy.

## Agregados Principais

### Budget (Orçamento)
**Responsabilidade**: Container principal, gerenciar participantes e permissões

**Características**:
- Lista de participantes (User IDs)
- Configurações gerais do orçamento
- Raiz de todos os outros agregados

**Relacionamentos**: 
- Raiz - todos os outros agregados referenciam `budgetId`

**Invariantes**:
- Participantes devem ter IDs válidos  
- Operações só podem ser realizadas por participantes autorizados

---

### Account (Contas Financeiras)
**Responsabilidade**: Representar onde o dinheiro está fisicamente armazenado

**Características**:
- Saldo calculado com base nas transactions
- Tipos variados (corrente, poupança, carteira, investimento)
- Suporte a diferentes moedas via Value Object Money

**Relacionamentos**: 
- `budgetId` (referência ao Budget)
- Referenciado por `Transaction` via `accountId`
- Referenciado por `Goal` via `sourceAccountId`

**Invariantes**:
- Saldo deve sempre bater com soma das Transactions
- Nome único dentro do Budget
- Balance nunca deve ficar inconsistente

---

### Transaction (Transação Financeira)  
**Responsabilidade**: Registrar movimentações financeiras

**Características**:
- Valor, data, categoria, descrição
- Status temporal (agendada/realizada/atrasada/cancelada)
- Tipos: INCOME, EXPENSE, TRANSFER
- Suporte a transações recorrentes

**Relacionamentos**:
- `budgetId` (referência ao Budget)
- `accountId` (referência à Account)
- `categoryId` (referência à Category)
- Opcionalmente `creditCardId` para compras no cartão

**Invariantes**:
- Sempre deve ter Account de destino válida
- Valor deve ser > 0
- Status deve ser consistente com data da transação
- Data não pode estar muito no futuro (limite configurável)

---

### Category (Categorias)
**Responsabilidade**: Classificação de transações e base para envelopes

**Características**:
- Nome e descrição
- Tipo (necessidade/estilo de vida/prioridade financeira)
- Cor para identificação visual
- Ativa/inativa para controle de uso

**Relacionamentos**:
- `budgetId` (referência ao Budget)
- Referenciado por `Transaction` via `categoryId`
- Referenciado por `Envelope` via `categoryId`

**Invariantes**:
- Nome único dentro do Budget
- Tipo deve ser um dos valores válidos do enum

---

### CreditCard (Cartão de Crédito)
**Responsabilidade**: Master data do cartão (limite, datas de fechamento)

**Características**:
- Nome/descrição do cartão
- Limite total disponível
- Data de fechamento da fatura
- Data de vencimento
- Status ativo/inativo

**Relacionamentos**:
- `budgetId` (referência ao Budget)  
- Referenciado por `CreditCardBill` via `creditCardId`
- Referenciado por `Transaction` via `creditCardId`

**Invariantes**:
- Limite deve ser > 0
- Data de vencimento deve ser após data de fechamento
- Nome único dentro do Budget

---

### CreditCardBill (Fatura do Cartão)
**Responsabilidade**: Representar fatura específica de um período

**Características**:
- Valor total da fatura
- Data de fechamento e vencimento específicas
- Status (OPEN/CLOSED/PAID/OVERDUE)
- Período de referência (mês/ano)

**Relacionamentos**:
- `budgetId` (referência ao Budget)
- `creditCardId` (referência ao CreditCard)

**Invariantes**:
- Valor deve sempre bater com Transactions do cartão no período
- Status deve progredir logicamente (OPEN → CLOSED → PAID)
- Não pode ter duas faturas abertas para o mesmo cartão

---

### Envelope (Envelope de Gastos)
**Responsabilidade**: Controlar limite de gastos por categoria

**Características**:
- Limite de gastos mensais/anuais (armazenado)
- Status ativo/inativo
- Meta de economia para a categoria (opcional)
- **Uso atual calculado**: Soma das transações de despesa da categoria no período

**Relacionamentos**:
- `budgetId` (referência ao Budget)
- `categoryId` (referência à Category) - relacionamento 1:1

**Cálculo de Uso**:
- O uso do envelope **não é armazenado**, mas **calculado** a partir das transações
- Fórmula: `currentUsage = SUM(transações de despesa WHERE categoryId = envelope.categoryId AND status = 'completed' AND data no período)`
- Percentual de uso: `(currentUsage / limitInCents) × 100`

**Invariantes**:
- Deve estar vinculado a uma Category válida
- Limite de gastos deve ser >= 0
- Uso calculado pode exceder o limite (indica estouro do orçamento)

**Operações Válidas**:
- **Ajustar limite**: Editar `limitInCents` do envelope (aumentar ou diminuir)
- **Reclassificar transações**: Mudar `categoryId` de transações existentes (afeta uso calculado de ambos envelopes)
- **Desativar/ativar**: Controlar se o envelope está ativo para o período

**Operações que NÃO fazem sentido**:
- ❌ **Transferência entre envelopes**: Como o uso é calculado (não armazenado), não há "saldo" para transferir
  - **Alternativa**: Ajustar limites de ambos envelopes ou reclassificar transações

---

### Goal (Meta Financeira)
**Responsabilidade**: Controlar progresso de objetivos financeiros com reserva física

**Características**:
- Valor alvo (targetAmount)
- Valor atual reservado (currentAmount)  
- Data limite para atingir a meta
- Descrição e tipo da meta

**Relacionamentos**:
- `budgetId` (referência ao Budget)
- `sourceAccountId` (referência à Account onde está fisicamente o dinheiro)

**Invariantes**:
- `currentAmount <= targetAmount`
- Account(sourceAccountId) deve ter saldo disponível >= currentAmount
- Progresso deve ser rastreável via operações de aporte
- Data limite deve ser no futuro

## Modelo de Reservas (Goal ↔ Account)

### Conceito de Reserva 1:1
Goals implementam um modelo de **"reserva 1:1"**:
- Cada Goal aponta para uma única Account (`sourceAccountId`)
- O `currentAmount` da Goal representa quantia reservada daquela Account
- Account calcula: **Saldo Total** vs **Saldo Disponível** (descontando reservas)

### Cálculos de Saldo
```typescript
class Account {
  balance: Money;                    // Saldo total
  
  getAvailableBalance(): Money {     // Saldo disponível
    return balance.subtract(getTotalReservedForGoals());
  }
  
  private getTotalReservedForGoals(): Money {
    // Soma de currentAmount de todos os Goals que apontam para esta Account
  }
}
```

### Operações de Goals
- **`AddAmountToGoalUseCase`**: Adiciona valor à meta (aumenta currentAmount)
- **`RemoveAmountFromGoalUseCase`**: Remove valor da meta (diminui currentAmount)
- **`TransferGoalToAccountUseCase`**: Move Goal para outra Account

### Operações de Deleção e Transferência
**Ao deletar um Account:**
- Goal vinculado será deletado automaticamente, OU
- Goal deve ser transferido para outra Account antes da deleção

**Transferência de Goal:**
```typescript
// Use Case: TransferGoalToAccountUseCase
// Move Goal de uma Account para outra
// Atualiza sourceAccountId e recalcula saldos disponíveis
```

## Separação de Responsabilidades

| Agregado | Responsabilidade Principal |
|----------|---------------------------|
| **Budget** | Controle de acesso e participação |
| **Account** | Armazenamento físico do dinheiro |
| **Goal** | Reserva e rastreamento de objetivos |
| **Transaction** | Movimentação e fluxo financeiro |
| **CreditCard/CreditCardBill** | Gestão de crédito e faturas |
| **Envelope** | Controle de gastos por categoria |
| **Category** | Classificação e organização |

## Relacionamentos e Consistência

### Relacionamentos por Referência
Todos os agregados mantêm consistência eventual através de referências de ID:
- **Budget** ↔ todos os outros (1:N)
- **Account** ↔ **Transaction** (1:N) 
- **Account** ↔ **Goal** (1:N)
- **Category** ↔ **Transaction** (1:N)
- **Category** ↔ **Envelope** (1:1)
- **CreditCard** ↔ **CreditCardBill** (1:N)

### Invariantes Cross-Aggregate
Algumas regras de consistência cruzam agregados:
- **Account.balance** = SUM(Transactions daquela Account)
- **CreditCardBill.totalAmount** = SUM(Transactions do cartão no período)
- **Account.availableBalance** = balance - SUM(Goals.currentAmount)
- **Envelope.currentUsage** = SUM(Transactions de despesa WHERE categoryId = envelope.categoryId AND status = 'completed' AND data no período)

## Exemplo Conceitual

```typescript
// Budget como container
class Budget {
  participants: string[];  // User IDs autorizados
  settings: BudgetSettings;
}

// Account com reservas para Goals
class Account {
  balance: Money;                    // Total físico
  
  getAvailableBalance(): Money {     // Disponível após reservas
    return balance.subtract(getTotalReservedForGoals());
  }
}

// Goal reservando dinheiro de uma Account
class Goal {
  targetAmount: Money;    // Meta a atingir
  currentAmount: Money;   // Valor já reservado
  sourceAccountId: string; // Conta onde está fisicamente
}

// Transaction movimentando Account
class Transaction {
  amount: Money;
  type: TransactionTypeEnum; // INCOME, EXPENSE, TRANSFER
  accountId: string;         // Sempre presente
  categoryId: string;        // Categoria da transação
  
  // Afeta Account.balance
}

// Envelope controlando gastos por categoria
class Envelope {
  categoryId: string;         // Categoria vinculada (1:1)
  limitInCents: number;       // Limite de gastos no período
  
  getCurrentUsage(transactions: Transaction[], period: DatePeriod): number {
    // Calcula uso a partir das transações de despesa da categoria
    return transactions
      .filter(t => t.categoryId === this.categoryId)
      .filter(t => t.type === TransactionTypeEnum.EXPENSE)
      .filter(t => t.status === TransactionStatusEnum.COMPLETED)
      .filter(t => period.contains(t.date))
      .reduce((sum, t) => sum + t.amount.value, 0);
  }
  
  getUsagePercentage(transactions: Transaction[], period: DatePeriod): number {
    return (this.getCurrentUsage(transactions, period) / this.limitInCents) * 100;
  }
}
```

---

**Ver também:**
- [Domain Services](./domain-services.md) - Coordenação entre agregados
- [Repository Pattern](./repository-pattern.md) - Persistência dos agregados
- [Authorization](./authorization.md) - Controle de acesso via Budget