# Estratégia de Testes - DTO-First Architecture

---

**Metadados Estruturados para IA/RAG:**

```yaml
document_type: "technical_architecture"
domain: "frontend_architecture"
audience: ["frontend_developers", "qa_engineers", "tech_leads"]
complexity: "intermediate"
tags: ["testing_strategy", "dto_first", "frontend", "typescript"]
related_docs:
  ["dto-first-principles.md", "dto-conventions.md", "backend-integration.md"]
ai_context: "Comprehensive testing strategy for DTO-First Architecture frontend applications"
technologies: ["TypeScript", "Angular", "Jest", "MSW", "DTOs"]
patterns: ["DTO-First", "API-First", "Test-Driven Development"]
last_updated: "2025-01-24"
```

---

## Filosofia de Testes

- **DTO-First Testing**: Testes focados em DTOs como contratos principais
- **API Contract Testing**: Validação de contratos entre frontend e backend
- **Behavior-Focused**: Testes verificam comportamento, não implementação
- **Fast Feedback**: Testes unitários rápidos, integração quando necessário
- **Realistic Mocking**: MSW para mocks de API realistas

## Tipos de Teste por Camada

### 1. DTOs e Validações - 100% Testável

**Características:**

- **Pure Functions**: Sem dependências externas
- **Determinísticos**: Mesma entrada = mesma saída
- **Fast**: Execução instantânea
- **Isolation**: Cada teste independente

```typescript
// application/dtos/validators/CreateTransactionValidator.spec.ts
describe("CreateTransactionValidator", () => {
  describe("when validating transaction DTO", () => {
    it("should validate valid transaction DTO", () => {
      // Arrange
      const dto: CreateTransactionRequestDto = {
        accountId: "account-123",
        budgetId: "budget-456",
        amountInCents: 10000,
        description: "Grocery shopping",
        type: "EXPENSE",
        date: "2024-01-15T10:00:00.000Z",
      };

      // Act
      const result = CreateTransactionValidator.validate(dto);

      // Assert
      expect(result.hasError).toBe(false);
      expect(result.errors).toHaveLength(0);
    });

    it("should reject DTO with empty description", () => {
      // Arrange
      const dto: CreateTransactionRequestDto = {
        accountId: "account-123",
        budgetId: "budget-456",
        amountInCents: 10000,
        description: "",
        type: "EXPENSE",
        date: "2024-01-15T10:00:00.000Z",
      };

      // Act
      const result = CreateTransactionValidator.validate(dto);

      // Assert
      expect(result.hasError).toBe(true);
      expect(result.errors).toContain("Descrição é obrigatória");
    });

    it("should reject DTO with invalid amount", () => {
      // Arrange
      const dto: CreateTransactionRequestDto = {
        accountId: "account-123",
        budgetId: "budget-456",
        amountInCents: -100,
        description: "Invalid amount",
        type: "EXPENSE",
        date: "2024-01-15T10:00:00.000Z",
      };

      // Act
      const result = CreateTransactionValidator.validate(dto);

      // Assert
      expect(result.hasError).toBe(true);
      expect(result.errors).toContain("Valor deve ser maior que zero");
    });
  });

  describe("when validating money calculations", () => {
    it("should calculate percentage correctly", () => {
      // Test DTO-based calculations
      const budget: BudgetResponseDto = {
        id: "budget-123",
        name: "Test Budget",
        limitInCents: 100000,
        currentUsageInCents: 25000,
        participants: [],
        createdAt: "2024-01-15T10:00:00.000Z",
        updatedAt: "2024-01-15T10:00:00.000Z",
      };

      const usagePercentage =
        (budget.currentUsageInCents / budget.limitInCents) * 100;
      expect(usagePercentage).toBe(25);
    });

    it("should format money correctly", () => {
      const amountInCents = 1050; // R$ 10,50
      const formatted = MoneyFormatter.toDisplayString(amountInCents);
      expect(formatted).toBe("R$ 10,50");
    });
  });
});
```

### 2. Application (Use Cases e Queries) - DTO-First Testing

**Características:**

- **DTO-Based Testing**: Testes focados em DTOs como entrada e saída
- **API Contract Validation**: Verifica contratos com backend
- **Error Scenarios**: Valida tratamento de erros de API
- **Business Flows**: Testa orquestração de operações

```typescript
// application/use-cases/CreateTransactionUseCase.spec.ts
describe("CreateTransactionUseCase", () => {
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

  describe("when creating a valid transaction", () => {
    it("should create transaction successfully", async () => {
      // Arrange
      const requestDto: CreateTransactionRequestDto = {
        accountId: "account-123",
        budgetId: "budget-456",
        amountInCents: 10000,
        description: "Grocery shopping",
        type: "EXPENSE",
        date: "2024-01-15T10:00:00.000Z",
      };

      const mockAccount: AccountResponseDto = {
        id: "account-123",
        name: "Test Account",
        type: "CHECKING",
        balanceInCents: 50000,
        createdAt: "2024-01-01T00:00:00.000Z",
        updatedAt: "2024-01-01T00:00:00.000Z",
      };

      mockAccountService.getById.mockResolvedValue(Either.success(mockAccount));
      mockTransactionService.create.mockResolvedValue(
        Either.success(undefined)
      );

      // Act
      const result = await useCase.execute(requestDto);

      // Assert
      expect(result.hasError).toBe(false);
      expect(mockTransactionService.create).toHaveBeenCalledTimes(1);
      expect(mockTransactionService.create).toHaveBeenCalledWith(requestDto);
    });
  });

  describe("when account does not exist", () => {
    it("should return AccountNotFoundError", async () => {
      // Arrange
      const requestDto: CreateTransactionRequestDto = {
        accountId: "non-existent-account",
        budgetId: "budget-456",
        amountInCents: 10000,
        description: "Test transaction",
        type: "EXPENSE",
        date: "2024-01-15T10:00:00.000Z",
      };

      mockAccountService.getById.mockResolvedValue(
        Either.error(new AccountNotFoundError(requestDto.accountId))
      );

      // Act
      const result = await useCase.execute(requestDto);

      // Assert
      expect(result.hasError).toBe(true);
      expect(result.errors[0]).toBeInstanceOf(AccountNotFoundError);
      expect(mockTransactionService.create).not.toHaveBeenCalled();
    });
  });

  describe("when API returns validation error", () => {
    it("should handle API validation errors", async () => {
      // Arrange
      const requestDto: CreateTransactionRequestDto = {
        accountId: "account-123",
        budgetId: "budget-456",
        amountInCents: 10000,
        description: "Test transaction",
        type: "EXPENSE",
        date: "2024-01-15T10:00:00.000Z",
      };

      const mockAccount: AccountResponseDto = {
        id: "account-123",
        name: "Test Account",
        type: "CHECKING",
        balanceInCents: 50000,
        createdAt: "2024-01-01T00:00:00.000Z",
        updatedAt: "2024-01-01T00:00:00.000Z",
      };

      mockAccountService.getById.mockResolvedValue(Either.success(mockAccount));
      mockTransactionService.create.mockResolvedValue(
        Either.error(new ValidationError("Amount exceeds budget limit"))
      );

      // Act
      const result = await useCase.execute(requestDto);

      // Assert
      expect(result.hasError).toBe(true);
      expect(result.errors[0]).toBeInstanceOf(ValidationError);
      expect(result.errors[0].message).toBe("Amount exceeds budget limit");
    });
  });
});
```

### 3. Infrastructure (Adapters) - DTO Contract Testing

**Características:**

- **Real Dependencies**: Usa MSW para HTTP, IndexedDB para storage
- **DTO Contract Validation**: Testa se adapters respeitam contratos de DTO
- **Error Mapping**: Verifica conversão de erros de API para erros de aplicação
- **API Response Mapping**: Valida transformação de respostas da API para DTOs

```typescript
// infra/adapters/http/HttpBudgetServiceAdapter.integration.spec.ts
describe("HttpBudgetServiceAdapter Integration", () => {
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

  describe("create budget", () => {
    it("should create budget successfully", async () => {
      // Arrange
      const requestDto: CreateBudgetRequestDto = {
        name: "Test Budget",
        limitInCents: 500000,
        description: "Test description",
      };

      server.use(
        rest.post("/api/budget/create", (req, res, ctx) => {
          return res(ctx.status(204));
        })
      );

      // Act
      const result = await adapter.create(requestDto);

      // Assert
      expect(result.hasError).toBe(false);
    });

    it("should handle API validation errors", async () => {
      // Arrange
      const requestDto: CreateBudgetRequestDto = {
        name: "", // Invalid empty name
        limitInCents: 500000,
        description: "Test description",
      };

      server.use(
        rest.post("/api/budget/create", (req, res, ctx) => {
          return res(
            ctx.status(400),
            ctx.json({
              success: false,
              errors: [
                { code: "VALIDATION_ERROR", message: "Name is required" },
              ],
            })
          );
        })
      );

      // Act
      const result = await adapter.create(requestDto);

      // Assert
      expect(result.hasError).toBe(true);
      expect(result.errors[0]).toBeInstanceOf(ValidationError);
      expect(result.errors[0].message).toBe("Name is required");
    });

    it("should handle network errors", async () => {
      // Arrange
      const requestDto: CreateBudgetRequestDto = {
        name: "Test Budget",
        limitInCents: 500000,
        description: "Test description",
      };

      server.use(
        rest.post("/api/budget/create", (req, res) => {
          return res.networkError("Network error");
        })
      );

      // Act
      const result = await adapter.create(requestDto);

      // Assert
      expect(result.hasError).toBe(true);
      expect(result.errors[0]).toBeInstanceOf(NetworkError);
    });
  });

  describe("get budget", () => {
    it("should fetch and return DTO correctly", async () => {
      // Arrange
      const mockApiResponse: BudgetResponseDto = {
        id: "budget-123",
        name: "Home Budget",
        limitInCents: 500000,
        currentUsageInCents: 250000,
        participants: [
          {
            userId: "user-1",
            role: "ADMIN",
            joinedAt: "2024-01-15T10:00:00.000Z",
          },
          {
            userId: "user-2",
            role: "MEMBER",
            joinedAt: "2024-01-16T10:00:00.000Z",
          },
        ],
        createdAt: "2024-01-15T10:00:00.000Z",
        updatedAt: "2024-01-15T10:00:00.000Z",
      };

      server.use(
        rest.get("/api/budget/:id", (req, res, ctx) => {
          return res(ctx.json(mockApiResponse));
        })
      );

      // Act
      const result = await adapter.getById("budget-123");

      // Assert
      expect(result.hasError).toBe(false);

      const budget = result.data!;
      expect(budget).toEqual(mockApiResponse);
      expect(budget.id).toBe("budget-123");
      expect(budget.name).toBe("Home Budget");
      expect(budget.limitInCents).toBe(500000);
      expect(budget.participants).toHaveLength(2);
    });

    it("should handle API not found errors", async () => {
      // Arrange
      server.use(
        rest.get("/api/budget/:id", (req, res, ctx) => {
          return res(
            ctx.status(404),
            ctx.json({
              success: false,
              errors: [{ code: "NOT_FOUND", message: "Budget not found" }],
            })
          );
        })
      );

      // Act
      const result = await adapter.getById("non-existent-budget");

      // Assert
      expect(result.hasError).toBe(true);
      expect(result.errors[0]).toBeInstanceOf(NotFoundError);
      expect(result.errors[0].message).toBe("Budget not found");
    });
  });
});
```

### 4. UI (Angular Components) - DTO-Based Testing

**Características:**

- **DTO-Based State**: Testa estado reativo baseado em DTOs
- **Component Behavior**: Testa interação usuário → output
- **Template Rendering**: Verifica renderização condicional com DTOs
- **User Events**: Simula cliques, inputs, formulários

```typescript
// app/features/budgets/pages/budget-list.page.spec.ts
describe("BudgetListPage", () => {
  let component: BudgetListPage;
  let fixture: ComponentFixture<BudgetListPage>;
  let mockGetBudgetListUseCase: jest.Mocked<GetBudgetListUseCase>;

  beforeEach(async () => {
    mockGetBudgetListUseCase = createMockUseCase();

    await TestBed.configureTestingModule({
      imports: [BudgetListPage],
      providers: [
        { provide: GetBudgetListUseCase, useValue: mockGetBudgetListUseCase },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(BudgetListPage);
    component = fixture.componentInstance;
  });

  describe("when loading budgets", () => {
    it("should display loading state initially", async () => {
      // Arrange
      mockGetBudgetListUseCase.execute.mockImplementation(
        () => new Promise((resolve) => {}) // Never resolves - stays loading
      );

      // Act
      fixture.detectChanges();
      await fixture.whenStable();

      // Assert
      const loadingElement = fixture.debugElement.query(
        By.css("os-skeleton-list")
      );
      expect(loadingElement).toBeTruthy();
      expect(component.loading()).toBe(true);
    });

    it("should display budgets when loaded successfully", async () => {
      // Arrange
      const mockBudgetDtos: BudgetResponseDto[] = [
        {
          id: "budget-1",
          name: "Home Budget",
          limitInCents: 500000,
          currentUsageInCents: 250000,
          participants: [],
          createdAt: "2024-01-15T10:00:00.000Z",
          updatedAt: "2024-01-15T10:00:00.000Z",
        },
        {
          id: "budget-2",
          name: "Travel Fund",
          limitInCents: 1000000,
          currentUsageInCents: 750000,
          participants: [],
          createdAt: "2024-01-16T10:00:00.000Z",
          updatedAt: "2024-01-16T10:00:00.000Z",
        },
      ];

      mockGetBudgetListUseCase.execute.mockResolvedValue(
        Either.success(mockBudgetDtos)
      );

      // Act
      fixture.detectChanges();
      await fixture.whenStable();
      fixture.detectChanges();

      // Assert
      const budgetCards = fixture.debugElement.queryAll(
        By.css("os-budget-card")
      );
      expect(budgetCards.length).toBe(2);
      expect(component.budgets()).toEqual(mockBudgetDtos);
      expect(component.loading()).toBe(false);
    });

    it("should display error state when loading fails", async () => {
      // Arrange
      mockGetBudgetListUseCase.execute.mockResolvedValue(
        Either.error(new ServiceError("Failed to load budgets"))
      );

      // Act
      fixture.detectChanges();
      await fixture.whenStable();
      fixture.detectChanges();

      // Assert
      const errorElement = fixture.debugElement.query(By.css("os-error-state"));
      expect(errorElement).toBeTruthy();
      expect(component.error()).toBe("Failed to load budgets");
    });
  });

  describe("budget card interactions", () => {
    it("should display budget information correctly", async () => {
      // Arrange
      const mockBudget: BudgetResponseDto = {
        id: "budget-123",
        name: "Test Budget",
        limitInCents: 100000,
        currentUsageInCents: 30000,
        participants: [
          {
            userId: "user-1",
            role: "ADMIN",
            joinedAt: "2024-01-15T10:00:00.000Z",
          },
        ],
        createdAt: "2024-01-15T10:00:00.000Z",
        updatedAt: "2024-01-15T10:00:00.000Z",
      };

      mockGetBudgetListUseCase.execute.mockResolvedValue(
        Either.success([mockBudget])
      );

      // Act
      fixture.detectChanges();
      await fixture.whenStable();
      fixture.detectChanges();

      // Assert
      const budgetCard = fixture.debugElement.query(By.css("os-budget-card"));
      expect(budgetCard.componentInstance.budget()).toEqual(mockBudget);

      // Test computed properties
      const usagePercentage =
        (mockBudget.currentUsageInCents / mockBudget.limitInCents) * 100;
      expect(usagePercentage).toBe(30);
    });

    it("should navigate to budget details when card is clicked", async () => {
      // Arrange
      const mockBudget: BudgetResponseDto = {
        id: "budget-123",
        name: "Test Budget",
        limitInCents: 100000,
        currentUsageInCents: 30000,
        participants: [],
        createdAt: "2024-01-15T10:00:00.000Z",
        updatedAt: "2024-01-15T10:00:00.000Z",
      };
      const routerSpy = jest.spyOn(TestBed.inject(Router), "navigate");

      mockGetBudgetListUseCase.execute.mockResolvedValue(
        Either.success([mockBudget])
      );

      // Act
      fixture.detectChanges();
      await fixture.whenStable();
      fixture.detectChanges();

      const budgetCard = fixture.debugElement.query(By.css("os-budget-card"));
      budgetCard.triggerEventHandler("onClick", mockBudget);

      // Assert
      expect(routerSpy).toHaveBeenCalledWith(["/budgets", "budget-123"]);
    });
  });

  describe("create budget form", () => {
    it("should create budget with valid DTO", async () => {
      // Arrange
      const createBudgetDto: CreateBudgetRequestDto = {
        name: "New Budget",
        limitInCents: 200000,
        description: "Test description",
      };

      const mockCreateUseCase = createMockCreateBudgetUseCase();
      mockCreateUseCase.execute.mockResolvedValue(Either.success(undefined));

      // Act
      component.createBudget(createBudgetDto);

      // Assert
      expect(mockCreateUseCase.execute).toHaveBeenCalledWith(createBudgetDto);
    });
  });
});
```

### 5. UI Components (Design System) - DTO-Aware Testing

```typescript
// app/shared/ui-components/atoms/os-budget-card/os-budget-card.component.spec.ts
describe("OsBudgetCardComponent", () => {
  let component: OsBudgetCardComponent;
  let fixture: ComponentFixture<OsBudgetCardComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [OsBudgetCardComponent],
    }).compileComponents();

    fixture = TestBed.createComponent(OsBudgetCardComponent);
    component = fixture.componentInstance;
  });

  describe("budget DTO display", () => {
    it("should display budget information correctly", () => {
      // Arrange
      const budgetDto: BudgetResponseDto = {
        id: "budget-123",
        name: "Test Budget",
        limitInCents: 100000,
        currentUsageInCents: 30000,
        participants: [
          {
            userId: "user-1",
            role: "ADMIN",
            joinedAt: "2024-01-15T10:00:00.000Z",
          },
        ],
        createdAt: "2024-01-15T10:00:00.000Z",
        updatedAt: "2024-01-15T10:00:00.000Z",
      };

      fixture.componentRef.setInput("budget", budgetDto);

      // Act
      fixture.detectChanges();

      // Assert
      const nameElement = fixture.debugElement.query(
        By.css('[data-testid="budget-name"]')
      );
      const limitElement = fixture.debugElement.query(
        By.css('[data-testid="budget-limit"]')
      );
      const usageElement = fixture.debugElement.query(
        By.css('[data-testid="budget-usage"]')
      );

      expect(nameElement.nativeElement.textContent).toBe("Test Budget");
      expect(limitElement.nativeElement.textContent).toContain("R$ 1.000,00");
      expect(usageElement.nativeElement.textContent).toContain("R$ 300,00");
    });

    it("should calculate usage percentage correctly", () => {
      // Arrange
      const budgetDto: BudgetResponseDto = {
        id: "budget-123",
        name: "Test Budget",
        limitInCents: 100000,
        currentUsageInCents: 25000,
        participants: [],
        createdAt: "2024-01-15T10:00:00.000Z",
        updatedAt: "2024-01-15T10:00:00.000Z",
      };

      fixture.componentRef.setInput("budget", budgetDto);

      // Act
      fixture.detectChanges();

      // Assert
      const percentageElement = fixture.debugElement.query(
        By.css('[data-testid="usage-percentage"]')
      );
      expect(percentageElement.nativeElement.textContent).toContain("25%");
    });

    it("should display participant count correctly", () => {
      // Arrange
      const budgetDto: BudgetResponseDto = {
        id: "budget-123",
        name: "Test Budget",
        limitInCents: 100000,
        currentUsageInCents: 30000,
        participants: [
          {
            userId: "user-1",
            role: "ADMIN",
            joinedAt: "2024-01-15T10:00:00.000Z",
          },
          {
            userId: "user-2",
            role: "MEMBER",
            joinedAt: "2024-01-16T10:00:00.000Z",
          },
        ],
        createdAt: "2024-01-15T10:00:00.000Z",
        updatedAt: "2024-01-15T10:00:00.000Z",
      };

      fixture.componentRef.setInput("budget", budgetDto);

      // Act
      fixture.detectChanges();

      // Assert
      const participantElement = fixture.debugElement.query(
        By.css('[data-testid="participant-count"]')
      );
      expect(participantElement.nativeElement.textContent).toContain(
        "2 participantes"
      );
    });
  });

  describe("interactions", () => {
    it("should emit onClick with budget DTO when clicked", () => {
      // Arrange
      const budgetDto: BudgetResponseDto = {
        id: "budget-123",
        name: "Test Budget",
        limitInCents: 100000,
        currentUsageInCents: 30000,
        participants: [],
        createdAt: "2024-01-15T10:00:00.000Z",
        updatedAt: "2024-01-15T10:00:00.000Z",
      };

      fixture.componentRef.setInput("budget", budgetDto);
      const onClickSpy = jest.fn();
      fixture.componentRef.instance.onClick.subscribe(onClickSpy);

      // Act
      fixture.detectChanges();
      const card = fixture.debugElement.query(
        By.css('[data-testid="budget-card"]')
      );
      card.nativeElement.click();

      // Assert
      expect(onClickSpy).toHaveBeenCalledTimes(1);
      expect(onClickSpy).toHaveBeenCalledWith(budgetDto);
    });

    it("should not emit onClick when disabled", () => {
      // Arrange
      const budgetDto: BudgetResponseDto = {
        id: "budget-123",
        name: "Test Budget",
        limitInCents: 100000,
        currentUsageInCents: 30000,
        participants: [],
        createdAt: "2024-01-15T10:00:00.000Z",
        updatedAt: "2024-01-15T10:00:00.000Z",
      };

      fixture.componentRef.setInput("budget", budgetDto);
      fixture.componentRef.setInput("disabled", true);
      const onClickSpy = jest.fn();
      fixture.componentRef.instance.onClick.subscribe(onClickSpy);

      // Act
      fixture.detectChanges();
      const card = fixture.debugElement.query(
        By.css('[data-testid="budget-card"]')
      );
      card.nativeElement.click();

      // Assert
      expect(onClickSpy).not.toHaveBeenCalled();
    });
  });
});
```

## Mock Service Worker (MSW) Setup - DTO-First

### Browser Setup para Desenvolvimento

```typescript
// mocks/browser.ts
import { setupWorker } from "msw/browser";
import { handlers } from "./handlers";

export const worker = setupWorker(...handlers);
```

### Test Setup para Karma

```typescript
// src/test-setup.ts
import { setupServer } from "msw/node";
import { handlers } from "./mocks/handlers";

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

### Handlers por Contexto - DTO-Based

```typescript
// mocks/context/budgetHandlers.ts
import { http, HttpResponse } from "msw";
import { CreateBudgetRequestDto, BudgetResponseDto } from "@dtos/budget";

export const budgetHandlers = [
  // Create budget
  http.post("/api/budget/create", async ({ request }) => {
    const body: CreateBudgetRequestDto = await request.json();

    // Simulate validation
    if (!body.name) {
      return HttpResponse.json(
        {
          success: false,
          errors: [{ code: "VALIDATION_ERROR", message: "Name is required" }],
        },
        { status: 400 }
      );
    }

    return new HttpResponse(null, { status: 204 });
  }),

  // Get budget
  http.get("/api/budget/:id", ({ params }) => {
    const { id } = params;

    if (id === "not-found") {
      return HttpResponse.json(
        {
          success: false,
          errors: [{ code: "NOT_FOUND", message: "Budget not found" }],
        },
        { status: 404 }
      );
    }

    const budgetResponse: BudgetResponseDto = {
      id: id as string,
      name: "Mock Budget",
      limitInCents: 500000,
      currentUsageInCents: 250000,
      participants: [
        {
          userId: "user-1",
          role: "ADMIN",
          joinedAt: "2024-01-15T10:00:00.000Z",
        },
      ],
      createdAt: "2024-01-15T10:00:00.000Z",
      updatedAt: "2024-01-15T10:00:00.000Z",
    };

    return HttpResponse.json(budgetResponse);
  }),

  // Get budget list
  http.get("/api/budgets", ({ request }) => {
    const url = new URL(request.url);
    const page = parseInt(url.searchParams.get("page") || "1");
    const pageSize = parseInt(url.searchParams.get("pageSize") || "10");

    const budgets: BudgetResponseDto[] = Array.from(
      { length: pageSize },
      (_, i) => ({
        id: `budget-${page}-${i}`,
        name: `Mock Budget ${page}-${i}`,
        limitInCents: 500000,
        currentUsageInCents: 250000,
        participants: [],
        createdAt: "2024-01-15T10:00:00.000Z",
        updatedAt: "2024-01-15T10:00:00.000Z",
      })
    );

    return HttpResponse.json({
      budgets,
      total: 50,
      page,
      pageSize,
      totalPages: 5,
    });
  }),

  // Get budget summary
  http.get("/api/budget/:id/summary", ({ params, request }) => {
    const url = new URL(request.url);
    const period = url.searchParams.get("period") || "current_month";

    return HttpResponse.json({
      budgetId: params.id,
      budgetName: "Mock Budget",
      limitInCents: 500000,
      totalSpentInCents: 350000,
      remainingInCents: 150000,
      usagePercentage: 70,
      transactionCount: 25,
      period: period,
    });
  }),
];
```

## Test Utilities e Helpers - DTO-First

### DTO Mock Factories

```typescript
// test/factories/DtoFactory.ts
import {
  BudgetResponseDto,
  CreateBudgetRequestDto,
  TransactionResponseDto,
  CreateTransactionRequestDto,
} from "@dtos";

export function createMockBudgetDto(
  overrides: Partial<BudgetResponseDto> = {}
): BudgetResponseDto {
  return {
    id: "budget-123",
    name: "Test Budget",
    limitInCents: 500000,
    currentUsageInCents: 250000,
    participants: [
      {
        userId: "user-1",
        role: "ADMIN",
        joinedAt: "2024-01-15T10:00:00.000Z",
      },
    ],
    createdAt: "2024-01-15T10:00:00.000Z",
    updatedAt: "2024-01-15T10:00:00.000Z",
    ...overrides,
  };
}

export function createMockCreateBudgetDto(
  overrides: Partial<CreateBudgetRequestDto> = {}
): CreateBudgetRequestDto {
  return {
    name: "Test Budget",
    limitInCents: 500000,
    description: "Test description",
    ...overrides,
  };
}

export function createMockTransactionDto(
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

export function createMockCreateTransactionDto(
  overrides: Partial<CreateTransactionRequestDto> = {}
): CreateTransactionRequestDto {
  return {
    accountId: "account-123",
    budgetId: "budget-123",
    amountInCents: 10000,
    description: "Test transaction",
    type: "EXPENSE",
    categoryId: "category-123",
    date: "2024-01-15T10:00:00.000Z",
    ...overrides,
  };
}
```

### Mock Services

```typescript
// test/mocks/createMockBudgetService.ts
export function createMockBudgetService(): jest.Mocked<IBudgetServicePort> {
  return {
    create: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
    getById: jest.fn(),
    getList: jest.fn(),
    getSummary: jest.fn(),
  };
}

export function createMockTransactionService(): jest.Mocked<ITransactionServicePort> {
  return {
    create: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
    getById: jest.fn(),
    getByBudget: jest.fn(),
    getByAccount: jest.fn(),
  };
}
```

### DTO Test Data Builders

```typescript
// test/builders/BudgetDtoBuilder.ts
export class BudgetDtoBuilder {
  private dto: Partial<BudgetResponseDto> = {};

  withId(id: string): this {
    this.dto.id = id;
    return this;
  }

  withName(name: string): this {
    this.dto.name = name;
    return this;
  }

  withLimitInCents(limitInCents: number): this {
    this.dto.limitInCents = limitInCents;
    return this;
  }

  withCurrentUsageInCents(currentUsageInCents: number): this {
    this.dto.currentUsageInCents = currentUsageInCents;
    return this;
  }

  withParticipants(participants: BudgetParticipantDto[]): this {
    this.dto.participants = participants;
    return this;
  }

  build(): BudgetResponseDto {
    return createMockBudgetDto(this.dto);
  }
}

// test/builders/TransactionDtoBuilder.ts
export class TransactionDtoBuilder {
  private dto: Partial<CreateTransactionRequestDto> = {};

  withDescription(description: string): this {
    this.dto.description = description;
    return this;
  }

  withAmountInCents(amountInCents: number): this {
    this.dto.amountInCents = amountInCents;
    return this;
  }

  withAccount(accountId: string): this {
    this.dto.accountId = accountId;
    return this;
  }

  withBudget(budgetId: string): this {
    this.dto.budgetId = budgetId;
    return this;
  }

  asIncome(): this {
    this.dto.type = "INCOME";
    return this;
  }

  asExpense(): this {
    this.dto.type = "EXPENSE";
    return this;
  }

  build(): CreateTransactionRequestDto {
    return createMockCreateTransactionDto(this.dto);
  }
}

// Usage examples
const budgetDto = new BudgetDtoBuilder()
  .withName("Grocery Budget")
  .withLimitInCents(100000)
  .withCurrentUsageInCents(30000)
  .build();

const transactionDto = new TransactionDtoBuilder()
  .withDescription("Grocery shopping")
  .withAmountInCents(8500)
  .asExpense()
  .withAccount("account-123")
  .withBudget("budget-456")
  .build();
```

### DTO Validation Helpers

```typescript
// test/helpers/dtoValidationHelpers.ts
export function expectValidDto<T>(dto: T, expectedShape: Partial<T>): void {
  Object.keys(expectedShape).forEach((key) => {
    expect(dto).toHaveProperty(key);
    expect(dto[key as keyof T]).toEqual(expectedShape[key]);
  });
}

export function expectValidBudgetDto(dto: BudgetResponseDto): void {
  expect(dto).toHaveProperty("id");
  expect(dto).toHaveProperty("name");
  expect(dto).toHaveProperty("limitInCents");
  expect(dto).toHaveProperty("currentUsageInCents");
  expect(dto).toHaveProperty("participants");
  expect(dto).toHaveProperty("createdAt");
  expect(dto).toHaveProperty("updatedAt");

  expect(typeof dto.id).toBe("string");
  expect(typeof dto.name).toBe("string");
  expect(typeof dto.limitInCents).toBe("number");
  expect(typeof dto.currentUsageInCents).toBe("number");
  expect(Array.isArray(dto.participants)).toBe(true);
  expect(typeof dto.createdAt).toBe("string");
  expect(typeof dto.updatedAt).toBe("string");
}

export function expectValidCreateBudgetDto(dto: CreateBudgetRequestDto): void {
  expect(dto).toHaveProperty("name");
  expect(dto).toHaveProperty("limitInCents");

  expect(typeof dto.name).toBe("string");
  expect(typeof dto.limitInCents).toBe("number");
  expect(dto.name.length).toBeGreaterThan(0);
  expect(dto.limitInCents).toBeGreaterThan(0);
}
```

## Coverage e Qualidade - DTO-First

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
            'src/application/dtos/**/*': {
              statements: 95,
              branches: 90,
              functions: 95,
              lines: 95
            },
            'src/application/validators/**/*': {
              statements: 90,
              branches: 85,
              functions: 90,
              lines: 90
            },
            'src/application/use-cases/**/*': {
              statements: 85,
              branches: 80,
              functions: 85,
              lines: 85
            },
            'src/infrastructure/adapters/**/*': {
              statements: 80,
              branches: 75,
              functions: 80,
              lines: 80
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
    "test:debug": "ng test --source-map=false",
    "test:dto": "ng test --include='**/*dto*.spec.ts'",
    "test:contract": "ng test --include='**/*contract*.spec.ts'"
  }
}
```

### DTO-Specific Testing Guidelines

#### 1. DTO Validation Testing

- **100% Coverage**: Todos os validadores de DTO devem ter cobertura completa
- **Edge Cases**: Testar valores limite, tipos inválidos, campos obrigatórios
- **Error Messages**: Validar mensagens de erro específicas e claras

#### 2. API Contract Testing

- **Request DTOs**: Validar estrutura e tipos de dados enviados
- **Response DTOs**: Validar estrutura e tipos de dados recebidos
- **Error Responses**: Validar mapeamento de erros de API para DTOs

#### 3. Component DTO Integration

- **Data Binding**: Testar binding de DTOs em componentes
- **Computed Properties**: Testar cálculos baseados em DTOs
- **User Interactions**: Testar interações que modificam DTOs

### Test Organization

```
src/
  application/
    dtos/
      validators/
        - CreateBudgetValidator.spec.ts
        - CreateTransactionValidator.spec.ts
    use-cases/
      - CreateBudgetUseCase.spec.ts
      - GetBudgetListUseCase.spec.ts
  infrastructure/
    adapters/
      - HttpBudgetServiceAdapter.integration.spec.ts
  app/
    features/
      budgets/
        pages/
          - budget-list.page.spec.ts
        components/
          - budget-card.component.spec.ts
  test/
    factories/
      - DtoFactory.ts
    builders/
      - BudgetDtoBuilder.ts
      - TransactionDtoBuilder.ts
    helpers/
      - dtoValidationHelpers.ts
```

---

**Ver também:**

- [DTO-First Principles](./dto-first-principles.md) - Princípios fundamentais da arquitetura
- [DTO Conventions](./dto-conventions.md) - Convenções para DTOs
- [MSW Configuration](./msw-configuration.md) - Configuração detalhada do Mock Service Worker
- [Backend Integration](./backend-integration.md) - Integração com APIs
