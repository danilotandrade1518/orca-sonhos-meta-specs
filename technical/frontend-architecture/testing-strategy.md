# Estratégia de Testes

## Filosofia de Testes

- **Test-Driven**: Testes guiam o design das camadas de Domain e Application
- **Behavior-Focused**: Testes verificam comportamento, não implementação
- **Fast Feedback**: Testes unitários rápidos, integração when necessary
- **Realistic Mocking**: MSW para mocks de API realistas

## Tipos de Teste por Camada

### 1. Models (Domain) - 100% Testável

**Características:**
- **Pure Functions**: Sem dependências externas
- **Determinísticos**: Mesma entrada = mesma saída
- **Fast**: Execução instantânea
- **Isolation**: Cada teste independente

```typescript
// models/entities/Transaction.spec.ts
describe('Transaction', () => {
  describe('when creating a transaction', () => {
    it('should create valid income transaction', () => {
      // Arrange
      const params = {
        description: 'Salary',
        amount: Money.fromReais(5000),
        accountId: 'account-123',
        type: TransactionType.INCOME,
        date: new Date('2024-01-15')
      };

      // Act  
      const result = Transaction.create(params);

      // Assert
      expect(result.hasError).toBe(false);
      
      const transaction = result.data!;
      expect(transaction.description).toBe('Salary');
      expect(transaction.amount.reais).toBe(5000);
      expect(transaction.type).toBe(TransactionType.INCOME);
    });

    it('should reject transaction with empty description', () => {
      // Arrange
      const params = {
        description: '',
        amount: Money.fromReais(100),
        accountId: 'account-123',
        type: TransactionType.EXPENSE,
        date: new Date()
      };

      // Act
      const result = Transaction.create(params);

      // Assert  
      expect(result.hasError).toBe(true);
      expect(result.errors[0]).toBeInstanceOf(ValidationError);
      expect(result.errors[0].message).toContain('description');
    });
  });

  describe('when calculating balance impact', () => {
    it('should return negative impact for expense', () => {
      // Test business logic
      const transaction = createExpenseTransaction(100);
      
      expect(transaction.getBalanceImpact().cents).toBe(-10000);
    });

    it('should return positive impact for income', () => {
      const transaction = createIncomeTransaction(500);
      
      expect(transaction.getBalanceImpact().cents).toBe(50000);
    });
  });
});
```

### 2. Application (Use Cases e Queries) - Mock Dependencies

**Características:**
- **Mock Ports**: Todas as dependências são interfaces mockadas
- **Business Flows**: Testa orquestração de regras de negócio
- **Error Scenarios**: Valida tratamento de erros
- **Integration Points**: Verifica contratos com infra

```typescript
// application/use-cases/CreateTransactionUseCase.spec.ts
describe('CreateTransactionUseCase', () => {
  let useCase: CreateTransactionUseCase;
  let mockTransactionService: jest.Mocked<ITransactionServicePort>;
  let mockAccountService: jest.Mocked<IAccountServicePort>;

  beforeEach(() => {
    // Arrange - Setup mocks
    mockTransactionService = createMockTransactionService();
    mockAccountService = createMockAccountService();
    
    useCase = new CreateTransactionUseCase(
      mockTransactionService,
      mockAccountService
    );
  });

  describe('when creating a valid transaction', () => {
    it('should create transaction successfully', async () => {
      // Arrange
      const dto = createValidTransactionDto();
      const mockAccount = createMockAccount({ id: dto.accountId });
      
      mockAccountService.getById.mockResolvedValue(Either.success(mockAccount));
      mockTransactionService.create.mockResolvedValue(Either.success(undefined));

      // Act
      const result = await useCase.execute(dto);

      // Assert
      expect(result.hasError).toBe(false);
      expect(mockTransactionService.create).toHaveBeenCalledTimes(1);
      expect(mockTransactionService.create).toHaveBeenCalledWith(
        expect.objectContaining({
          description: dto.description,
          amount: expect.objectContaining({ cents: dto.amountInCents })
        })
      );
    });
  });

  describe('when account does not exist', () => {
    it('should return AccountNotFoundError', async () => {
      // Arrange
      const dto = createValidTransactionDto();
      
      mockAccountService.getById.mockResolvedValue(
        Either.error(new AccountNotFoundError(dto.accountId))
      );

      // Act
      const result = await useCase.execute(dto);

      // Assert
      expect(result.hasError).toBe(true);
      expect(result.errors[0]).toBeInstanceOf(AccountNotFoundError);
      expect(mockTransactionService.create).not.toHaveBeenCalled();
    });
  });

  describe('when service fails', () => {
    it('should handle service errors gracefully', async () => {
      // Arrange
      const dto = createValidTransactionDto();
      const mockAccount = createMockAccount({ id: dto.accountId });
      
      mockAccountService.getById.mockResolvedValue(Either.success(mockAccount));
      mockTransactionService.create.mockResolvedValue(
        Either.error(new ServiceError('Database connection failed'))
      );

      // Act
      const result = await useCase.execute(dto);

      // Assert
      expect(result.hasError).toBe(true);
      expect(result.errors[0]).toBeInstanceOf(ServiceError);
    });
  });
});
```

### 3. Infrastructure (Adapters) - Integration Tests

**Características:**
- **Real Dependencies**: Usa MSW para HTTP, IndexedDB para storage
- **Contract Validation**: Testa se adapters implementam Ports corretamente
- **Error Mapping**: Verifica conversão de erros externos para domain errors
- **Data Transformation**: Valida mappers API ↔ Domain

```typescript
// infra/adapters/http/HttpBudgetServiceAdapter.integration.spec.ts
describe('HttpBudgetServiceAdapter Integration', () => {
  let adapter: HttpBudgetServiceAdapter;
  let httpClient: FetchHttpClient;
  let server: SetupServer;

  beforeEach(() => {
    // Setup MSW server
    server = setupServer();
    server.listen();
    
    httpClient = new FetchHttpClient(mockTokenProvider);
    adapter = new HttpBudgetServiceAdapter(httpClient);
  });

  afterEach(() => {
    server.resetHandlers();
  });

  afterAll(() => {
    server.close();
  });

  describe('create budget', () => {
    it('should create budget successfully', async () => {
      // Arrange
      const budget = createMockBudget();
      
      server.use(
        rest.post('/api/budget/create', (req, res, ctx) => {
          return res(ctx.status(204));
        })
      );

      // Act
      const result = await adapter.create(budget);

      // Assert
      expect(result.hasError).toBe(false);
    });

    it('should handle validation errors', async () => {
      // Arrange
      const budget = createMockBudget();
      
      server.use(
        rest.post('/api/budget/create', (req, res, ctx) => {
          return res(
            ctx.status(400),
            ctx.json({
              success: false,
              errors: [{ code: 'VALIDATION_ERROR', message: 'Name is required' }]
            })
          );
        })
      );

      // Act
      const result = await adapter.create(budget);

      // Assert
      expect(result.hasError).toBe(true);
      expect(result.errors[0]).toBeInstanceOf(ValidationError);
    });

    it('should handle network errors', async () => {
      // Arrange
      const budget = createMockBudget();
      
      server.use(
        rest.post('/api/budget/create', (req, res) => {
          return res.networkError('Network error');
        })
      );

      // Act
      const result = await adapter.create(budget);

      // Assert
      expect(result.hasError).toBe(true);
      expect(result.errors[0]).toBeInstanceOf(NetworkError);
    });
  });

  describe('get budget', () => {
    it('should fetch and map budget correctly', async () => {
      // Arrange
      const mockApiResponse = {
        id: 'budget-123',
        name: 'Home Budget',
        limit_in_cents: 500000,
        participants: ['user-1', 'user-2'],
        created_at: '2024-01-15T10:00:00Z'
      };
      
      server.use(
        rest.get('/api/budget/:id', (req, res, ctx) => {
          return res(ctx.json(mockApiResponse));
        })
      );

      // Act
      const result = await adapter.getById('budget-123');

      // Assert
      expect(result.hasError).toBe(false);
      
      const budget = result.data!;
      expect(budget.id).toBe('budget-123');
      expect(budget.name).toBe('Home Budget');
      expect(budget.limit.cents).toBe(500000);
      expect(budget.participants).toEqual(['user-1', 'user-2']);
    });
  });
});
```

### 4. UI (Angular Components) - TestBed + Signals

**Características:**
- **Component Behavior**: Testa interação usuário → output
- **Signal State**: Valida estado reativo
- **Template Rendering**: Verifica renderização condicional
- **User Events**: Simula cliques, inputs, formulários

```typescript
// app/features/budgets/pages/budget-list.page.spec.ts
describe('BudgetListPage', () => {
  let component: BudgetListPage;
  let fixture: ComponentFixture<BudgetListPage>;
  let mockGetBudgetListUseCase: jest.Mocked<GetBudgetListUseCase>;

  beforeEach(async () => {
    mockGetBudgetListUseCase = createMockUseCase();

    await TestBed.configureTestingModule({
      imports: [BudgetListPage],
      providers: [
        { provide: GetBudgetListUseCase, useValue: mockGetBudgetListUseCase }
      ]
    }).compileComponents();

    fixture = TestBed.createComponent(BudgetListPage);
    component = fixture.componentInstance;
  });

  describe('when loading budgets', () => {
    it('should display loading state initially', async () => {
      // Arrange
      mockGetBudgetListUseCase.execute.mockImplementation(() => 
        new Promise(resolve => {}) // Never resolves - stays loading
      );

      // Act
      fixture.detectChanges();
      await fixture.whenStable();

      // Assert
      const loadingElement = fixture.debugElement.query(By.css('os-skeleton-list'));
      expect(loadingElement).toBeTruthy();
      expect(component.loading()).toBe(true);
    });

    it('should display budgets when loaded successfully', async () => {
      // Arrange
      const mockBudgets = [
        createMockBudget({ id: '1', name: 'Home Budget' }),
        createMockBudget({ id: '2', name: 'Travel Fund' })
      ];
      
      mockGetBudgetListUseCase.execute.mockResolvedValue(
        Either.success(mockBudgets)
      );

      // Act
      fixture.detectChanges();
      await fixture.whenStable();
      fixture.detectChanges();

      // Assert
      const budgetCards = fixture.debugElement.queryAll(By.css('os-budget-card'));
      expect(budgetCards.length).toBe(2);
      expect(component.budgets()).toEqual(mockBudgets);
      expect(component.loading()).toBe(false);
    });

    it('should display error state when loading fails', async () => {
      // Arrange
      mockGetBudgetListUseCase.execute.mockResolvedValue(
        Either.error(new ServiceError('Failed to load budgets'))
      );

      // Act
      fixture.detectChanges();
      await fixture.whenStable();
      fixture.detectChanges();

      // Assert
      const errorElement = fixture.debugElement.query(By.css('os-error-state'));
      expect(errorElement).toBeTruthy();
      expect(component.error()).toBe('Failed to load budgets');
    });
  });

  describe('user interactions', () => {
    it('should navigate to budget details when card is clicked', async () => {
      // Arrange
      const mockBudget = createMockBudget({ id: 'budget-123' });
      const routerSpy = jest.spyOn(TestBed.inject(Router), 'navigate');
      
      mockGetBudgetListUseCase.execute.mockResolvedValue(
        Either.success([mockBudget])
      );

      // Act
      fixture.detectChanges();
      await fixture.whenStable();
      fixture.detectChanges();

      const budgetCard = fixture.debugElement.query(By.css('os-budget-card'));
      budgetCard.triggerEventHandler('onClick', null);

      // Assert
      expect(routerSpy).toHaveBeenCalledWith(['/budgets', 'budget-123']);
    });

    it('should navigate to create budget when create button clicked', () => {
      // Arrange
      const routerSpy = jest.spyOn(TestBed.inject(Router), 'navigate');

      // Act
      component.createBudget();

      // Assert
      expect(routerSpy).toHaveBeenCalledWith(['/budgets/create']);
    });
  });
});
```

### 5. UI Components (Design System) - Component Testing

```typescript
// app/shared/ui-components/atoms/os-button/os-button.component.spec.ts
describe('OsButtonComponent', () => {
  let component: OsButtonComponent;
  let fixture: ComponentFixture<OsButtonComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [OsButtonComponent, MatButtonModule]
    }).compileComponents();

    fixture = TestBed.createComponent(OsButtonComponent);
    component = fixture.componentInstance;
  });

  describe('appearance', () => {
    it('should apply primary variant by default', () => {
      fixture.detectChanges();
      
      const button = fixture.debugElement.query(By.css('button'));
      expect(button.nativeElement).toHaveClass('os-button--primary');
    });

    it('should apply danger variant when specified', () => {
      // Arrange
      fixture.componentRef.setInput('variant', 'danger');

      // Act
      fixture.detectChanges();

      // Assert
      const button = fixture.debugElement.query(By.css('button'));
      expect(button.nativeElement).toHaveClass('os-button--danger');
    });

    it('should show loading spinner when loading', () => {
      // Arrange
      fixture.componentRef.setInput('loading', true);

      // Act
      fixture.detectChanges();

      // Assert
      const spinner = fixture.debugElement.query(By.css('mat-spinner'));
      const button = fixture.debugElement.query(By.css('button'));
      
      expect(spinner).toBeTruthy();
      expect(button.nativeElement.disabled).toBe(true);
    });
  });

  describe('interactions', () => {
    it('should emit onClick when clicked', () => {
      // Arrange
      const onClickSpy = jest.fn();
      fixture.componentRef.instance.onClick.subscribe(onClickSpy);

      // Act
      const button = fixture.debugElement.query(By.css('button'));
      button.nativeElement.click();

      // Assert
      expect(onClickSpy).toHaveBeenCalledTimes(1);
      expect(onClickSpy).toHaveBeenCalledWith(expect.any(MouseEvent));
    });

    it('should not emit onClick when disabled', () => {
      // Arrange
      fixture.componentRef.setInput('disabled', true);
      const onClickSpy = jest.fn();
      fixture.componentRef.instance.onClick.subscribe(onClickSpy);

      // Act
      fixture.detectChanges();
      const button = fixture.debugElement.query(By.css('button'));
      button.nativeElement.click();

      // Assert
      expect(onClickSpy).not.toHaveBeenCalled();
    });

    it('should not emit onClick when loading', () => {
      // Arrange
      fixture.componentRef.setInput('loading', true);
      const onClickSpy = jest.fn();
      fixture.componentRef.instance.onClick.subscribe(onClickSpy);

      // Act
      fixture.detectChanges();
      const button = fixture.debugElement.query(By.css('button'));
      button.nativeElement.click();

      // Assert
      expect(onClickSpy).not.toHaveBeenCalled();
    });
  });
});
```

## Mock Service Worker (MSW) Setup

### Browser Setup para Desenvolvimento

```typescript
// mocks/browser.ts
import { setupWorker } from 'msw/browser';
import { handlers } from './handlers';

export const worker = setupWorker(...handlers);
```

### Test Setup para Karma

```typescript
// src/test-setup.ts
import { setupServer } from 'msw/node';
import { handlers } from './mocks/handlers';

// Setup MSW server para testes
const server = setupServer(...handlers);

beforeAll(() => {
  server.listen();
});

afterEach(() => {
  server.resetHandlers();
});

afterAll(() => {
  server.close();
});

// Tornar server disponível globalmente para testes específicos
(globalThis as any).mswServer = server;
```

### Handlers por Contexto

```typescript
// mocks/context/budgetHandlers.ts
import { http, HttpResponse } from 'msw';

export const budgetHandlers = [
  // Create budget
  http.post('/api/budget/create', async ({ request }) => {
    const body = await request.json();
    
    // Simulate validation
    if (!body.name) {
      return HttpResponse.json(
        { 
          success: false, 
          errors: [{ code: 'VALIDATION_ERROR', message: 'Name is required' }] 
        },
        { status: 400 }
      );
    }

    return new HttpResponse(null, { status: 204 });
  }),

  // Get budget
  http.get('/api/budget/:id', ({ params }) => {
    const { id } = params;
    
    if (id === 'not-found') {
      return HttpResponse.json(
        { success: false, errors: [{ code: 'NOT_FOUND', message: 'Budget not found' }] },
        { status: 404 }
      );
    }

    return HttpResponse.json({
      id: id,
      name: 'Mock Budget',
      limit_in_cents: 500000,
      participants: ['user-1'],
      created_at: '2024-01-15T10:00:00Z'
    });
  }),

  // Get budget summary
  http.get('/api/budget/:id/summary', ({ params, request }) => {
    const url = new URL(request.url);
    const period = url.searchParams.get('period') || 'current_month';

    return HttpResponse.json({
      budget_id: params.id,
      budget_name: 'Mock Budget',
      limit_in_cents: 500000,
      total_spent_in_cents: 350000,
      remaining_in_cents: 150000,
      usage_percentage: 70,
      transaction_count: 25,
      period: period
    });
  })
];
```

## Test Utilities e Helpers

### Mock Factories

```typescript
// test/factories/BudgetFactory.ts
export function createMockBudget(overrides: Partial<Budget> = {}): Budget {
  return Budget.fromSnapshot({
    id: 'budget-123',
    name: 'Test Budget',
    limitInCents: 500000,
    participants: ['user-1'],
    createdAt: new Date('2024-01-15'),
    ...overrides
  });
}

export function createValidBudgetDto(overrides: Partial<CreateBudgetDto> = {}): CreateBudgetDto {
  return {
    name: 'Test Budget',
    limitInCents: 500000,
    ...overrides
  };
}
```

### Mock Services

```typescript
// test/mocks/createMockTransactionService.ts
export function createMockTransactionService(): jest.Mocked<ITransactionServicePort> {
  return {
    create: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
    getById: jest.fn(),
    getByBudget: jest.fn(),
    getByAccount: jest.fn()
  };
}
```

### Test Data Builders

```typescript
// test/builders/TransactionBuilder.ts
export class TransactionBuilder {
  private params: Partial<CreateTransactionParams> = {};

  withDescription(description: string): this {
    this.params.description = description;
    return this;
  }

  withAmount(reais: number): this {
    this.params.amount = Money.fromReais(reais);
    return this;
  }

  withAccount(accountId: string): this {
    this.params.accountId = accountId;
    return this;
  }

  asIncome(): this {
    this.params.type = TransactionType.INCOME;
    return this;
  }

  asExpense(): this {
    this.params.type = TransactionType.EXPENSE;
    return this;
  }

  build(): Either<DomainError, Transaction> {
    const defaults = {
      description: 'Test Transaction',
      amount: Money.fromReais(100),
      accountId: 'account-123',
      type: TransactionType.EXPENSE,
      date: new Date()
    };

    return Transaction.create({ ...defaults, ...this.params });
  }

  buildValid(): Transaction {
    const result = this.build();
    if (result.hasError) {
      throw new Error('Failed to build valid transaction');
    }
    return result.data!;
  }
}

// Usage
const transaction = new TransactionBuilder()
  .withDescription('Grocery shopping')
  .withAmount(85.50)
  .asExpense()
  .buildValid();
```

## Coverage e Qualidade

### Coverage Thresholds

```json
// karma.conf.js
module.exports = function (config) {
  config.set({
    coverageReporter: {
      dir: require('path').join(__dirname, './coverage'),
      subdir: '.',
      reporters: [
        { type: 'html' },
        { type: 'text-summary' },
        { type: 'json-summary' }
      ],
      check: {
        global: {
          statements: 80,
          branches: 75,
          functions: 80,
          lines: 80
        },
        each: {
          statements: 70,
          branches: 65,
          functions: 70,
          lines: 70,
          overrides: {
            'src/models/**/*': {
              statements: 90,
              branches: 85,
              functions: 90,
              lines: 90
            },
            'src/application/**/*': {
              statements: 85,
              branches: 80,
              functions: 85,
              lines: 85
            }
          }
        }
      }
    }
  });
};
```

### Scripts de Teste

```json
// package.json
{
  "scripts": {
    "test": "ng test",
    "test:watch": "ng test --watch",
    "test:ci": "ng test --watch=false --browsers=ChromeHeadless --code-coverage",
    "test:coverage": "ng test --code-coverage --watch=false",
    "test:debug": "ng test --source-map=false"
  }
}
```

---

**Ver também:**
- [MSW Configuration](./msw-configuration.md) - Configuração detalhada do Mock Service Worker
- [Layer Responsibilities](./layer-responsibilities.md) - O que testar em cada camada
- [Naming Conventions](./naming-conventions.md) - Convenções para arquivos de teste