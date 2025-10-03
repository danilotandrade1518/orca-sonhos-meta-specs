# Padrões de Teste para Features - Feature-Based Architecture

---

**Metadados Estruturados para IA/RAG:**

```yaml
document_type: "technical_architecture"
domain: "frontend_architecture"
audience: ["frontend_developers", "qa_engineers", "tech_leads"]
complexity: "intermediate"
tags: ["testing_patterns", "feature_based", "angular", "typescript", "signals"]
related_docs:
  ["testing-strategy.md", "feature-organization.md", "state-management.md"]
ai_context: "Comprehensive testing patterns for Feature-Based Architecture with Angular Signals"
technologies: ["TypeScript", "Angular", "Jest", "Angular Signals", "DTOs"]
patterns: ["Feature-Based", "Test-Driven Development", "Reactive Testing"]
last_updated: "2025-01-24"
```

---

## Visão Geral

Este documento define padrões específicos para testes em Feature-Based Architecture, focando em isolamento de features, comunicação via DTOs, e gerenciamento de estado reativo com Angular Signals.

## Princípios Fundamentais

### 1. Isolamento de Features

- Cada feature é testada independentemente
- Mocks para comunicação entre features
- Validação de boundaries entre features
- Testes não devem depender de outras features

### 2. DTO-First Testing

- DTOs como contratos de comunicação
- Validação de transformações DTO ↔ ViewModel
- Testes de validação de DTOs
- Mocks baseados em DTOs

### 3. Angular Signals Testing

- Testes de estado reativo
- Validação de computed signals
- Testes de efeitos (effects)
- Mock de signals em testes

## Padrões por Tipo de Componente

### 1. Componentes de Feature

#### Estrutura Padrão

```typescript
// app/features/budgets/components/budget-list.component.spec.ts
import { ComponentFixture, TestBed } from "@angular/core/testing";
import { By } from "@angular/platform-browser";
import { signal } from "@angular/core";
import { of } from "rxjs";

import { BudgetListComponent } from "./budget-list.component";
import { BudgetService } from "../services/budget.service";
import { BudgetState } from "../state/budget.state";
import { BudgetResponseDto, CreateBudgetRequestDto } from "@dtos/budget";
import { createMockBudgetDto } from "@test/factories/DtoFactory";

describe("BudgetListComponent", () => {
  let component: BudgetListComponent;
  let fixture: ComponentFixture<BudgetListComponent>;
  let budgetService: jasmine.SpyObj<BudgetService>;
  let budgetState: jasmine.SpyObj<BudgetState>;

  beforeEach(async () => {
    const budgetServiceSpy = jasmine.createSpyObj("BudgetService", [
      "getBudgets",
      "createBudget",
      "updateBudget",
      "deleteBudget",
    ]);

    const budgetStateSpy = jasmine.createSpyObj("BudgetState", [
      "budgets",
      "loading",
      "error",
      "setBudgets",
      "setLoading",
      "setError",
    ]);

    await TestBed.configureTestingModule({
      imports: [BudgetListComponent],
      providers: [
        { provide: BudgetService, useValue: budgetServiceSpy },
        { provide: BudgetState, useValue: budgetStateSpy },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(BudgetListComponent);
    component = fixture.componentInstance;
    budgetService = TestBed.inject(
      BudgetService
    ) as jasmine.SpyObj<BudgetService>;
    budgetState = TestBed.inject(BudgetState) as jasmine.SpyObj<BudgetState>;
  });

  describe("initialization", () => {
    it("should create", () => {
      expect(component).toBeTruthy();
    });

    it("should initialize with empty state", () => {
      expect(component.budgets()).toEqual([]);
      expect(component.loading()).toBe(false);
      expect(component.error()).toBeNull();
    });
  });

  describe("data loading", () => {
    it("should load budgets on init", () => {
      // Arrange
      const mockBudgets: BudgetResponseDto[] = [
        createMockBudgetDto({ id: "budget-1", name: "Budget 1" }),
        createMockBudgetDto({ id: "budget-2", name: "Budget 2" }),
      ];

      budgetService.getBudgets.and.returnValue(of(mockBudgets));
      budgetState.budgets = signal(mockBudgets);

      // Act
      component.ngOnInit();

      // Assert
      expect(budgetService.getBudgets).toHaveBeenCalled();
      expect(component.budgets()).toEqual(mockBudgets);
    });

    it("should handle loading state", () => {
      // Arrange
      budgetState.loading = signal(true);

      // Act
      fixture.detectChanges();

      // Assert
      expect(component.loading()).toBe(true);
      const loadingElement = fixture.debugElement.query(
        By.css('[data-testid="loading-skeleton"]')
      );
      expect(loadingElement).toBeTruthy();
    });

    it("should handle error state", () => {
      // Arrange
      budgetState.error = signal("Failed to load budgets");

      // Act
      fixture.detectChanges();

      // Assert
      expect(component.error()).toBe("Failed to load budgets");
      const errorElement = fixture.debugElement.query(
        By.css('[data-testid="error-message"]')
      );
      expect(errorElement).toBeTruthy();
    });
  });

  describe("user interactions", () => {
    it("should create budget with valid DTO", () => {
      // Arrange
      const createBudgetDto: CreateBudgetRequestDto = {
        name: "New Budget",
        limitInCents: 200000,
        description: "Test description",
      };

      const createdBudget: BudgetResponseDto = createMockBudgetDto({
        ...createBudgetDto,
        id: "budget-123",
      });

      budgetService.createBudget.and.returnValue(of(createdBudget));
      budgetService.getBudgets.and.returnValue(of([createdBudget]));

      // Act
      component.createBudget(createBudgetDto);

      // Assert
      expect(budgetService.createBudget).toHaveBeenCalledWith(createBudgetDto);
      expect(budgetService.getBudgets).toHaveBeenCalled();
    });

    it("should navigate to budget details", () => {
      // Arrange
      const budget: BudgetResponseDto = createMockBudgetDto();
      const routerSpy = spyOn(TestBed.inject(Router), "navigate");

      // Act
      component.viewBudget(budget);

      // Assert
      expect(routerSpy).toHaveBeenCalledWith(["/budgets", budget.id]);
    });
  });
});
```

#### Padrões de Teste para Componentes

**1. Teste de Inicialização**

```typescript
describe("initialization", () => {
  it("should create", () => {
    expect(component).toBeTruthy();
  });

  it("should initialize with default state", () => {
    expect(component.data()).toEqual([]);
    expect(component.loading()).toBe(false);
    expect(component.error()).toBeNull();
  });
});
```

**2. Teste de Estados de Loading**

```typescript
describe("loading states", () => {
  it("should show loading skeleton when loading", () => {
    // Arrange
    component.loading = signal(true);

    // Act
    fixture.detectChanges();

    // Assert
    const loadingElement = fixture.debugElement.query(
      By.css('[data-testid="loading-skeleton"]')
    );
    expect(loadingElement).toBeTruthy();
  });

  it("should hide loading skeleton when data loaded", () => {
    // Arrange
    component.loading = signal(false);
    component.data = signal([createMockData()]);

    // Act
    fixture.detectChanges();

    // Assert
    const loadingElement = fixture.debugElement.query(
      By.css('[data-testid="loading-skeleton"]')
    );
    expect(loadingElement).toBeFalsy();
  });
});
```

**3. Teste de Estados de Erro**

```typescript
describe("error states", () => {
  it("should display error message when error occurs", () => {
    // Arrange
    component.error = signal("Something went wrong");

    // Act
    fixture.detectChanges();

    // Assert
    const errorElement = fixture.debugElement.query(
      By.css('[data-testid="error-message"]')
    );
    expect(errorElement.nativeElement.textContent).toContain(
      "Something went wrong"
    );
  });

  it("should hide error message when error is cleared", () => {
    // Arrange
    component.error = signal(null);

    // Act
    fixture.detectChanges();

    // Assert
    const errorElement = fixture.debugElement.query(
      By.css('[data-testid="error-message"]')
    );
    expect(errorElement).toBeFalsy();
  });
});
```

### 2. Serviços de Feature

#### Estrutura Padrão

```typescript
// app/features/budgets/services/budget.service.spec.ts
import { TestBed } from "@angular/core/testing";
import { HttpClient } from "@angular/common/http";
import { of, throwError } from "rxjs";
import { HttpErrorResponse } from "@angular/common/http";

import { BudgetService } from "./budget.service";
import { BudgetState } from "../state/budget.state";
import { BudgetResponseDto, CreateBudgetRequestDto } from "@dtos/budget";
import { createMockBudgetDto } from "@test/factories/DtoFactory";

describe("BudgetService", () => {
  let service: BudgetService;
  let httpClient: jasmine.SpyObj<HttpClient>;
  let budgetState: jasmine.SpyObj<BudgetState>;

  beforeEach(() => {
    const httpClientSpy = jasmine.createSpyObj("HttpClient", [
      "get",
      "post",
      "put",
      "delete",
    ]);
    const budgetStateSpy = jasmine.createSpyObj("BudgetState", [
      "setBudgets",
      "setLoading",
      "setError",
    ]);

    TestBed.configureTestingModule({
      providers: [
        BudgetService,
        { provide: HttpClient, useValue: httpClientSpy },
        { provide: BudgetState, useValue: budgetStateSpy },
      ],
    });

    service = TestBed.inject(BudgetService);
    httpClient = TestBed.inject(HttpClient) as jasmine.SpyObj<HttpClient>;
    budgetState = TestBed.inject(BudgetState) as jasmine.SpyObj<BudgetState>;
  });

  describe("getBudgets", () => {
    it("should fetch budgets and update state", () => {
      // Arrange
      const mockBudgets: BudgetResponseDto[] = [
        createMockBudgetDto({ id: "budget-1" }),
        createMockBudgetDto({ id: "budget-2" }),
      ];

      httpClient.get.and.returnValue(of(mockBudgets));

      // Act
      service.getBudgets().subscribe();

      // Assert
      expect(httpClient.get).toHaveBeenCalledWith("/api/budgets");
      expect(budgetState.setBudgets).toHaveBeenCalledWith(mockBudgets);
    });

    it("should handle API errors", () => {
      // Arrange
      const error = new HttpErrorResponse({
        status: 500,
        statusText: "Internal Server Error",
      });

      httpClient.get.and.returnValue(throwError(() => error));

      // Act
      service.getBudgets().subscribe({
        next: () => fail("Should have failed"),
        error: (err) => {
          // Assert
          expect(err).toBe(error);
          expect(budgetState.setError).toHaveBeenCalledWith(
            "Failed to load budgets"
          );
        },
      });
    });
  });

  describe("createBudget", () => {
    it("should create budget and refresh list", () => {
      // Arrange
      const createBudgetDto: CreateBudgetRequestDto = {
        name: "New Budget",
        limitInCents: 200000,
        description: "Test description",
      };

      const createdBudget: BudgetResponseDto = createMockBudgetDto({
        ...createBudgetDto,
        id: "budget-123",
      });

      httpClient.post.and.returnValue(of(createdBudget));
      httpClient.get.and.returnValue(of([createdBudget]));

      // Act
      service.createBudget(createBudgetDto).subscribe();

      // Assert
      expect(httpClient.post).toHaveBeenCalledWith(
        "/api/budgets",
        createBudgetDto
      );
      expect(httpClient.get).toHaveBeenCalledWith("/api/budgets");
      expect(budgetState.setBudgets).toHaveBeenCalledWith([createdBudget]);
    });
  });
});
```

#### Padrões de Teste para Serviços

**1. Teste de Chamadas HTTP**

```typescript
describe("HTTP calls", () => {
  it("should make correct API call", () => {
    // Arrange
    const expectedUrl = "/api/budgets";
    const expectedData = { name: "Test Budget" };

    httpClient.post.and.returnValue(of({}));

    // Act
    service.createBudget(expectedData).subscribe();

    // Assert
    expect(httpClient.post).toHaveBeenCalledWith(expectedUrl, expectedData);
  });
});
```

**2. Teste de Tratamento de Erros**

```typescript
describe("error handling", () => {
  it("should handle validation errors", () => {
    // Arrange
    const validationError = new HttpErrorResponse({
      status: 400,
      statusText: "Bad Request",
      error: { message: "Validation failed" },
    });

    httpClient.post.and.returnValue(throwError(() => validationError));

    // Act
    service.createBudget({}).subscribe({
      next: () => fail("Should have failed"),
      error: (err) => {
        // Assert
        expect(err).toBe(validationError);
        expect(budgetState.setError).toHaveBeenCalledWith("Validation failed");
      },
    });
  });
});
```

### 3. Estado com Angular Signals

#### Estrutura Padrão

```typescript
// app/features/budgets/state/budget.state.spec.ts
import { TestBed } from "@angular/core/testing";
import { signal } from "@angular/core";

import { BudgetState } from "./budget.state";
import { BudgetResponseDto } from "@dtos/budget";
import { createMockBudgetDto } from "@test/factories/DtoFactory";

describe("BudgetState", () => {
  let state: BudgetState;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [BudgetState],
    });

    state = TestBed.inject(BudgetState);
  });

  describe("initial state", () => {
    it("should initialize with empty state", () => {
      expect(state.budgets()).toEqual([]);
      expect(state.loading()).toBe(false);
      expect(state.error()).toBeNull();
    });
  });

  describe("budgets signal", () => {
    it("should update budgets when setBudgets is called", () => {
      // Arrange
      const mockBudgets: BudgetResponseDto[] = [
        createMockBudgetDto({ id: "budget-1" }),
        createMockBudgetDto({ id: "budget-2" }),
      ];

      // Act
      state.setBudgets(mockBudgets);

      // Assert
      expect(state.budgets()).toEqual(mockBudgets);
    });

    it("should clear budgets when setBudgets is called with empty array", () => {
      // Arrange
      state.setBudgets([createMockBudgetDto()]);

      // Act
      state.setBudgets([]);

      // Assert
      expect(state.budgets()).toEqual([]);
    });
  });

  describe("loading signal", () => {
    it("should update loading state", () => {
      // Act
      state.setLoading(true);

      // Assert
      expect(state.loading()).toBe(true);

      // Act
      state.setLoading(false);

      // Assert
      expect(state.loading()).toBe(false);
    });
  });

  describe("error signal", () => {
    it("should update error state", () => {
      // Act
      state.setError("Something went wrong");

      // Assert
      expect(state.error()).toBe("Something went wrong");
    });

    it("should clear error when setError is called with null", () => {
      // Arrange
      state.setError("Previous error");

      // Act
      state.setError(null);

      // Assert
      expect(state.error()).toBeNull();
    });
  });

  describe("computed signals", () => {
    it("should calculate total budgets count", () => {
      // Arrange
      const mockBudgets: BudgetResponseDto[] = [
        createMockBudgetDto({ id: "budget-1" }),
        createMockBudgetDto({ id: "budget-2" }),
        createMockBudgetDto({ id: "budget-3" }),
      ];

      state.setBudgets(mockBudgets);

      // Assert
      expect(state.totalBudgets()).toBe(3);
    });

    it("should calculate total budget amount", () => {
      // Arrange
      const mockBudgets: BudgetResponseDto[] = [
        createMockBudgetDto({ limitInCents: 100000 }),
        createMockBudgetDto({ limitInCents: 200000 }),
        createMockBudgetDto({ limitInCents: 300000 }),
      ];

      state.setBudgets(mockBudgets);

      // Assert
      expect(state.totalBudgetAmount()).toBe(600000);
    });
  });
});
```

#### Padrões de Teste para Estado

**1. Teste de Signals Básicos**

```typescript
describe("basic signals", () => {
  it("should initialize with default values", () => {
    expect(state.data()).toEqual([]);
    expect(state.loading()).toBe(false);
    expect(state.error()).toBeNull();
  });

  it("should update signal values", () => {
    // Act
    state.setData([mockData]);
    state.setLoading(true);
    state.setError("Error message");

    // Assert
    expect(state.data()).toEqual([mockData]);
    expect(state.loading()).toBe(true);
    expect(state.error()).toBe("Error message");
  });
});
```

**2. Teste de Computed Signals**

```typescript
describe("computed signals", () => {
  it("should calculate derived values", () => {
    // Arrange
    state.setData([mockData1, mockData2, mockData3]);

    // Assert
    expect(state.dataCount()).toBe(3);
    expect(state.hasData()).toBe(true);
  });

  it("should update when dependencies change", () => {
    // Arrange
    state.setData([]);
    expect(state.hasData()).toBe(false);

    // Act
    state.setData([mockData]);

    // Assert
    expect(state.hasData()).toBe(true);
  });
});
```

### 4. Páginas de Feature

#### Estrutura Padrão

```typescript
// app/features/budgets/pages/budget-list.page.spec.ts
import { ComponentFixture, TestBed } from "@angular/core/testing";
import { Router } from "@angular/router";
import { of } from "rxjs";

import { BudgetListPage } from "./budget-list.page";
import { BudgetService } from "../services/budget.service";
import { BudgetState } from "../state/budget.state";
import { BudgetResponseDto } from "@dtos/budget";
import { createMockBudgetDto } from "@test/factories/DtoFactory";

describe("BudgetListPage", () => {
  let component: BudgetListPage;
  let fixture: ComponentFixture<BudgetListPage>;
  let budgetService: jasmine.SpyObj<BudgetService>;
  let budgetState: jasmine.SpyObj<BudgetState>;
  let router: jasmine.SpyObj<Router>;

  beforeEach(async () => {
    const budgetServiceSpy = jasmine.createSpyObj("BudgetService", [
      "getBudgets",
    ]);
    const budgetStateSpy = jasmine.createSpyObj("BudgetState", [
      "budgets",
      "loading",
      "error",
    ]);
    const routerSpy = jasmine.createSpyObj("Router", ["navigate"]);

    await TestBed.configureTestingModule({
      imports: [BudgetListPage],
      providers: [
        { provide: BudgetService, useValue: budgetServiceSpy },
        { provide: BudgetState, useValue: budgetStateSpy },
        { provide: Router, useValue: routerSpy },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(BudgetListPage);
    component = fixture.componentInstance;
    budgetService = TestBed.inject(
      BudgetService
    ) as jasmine.SpyObj<BudgetService>;
    budgetState = TestBed.inject(BudgetState) as jasmine.SpyObj<BudgetState>;
    router = TestBed.inject(Router) as jasmine.SpyObj<Router>;
  });

  describe("page initialization", () => {
    it("should load data on page init", () => {
      // Arrange
      const mockBudgets: BudgetResponseDto[] = [createMockBudgetDto()];
      budgetService.getBudgets.and.returnValue(of(mockBudgets));
      budgetState.budgets = signal(mockBudgets);

      // Act
      component.ngOnInit();

      // Assert
      expect(budgetService.getBudgets).toHaveBeenCalled();
      expect(component.budgets()).toEqual(mockBudgets);
    });
  });

  describe("navigation", () => {
    it("should navigate to create budget page", () => {
      // Act
      component.navigateToCreate();

      // Assert
      expect(router.navigate).toHaveBeenCalledWith(["/budgets/create"]);
    });

    it("should navigate to budget details", () => {
      // Arrange
      const budget = createMockBudgetDto({ id: "budget-123" });

      // Act
      component.navigateToDetails(budget);

      // Assert
      expect(router.navigate).toHaveBeenCalledWith(["/budgets", "budget-123"]);
    });
  });
});
```

## Padrões de Mock e Factory

### 1. Factories para DTOs

```typescript
// test/factories/FeatureDtoFactory.ts
import { BudgetResponseDto, CreateBudgetRequestDto } from "@dtos/budget";
import {
  TransactionResponseDto,
  CreateTransactionRequestDto,
} from "@dtos/transaction";

export class BudgetDtoFactory {
  static create(overrides: Partial<BudgetResponseDto> = {}): BudgetResponseDto {
    return {
      id: "budget-123",
      name: "Test Budget",
      limitInCents: 500000,
      currentUsageInCents: 250000,
      participants: [],
      createdAt: "2024-01-15T10:00:00.000Z",
      updatedAt: "2024-01-15T10:00:00.000Z",
      ...overrides,
    };
  }

  static createList(count: number = 3): BudgetResponseDto[] {
    return Array.from({ length: count }, (_, index) =>
      BudgetDtoFactory.create({
        id: `budget-${index + 1}`,
        name: `Budget ${index + 1}`,
        limitInCents: 100000 * (index + 1),
      })
    );
  }

  static createCreateRequest(
    overrides: Partial<CreateBudgetRequestDto> = {}
  ): CreateBudgetRequestDto {
    return {
      name: "New Budget",
      limitInCents: 200000,
      description: "Test description",
      ...overrides,
    };
  }
}

export class TransactionDtoFactory {
  static create(
    overrides: Partial<TransactionResponseDto> = {}
  ): TransactionResponseDto {
    return {
      id: "transaction-123",
      accountId: "account-123",
      budgetId: "budget-123",
      amountInCents: 10000,
      description: "Test transaction",
      type: "EXPENSE",
      categoryId: "category-123",
      date: "2024-01-15T10:00:00.000Z",
      createdAt: "2024-01-15T10:00:00.000Z",
      updatedAt: "2024-01-15T10:00:00.000Z",
      ...overrides,
    };
  }

  static createList(count: number = 3): TransactionResponseDto[] {
    return Array.from({ length: count }, (_, index) =>
      TransactionDtoFactory.create({
        id: `transaction-${index + 1}`,
        description: `Transaction ${index + 1}`,
        amountInCents: 1000 * (index + 1),
      })
    );
  }
}
```

### 2. Mocks para Serviços de Feature

```typescript
// test/mocks/FeatureServiceMocks.ts
import { BudgetService } from "@features/budgets/services/budget.service";
import { TransactionService } from "@features/transactions/services/transaction.service";
import { BudgetState } from "@features/budgets/state/budget.state";
import { TransactionState } from "@features/transactions/state/transaction.state";

export function createMockBudgetService(): jasmine.SpyObj<BudgetService> {
  return jasmine.createSpyObj("BudgetService", [
    "getBudgets",
    "createBudget",
    "updateBudget",
    "deleteBudget",
    "getBudgetById",
  ]);
}

export function createMockTransactionService(): jasmine.SpyObj<TransactionService> {
  return jasmine.createSpyObj("TransactionService", [
    "getTransactions",
    "createTransaction",
    "updateTransaction",
    "deleteTransaction",
    "getTransactionById",
  ]);
}

export function createMockBudgetState(): jasmine.SpyObj<BudgetState> {
  return jasmine.createSpyObj("BudgetState", [
    "budgets",
    "loading",
    "error",
    "setBudgets",
    "setLoading",
    "setError",
    "totalBudgets",
    "totalBudgetAmount",
  ]);
}

export function createMockTransactionState(): jasmine.SpyObj<TransactionState> {
  return jasmine.createSpyObj("TransactionState", [
    "transactions",
    "loading",
    "error",
    "setTransactions",
    "setLoading",
    "setError",
    "totalTransactions",
    "totalAmount",
  ]);
}
```

### 3. Helpers para Testes de Feature

```typescript
// test/helpers/FeatureTestingHelpers.ts
import { ComponentFixture } from "@angular/core/testing";
import { By } from "@angular/platform-browser";

export class FeatureTestingHelpers {
  static expectLoadingState(fixture: ComponentFixture<any>): void {
    const loadingElement = fixture.debugElement.query(
      By.css('[data-testid="loading-skeleton"]')
    );
    expect(loadingElement).toBeTruthy();
  }

  static expectErrorState(
    fixture: ComponentFixture<any>,
    expectedMessage?: string
  ): void {
    const errorElement = fixture.debugElement.query(
      By.css('[data-testid="error-message"]')
    );
    expect(errorElement).toBeTruthy();

    if (expectedMessage) {
      expect(errorElement.nativeElement.textContent).toContain(expectedMessage);
    }
  }

  static expectDataDisplayed(
    fixture: ComponentFixture<any>,
    expectedCount: number
  ): void {
    const dataElements = fixture.debugElement.queryAll(
      By.css('[data-testid="data-item"]')
    );
    expect(dataElements.length).toBe(expectedCount);
  }

  static expectEmptyState(fixture: ComponentFixture<any>): void {
    const emptyElement = fixture.debugElement.query(
      By.css('[data-testid="empty-state"]')
    );
    expect(emptyElement).toBeTruthy();
  }
}
```

## Padrões de Teste de Integração entre Features

### 1. Comunicação via DTOs

```typescript
// test/integration/feature-communication.spec.ts
describe("Feature Communication", () => {
  let budgetService: jasmine.SpyObj<BudgetService>;
  let transactionService: jasmine.SpyObj<TransactionService>;
  let budgetState: jasmine.SpyObj<BudgetState>;
  let transactionState: jasmine.SpyObj<TransactionState>;

  beforeEach(() => {
    budgetService = createMockBudgetService();
    transactionService = createMockTransactionService();
    budgetState = createMockBudgetState();
    transactionState = createMockTransactionState();
  });

  describe("budget to transaction communication", () => {
    it("should update transaction list when budget is created", () => {
      // Arrange
      const budget = BudgetDtoFactory.create();
      const transactions = TransactionDtoFactory.createList(2);

      budgetService.createBudget.and.returnValue(of(budget));
      transactionService.getTransactions.and.returnValue(of(transactions));

      // Act
      budgetService
        .createBudget(BudgetDtoFactory.createCreateRequest())
        .subscribe();
      transactionService.getTransactions().subscribe();

      // Assert
      expect(transactionService.getTransactions).toHaveBeenCalled();
      expect(transactionState.setTransactions).toHaveBeenCalledWith(
        transactions
      );
    });
  });
});
```

### 2. Teste de Lazy Loading

```typescript
// test/integration/lazy-loading.spec.ts
describe("Lazy Loading", () => {
  it("should load feature module on demand", async () => {
    // Arrange
    const router = TestBed.inject(Router);
    const loader = TestBed.inject(NgModuleFactoryLoader);

    // Act
    await router.navigate(["/budgets"]);

    // Assert
    const moduleRef = await loader.load(
      "app/features/budgets/budgets.module#BudgetsModule"
    );
    expect(moduleRef).toBeTruthy();
  });
});
```

## Scripts de Teste por Feature

### package.json

```json
{
  "scripts": {
    "test": "ng test",
    "test:watch": "ng test --watch",
    "test:coverage": "ng test --code-coverage",
    "test:features": "ng test --include='**/features/**/*.spec.ts'",
    "test:shared": "ng test --include='**/shared/**/*.spec.ts'",
    "test:dtos": "ng test --include='**/dtos/**/*.spec.ts'",
    "test:state": "ng test --include='**/state/**/*.spec.ts'",
    "test:budgets": "ng test --include='**/features/budgets/**/*.spec.ts'",
    "test:transactions": "ng test --include='**/features/transactions/**/*.spec.ts'",
    "test:goals": "ng test --include='**/features/goals/**/*.spec.ts'",
    "test:integration": "ng test --include='**/integration/**/*.spec.ts'"
  }
}
```

## Boas Práticas

### DOs - Feature-Based Testing

✅ Testar cada feature como módulo isolado  
✅ Usar DTOs como contratos de comunicação  
✅ Mockar dependências entre features  
✅ Testar Angular Signals e reatividade  
✅ Validar lazy loading de features  
✅ Usar factories para criar dados de teste  
✅ Testar estados de loading, error e success  
✅ Validar navegação entre features

### DON'Ts - Feature-Based Testing

❌ Testar múltiplas features no mesmo teste  
❌ Acoplar features nos testes  
❌ Ignorar boundaries entre features  
❌ Testar implementação interna de signals  
❌ Hard-codear dados de teste  
❌ Ignorar estados de loading e error  
❌ Testar carregamento síncrono de features  
❌ Quebrar isolamento de features

---

**Ver também:**

- [Testing Strategy](./testing-strategy.md) - Estratégia geral de testes
- [Feature Organization](./feature-organization.md) - Organização de features
- [State Management](./state-management.md) - Gerenciamento de estado com Angular Signals
- [DTO Conventions](./dto-conventions.md) - Convenções para DTOs
