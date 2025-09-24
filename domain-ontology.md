# 🧠 Domain Ontology - Orça Sonhos

## 📋 Metadados da Ontologia

```yaml
ontology:
  name: "OrçaSonhos Domain Model"
  version: "1.0.0"
  description: "Ontologia formal do domínio financeiro pessoal e familiar"
  language: "pt-BR"
  created: "2025-01-24"
  tags: ["domain", "ontology", "financial", "budgeting", "goals"]
  ai_optimization: true
  rag_ready: true
```

---

## 🏗️ Taxonomia Hierárquica

### 1. **Contexto Financeiro (Financial Context)**
```
FinancialContext
├── PersonalFinance (Finanças Pessoais)
├── FamilyFinance (Finanças Familiares)
├── BusinessFinance (Finanças Empresariais)
└── SharedFinance (Finanças Compartilhadas)
```

### 2. **Agregados de Domínio (Domain Aggregates)**
```
DomainAggregates
├── Budget (Orçamento)
│   ├── PersonalBudget
│   ├── SharedBudget
│   └── FamilyBudget
├── Transaction (Transação)
│   ├── Income (Receita)
│   ├── Expense (Despesa)
│   └── Transfer (Transferência)
├── Goal (Meta)
│   ├── SavingGoal
│   ├── PurchaseGoal
│   └── DebtPayoffGoal
├── Account (Conta)
│   ├── BankAccount
│   ├── CreditCard
│   ├── DigitalWallet
│   └── CashWallet
└── Category (Categoria)
    ├── IncomeCategory
    ├── ExpenseCategory
    └── TransferCategory
```

### 3. **Value Objects (Objetos de Valor)**
```
ValueObjects
├── Money (Dinheiro)
├── Percentage (Porcentagem)
├── Date (Data)
├── Period (Período)
├── Status (Status)
├── Priority (Prioridade)
└── Color (Cor)
```

### 4. **Estados Temporais (Temporal States)**
```
TemporalStates
├── TransactionState
│   ├── Scheduled (Agendada)
│   ├── Completed (Realizada)
│   ├── Overdue (Atrasada)
│   └── Cancelled (Cancelada)
├── GoalState
│   ├── Active (Ativa)
│   ├── Completed (Concluída)
│   ├── Paused (Pausada)
│   └── Cancelled (Cancelada)
└── BudgetState
    ├── Active (Ativo)
    ├── Inactive (Inativo)
    └── Archived (Arquivado)
```

---

## 🔗 Relações Semânticas

### Relações de Composição
- `Budget` **CONTAINS** `Transaction[]`
- `Budget` **CONTAINS** `Goal[]`
- `Budget` **CONTAINS** `Category[]`
- `Budget` **CONTAINS** `Envelope[]`
- `Goal` **HAS** `TargetAmount: Money`
- `Transaction` **BELONGS_TO** `Category`

### Relações de Associação
- `User` **MANAGES** `Budget[]`
- `Budget` **IS_SHARED_WITH** `User[]`
- `Transaction` **IMPACTS** `Account`
- `Goal` **TRACKS_PROGRESS_THROUGH** `Transaction[]`
- `CreditCard` **GENERATES** `Bill[]`

### Relações Temporais
- `Transaction` **OCCURS_ON** `Date`
- `Goal` **HAS_TARGET_DATE** `Date`
- `Bill` **DUE_ON** `Date`
- `Budget` **VALID_FOR** `Period`

---

## 📊 Schemas Estruturados

### Budget Entity Schema
```yaml
Budget:
  type: "aggregate"
  properties:
    id: { type: "string", format: "uuid" }
    name: { type: "string", maxLength: 100 }
    description: { type: "string", maxLength: 500 }
    type: { enum: ["personal", "shared", "family", "business"] }
    ownerId: { type: "string", format: "uuid" }
    participants:
      type: "array"
      items: { type: "string", format: "uuid" }
    createdAt: { type: "string", format: "date-time" }
    updatedAt: { type: "string", format: "date-time" }
    isActive: { type: "boolean" }
  relationships:
    - has_many: "Transaction"
    - has_many: "Goal"
    - has_many: "Category"
    - belongs_to: "User" (owner)
    - belongs_to_many: "User" (participants)
  business_rules:
    - "Budget must have at least one participant"
    - "Personal budgets can have only one participant"
    - "Shared budgets can have multiple participants"
```

### Transaction Entity Schema
```yaml
Transaction:
  type: "aggregate"
  properties:
    id: { type: "string", format: "uuid" }
    budgetId: { type: "string", format: "uuid" }
    categoryId: { type: "string", format: "uuid" }
    accountId: { type: "string", format: "uuid" }
    amount: { type: "integer", description: "Value in cents" }
    description: { type: "string", maxLength: 200 }
    date: { type: "string", format: "date" }
    type: { enum: ["income", "expense", "transfer"] }
    status: { enum: ["scheduled", "completed", "overdue", "cancelled"] }
    paymentMethod: { type: "string" }
    isRecurring: { type: "boolean" }
    createdAt: { type: "string", format: "date-time" }
  relationships:
    - belongs_to: "Budget"
    - belongs_to: "Category"
    - belongs_to: "Account"
    - created_by: "User"
  business_rules:
    - "Amount must be positive"
    - "Date can be past, present, or future"
    - "Scheduled transactions don't impact current balance"
    - "Completed transactions impact account balance immediately"
```

### Goal Entity Schema
```yaml
Goal:
  type: "aggregate"
  properties:
    id: { type: "string", format: "uuid" }
    budgetId: { type: "string", format: "uuid" }
    name: { type: "string", maxLength: 100 }
    description: { type: "string", maxLength: 500 }
    targetAmount: { type: "integer", description: "Value in cents" }
    currentAmount: { type: "integer", description: "Value in cents" }
    targetDate: { type: "string", format: "date" }
    priority: { enum: ["low", "medium", "high", "critical"] }
    category: { enum: ["home", "travel", "education", "emergency", "vehicle", "other"] }
    status: { enum: ["active", "completed", "paused", "cancelled"] }
    isSmartGoal: { type: "boolean" }
    createdAt: { type: "string", format: "date-time" }
  relationships:
    - belongs_to: "Budget"
    - tracks_through: "Transaction[]"
  business_rules:
    - "Target amount must be positive"
    - "Target date must be in the future for active goals"
    - "Current amount cannot exceed target amount"
    - "SMART goals must have specific, measurable criteria"
```

---

## 🏷️ Sistema de Tags Semânticas

### Tags por Contexto
```yaml
context_tags:
  financial_planning: ["budget", "goal", "planning", "forecast"]
  transaction_management: ["income", "expense", "transfer", "payment"]
  collaboration: ["shared", "family", "participants", "permissions"]
  temporal: ["scheduled", "recurring", "overdue", "historical"]
  analytics: ["reports", "charts", "insights", "trends"]
```

### Tags por Complexidade
```yaml
complexity_tags:
  beginner: ["basic_budget", "simple_transaction", "first_goal"]
  intermediate: ["shared_budget", "multiple_goals", "categories"]
  advanced: ["complex_planning", "cash_flow", "optimization"]
```

### Tags por Persona
```yaml
persona_tags:
  ana_familiar: ["family_budget", "shared_goals", "household_management"]
  carlos_young: ["personal_budget", "learning", "first_planning"]
  roberto_maria: ["multiple_goals", "long_term_planning", "advanced_features"]
  julia_entrepreneur: ["business_finance", "variable_income", "flexibility"]
```

---

## 🔍 Índices Semânticos para IA/RAG

### Conceitos Centrais
```yaml
core_concepts:
  primary:
    - id: "budget"
      synonyms: ["orçamento", "budget", "financial_plan"]
      definition: "Container virtual que agrupa transações, metas e categorias com propósito comum"
      related: ["transaction", "goal", "category", "envelope"]

    - id: "transaction"
      synonyms: ["transação", "lançamento", "movement"]
      definition: "Registro de entrada ou saída de dinheiro com data, valor e categoria"
      related: ["budget", "category", "account", "money"]

    - id: "goal"
      synonyms: ["meta", "objetivo", "target"]
      definition: "Objetivo financeiro com valor-alvo e prazo definido seguindo metodologia SMART"
      related: ["budget", "money", "planning", "timeline"]

    - id: "account"
      synonyms: ["conta", "account", "wallet"]
      definition: "Local físico onde o dinheiro está armazenado"
      related: ["balance", "transaction", "bank", "credit_card"]
```

### Padrões de Consulta
```yaml
query_patterns:
  create_operations:
    - "como criar [budget|meta|transação]"
    - "novo [orçamento|objetivo|lançamento]"
    - "adicionar [receita|despesa|categoria]"

  management_operations:
    - "compartilhar orçamento"
    - "gerenciar [metas|categorias|contas]"
    - "controlar gastos"

  analysis_operations:
    - "relatório de [gastos|metas|categorias]"
    - "análise financeira"
    - "progresso das metas"
```

---

## 🎯 Mapeamento para Casos de Uso

### UC001: Gestão Familiar
```yaml
use_case: "family_management"
entities: ["SharedBudget", "User", "Transaction", "Goal"]
concepts: ["collaboration", "shared_access", "family_planning"]
flow: "create_budget → add_participants → set_goals → track_expenses"
```

### UC002: Planejamento Individual
```yaml
use_case: "personal_planning"
entities: ["PersonalBudget", "Goal", "Transaction", "Category"]
concepts: ["individual_control", "goal_tracking", "expense_management"]
flow: "create_personal_budget → define_goals → categorize_expenses → monitor_progress"
```

### UC003: Transações Futuras
```yaml
use_case: "future_planning"
entities: ["ScheduledTransaction", "Budget", "CashFlow"]
concepts: ["temporal_planning", "forecasting", "scheduled_payments"]
flow: "schedule_transaction → project_cash_flow → adjust_planning"
```

---

## 🔧 Configurações para IA/RAG

### Embedding Optimization
```yaml
embedding_config:
  chunk_size: 512
  overlap: 50
  preferred_fields: ["definition", "business_rules", "relationships"]
  weight_boost:
    - "core_concepts": 1.5
    - "business_rules": 1.3
    - "relationships": 1.2
```

### Search Enhancement
```yaml
search_config:
  synonyms_enabled: true
  fuzzy_matching: true
  semantic_similarity_threshold: 0.7
  context_window: 1024
  max_results: 10
```

---

## 📚 Referências Cruzadas

### Documentos Relacionados
- **[Core Concepts](./business/product-vision/core-concepts.md)** - Definições conceituais detalhadas
- **[Domain Model](./technical/backend-architecture/domain-model.md)** - Implementação técnica dos agregados
- **[Use Cases](./business/product-vision/use-cases.md)** - Casos de uso práticos
- **[Personas](./business/customer-profile/personas.md)** - Perfis de usuários e contextos

### ADRs Relacionados
- **[ADR-0004](./adr/0004-escolha-postgresql-como-banco-de-dados.md)** - Decisões de persistência
- **[ADR-0008](./adr/0008-padrao-endpoints-mutations-post-comando.md)** - Padrões de API
- **[ADR-0011](./adr/0011-postergacao-offline-first-mvp.md)** - Estratégia offline

---

## 🤖 Notas para IA

Esta ontologia serve como fonte de verdade para o domínio OrçaSonhos. Use as definições e relações aqui estabelecidas para:

1. **Responder perguntas** sobre conceitos de domínio
2. **Validar consistência** de implementações
3. **Sugerir melhorias** baseadas nas regras de negócio
4. **Gerar código** seguindo os padrões estabelecidos
5. **Explicar funcionalidades** usando a terminologia correta

### Prioridades de Contexto para RAG
1. Definições dos conceitos centrais (Budget, Transaction, Goal, Account)
2. Regras de negócio e invariantes
3. Relações entre entidades
4. Estados e transições válidas
5. Casos de uso e fluxos principais