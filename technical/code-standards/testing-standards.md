# Testing Standards - Padrões de Testes

## 🧪 Padrões de Testes

### Nomenclatura de Testes

```typescript
// ✅ Estrutura descritiva obrigatória
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
    
    it('should return domain error when transaction exceeds budget limit', async () => {
      // Test business rules
    });
    
    it('should dispatch transaction created event after successful creation', async () => {
      // Test side effects
    });
  });
  
  describe('validation', () => {
    it('should validate required fields', async () => {
      // Group validation tests
    });
    
    it('should sanitize input data', async () => {
      // Test sanitization
    });
  });
});

// ✅ Domain entities tests
describe('Transaction', () => {
  describe('create', () => {
    it('should create transaction with valid data', () => {
      // Test entity creation
    });
    
    it('should return error when amount is zero or negative', () => {
      // Test domain rules
    });
    
    it('should trim description whitespace', () => {
      // Test data normalization
    });
  });
  
  describe('markAsLate', () => {
    it('should mark pending transaction as late', () => {
      // Test state transitions
    });
    
    it('should return error when transaction is already completed', () => {
      // Test invalid state transitions
    });
  });
});

// ✅ Angular component tests
describe('TransactionFormComponent', () => {
  describe('form validation', () => {
    it('should show error when amount is empty', () => {
      // Test form validation
    });
    
    it('should enable submit button when form is valid', () => {
      // Test UI state
    });
  });
  
  describe('submission', () => {
    it('should emit save event on successful submission', fakeAsync(() => {
      // Test events with fakeAsync
    }));
    
    it('should show loading state during submission', () => {
      // Test loading states
    });
  });
});
```

### Estrutura AAA (Arrange, Act, Assert)

```typescript
// ✅ Testes unitários com estrutura AAA
describe('BudgetCalculator', () => {
  describe('calculateRemainingAmount', () => {
    it('should calculate remaining amount correctly', () => {
      // Arrange
      const budgetAmount = Money.fromCents(100000); // R$ 1000
      const transactions = [
        TransactionFactory.create({ amountCents: 30000 }), // R$ 300
        TransactionFactory.create({ amountCents: 20000 })  // R$ 200
      ];
      const budget = BudgetFactory.create({
        amount: budgetAmount,
        transactions
      });
      const calculator = new BudgetCalculator();
      
      // Act
      const remaining = calculator.calculateRemainingAmount(budget);
      
      // Assert
      expect(remaining.getCents()).toBe(50000); // R$ 500
      expect(remaining.getReais()).toBe(500);
    });
    
    it('should handle empty transaction list', () => {
      // Arrange
      const budgetAmount = Money.fromCents(100000);
      const budget = BudgetFactory.create({
        amount: budgetAmount,
        transactions: []
      });
      const calculator = new BudgetCalculator();
      
      // Act
      const remaining = calculator.calculateRemainingAmount(budget);
      
      // Assert
      expect(remaining.getCents()).toBe(100000);
      expect(remaining).toEqual(budgetAmount);
    });
  });
});

// ✅ Use case tests com mocks
describe('CreateTransactionUseCase', () => {
  let useCase: CreateTransactionUseCase;
  let mockRepository: jest.Mocked<IAddTransactionRepository>;
  let mockAuthService: jest.Mocked<IBudgetAuthorizationService>;
  let mockEventDispatcher: jest.Mocked<IDomainEventDispatcher>;
  
  beforeEach(() => {
    // Arrange - Setup mocks
    mockRepository = {
      execute: jest.fn()
    };
    
    mockAuthService = {
      canManageTransactions: jest.fn()
    };
    
    mockEventDispatcher = {
      dispatch: jest.fn()
    };
    
    useCase = new CreateTransactionUseCase(
      mockRepository,
      mockAuthService,
      mockEventDispatcher
    );
  });
  
  it('should create transaction successfully', async () => {
    // Arrange
    const dto = CreateTransactionDtoFactory.create({
      amountCents: 1500,
      description: 'Test transaction',
      budgetId: 'budget-123'
    });
    const userId = 'user-456';
    
    mockAuthService.canManageTransactions.mockResolvedValue(Either.right(void 0));
    mockRepository.execute.mockResolvedValue(Either.right(void 0));
    mockEventDispatcher.dispatch.mockResolvedValue(Either.right(void 0));
    
    // Act
    const result = await useCase.execute(dto, userId);
    
    // Assert
    expect(result.isRight()).toBe(true);
    expect(mockAuthService.canManageTransactions).toHaveBeenCalledWith(userId, dto.budgetId);
    expect(mockRepository.execute).toHaveBeenCalledWith(
      expect.objectContaining({
        amount: expect.objectContaining({ cents: 1500 }),
        description: 'Test transaction'
      })
    );
    expect(mockEventDispatcher.dispatch).toHaveBeenCalledWith(
      expect.any(TransactionCreatedEvent)
    );
  });
  
  it('should return error when user is unauthorized', async () => {
    // Arrange
    const dto = CreateTransactionDtoFactory.create();
    const userId = 'user-456';
    const authError = new UnauthorizedError('Cannot manage transactions');
    
    mockAuthService.canManageTransactions.mockResolvedValue(Either.left(authError));
    
    // Act
    const result = await useCase.execute(dto, userId);
    
    // Assert
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(UnauthorizedError);
    }
    expect(mockRepository.execute).not.toHaveBeenCalled();
    expect(mockEventDispatcher.dispatch).not.toHaveBeenCalled();
  });
});
```

### Test Factories e Builders

```typescript
// ✅ Factory pattern para testes
export class TransactionFactory {
  public static create(overrides: Partial<CreateTransactionDto> = {}): Transaction {
    const defaultData: CreateTransactionDto = {
      amountCents: 1000,
      description: 'Test transaction',
      budgetId: 'budget-123',
      categoryId: 'category-456',
      date: new Date()
    };
    
    const data = { ...defaultData, ...overrides };
    const result = Transaction.create(data);
    
    if (result.isLeft()) {
      throw new Error(`Failed to create test transaction: ${result.value.message}`);
    }
    
    return result.value;
  }
  
  public static createMany(count: number, overrides: Partial<CreateTransactionDto> = {}): Transaction[] {
    return Array.from({ length: count }, (_, index) => 
      this.create({
        ...overrides,
        description: `Test transaction ${index + 1}`,
        amountCents: (overrides.amountCents || 1000) + (index * 100)
      })
    );
  }
  
  public static createPending(overrides: Partial<CreateTransactionDto> = {}): Transaction {
    return this.create({
      ...overrides,
      // Create with pending status by default
    });
  }
  
  public static createCompleted(overrides: Partial<CreateTransactionDto> = {}): Transaction {
    const transaction = this.create(overrides);
    // Mark as completed (if such method exists)
    return transaction;
  }
}

// ✅ Builder pattern para cenários complexos
export class BudgetTestBuilder {
  private amount: Money = Money.fromCents(100000);
  private transactions: Transaction[] = [];
  private name: string = 'Test Budget';
  private userId: string = 'user-123';
  
  public withAmount(amountCents: number): this {
    this.amount = Money.fromCents(amountCents);
    return this;
  }
  
  public withTransactions(transactions: Transaction[]): this {
    this.transactions = transactions;
    return this;
  }
  
  public withName(name: string): this {
    this.name = name;
    return this;
  }
  
  public withUser(userId: string): this {
    this.userId = userId;
    return this;
  }
  
  public build(): Budget {
    const result = Budget.create({
      amount: this.amount,
      name: this.name,
      userId: this.userId,
      transactions: this.transactions
    });
    
    if (result.isLeft()) {
      throw new Error(`Failed to build test budget: ${result.value.message}`);
    }
    
    return result.value;
  }
}

// ✅ Usage in tests
describe('Budget calculations', () => {
  it('should calculate remaining amount with multiple transactions', () => {
    // Arrange
    const transactions = TransactionFactory.createMany(3, { amountCents: 2000 });
    const budget = new BudgetTestBuilder()
      .withAmount(10000)
      .withTransactions(transactions)
      .withName('Groceries Budget')
      .build();
    
    // Act
    const remaining = budget.getRemainingAmount();
    
    // Assert
    expect(remaining.getCents()).toBe(4000); // 10000 - (3 * 2000)
  });
});
```

### Mocking Strategies

```typescript
// ✅ Repository mocking
const createMockRepository = <T>(): jest.Mocked<T> => {
  return {
    execute: jest.fn()
  } as any;
};

// ✅ Service mocking com comportamentos específicos
const createMockAuthService = () => {
  const mock = {
    canManageTransactions: jest.fn(),
    canViewTransactions: jest.fn(),
    getCurrentUser: jest.fn()
  };
  
  // Default behaviors
  mock.canManageTransactions.mockResolvedValue(Either.right(void 0));
  mock.canViewTransactions.mockResolvedValue(Either.right(void 0));
  mock.getCurrentUser.mockResolvedValue(Either.right(UserFactory.create()));
  
  return mock;
};

// ✅ Angular testing utilities
const createComponentTestBed = <T>(component: Type<T>, providers: Provider[] = []) => {
  return TestBed.configureTestingModule({
    imports: [component], // Standalone components
    providers: [
      ...providers,
      // Common mocks
      { provide: Router, useValue: { navigate: jest.fn() } },
      { provide: ActivatedRoute, useValue: { params: of({}) } }
    ]
  });
};

// ✅ HTTP testing
describe('TransactionService', () => {
  let service: TransactionService;
  let httpMock: HttpTestingController;
  
  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [TransactionService]
    });
    
    service = TestBed.inject(TransactionService);
    httpMock = TestBed.inject(HttpTestingController);
  });
  
  afterEach(() => {
    httpMock.verify(); // Ensure no outstanding requests
  });
  
  it('should create transaction via HTTP', async () => {
    // Arrange
    const dto = CreateTransactionDtoFactory.create();
    const expectedResponse = { transactionId: 'txn-123' };
    
    // Act
    const resultPromise = service.createTransaction(dto);
    
    // Assert
    const req = httpMock.expectOne('/transaction/create-transaction');
    expect(req.request.method).toBe('POST');
    expect(req.request.body).toEqual(dto);
    expect(req.request.headers.get('Content-Type')).toBe('application/json');
    
    req.flush({ success: true, data: expectedResponse });
    
    const result = await resultPromise;
    expect(result.isRight()).toBe(true);
  });
  
  it('should handle HTTP errors', async () => {
    // Arrange
    const dto = CreateTransactionDtoFactory.create();
    
    // Act
    const resultPromise = service.createTransaction(dto);
    
    // Assert
    const req = httpMock.expectOne('/transaction/create-transaction');
    req.flush('Server error', { status: 500, statusText: 'Internal Server Error' });
    
    const result = await resultPromise;
    expect(result.isLeft()).toBe(true);
  });
});
```

### Component Testing

```typescript
// ✅ Angular component testing
describe('TransactionFormComponent', () => {
  let component: TransactionFormComponent;
  let fixture: ComponentFixture<TransactionFormComponent>;
  let mockUseCase: jest.Mocked<CreateTransactionUseCase>;
  
  beforeEach(async () => {
    mockUseCase = {
      execute: jest.fn()
    } as any;
    
    await createComponentTestBed(TransactionFormComponent, [
      { provide: CreateTransactionUseCase, useValue: mockUseCase }
    ]).compileComponents();
    
    fixture = TestBed.createComponent(TransactionFormComponent);
    component = fixture.componentInstance;
    
    // Set required inputs
    component.budgetId.set('budget-123');
    
    fixture.detectChanges();
  });
  
  it('should create component', () => {
    expect(component).toBeTruthy();
  });
  
  it('should validate required fields', () => {
    // Arrange
    const form = component.form();
    
    // Act
    form.get('amount')?.setValue('');
    form.get('description')?.setValue('');
    form.markAllAsTouched();
    
    fixture.detectChanges();
    
    // Assert
    expect(form.invalid).toBe(true);
    expect(form.get('amount')?.hasError('required')).toBe(true);
    expect(form.get('description')?.hasError('required')).toBe(true);
  });
  
  it('should submit valid form', fakeAsync(() => {
    // Arrange
    const form = component.form();
    const expectedDto: CreateTransactionDto = {
      amountCents: 1500,
      description: 'Test transaction',
      budgetId: 'budget-123'
    };
    
    mockUseCase.execute.mockResolvedValue(Either.right(new TransactionId('txn-123')));
    
    // Act
    form.patchValue({
      amount: '15.00',
      description: 'Test transaction'
    });
    
    component.onSubmit();
    tick(); // Process async operations
    
    // Assert
    expect(mockUseCase.execute).toHaveBeenCalledWith(
      expect.objectContaining(expectedDto),
      expect.any(String) // userId
    );
  }));
  
  it('should show loading state during submission', fakeAsync(() => {
    // Arrange
    const form = component.form();
    mockUseCase.execute.mockImplementation(() => 
      new Promise(resolve => setTimeout(() => resolve(Either.right(new TransactionId('txn-123'))), 1000))
    );
    
    // Act
    form.patchValue({
      amount: '15.00',
      description: 'Test transaction'
    });
    
    component.onSubmit();
    
    // Assert - loading state should be true
    expect(component.loading()).toBe(true);
    
    tick(1000); // Complete the async operation
    
    // Assert - loading state should be false
    expect(component.loading()).toBe(false);
  }));
  
  it('should emit save event on successful submission', fakeAsync(() => {
    // Arrange
    const form = component.form();
    const transactionId = new TransactionId('txn-123');
    let emittedId: TransactionId | undefined;
    
    component.save.subscribe(id => emittedId = id);
    mockUseCase.execute.mockResolvedValue(Either.right(transactionId));
    
    // Act
    form.patchValue({
      amount: '15.00',
      description: 'Test transaction'
    });
    
    component.onSubmit();
    tick();
    
    // Assert
    expect(emittedId).toEqual(transactionId);
  }));
});
```

### Integration Testing

```typescript
// ✅ Integration tests com TestBed
describe('Transaction Feature Integration', () => {
  let app: ComponentFixture<AppComponent>;
  let httpMock: HttpTestingController;
  
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [
        AppComponent,
        HttpClientTestingModule,
        RouterTestingModule.withRoutes([
          { path: 'transactions', component: TransactionListPage }
        ])
      ],
      providers: [
        // Real services for integration testing
        TransactionService,
        CreateTransactionUseCase,
        // Mock external dependencies
        { provide: AuthService, useClass: MockAuthService },
        { provide: ConfigService, useClass: MockConfigService }
      ]
    }).compileComponents();
    
    app = TestBed.createComponent(AppComponent);
    httpMock = TestBed.inject(HttpTestingController);
  });
  
  it('should complete transaction creation flow', fakeAsync(() => {
    // Arrange
    app.detectChanges();
    
    // Navigate to transaction form
    const router = TestBed.inject(Router);
    router.navigate(['/transactions/create']);
    tick();
    
    // Fill form
    const form = app.debugElement.query(By.css('form'));
    const amountInput = form.query(By.css('[data-test="amount-input"]'));
    const descriptionInput = form.query(By.css('[data-test="description-input"]'));
    const submitButton = form.query(By.css('[data-test="submit-button"]'));
    
    amountInput.nativeElement.value = '25.50';
    amountInput.nativeElement.dispatchEvent(new Event('input'));
    
    descriptionInput.nativeElement.value = 'Integration test transaction';
    descriptionInput.nativeElement.dispatchEvent(new Event('input'));
    
    app.detectChanges();
    
    // Submit form
    submitButton.nativeElement.click();
    
    // Handle HTTP request
    const req = httpMock.expectOne('/transaction/create-transaction');
    req.flush({
      success: true,
      data: { transactionId: 'txn-integration-123' }
    });
    
    tick();
    app.detectChanges();
    
    // Assert navigation happened
    expect(router.url).toBe('/transactions/txn-integration-123');
  }));
});
```

### Performance Testing

```typescript
// ✅ Performance tests
describe('TransactionListComponent Performance', () => {
  let component: TransactionListComponent;
  let fixture: ComponentFixture<TransactionListComponent>;
  
  beforeEach(() => {
    // Setup component
  });
  
  it('should handle large transaction lists efficiently', () => {
    // Arrange
    const largeTransactionList = TransactionFactory.createMany(10000);
    const startTime = performance.now();
    
    // Act
    component.transactions.set(largeTransactionList);
    fixture.detectChanges();
    
    const endTime = performance.now();
    const renderTime = endTime - startTime;
    
    // Assert
    expect(renderTime).toBeLessThan(100); // Should render in less than 100ms
    expect(component.filteredTransactions().length).toBe(10000);
  });
  
  it('should update filtered list efficiently', () => {
    // Arrange
    const transactions = TransactionFactory.createMany(1000);
    component.transactions.set(transactions);
    
    const startTime = performance.now();
    
    // Act
    component.searchTerm.set('test');
    fixture.detectChanges();
    
    const endTime = performance.now();
    const filterTime = endTime - startTime;
    
    // Assert
    expect(filterTime).toBeLessThan(50); // Should filter in less than 50ms
  });
});
```

---

**Padrões obrigatórios para testes:**
- ✅ **AAA structure** (Arrange, Act, Assert)
- ✅ **Descriptive naming** com should/when/given
- ✅ **Test factories** para dados de teste
- ✅ **Proper mocking** com jest.Mocked
- ✅ **Either testing** para error cases
- ✅ **Component testing** com TestBed
- ✅ **HTTP testing** com HttpClientTestingModule
- ✅ **Performance testing** para operações críticas

**Próximos tópicos:**
- **[Validation Rules](./validation-rules.md)** - Regras de validação
- **[Code Review Checklist](./code-review-checklist.md)** - Checklist de review