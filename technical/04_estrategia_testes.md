# Estratégia de Testes - OrcaSonhos

## Visão Geral

Esta estratégia define as práticas, ferramentas e processos de teste para garantir qualidade, confiabilidade e manutenibilidade da aplicação OrcaSonhos, com foco especial nos padrões DDD e Clean Architecture implementados no backend e na **Feature-Based Architecture** adotada no frontend.

## Objetivos

- **Cobertura mínima**: 80% do código base
- **Cobertura crítica**: 100% para agregados e use cases de domínio
- **Confiabilidade**: Detectar regressões antes da produção
- **Velocidade**: Feedback rápido durante desenvolvimento
- **Manutenibilidade**: Testes fáceis de entender e manter
- **Arquitetura**: Validar integridade dos padrões DDD/Clean Architecture
- **Features**: Garantir isolamento e testabilidade de cada feature do frontend
- **DTO-First**: Validar contratos de API e transformações de dados

## Tipos de Testes

### 1. Testes Unitários

**Escopo**: Agregados, Value Objects, Use Cases, Domain Services isolados

**Ferramentas**:

- **Frontend**: Vitest
- **Backend**: Jest com TypeScript

**Estratégia**:

- Testar invariantes de domínio nos agregados
- Validar comportamentos de use cases
- Mockar repositórios e dependências externas
- Testar padrão Either para tratamento de erros
- 100% cobertura para camada de domínio

**Estrutura de arquivos**:

```
src/
├── domain/
│   ├── aggregates/
│   │   ├── account/
│   │   │   ├── account.ts
│   │   │   └── account.spec.ts
│   ├── shared/
│   │   ├── value-objects/
│   │   │   ├── money-vo.ts
│   │   │   └── money-vo.spec.ts
├── application/
│   ├── use-cases/
│   │   ├── create-account/
│   │   │   ├── create-account.use-case.ts
│   │   │   └── create-account.use-case.spec.ts
├── components/
│   ├── user-profile/
│   │   ├── user-profile.component.ts
│   │   └── user-profile.component.spec.ts
```

### 2. Testes de Features (Frontend)

**Escopo**: Módulos de funcionalidades isolados na Feature-Based Architecture

**Ferramentas**:

- **Angular Testing**: Vitest + Angular Testing Utilities
- **MSW**: Mock Service Worker para APIs
- **Angular Signals**: Testes de estado reativo

**Estratégia**:

- Testar cada feature como módulo independente
- Validar comunicação entre features via DTOs
- Mockar dependências externas (APIs, outros features)
- Testar lazy loading e roteamento
- Validar transformações DTO ↔ ViewModel

**Estrutura de arquivos**:

```
src/app/features/
├── /budgets/
│   ├── /components/
│   │   ├── budget-list.component.ts
│   │   ├── budget-list.component.spec.ts
│   │   ├── budget-form.component.ts
│   │   └── budget-form.component.spec.ts
│   ├── /services/
│   │   ├── budget.service.ts
│   │   └── budget.service.spec.ts
│   ├── /state/
│   │   ├── budget.state.ts
│   │   └── budget.state.spec.ts
│   └── /budgets.module.ts
├── /transactions/
│   ├── /components/
│   ├── /services/
│   ├── /state/
│   └── /transactions.module.ts
```

**Padrões de teste por feature**:

- **Componentes**: Comportamento e integração com serviços
- **Serviços**: Lógica de negócio e comunicação com APIs
- **Estado**: Angular Signals e reatividade
- **DTOs**: Transformações e validações
- **Roteamento**: Navegação e lazy loading

### 3. Testes de Componentes Shared

**Escopo**: Design System e utilitários compartilhados

**Estratégia**:

- Testes unitários de componentes UI
- Testes de acessibilidade
- Testes de responsividade
- Validação de integração com Angular Material

**Componentes críticos**:

- Atoms (botões, inputs, labels)
- Molecules (formulários, cards)
- Organisms (navegação, layouts)
- Pipes e Directives customizados

### 4. Testes End-to-End (E2E)

**Escopo**: Fluxos completos de usuário

**Ferramenta**: Playwright

**Estratégia**:

- Cenários críticos de negócio
- Fluxos principais de usuário
- Validação de integração frontend/backend
- Testes cross-browser principais

**Cenários prioritários**:

- Cadastro e autenticação de usuário
- Navegação principal da aplicação
- Fluxos de criação/edição de dados
- Funcionalidades PWA/offline

## Configuração Offline/PWA

### Service Worker e Cache

```typescript
// Testes específicos para PWA
describe("PWA Functionality", () => {
  it("should cache critical resources", async () => {
    // Simular offline
    await page.setOfflineMode(true);
    // Verificar funcionamento básico
  });
});
```

### Sincronização de Dados

```typescript
// Testes de sincronização IndexedDB
describe("Offline Sync", () => {
  it("should sync data when connection restored", async () => {
    // Simular dados offline
    // Restaurar conexão
    // Verificar sincronização
  });
});
```

## Padrões de Teste por Camada

### 1. Testes de Features (Frontend - Feature-Based)

**Estrutura para Componentes de Feature**:

```typescript
describe("BudgetListComponent", () => {
  let component: BudgetListComponent;
  let fixture: ComponentFixture<BudgetListComponent>;
  let budgetService: any;
  let budgetState: any;

  beforeEach(async () => {
    const budgetServiceSpy = {
      getBudgets: vi.fn(),
      createBudget: vi.fn(),
    };
    const budgetStateSpy = {
      budgets: vi.fn(),
      loading: vi.fn(),
      error: vi.fn(),
    };

    await TestBed.configureTestingModule({
      imports: [BudgetListComponent],
      providers: [
        { provide: BudgetService, useValue: budgetServiceSpy },
        { provide: BudgetState, useValue: budgetStateSpy },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(BudgetListComponent);
    component = fixture.componentInstance;
    budgetService = TestBed.inject(BudgetService);
    budgetState = TestBed.inject(BudgetState);
  });

  describe("ngOnInit", () => {
    it("should load budgets on init", () => {
      // Arrange
      const mockBudgets: BudgetDto[] = [BudgetDtoFactory.create()];
      budgetService.getBudgets.mockReturnValue(of(mockBudgets));
      budgetState.budgets = signal(mockBudgets);

      // Act
      component.ngOnInit();

      // Assert
      expect(budgetService.getBudgets).toHaveBeenCalled();
      expect(component.budgets()).toEqual(mockBudgets);
    });
  });

  describe("createBudget", () => {
    it("should create budget and refresh list", () => {
      // Arrange
      const newBudget = CreateBudgetDtoFactory.create();
      const createdBudget = BudgetDtoFactory.create();
      budgetService.createBudget.and.returnValue(of(createdBudget));
      budgetService.getBudgets.and.returnValue(of([createdBudget]));

      // Act
      component.createBudget(newBudget);

      // Assert
      expect(budgetService.createBudget).toHaveBeenCalledWith(newBudget);
      expect(budgetService.getBudgets).toHaveBeenCalled();
    });
  });
});
```

**Estrutura para Serviços de Feature**:

```typescript
describe("BudgetService", () => {
  let service: BudgetService;
  let httpClient: any;
  let budgetState: any;

  beforeEach(() => {
    const httpClientSpy = {
      get: vi.fn(),
      post: vi.fn(),
      put: vi.fn(),
      delete: vi.fn(),
    };
    const budgetStateSpy = {
      setBudgets: vi.fn(),
      setLoading: vi.fn(),
      setError: vi.fn(),
    };

    TestBed.configureTestingModule({
      providers: [
        BudgetService,
        { provide: HttpClient, useValue: httpClientSpy },
        { provide: BudgetState, useValue: budgetStateSpy },
      ],
    });

    service = TestBed.inject(BudgetService);
    httpClient = TestBed.inject(HttpClient);
    budgetState = TestBed.inject(BudgetState);
  });

  describe("getBudgets", () => {
    it("should fetch budgets and update state", () => {
      // Arrange
      const mockBudgets: BudgetDto[] = [BudgetDtoFactory.create()];
      httpClient.get.mockReturnValue(of(mockBudgets));

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
      httpClient.get.mockReturnValue(throwError(() => error));

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
});
```

**Estrutura para Estado com Angular Signals**:

```typescript
describe("BudgetState", () => {
  let state: BudgetState;

  beforeEach(() => {
    state = new BudgetState();
  });

  describe("budgets signal", () => {
    it("should initialize with empty array", () => {
      // Assert
      expect(state.budgets()).toEqual([]);
    });

    it("should update budgets when setBudgets is called", () => {
      // Arrange
      const mockBudgets: BudgetDto[] = [BudgetDtoFactory.create()];

      // Act
      state.setBudgets(mockBudgets);

      // Assert
      expect(state.budgets()).toEqual(mockBudgets);
    });
  });

  describe("loading signal", () => {
    it("should initialize as false", () => {
      // Assert
      expect(state.loading()).toBe(false);
    });

    it("should update loading state", () => {
      // Act
      state.setLoading(true);

      // Assert
      expect(state.loading()).toBe(true);
    });
  });
});
```

**Estrutura para Testes de DTOs**:

```typescript
describe("BudgetDto", () => {
  describe("create", () => {
    it("should create valid budget DTO", () => {
      // Arrange
      const budgetData = {
        id: "budget-123",
        name: "Orçamento Mensal",
        amount: 5000,
        startDate: "2024-01-01",
        endDate: "2024-01-31",
      };

      // Act
      const result = BudgetDto.create(budgetData);

      // Assert
      expect(result.isRight()).toBe(true);
      const budget = result.value as BudgetDto;
      expect(budget.id).toBe("budget-123");
      expect(budget.name).toBe("Orçamento Mensal");
    });

    it("should fail with invalid data", () => {
      // Arrange
      const invalidData = {
        id: "",
        name: "",
        amount: -100,
        startDate: "invalid-date",
        endDate: "2024-01-01",
      };

      // Act
      const result = BudgetDto.create(invalidData);

      // Assert
      expect(result.isLeft()).toBe(true);
      expect(result.value).toBeInstanceOf(ValidationError);
    });
  });

  describe("toViewModel", () => {
    it("should convert DTO to ViewModel", () => {
      // Arrange
      const budgetDto = BudgetDtoFactory.create();
      const expectedViewModel = {
        id: budgetDto.id,
        name: budgetDto.name,
        amount: budgetDto.amount,
        formattedAmount: `R$ ${budgetDto.amount.toFixed(2)}`,
        period: `${budgetDto.startDate} - ${budgetDto.endDate}`,
      };

      // Act
      const viewModel = budgetDto.toViewModel();

      // Assert
      expect(viewModel).toEqual(expectedViewModel);
    });
  });
});
```

### 2. Testes de Agregados (Domain)

**Estrutura**:

```typescript
describe("Account Aggregate", () => {
  describe("constructor validations", () => {
    it("should create valid account", () => {
      // Arrange
      const accountData = {
        name: "Conta Corrente",
        type: AccountType.CHECKING,
      };

      // Act
      const result = Account.create(accountData);

      // Assert
      expect(result.isRight()).toBe(true);
      const account = result.value as Account;
      expect(account.name.value).toBe("Conta Corrente");
    });

    it("should fail with invalid name", () => {
      // Arrange
      const accountData = { name: "", type: AccountType.CHECKING };

      // Act
      const result = Account.create(accountData);

      // Assert
      expect(result.isLeft()).toBe(true);
      expect(result.value).toBeInstanceOf(ValidationError);
    });
  });

  describe("business rules", () => {
    it("should debit successfully with sufficient balance", () => {
      // Arrange
      const account = AccountFactory.createWithBalance(100);
      const debitAmount = MoneyVo.create(50).value as MoneyVo;

      // Act
      const result = account.debit(debitAmount);

      // Assert
      expect(result.isRight()).toBe(true);
      expect(account.balance.value).toBe(50);
    });

    it("should fail debit with insufficient balance", () => {
      // Arrange
      const account = AccountFactory.createWithBalance(30);
      const debitAmount = MoneyVo.create(50).value as MoneyVo;

      // Act
      const result = account.debit(debitAmount);

      // Assert
      expect(result.isLeft()).toBe(true);
      expect(result.value).toBeInstanceOf(InsufficientBalanceError);
    });
  });
});
```

### 2. Testes de Use Cases (Application)

**Estrutura**:

```typescript
describe("CreateAccountUseCase", () => {
  let useCase: CreateAccountUseCase;
  let mockAccountRepo: jest.Mocked<IAccountRepository>;
  let mockBudgetRepo: jest.Mocked<IBudgetRepository>;

  beforeEach(() => {
    mockAccountRepo = createMockAccountRepository();
    mockBudgetRepo = createMockBudgetRepository();
    useCase = new CreateAccountUseCase(mockAccountRepo, mockBudgetRepo);
  });

  describe("execute", () => {
    it("should create account successfully", async () => {
      // Arrange
      const request = CreateAccountRequestFactory.create();
      mockAccountRepo.save.mockResolvedValue(right(undefined));

      // Act
      const result = await useCase.execute(request);

      // Assert
      expect(result.isRight()).toBe(true);
      expect(mockAccountRepo.save).toHaveBeenCalledTimes(1);
      const savedAccount = mockAccountRepo.save.mock.calls[0][0];
      expect(savedAccount.name.value).toBe(request.name);
    });

    it("should fail when repository throws error", async () => {
      // Arrange
      const request = CreateAccountRequestFactory.create();
      mockAccountRepo.save.mockResolvedValue(left(new RepositoryError()));

      // Act
      const result = await useCase.execute(request);

      // Assert
      expect(result.isLeft()).toBe(true);
      expect(result.value).toBeInstanceOf(RepositoryError);
    });
  });
});
```

### 3. Testes de Value Objects

**Estrutura**:

```typescript
describe("MoneyVo", () => {
  describe("create", () => {
    it("should create valid money value", () => {
      // Act
      const result = MoneyVo.create(100.5);

      // Assert
      expect(result.isRight()).toBe(true);
      const money = result.value as MoneyVo;
      expect(money.value).toBe(100.5);
    });

    it("should fail with negative value", () => {
      // Act
      const result = MoneyVo.create(-10);

      // Assert
      expect(result.isLeft()).toBe(true);
      expect(result.value).toBeInstanceOf(InvalidMoneyError);
    });
  });

  describe("operations", () => {
    it("should add money values correctly", () => {
      // Arrange
      const money1 = MoneyVo.create(100).value as MoneyVo;
      const money2 = MoneyVo.create(50).value as MoneyVo;

      // Act
      const result = money1.add(money2);

      // Assert
      expect(result.isRight()).toBe(true);
      const sum = result.value as MoneyVo;
      expect(sum.value).toBe(150);
    });
  });
});
```

## Estratégia de Mocks e Factories

### Frontend Mocks para Features

**Service Mocks**:

```typescript
// Mock para serviços de feature
export const createMockBudgetService = () => ({
  getBudgets: vi.fn(),
  createBudget: vi.fn(),
  updateBudget: vi.fn(),
  deleteBudget: vi.fn(),
});

// Mock para estado de feature
export const createMockBudgetState = () => ({
  budgets: vi.fn(),
  loading: vi.fn(),
  error: vi.fn(),
  setBudgets: vi.fn(),
  setLoading: vi.fn(),
  setError: vi.fn(),
});

// Mock para comunicação entre features
export const createMockFeatureCommunication = () => ({
  notifyBudgetCreated: vi.fn(),
  notifyBudgetUpdated: vi.fn(),
  notifyBudgetDeleted: vi.fn(),
});
```

**DTO Factories para Frontend**:

```typescript
// Factory para DTOs de feature
export class BudgetDtoFactory {
  static create(overrides: Partial<BudgetDto> = {}): BudgetDto {
    const defaultData: BudgetDto = {
      id: "budget-123",
      name: "Orçamento Teste",
      amount: 5000,
      startDate: "2024-01-01",
      endDate: "2024-01-31",
      userId: "user-123",
      createdAt: new Date("2024-01-01T00:00:00Z"),
      updatedAt: new Date("2024-01-01T00:00:00Z"),
    };

    return { ...defaultData, ...overrides };
  }

  static createList(count: number = 3): BudgetDto[] {
    return Array.from({ length: count }, (_, index) =>
      BudgetDtoFactory.create({
        id: `budget-${index + 1}`,
        name: `Orçamento ${index + 1}`,
        amount: 1000 * (index + 1),
      })
    );
  }

  static createWithAmount(amount: number): BudgetDto {
    return BudgetDtoFactory.create({ amount });
  }
}

// Factory para ViewModels
export class BudgetViewModelFactory {
  static create(overrides: Partial<BudgetViewModel> = {}): BudgetViewModel {
    const defaultData: BudgetViewModel = {
      id: "budget-123",
      name: "Orçamento Teste",
      amount: 5000,
      formattedAmount: "R$ 5.000,00",
      period: "01/01/2024 - 31/01/2024",
      isActive: true,
    };

    return { ...defaultData, ...overrides };
  }
}
```

**MSW Handlers para APIs**:

```typescript
// MSW handlers para APIs de features
export const budgetHandlers = [
  rest.get("/api/budgets", (req, res, ctx) => {
    return res(
      ctx.json({
        budgets: BudgetDtoFactory.createList(3),
        total: 3,
        page: 1,
        limit: 10,
      })
    );
  }),

  rest.post("/api/budgets", async (req, res, ctx) => {
    const body = await req.json();
    const newBudget = BudgetDtoFactory.create({
      ...body,
      id: `budget-${Date.now()}`,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    });

    return res(ctx.status(201), ctx.json(newBudget));
  }),

  rest.put("/api/budgets/:id", async (req, res, ctx) => {
    const { id } = req.params;
    const body = await req.json();
    const updatedBudget = BudgetDtoFactory.create({
      ...body,
      id: id as string,
      updatedAt: new Date().toISOString(),
    });

    return res(ctx.json(updatedBudget));
  }),

  rest.delete("/api/budgets/:id", (req, res, ctx) => {
    return res(ctx.status(204));
  }),
];
```

### Repository Mocks

```typescript
// Mock para repositórios seguindo interface
export const createMockAccountRepository =
  (): jest.Mocked<IAccountRepository> => ({
    findById: jest.fn(),
    findByBudgetId: jest.fn(),
    save: jest.fn(),
    delete: jest.fn(),
    existsByName: jest.fn(),
  });

// Helper para setup padrão
export const setupMockAccountRepository = (
  scenarios: Partial<IAccountRepository> = {}
) => {
  const mock = createMockAccountRepository();

  // Defaults que funcionam na maioria dos casos
  mock.save.mockResolvedValue(right(undefined));
  mock.findById.mockResolvedValue(right(null));
  mock.existsByName.mockResolvedValue(right(false));

  // Override com cenários específicos
  Object.assign(mock, scenarios);

  return mock;
};
```

### Factories para Entidades e VOs

```typescript
// Factory para agregados de domínio
export class AccountFactory {
  static create(overrides: Partial<CreateAccountDTO> = {}): Account {
    const defaultData: CreateAccountDTO = {
      name: "Conta Teste",
      type: AccountType.CHECKING,
      initialBalance: 0,
      budgetId: "budget-123",
    };

    const accountData = { ...defaultData, ...overrides };
    const result = Account.create(accountData);

    if (result.isLeft()) {
      throw new Error(`Failed to create Account: ${result.value.message}`);
    }

    return result.value;
  }

  static createWithBalance(balance: number): Account {
    return AccountFactory.create({ initialBalance: balance });
  }

  static createSavingsAccount(): Account {
    return AccountFactory.create({
      name: "Conta Poupança",
      type: AccountType.SAVINGS,
    });
  }
}

// Factory para requests de use case
export class CreateAccountRequestFactory {
  static create(
    overrides: Partial<CreateAccountRequest> = {}
  ): CreateAccountRequest {
    return {
      name: "Nova Conta",
      type: "CHECKING",
      initialBalance: 0,
      budgetId: "budget-123",
      userId: "user-123",
      ...overrides,
    };
  }
}
```

### Domain Services Mock

```typescript
// Mock para services de domínio
export const createMockAccountDomainService =
  (): jest.Mocked<IAccountDomainService> => ({
    validateAccountCreation: jest.fn(),
    calculateTotalBalance: jest.fn(),
    canDeleteAccount: jest.fn(),
  });
```

### Frontend Mocks

```typescript
// MSW para APIs
import { setupServer } from "msw/node";

const server = setupServer(
  rest.get("/api/accounts", (req, res, ctx) => {
    return res(ctx.json({ accounts: [] }));
  }),
  rest.post("/api/accounts", (req, res, ctx) => {
    return res(ctx.status(201), ctx.json({ id: "account-123" }));
  })
);
```

## Organização e Convenções

### Nomenclatura

- **Unitários**: `*.spec.ts`
- **E2E**: `*.e2e.ts`
- **Helpers**: `test-utils/`

### Estrutura de describe/it

```typescript
describe("UserService", () => {
  describe("createUser", () => {
    it("should create user with valid data", () => {
      // Arrange, Act, Assert
    });

    it("should throw error with invalid email", () => {
      // Test error cases
    });
  });
});
```

### Padrão AAA (Arrange, Act, Assert)

```typescript
it("should calculate user age correctly", () => {
  // Arrange
  const birthDate = new Date("1990-01-01");
  const user = UserFactory.create({ birthDate });

  // Act
  const age = user.getAge();

  // Assert
  expect(age).toBe(34);
});
```

## Execução e Pipeline

### Scripts NPM

**Backend**:

```json
{
  "test": "jest",
  "test:watch": "jest --watch",
  "test:coverage": "jest --coverage",
  "test:domain": "jest --testPathPattern=domain",
  "test:application": "jest --testPathPattern=application",
  "test:integration": "jest --testPathPattern=integration"
}
```

**Frontend**:

```json
{
  "test": "vitest",
  "test:watch": "vitest --watch",
  "test:ui": "vitest --ui",
  "test:coverage": "vitest --coverage",
  "test:run": "vitest run",
  "test:ci": "vitest run --coverage --reporter=verbose",
  "test:features": "vitest run --include='**/features/**/*.spec.ts'",
  "test:shared": "vitest run --include='**/shared/**/*.spec.ts'",
  "test:dtos": "vitest run --include='**/dtos/**/*.spec.ts'",
  "test:state": "vitest run --include='**/state/**/*.spec.ts'",
  "test:e2e": "playwright test",
  "test:e2e:ui": "playwright test --ui",
  "test:budgets": "vitest run --include='**/features/budgets/**/*.spec.ts'",
  "test:transactions": "vitest run --include='**/features/transactions/**/*.spec.ts'",
  "test:goals": "vitest run --include='**/features/goals/**/*.spec.ts'"
}
```

### CI/CD Integration

- **Pull Request**: Testes unitários obrigatórios
- **Main branch**: Suite completa (unit + e2e)
- **Deploy**: Smoke tests em staging

## Relatórios e Métricas

### Cobertura

- Relatórios HTML gerados automaticamente
- Falha no CI se cobertura < 80%
- Domínio deve manter 100%

### Performance E2E

- Timeout padrão: 30s por teste
- Paralelização quando possível
- Retry em casos de flaky tests

## Boas Práticas

### DOs - Arquitetura DDD + Feature-Based

✅ Testar invariantes de domínio nos agregados  
✅ Validar padrão Either em todos os retornos  
✅ Usar factories para criar objetos de domínio  
✅ Mockar repositórios seguindo suas interfaces  
✅ Testar comportamentos, não implementação  
✅ Usar nomes descritivos para testes (Given/When/Then)  
✅ Manter testes simples e focados em um aspecto  
✅ Limpar estado entre testes  
✅ Usar TypeScript com strict mode em todos os testes  
✅ Testar cenários de erro além dos casos felizes  
✅ **Features**: Testar cada feature como módulo isolado  
✅ **DTOs**: Validar transformações DTO ↔ ViewModel  
✅ **Estado**: Testar Angular Signals e reatividade  
✅ **Comunicação**: Mockar comunicação entre features  
✅ **Lazy Loading**: Testar carregamento sob demanda  
✅ **Roteamento**: Validar navegação entre features

### DON'Ts - Arquitetura DDD + Feature-Based

❌ Testar detalhes de implementação interna dos agregados  
❌ Quebrar encapsulamento de agregados nos testes  
❌ Testes dependentes entre si ou com ordem específica  
❌ Hard-coding de delays em E2E  
❌ Testes muito complexos ou longos  
❌ Ignorar testes que falham ocasionalmente (flaky tests)  
❌ Usar mocks que não seguem as interfaces de domínio  
❌ Testar múltiplas responsabilidades no mesmo teste  
❌ Pular validação do padrão Either nos retornos  
❌ **Features**: Testar múltiplas features no mesmo teste  
❌ **DTOs**: Ignorar validação de contratos de API  
❌ **Estado**: Testar implementação interna de signals  
❌ **Comunicação**: Acoplar features nos testes  
❌ **Lazy Loading**: Testar carregamento síncrono  
❌ **Roteamento**: Hard-codear URLs de roteamento

## Ferramentas e Configuração

### Ambiente Local

**Backend**:

```bash
# Rodar todos os testes
npm run test

# Rodar com watch mode
npm run test:watch

# Rodar com cobertura
npm run test:coverage

# Rodar apenas testes de domínio
npm run test:domain

# Rodar apenas testes de aplicação
npm run test:application
```

**Frontend**:

```bash
# Rodar testes unitários
npm run test

# Rodar com cobertura
npm run test:coverage

# Rodar E2E
npm run test:e2e
```

### Configuração Jest (Backend)

**jest.config.js**:

```javascript
module.exports = {
  preset: "ts-jest",
  testEnvironment: "node",
  roots: ["<rootDir>/src"],
  testMatch: ["**/*.spec.ts"],
  collectCoverageFrom: [
    "src/**/*.ts",
    "!src/**/*.d.ts",
    "!src/shared/observability/**",
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80,
    },
    "./src/domain/": {
      branches: 100,
      functions: 100,
      lines: 100,
      statements: 100,
    },
  },
  moduleNameMapping: {
    "^@domain/(.*)$": "<rootDir>/src/domain/$1",
    "^@application/(.*)$": "<rootDir>/src/application/$1",
    "^@infrastructure/(.*)$": "<rootDir>/src/infrastructure/$1",
    "^@http/(.*)$": "<rootDir>/src/interface/http/$1",
    "^@shared/(.*)$": "<rootDir>/src/shared/$1",
  },
  setupFilesAfterEnv: ["<rootDir>/src/shared/test/setup.ts"],
};
```

**setup.ts**:

```typescript
// Helper para Either pattern em testes
declare global {
  namespace jest {
    interface Matchers<R> {
      toBeRight(): R;
      toBeLeft(): R;
      toBeRightWith(expected: any): R;
      toBeLeftWith(expected: any): R;
    }
  }
}

expect.extend({
  toBeRight(received) {
    const pass = received.isRight();
    return {
      message: () =>
        `expected Either to be Right, but was Left: ${received.value}`,
      pass,
    };
  },

  toBeLeft(received) {
    const pass = received.isLeft();
    return {
      message: () =>
        `expected Either to be Left, but was Right: ${received.value}`,
      pass,
    };
  },

  toBeRightWith(received, expected) {
    if (!received.isRight()) {
      return {
        message: () =>
          `expected Either to be Right, but was Left: ${received.value}`,
        pass: false,
      };
    }

    const pass = this.equals(received.value, expected);
    return {
      message: () =>
        `expected Right value to be ${this.utils.printExpected(
          expected
        )}, but received ${this.utils.printReceived(received.value)}`,
      pass,
    };
  },

  toBeLeftWith(received, expected) {
    if (!received.isLeft()) {
      return {
        message: () =>
          `expected Either to be Left, but was Right: ${received.value}`,
        pass: false,
      };
    }

    const pass =
      received.value instanceof expected ||
      this.equals(received.value, expected);
    return {
      message: () =>
        `expected Left value to be ${this.utils.printExpected(
          expected
        )}, but received ${this.utils.printReceived(received.value)}`,
      pass,
    };
  },
});
```

### Debugging

- **VS Code**: Launch configs para debugging Jest
- **Jest**: `--verbose` para output detalhado
- **Playwright**: Interface visual para E2E
- **Chrome DevTools**: Para testes unitários frontend

## Roadmap Futuro

### Fase 2

- Testes de integração específicos
- Testes de performance/carga
- Testes de acessibilidade automatizados
- Visual regression tests

### Fase 3

- Dados de teste gerenciados
- Ambiente de testes dedicado
- Testes com autenticação real
- Monitoramento de qualidade avançado

## Responsabilidades

### Desenvolvedores Backend

- **Domínio**: Escrever testes unitários para agregados, value objects e domain services
- **Aplicação**: Implementar testes de use cases com mocks de repositórios
- **Arquitetura**: Garantir que testes seguem padrões DDD/Clean Architecture
- **Either Pattern**: Validar tratamento de erros em todos os retornos

### Desenvolvedores Frontend

- **Componentes**: Testes unitários de comportamento e integração
- **Serviços**: Mock de APIs e validação de estados
- **E2E**: Colaborar na definição de cenários críticos
- **Features**: Testes isolados de cada módulo de funcionalidade
- **DTOs**: Validação de contratos de API e transformações
- **Estado**: Testes de Angular Signals e reatividade
- **Comunicação**: Mock de comunicação entre features
- **Lazy Loading**: Validação de carregamento sob demanda

### Tech Lead

- **Estratégia**: Revisar e evoluir padrões de teste
- **Cobertura**: Monitorar métricas de qualidade
- **Arquitetura**: Validar aderência aos padrões estabelecidos
- **Code Review**: Garantir qualidade dos testes em PRs

### DevOps

- **Pipeline**: Manter execução automatizada funcionando
- **Ambiente**: Configurar ambientes de teste isolados
- **Métricas**: Coletar e reportar dados de qualidade
- **Performance**: Otimizar tempo de execução dos testes

---

_Esta estratégia será evoluída conforme o projeto cresce e novas necessidades surgem._
