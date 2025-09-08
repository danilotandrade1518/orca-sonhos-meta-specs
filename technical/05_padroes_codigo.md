# Padrões de Código - OrçaSonhos

## 1. Visão Geral

Este documento define os padrões de código, convenções de nomenclatura, estrutura e boas práticas para o desenvolvimento do projeto OrçaSonhos. O objetivo é garantir consistência, legibilidade e manutenibilidade em todo o codebase, tanto no frontend (Angular/TypeScript) quanto no backend (Node.js/Express/TypeScript).

## 2. Linguagem e Idioma

**OBRIGATÓRIO**: Todo o código deve ser escrito em **inglês**:
- Nomes de variáveis, funções, classes, interfaces, comentários, mensagens de commit
- Arquivos, pastas, documentação de código
- Logs e mensagens de erro técnicas

**Exceções**: Apenas conteúdo voltado ao usuário final (textos de UI, mensagens de validação, etc.) em português.

## 3. Convenções de Nomenclatura

### 3.1. Classes e Arquivos

#### Backend
```typescript
// Classes: PascalCase
export class CreateTransactionUseCase { }
export class TransactionRepository { }
export class BudgetAuthorizationService { }

// Arquivos: PascalCase
CreateTransactionUseCase.ts
TransactionRepository.ts
BudgetAuthorizationService.ts
TransferBetweenAccountsUnitOfWork.ts
```

#### Frontend
```typescript
// Classes: PascalCase
export class CreateTransactionUseCase { }
export class TransactionServiceAdapter { }

// Arquivos Angular: kebab-case
create-transaction.page.ts
transaction-list.component.ts
budget-overview.widget.ts

// Arquivos Models/Application: PascalCase
CreateTransactionUseCase.ts
TransactionServiceAdapter.ts
```

### 3.2. Métodos e Variáveis

```typescript
// Métodos e variáveis: camelCase
public createTransaction() { }
public findByAccountId() { }
private validateAmount() { }

const transactionAmount = Money.fromCents(1000);
const userAccountList = [];
```

### 3.3. Constantes

```typescript
// SCREAMING_SNAKE_CASE para constantes globais
const MAX_RETRY_ATTEMPTS = 3;
const DEFAULT_TIMEOUT_MS = 5000;
const API_BASE_URL = '/api';

// camelCase para constantes locais/contextuais
const defaultBudgetSettings = { /* */ };
```

### 3.4. Interfaces e Contratos

```typescript
// Interfaces: prefixo "I"
interface ITransactionRepository { }
interface IBudgetServicePort { }
interface IUnitOfWork { }

// Types: PascalCase sem prefixo
type TransactionStatus = 'pending' | 'completed' | 'cancelled';
type CreateTransactionDto = { /* */ };
```

### 3.5. Pastas e Estruturas

```bash
# Pastas: kebab-case
/use-cases
/aggregates
/value-objects
/unit-of-works
/ui-components

# Contextos de negócio: kebab-case
/credit-cards
/credit-card-bills
/budget-management
```

### 3.6. Componentes Angular

```typescript
// Seletores: prefixo "os-" (OrçaSonhos)
@Component({
  selector: 'os-transaction-form'
})

@Component({
  selector: 'os-button'  // Camada de abstração UI
})

// Classes de componentes: sufixo Component/Page/Widget
export class TransactionFormComponent { }
export class BudgetOverviewPage { }
export class AccountSummaryWidget { }
```

## 4. Estrutura de Classes e Métodos

### 4.1. Ordem de Declaração

**Todas as classes** devem seguir esta ordem:

1. **Propriedades públicas** (incluindo getters/setters)
2. **Propriedades privadas**
3. **Construtor**
4. **Métodos públicos**
5. **Métodos estáticos**
6. **Métodos privados**

```typescript
export class TransactionService {
  // 1. Propriedades públicas
  public readonly config: TransactionConfig;
  
  // 2. Propriedades privadas
  private readonly repository: ITransactionRepository;
  private readonly logger: ILogger;
  
  // 3. Construtor
  constructor(
    repository: ITransactionRepository,
    logger: ILogger
  ) {
    this.repository = repository;
    this.logger = logger;
  }
  
  // 4. Métodos públicos
  public async createTransaction(dto: CreateTransactionDto): Promise<Either<Error, Transaction>> {
    // implementação
  }
  
  public getTransactionById(id: string): Promise<Transaction | null> {
    // implementação
  }
  
  // 5. Métodos estáticos
  public static fromConfig(config: ServiceConfig): TransactionService {
    // implementação
  }
  
  // 6. Métodos privados
  private validateTransactionData(dto: CreateTransactionDto): boolean {
    // implementação
  }
  
  private logTransactionEvent(event: string): void {
    // implementação
  }
}
```

### 4.2. Padrões de Construção

#### Domain Entities
```typescript
export class Transaction {
  private constructor(
    public readonly id: TransactionId,
    public readonly amount: Money,
    public readonly budgetId: BudgetId,
    private status: TransactionStatus
  ) {}
  
  // Factory methods estáticos
  public static create(dto: CreateTransactionDto): Either<DomainError, Transaction> {
    // validações e construção
  }
  
  public static reconstruct(data: TransactionData): Transaction {
    // reconstrução a partir de dados persistidos
  }
  
  // Métodos de negócio
  public markAsLate(): Either<DomainError, void> {
    // lógica de domínio
  }
}
```

#### Use Cases
```typescript
export class CreateTransactionUseCase {
  constructor(
    private readonly authService: IBudgetAuthorizationService,
    private readonly repository: IAddTransactionRepository
  ) {}
  
  public async execute(
    dto: CreateTransactionDto, 
    userId: string
  ): Promise<Either<ApplicationError, TransactionId>> {
    // 1. Validação de autorização
    // 2. Validação de dados
    // 3. Criação da entidade
    // 4. Persistência
    // 5. Retorno
  }
}
```

## 5. Padrões de Import e Dependências

### 5.1. Path Aliases vs Imports Relativos

```typescript
// ✅ Path Alias: Entre camadas diferentes
import { Transaction } from '@domain/aggregates/transaction/Transaction';
import { ITransactionRepository } from '@application/contracts/ITransactionRepository';
import { HttpTransactionAdapter } from '@infra/adapters/HttpTransactionAdapter';

// ✅ Import Relativo: Dentro da mesma camada
import { Money } from '../value-objects/Money';
import { TransactionId } from './TransactionId';
import { TransactionStatus } from './TransactionStatus';
```

### 5.2. Organização de Imports

```typescript
// 1. Imports de bibliotecas externas
import { Component, inject, signal } from '@angular/core';
import { Either } from 'fp-ts/lib/Either';

// 2. Imports de camadas internas (por ordem: domain → application → infra)
import { Transaction } from '@domain/aggregates/transaction/Transaction';
import { CreateTransactionUseCase } from '@application/use-cases/CreateTransactionUseCase';
import { HttpTransactionAdapter } from '@infra/adapters/HttpTransactionAdapter';

// 3. Imports relativos da mesma camada
import { BaseComponent } from '../shared/BaseComponent';
import { TransactionFormData } from './types';
```

## 6. Tratamento de Erros

### 6.1. Padrão Either

**Obrigatório**: Usar padrão `Either<Error, Success>` evitando `throw/try/catch`:

```typescript
// ✅ Correto
export class CreateTransactionUseCase {
  async execute(dto: CreateTransactionDto): Promise<Either<ApplicationError, TransactionId>> {
    const validationResult = this.validateDto(dto);
    if (validationResult.isLeft()) {
      return Either.left(new ValidationError(validationResult.value));
    }
    
    const transaction = Transaction.create(validationResult.value);
    if (transaction.isLeft()) {
      return Either.left(new DomainError(transaction.value.message));
    }
    
    const saveResult = await this.repository.execute(transaction.value);
    return saveResult.map(() => transaction.value.id);
  }
}

// ❌ Evitar
export class BadCreateTransactionUseCase {
  async execute(dto: CreateTransactionDto): Promise<TransactionId> {
    if (!dto.amount) {
      throw new Error('Amount is required'); // Avoid throws
    }
    
    try {
      const transaction = new Transaction(dto); // Avoid direct constructor
      await this.repository.save(transaction);
      return transaction.id;
    } catch (error) {
      throw new ApplicationError('Failed to create transaction'); // Avoid throws
    }
  }
}
```

### 6.2. Hierarquia de Erros

```typescript
// Base errors
export abstract class DomainError extends Error {
  abstract readonly code: string;
}

export abstract class ApplicationError extends Error {
  abstract readonly code: string;
}

// Specific errors
export class ValidationError extends DomainError {
  readonly code = 'DOMAIN_VALIDATION_ERROR';
}

export class UnauthorizedError extends ApplicationError {
  readonly code = 'APPLICATION_UNAUTHORIZED';
}
```

## 7. Padrões Angular Específicos

### 7.1. Componentes Modernos

```typescript
// ✅ Padrões obrigatórios
@Component({
  selector: 'os-transaction-form',
  // standalone: true é padrão (não declarar)
  changeDetection: ChangeDetectionStrategy.OnPush, // Sempre OnPush
  imports: [CommonModule, ReactiveFormsModule], // Import explícito
  template: `
    @if (loading()) {
      <os-loading />
    } @else {
      <form [formGroup]="form" (ngSubmit)="onSubmit()">
        @for (field of formFields(); track field.id) {
          <os-form-field [field]="field" />
        }
      </form>
    }
  `
})
export class TransactionFormComponent {
  // ✅ Usar function-based APIs
  readonly loading = signal(false);
  readonly form = signal(this.createForm());
  readonly formFields = computed(() => this.generateFields());
  
  // ✅ Usar inject() ao invés de constructor injection
  private readonly useCase = inject(CreateTransactionUseCase);
  private readonly router = inject(Router);
  
  // ✅ input()/output() functions
  readonly transaction = input<Transaction>();
  readonly save = output<TransactionId>();
  
  onSubmit(): void {
    // implementação
  }
}
```

### 7.2. Control Flow e Bindings

```typescript
@Component({
  template: `
    <!-- ✅ Control flow nativo -->
    @if (user(); as currentUser) {
      <p>Olá, {{ currentUser.name }}</p>
    }
    
    @for (item of items(); track item.id) {
      <div [class.active]="item.selected">{{ item.name }}</div>
    } @empty {
      <p>Nenhum item encontrado</p>
    }
    
    @switch (status()) {
      @case ('loading') { <os-spinner /> }
      @case ('error') { <os-error-message /> }
      @default { <os-content /> }
    }
    
    <!-- ✅ Bindings diretos ao invés de ngClass/ngStyle -->
    <button 
      [class.btn-primary]="isPrimary()"
      [class.btn-disabled]="disabled()"
      [style.width.px]="buttonWidth()">
      Click me
    </button>
  `
})
```

### 7.3. Serviços e Dependency Injection

```typescript
@Injectable({ providedIn: 'root' })
export class TransactionService {
  // ✅ Usar inject() ao invés de constructor injection
  private readonly httpClient = inject(HttpClient);
  private readonly authService = inject(AuthService);
  
  // ✅ Métodos retornam Either
  createTransaction(dto: CreateTransactionDto): Promise<Either<ServiceError, Transaction>> {
    // implementação
  }
}
```

## 8. Comentários e Documentação

### 8.1. Quando NÃO Comentar

**IMPORTANTE**: **NÃO adicionar comentários** a menos que explicitamente solicitado.

```typescript
// ❌ Evitar comentários óbvios
export class TransactionService {
  // Creates a new transaction - DESNECESSÁRIO
  public createTransaction(dto: CreateTransactionDto) { }
  
  // Gets transaction by ID - DESNECESSÁRIO  
  public getById(id: string) { }
}

// ✅ Código auto-explicativo
export class TransactionService {
  public createTransaction(dto: CreateTransactionDto) { }
  public getById(id: string) { }
}
```

### 8.2. Quando Comentar (Exceções)

Apenas quando explicitamente solicitado ou para:

```typescript
// ✅ Regras de negócio complexas (quando solicitado)
export class Transaction {
  public markAsLate(): Either<DomainError, void> {
    // Business rule: only pending transactions older than 5 days can be marked late
    if (this.status !== 'pending' || this.daysSinceCreation() < 5) {
      return Either.left(new InvalidTransactionStateError());
    }
    // ... rest of implementation
  }
}

// ✅ Algoritmos não óbvios (quando solicitado)
private calculateCompoundInterest(principal: number, rate: number, time: number): number {
  // Formula: A = P(1 + r)^t
  return principal * Math.pow(1 + rate, time);
}
```

### 8.3. JSDoc (Quando Necessário)

```typescript
/**
 * Transfers amount between two accounts within the same budget
 * 
 * @param fromAccountId Source account
 * @param toAccountId Target account  
 * @param amount Amount in cents
 * @param budgetId Budget context for authorization
 * @returns Either error or void on success
 */
public async transferBetweenAccounts(
  fromAccountId: string,
  toAccountId: string, 
  amount: number,
  budgetId: string
): Promise<Either<ApplicationError, void>> {
  // implementation
}
```

## 9. Formatação e Estilo

### 9.1. Prettier e ESLint

**Obrigatório**: Usar Prettier + ESLint com configuração padrão do projeto.

### 9.2. Tamanho de Linha e Indentação

```typescript
// ✅ Max 100 caracteres por linha
const result = await this.transactionUseCase.execute(
  transactionDto,
  userId
);

// ✅ 2 espaços de indentação
if (condition) {
  doSomething();
  if (anotherCondition) {
    doAnotherThing();
  }
}
```

### 9.3. Quebras de Linha

```typescript
// ✅ Parâmetros em linha quando cabem
public createTransaction(dto: CreateTransactionDto, userId: string): Promise<Either<Error, Transaction>> {

// ✅ Quebrar quando não cabem
public transferBetweenAccounts(
  fromAccountId: string,
  toAccountId: string,
  amount: Money,
  budgetId: string,
  userId: string
): Promise<Either<ApplicationError, void>> {
```

## 10. Testes

### 10.1. Nomenclatura de Testes

```typescript
// ✅ Estrutura descritiva
describe('CreateTransactionUseCase', () => {
  describe('execute', () => {
    it('should create transaction with valid data', async () => {
      // Arrange, Act, Assert
    });
    
    it('should return validation error when amount is negative', async () => {
      // Test error cases
    });
    
    it('should return unauthorized error when user lacks permission', async () => {
      // Test authorization
    });
  });
});
```

### 10.2. Estrutura de Teste (AAA)

```typescript
it('should calculate transaction total correctly', async () => {
  // Arrange
  const baseAmount = Money.fromCents(1000);
  const fee = Money.fromCents(50);
  const transaction = TransactionFactory.create({
    amount: baseAmount,
    fee: fee
  });
  
  // Act
  const total = transaction.calculateTotal();
  
  // Assert
  expect(total.cents).toBe(1050);
});
```

## 11. Padrões de Arquitetura

### 11.1. Repository Pattern

```typescript
// ✅ Separação Add vs Save
interface IAddTransactionRepository {
  execute(transaction: Transaction): Promise<Either<RepositoryError, void>>;
}

interface ISaveTransactionRepository {
  execute(transaction: Transaction): Promise<Either<RepositoryError, void>>;
}

// ✅ Use Cases específicos com repositories genéricos
export class CreateTransactionUseCase {
  constructor(
    private readonly addRepository: IAddTransactionRepository
  ) {}
}

export class MarkTransactionLateUseCase {
  constructor(
    private readonly getRepository: IGetTransactionRepository,
    private readonly saveRepository: ISaveTransactionRepository
  ) {}
}
```

### 11.2. Unit of Work Pattern

```typescript
// ✅ Nomenclatura consistente
export class TransferBetweenAccountsUnitOfWork implements IUnitOfWork {
  async executeTransfer(params: TransferParams): Promise<Either<TransferError, void>> {
    // Transactional operations
  }
}

// ✅ Organização por contexto
/src/infrastructure/database/pg/unit-of-works/
├── transfer-between-accounts/
│   ├── TransferBetweenAccountsUnitOfWork.ts
│   └── TransferBetweenAccountsUnitOfWork.spec.ts
```

## 12. Padrões API e Endpoints

### 12.1. Estilo de Endpoints (Command-Style)

```typescript
// ✅ Mutações: POST orientado a comandos
POST /budget/create-budget
POST /transaction/mark-transaction-late  
POST /credit-card-bill/pay-credit-card-bill
POST /envelope/transfer-between-envelopes

// ✅ Controllers alinhados
@Controller('/transaction')
export class TransactionController {
  @Post('/create-transaction')
  async createTransaction(@Body() dto: CreateTransactionDto) {
    // implementation
  }
  
  @Post('/mark-transaction-late')
  async markTransactionLate(@Body() dto: MarkTransactionLateDto) {
    // implementation
  }
}
```

## 13. Validações e Constraints

### 13.1. Boundary Rules (ESLint)

```javascript
// eslint.config.js
module.exports = {
  rules: {
    'import/no-restricted-paths': [
      'error',
      {
        zones: [
          {
            target: './src/models',
            from: './src/application',
            message: 'Models layer cannot import from Application layer'
          },
          {
            target: './src/models', 
            from: './src/infra',
            message: 'Models layer cannot import from Infrastructure layer'
          },
          {
            target: './src/application',
            from: './src/app',
            message: 'Application layer cannot import from UI layer'
          }
        ]
      }
    ]
  }
};
```

### 13.2. TypeScript Strict Mode

```json
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "noImplicitReturns": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true
  }
}
```

## 14. Performance e Otimização

### 14.1. Angular Signals

```typescript
// ✅ Usar signals para estado reativo
export class TransactionListComponent {
  readonly transactions = signal<Transaction[]>([]);
  readonly filteredTransactions = computed(() => 
    this.transactions().filter(t => t.status === this.selectedStatus())
  );
  readonly selectedStatus = signal<TransactionStatus>('pending');
  
  // ✅ Effects para side effects
  constructor() {
    effect(() => {
      const status = this.selectedStatus();
      this.logFilterChange(status);
    });
  }
}
```

### 14.2. Lazy Loading e Tree Shaking

```typescript
// ✅ Lazy loading por feature
const routes: Routes = [
  {
    path: 'transactions',
    loadComponent: () => import('./features/transactions/transaction-list.page').then(m => m.TransactionListPage)
  },
  {
    path: 'budgets',
    loadChildren: () => import('./features/budgets/budget.routes').then(m => m.BUDGET_ROUTES)
  }
];

// ✅ Imports específicos
import { Either } from 'fp-ts/lib/Either';
import { pipe } from 'fp-ts/lib/function';
```

## 15. Segurança

### 15.1. Sanitização e Validação

```typescript
// ✅ Validação em Value Objects
export class Email {
  private constructor(private readonly value: string) {}
  
  public static create(value: string): Either<ValidationError, Email> {
    if (!this.isValidEmail(value)) {
      return Either.left(new ValidationError('Invalid email format'));
    }
    return Either.right(new Email(value.toLowerCase().trim()));
  }
  
  private static isValidEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }
}
```

### 15.2. Headers e Tokens

```typescript
// ✅ Headers seguros
export class FetchHttpClient {
  async request<T>(config: RequestConfig): Promise<T> {
    const headers = {
      'Content-Type': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
      ...config.headers
    };
    
    const token = await this.getAccessToken();
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }
    
    // request implementation
  }
}
```

## 16. Checklist de Code Review

### ✅ Estrutura e Organização
- [ ] Arquivos nomeados corretamente (PascalCase para classes, kebab-case para Angular)
- [ ] Imports organizados (externos → internos → relativos)
- [ ] Path aliases usados entre camadas, relativos dentro da camada
- [ ] Métodos organizados na ordem definida (público → estático → privado)

### ✅ Nomenclatura
- [ ] Todo código em inglês
- [ ] Classes em PascalCase
- [ ] Métodos e variáveis em camelCase
- [ ] Interfaces com prefixo "I"
- [ ] Constantes em SCREAMING_SNAKE_CASE
- [ ] Componentes Angular com prefixo "os-"

### ✅ Padrões Arquiteturais
- [ ] Either usado ao invés de throw/try/catch
- [ ] Repositories separados (Add/Save/Get/Find)
- [ ] Use Cases específicos para cada operação de negócio
- [ ] Unit of Work para operações transacionais
- [ ] Boundary rules respeitadas entre camadas

### ✅ Angular Específico
- [ ] ChangeDetectionStrategy.OnPush
- [ ] Signals usados para estado reativo
- [ ] Control flow nativo (@if, @for, @switch)
- [ ] inject() ao invés de constructor injection
- [ ] input()/output() functions

### ✅ Qualidade
- [ ] Sem comentários desnecessários
- [ ] Testes seguem padrão AAA (Arrange, Act, Assert)
- [ ] Validações em Value Objects
- [ ] Tratamento seguro de tokens e dados sensíveis
- [ ] ESLint e Prettier aplicados

---

**Este documento deve ser atualizado conforme novos padrões sejam adotados ou refinados durante o desenvolvimento do projeto.**