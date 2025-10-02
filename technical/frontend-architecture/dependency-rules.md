# Regras de Dependência (Boundaries)

## Arquitetura de Dependências

A arquitetura frontend segue **Feature-Based Architecture** com princípios **DTO-First** e **inversão de dependências**, onde features são isoladas e compartilham apenas componentes e serviços necessários.

```
┌─────────────────────────────────────┐
│              Features               │ ← Módulos independentes
│  ┌─────────┐ ┌─────────┐ ┌─────────┐│
│  │budgets  │ │transac  │ │goals    ││
│  └─────────┘ └─────────┘ └─────────┘│
├─────────────────────────────────────┤
│              Shared                 │ ← Componentes compartilhados
│  ┌─────────┐ ┌─────────┐ ┌─────────┐│
│  │ui-comp  │ │theme    │ │utils    ││
│  └─────────┘ └─────────┘ └─────────┘│
├─────────────────────────────────────┤
│               Core                  │ ← Serviços globais
│  ┌─────────┐ ┌─────────┐ ┌─────────┐│
│  │services │ │guards   │ │interc   ││
│  └─────────┘ └─────────┘ └─────────┘│
├─────────────────────────────────────┤
│              DTOs                   │ ← Contratos de API
└─────────────────────────────────────┘
```

## Regras por Estrutura

### 1. Features - Isolamento e Independência

**Pode Importar:**
- ✅ DTOs (para tipos e contratos)
- ✅ Shared components (ui-components, theme, utils)
- ✅ Core services (auth, config, interceptors)
- ✅ Services globais (api, state, validation)

**NÃO Pode Importar:**
- ❌ Outras features diretamente
- ❌ Componentes específicos de outras features
- ❌ Serviços específicos de outras features

```typescript
// ✅ PERMITIDO - Feature importando shared e core
// features/budgets/components/budget-list.component.ts
import { BudgetResponseDto } from "@dtos/budget/response/BudgetResponseDto"; // ✅ DTO
import { OsButtonComponent } from "@shared/ui-components/atoms/os-button"; // ✅ Shared
import { AuthService } from "@core/services/auth.service"; // ✅ Core
import { ApiService } from "@services/api/api.service"; // ✅ Global service

// ❌ PROIBIDO - Feature importando outra feature
import { TransactionCardComponent } from "@features/transactions/components/transaction-card.component"; // ❌
import { GoalService } from "@features/goals/services/goal.service"; // ❌
```

### 2. Shared - Componentes Compartilhados

**Pode Importar:**
- ✅ DTOs (para tipos)
- ✅ Core services (quando necessário)
- ✅ Angular framework
- ✅ Bibliotecas externas

**NÃO Pode Importar:**
- ❌ Features específicas
- ❌ Serviços específicos de features

```typescript
// ✅ PERMITIDO - Shared components
// shared/ui-components/atoms/os-button/os-button.component.ts
import { Component, input, output } from "@angular/core"; // ✅ Framework
import { Money } from "@dtos/shared/Money"; // ✅ DTO

// ❌ PROIBIDO - Shared importando features
import { BudgetCardComponent } from "@features/budgets/components/budget-card.component"; // ❌
```

### 3. Core - Serviços Globais

**Pode Importar:**
- ✅ DTOs (para tipos)
- ✅ Angular framework
- ✅ Bibliotecas externas
- ✅ Services globais

**NÃO Pode Importar:**
- ❌ Features específicas
- ❌ Componentes específicos

```typescript
// ✅ PERMITIDO - Core services
// core/services/auth.service.ts
import { Injectable, signal } from "@angular/core"; // ✅ Framework
import { User } from "@dtos/shared/User"; // ✅ DTO

// ❌ PROIBIDO - Core importando features
import { BudgetService } from "@features/budgets/services/budget.service"; // ❌
```

### 4. DTOs (Contratos) - Isolamento Total

**Pode Importar:**

- ✅ Nada interno (apenas TypeScript stdlib)
- ✅ Utilitários puros (lodash, date-fns)

**NÃO Pode Importar:**

- ❌ Application layer
- ❌ Infrastructure layer
- ❌ UI layer (Angular)
- ❌ Bibliotecas com side effects

```typescript
// ✅ PERMITIDO - DTOs
// dtos/transaction/response/TransactionResponseDto.ts
export interface TransactionResponseDto {
  readonly id: string;
  readonly accountId: string;
  readonly budgetId: string;
  readonly amountInCents: number;
  readonly description: string;
  readonly type: "INCOME" | "EXPENSE";
  readonly date: string;
  readonly createdAt: string;
  readonly updatedAt: string;
}

// dtos/shared/Money.ts
export type Money = number; // Sempre em centavos

// ❌ PROIBIDO - DTOs importando outras camadas
import { ITransactionRepository } from "@application/ports/ITransactionRepository"; // ❌
import { HttpClient } from "@angular/common/http"; // ❌
import { Component } from "@angular/core"; // ❌
```

### 2. Application - Usa DTOs, Define Ports

**Pode Importar:**

- ✅ DTOs (request/response DTOs, shared types)
- ✅ Utilitários puros
- ✅ TypeScript stdlib

**NÃO Pode Importar:**

- ❌ Infrastructure implementations
- ❌ UI layer (Angular)
- ❌ HTTP libraries, storage libs

```typescript
// ✅ PERMITIDO - Application
// application/commands/transaction/CreateTransactionCommand.ts
import { CreateTransactionRequestDto } from "@dtos/transaction/request/CreateTransactionRequestDto"; // ✅ DTO
import { ICreateTransactionPort } from "../ports/mutations/transaction/ICreateTransactionPort"; // ✅ Own layer

export class CreateTransactionCommand {
  constructor(
    private port: ICreateTransactionPort // Port interface, não implementação
  ) {}
}

// ❌ PROIBIDO - Application importando Infra ou UI
import { HttpCreateTransactionAdapter } from "@infra/adapters/HttpCreateTransactionAdapter"; // ❌
import { Component } from "@angular/core"; // ❌
```

### 3. Infrastructure - Implementa Application

**Pode Importar:**

- ✅ Application (ports, DTOs)
- ✅ DTOs (para trabalhar diretamente)
- ✅ Bibliotecas externas (HTTP, storage, etc.)
- ✅ Angular (se necessário para providers)

**NÃO Pode Importar:**

- ❌ UI components específicos
- ❌ Page components

```typescript
// ✅ PERMITIDO - Infrastructure
// infra/http/adapters/mutations/transaction/HttpCreateTransactionAdapter.ts
import { ICreateTransactionPort } from "@application/ports/mutations/transaction/ICreateTransactionPort"; // ✅
import { CreateTransactionRequestDto } from "@dtos/transaction/request/CreateTransactionRequestDto"; // ✅ DTO
import { HttpClient } from "@angular/common/http"; // ✅ External lib
import { Injectable } from "@angular/core"; // ✅ Para DI

@Injectable({ providedIn: "root" })
export class HttpCreateTransactionAdapter implements ICreateTransactionPort {
  constructor(private http: HttpClient) {} // ✅
}

// ❌ PROIBIDO - Infra importando UI específico
import { TransactionListComponent } from "@app/features/transactions/transaction-list.component"; // ❌
```

### 4. UI (Angular) - Pode Importar Tudo

**Pode Importar:**

- ✅ Application (commands, queries)
- ✅ DTOs (para tipos)
- ✅ Infra (apenas para DI providers)
- ✅ Shared UI components
- ✅ Angular framework

```typescript
// ✅ PERMITIDO - UI
// app/features/transactions/pages/create-transaction.page.ts
import { CreateTransactionCommand } from '@application/commands/transaction/CreateTransactionCommand'; // ✅
import { CreateTransactionRequestDto } from '@dtos/transaction/request/CreateTransactionRequestDto'; // ✅ Para tipos
import { Component, inject } from '@angular/core';             // ✅ Framework
import { OsButtonComponent } from '@shared/ui-components/atoms/os-button'; // ✅ Shared UI

@Component({...})
export class CreateTransactionPage {
  private createTransactionCommand = inject(CreateTransactionCommand); // ✅
}
```

## Path Aliases e Enforcement

### Configuração TypeScript

```json
// tsconfig.json
{
  "compilerOptions": {
    "baseUrl": "./src",
    "paths": {
      "@app/*": ["app/*"],
      "@core/*": ["app/core/*"],
      "@shared/*": ["app/shared/*"],
      "@features/*": ["app/features/*"],
      "@layouts/*": ["app/layouts/*"],
      "@dtos/*": ["app/dtos/*"],
      "@services/*": ["app/services/*"],
      "@mocks/*": ["mocks/*"]
    }
  }
}
```

### ESLint Rules para Enforcement

```json
// .eslintrc.json
{
  "extends": ["@typescript-eslint/recommended"],
  "plugins": ["import"],
  "rules": {
    "import/no-restricted-paths": [
      "error",
      {
        "zones": [
          // DTOs cannot import anything internal
          {
            "target": "./src/app/dtos/**/*",
            "from": [
              "./src/app/core/**/*",
              "./src/app/shared/**/*",
              "./src/app/features/**/*",
              "./src/app/services/**/*"
            ],
            "message": "DTOs cannot import from other app layers"
          },

          // Features cannot import other features
          {
            "target": "./src/app/features/**/*",
            "from": ["./src/app/features/**/*"],
            "except": ["./src/app/features/**/index.ts"],
            "message": "Features cannot import other features directly"
          },

          // Shared cannot import features
          {
            "target": "./src/app/shared/**/*",
            "from": ["./src/app/features/**/*"],
            "message": "Shared components cannot import features"
          },

          // Core cannot import features
          {
            "target": "./src/app/core/**/*",
            "from": ["./src/app/features/**/*"],
            "message": "Core services cannot import features"
          }
        ]
      }
    ],

    // Enforce path aliases between structures
    "import/no-relative-parent-imports": [
      "error",
      {
        "ignore": [
          "./src/app/features/**/*", // Features can use relative imports within
          "./src/app/shared/**/*" // Shared can use relative imports within
        ]
      }
    ]
  }
}
```

### Custom ESLint Rule

```javascript
// .eslint/rules/feature-boundaries.js
module.exports = {
  meta: {
    type: "problem",
    docs: {
      description: "Enforce Feature-Based Architecture boundaries",
    },
  },

  create(context) {
    const filename = context.getFilename();

    return {
      ImportDeclaration(node) {
        const importPath = node.source.value;

        // DTOs violations
        if (filename.includes("/app/dtos/")) {
          if (
            importPath.includes("@core") ||
            importPath.includes("@shared") ||
            importPath.includes("@features") ||
            importPath.includes("@services")
          ) {
            context.report({
              node,
              message: "DTOs cannot import from other app layers",
            });
          }
        }

        // Features violations
        if (filename.includes("/app/features/")) {
          if (importPath.includes("@features/") && !importPath.includes("index")) {
            context.report({
              node,
              message: "Features cannot import other features directly",
            });
          }
        }

        // Shared violations
        if (filename.includes("/app/shared/")) {
          if (importPath.includes("@features/")) {
            context.report({
              node,
              message: "Shared components cannot import features",
            });
          }
        }

        // Core violations
        if (filename.includes("/app/core/")) {
          if (importPath.includes("@features/")) {
            context.report({
              node,
              message: "Core services cannot import features",
            });
          }
        }
      },
    };
  },
};
```

## Padrões de Import

### Entre Estruturas Diferentes (Path Aliases Obrigatório)

```typescript
// ✅ CORRETO - Path aliases para estruturas diferentes
import { BudgetResponseDto } from "@dtos/budget/response/BudgetResponseDto"; // ✅ DTO
import { OsButtonComponent } from "@shared/ui-components/atoms/os-button"; // ✅ Shared
import { AuthService } from "@core/services/auth.service"; // ✅ Core
import { ApiService } from "@services/api/api.service"; // ✅ Global service

// ❌ EVITAR - Imports relativos entre estruturas
import { BudgetResponseDto } from "../../../dtos/budget/response/BudgetResponseDto";
import { OsButtonComponent } from "../../shared/ui-components/atoms/os-button";
```

### Dentro da Mesma Feature (Imports Relativos Recomendados)

```typescript
// ✅ CORRETO - Imports relativos dentro da feature
// features/budgets/components/budget-list.component.ts
import { BudgetCardComponent } from "./budget-card.component";
import { BudgetFormComponent } from "./budget-form.component";
import { BudgetFilters } from "./types/BudgetFilters";

// features/budgets/services/budget.service.ts
import { BudgetStateService } from "./budget-state.service";
import { BudgetValidator } from "./validators/budget.validator";
```

### Dentro do Shared (Imports Relativos Recomendados)

```typescript
// ✅ CORRETO - Imports relativos dentro do shared
// shared/ui-components/atoms/os-button/os-button.component.ts
import { ButtonVariant } from "./types/ButtonVariant";
import { ButtonSize } from "./types/ButtonSize";

// shared/utils/date.util.ts
import { DateFormat } from "./types/DateFormat";
import { Timezone } from "./types/Timezone";
```

### Imports de Third-Party Libraries

```typescript
// ✅ DTOs - Apenas utilitários puros
import { format } from "date-fns"; // ✅ Pure utility
import { cloneDeep } from "lodash"; // ✅ Pure utility

// ❌ DTOs - Libraries com side effects
import { HttpClient } from "@angular/common/http"; // ❌ Side effects
import { Injectable } from "@angular/core"; // ❌ Framework

// ✅ Features - Angular + utilitários
import { Component, inject } from "@angular/core"; // ✅ Framework
import { FormBuilder } from "@angular/forms"; // ✅ Framework
import { format } from "date-fns"; // ✅ Pure utility

// ✅ Shared - Angular + utilitários
import { Component, input, output } from "@angular/core"; // ✅ Framework
import { format } from "date-fns"; // ✅ Pure utility

// ✅ Core - Angular + bibliotecas externas
import { Injectable, signal } from "@angular/core"; // ✅ Framework
import { HttpClient } from "@angular/common/http"; // ✅ Framework
import axios from "axios"; // ✅ External library

// ✅ Services - Qualquer biblioteca
import { HttpClient } from "@angular/common/http"; // ✅
import { Injectable } from "@angular/core"; // ✅
import { Observable } from "rxjs"; // ✅
```

## Dependency Injection (DI) Strategy

### Interface Segregation

```typescript
// ✅ CORRETO - Interfaces específicas por operação (Padrão Command)
export interface ICreateBudgetPort {
  execute(request: CreateBudgetRequestDto): Promise<Either<ServiceError, void>>;
}

export interface IGetBudgetByIdPort {
  execute(id: string): Promise<Either<ServiceError, BudgetResponseDto>>;
}

export interface IGetBudgetSummaryPort {
  execute(
    request: GetBudgetSummaryRequest
  ): Promise<Either<ServiceError, BudgetSummaryResponseDto>>;
}

// ❌ EVITAR - Interface muito ampla
export interface IBudgetPort {
  // Muitos métodos misturados - commands e queries
  create(budget: CreateBudgetRequestDto): Promise<void>;
  update(budget: UpdateBudgetRequestDto): Promise<void>;
  delete(id: string): Promise<void>;
  getById(id: string): Promise<BudgetResponseDto>;
  getSummary(id: string): Promise<BudgetSummaryResponseDto>;
  getList(userId: string): Promise<BudgetListResponseDto>;
  // ... mais 20 métodos
}
```

### Provider Configuration (App Level)

```typescript
// app/app.config.ts
export const appConfig: ApplicationConfig = {
  providers: [
    // Core services
    AuthService,
    ConfigService,
    
    // Global services
    ApiService,
    StateService,
    ValidationService,
    
    // HTTP interceptors
    { provide: HTTP_INTERCEPTORS, useClass: AuthInterceptor, multi: true },
    { provide: HTTP_INTERCEPTORS, useClass: ErrorInterceptor, multi: true },
    
    // Route guards
    AuthGuard,
    RoleGuard,
  ],
};
```

### Feature Module Providers

```typescript
// features/budgets/budgets.module.ts
@NgModule({
  declarations: [
    BudgetListComponent,
    BudgetFormComponent,
    BudgetCardComponent,
  ],
  imports: [
    CommonModule,
    SharedModule,
    BudgetsRoutingModule,
  ],
  providers: [
    // Feature-specific services
    BudgetService,
    BudgetStateService,
    BudgetValidator,
  ],
})
export class BudgetsModule {}
```

### Constructor Injection Strategy

```typescript
// ✅ CORRETO - Feature service injeta dependências
@Injectable({ providedIn: 'root' })
export class BudgetService {
  constructor(
    private apiService: ApiService, // ✅ Global service
    private authService: AuthService, // ✅ Core service
    private budgetStateService: BudgetStateService // ✅ Feature service
  ) {}
}

// ✅ CORRETO - Feature component injeta services
@Component({...})
export class BudgetListComponent {
  private budgetService = inject(BudgetService); // ✅ Feature service
  private authService = inject(AuthService); // ✅ Core service
  private dateUtil = inject(DateUtil); // ✅ Shared utility
}

// ✅ CORRETO - Shared component injeta dependências
@Component({...})
export class OsButtonComponent {
  constructor(
    private themeService: ThemeService // ✅ Shared service
  ) {}
}

// ✅ CORRETO - Core service injeta dependências
@Injectable({ providedIn: 'root' })
export class AuthService {
  constructor(
    private httpClient: HttpClient, // ✅ Angular service
    private configService: ConfigService // ✅ Core service
  ) {}
}
```

## Testes e Boundaries

### Unit Tests - Feature Components

```typescript
// ✅ Feature component tests
describe("BudgetListComponent", () => {
  let component: BudgetListComponent;
  let mockBudgetService: jest.Mocked<BudgetService>;
  let mockAuthService: jest.Mocked<AuthService>;

  beforeEach(() => {
    mockBudgetService = {
      getBudgets: jest.fn(),
      createBudget: jest.fn(),
    } as jest.Mocked<BudgetService>;

    mockAuthService = {
      getCurrentUser: jest.fn(),
    } as jest.Mocked<AuthService>;

    component = new BudgetListComponent(mockBudgetService, mockAuthService);
  });

  it("should load budgets on init", async () => {
    const mockBudgets = [/* mock data */];
    mockBudgetService.getBudgets.mockResolvedValue(mockBudgets);

    await component.ngOnInit();

    expect(mockBudgetService.getBudgets).toHaveBeenCalled();
    expect(component.budgets()).toEqual(mockBudgets);
  });
});
```

### Unit Tests - Shared Components

```typescript
// ✅ Shared component tests
describe("OsButtonComponent", () => {
  let component: OsButtonComponent;
  let mockThemeService: jest.Mocked<ThemeService>;

  beforeEach(() => {
    mockThemeService = {
      getPrimaryColor: jest.fn(),
    } as jest.Mocked<ThemeService>;

    component = new OsButtonComponent(mockThemeService);
  });

  it("should apply correct color based on variant", () => {
    component.variant = "primary";
    expect(component.matColor()).toBe("primary");
  });
});
```

### Integration Tests - Feature Services

```typescript
// ✅ Feature service integration tests
describe("BudgetService", () => {
  let service: BudgetService;
  let mockApiService: jest.Mocked<ApiService>;
  let mockAuthService: jest.Mocked<AuthService>;

  beforeEach(() => {
    mockApiService = {
      get: jest.fn(),
      post: jest.fn(),
    } as jest.Mocked<ApiService>;

    mockAuthService = {
      getCurrentUser: jest.fn(),
    } as jest.Mocked<AuthService>;

    service = new BudgetService(mockApiService, mockAuthService, mockBudgetStateService);
  });

  it("should fetch budgets from API", async () => {
    const mockBudgets = [/* mock data */];
    mockApiService.get.mockResolvedValue(mockBudgets);

    const result = await service.getBudgets();

    expect(mockApiService.get).toHaveBeenCalledWith("/budgets");
    expect(result).toEqual(mockBudgets);
  });
});
```

## Validação Automatizada

### Pre-commit Hook

```bash
#!/bin/sh
# .git/hooks/pre-commit

# Run ESLint with boundary rules
npm run lint:boundaries

# Run dependency analysis
npm run analyze:dependencies

if [ $? -ne 0 ]; then
  echo "❌ Dependency boundary violations found!"
  echo "Fix violations before committing."
  exit 1
fi
```

### NPM Scripts

```json
{
  "scripts": {
    "lint:boundaries": "eslint src/ --ext .ts --config .eslint-boundaries.json",
    "analyze:dependencies": "madge --circular --extensions ts src/",
    "validate:architecture": "npm run lint:boundaries && npm run analyze:dependencies"
  }
}
```

### CI/CD Integration

```yaml
# .github/workflows/validate-architecture.yml
name: Validate Architecture
on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: "18"

      - run: npm install
      - run: npm run validate:architecture
        name: Validate dependency boundaries
```

---

**Ver também:**

- [Directory Structure](./directory-structure.md) - Organização física das features
- [Layer Responsibilities](./layer-responsibilities.md) - O que cada estrutura deve fazer
- [Feature Organization](./feature-organization.md) - Como organizar features independentes
- [Testing Strategy](./testing-strategy.md) - Como testar respeitando boundaries
