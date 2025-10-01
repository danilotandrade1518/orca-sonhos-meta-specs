# Regras de Dependência (Boundaries)

## Arquitetura de Dependências

A arquitetura frontend segue **DTO-First Architecture** com **inversão de dependências**, onde camadas internas não conhecem camadas externas.

```
┌─────────────────────────────────────┐
│          UI (Angular)               │ ← Pode importar tudo
├─────────────────────────────────────┤
│        Infra (Adapters)             │ ← Implementa Application
├─────────────────────────────────────┤
│    Application (Commands/Queries)   │ ← Usa DTOs, define Ports
├─────────────────────────────────────┤
│           DTOs (Contratos)          │ ← Não depende de nada
└─────────────────────────────────────┘
```

## Regras por Camada

### 1. DTOs (Contratos) - Isolamento Total

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
      "@dtos/*": ["dtos/*"],
      "@application/*": ["application/*"],
      "@infra/*": ["infra/*"],
      "@app/*": ["app/*"],
      "@shared/*": ["app/shared/*"]
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
          // DTOs layer cannot import anything internal
          {
            "target": "./src/dtos/**/*",
            "from": [
              "./src/application/**/*",
              "./src/infra/**/*",
              "./src/app/**/*"
            ],
            "message": "DTOs layer cannot import from other layers"
          },

          // Application cannot import Infra or UI
          {
            "target": "./src/application/**/*",
            "from": ["./src/infra/**/*", "./src/app/**/*"],
            "message": "Application layer cannot import Infrastructure or UI"
          },

          // Infrastructure cannot import UI components
          {
            "target": "./src/infra/**/*",
            "from": ["./src/app/features/**/*", "./src/app/pages/**/*"],
            "message": "Infrastructure cannot import specific UI components"
          }
        ]
      }
    ],

    // Enforce path aliases between layers
    "import/no-relative-parent-imports": [
      "error",
      {
        "ignore": [
          "./src/models/**/*", // Models can use relative imports within
          "./src/application/**/*" // Application can use relative imports within
        ]
      }
    ]
  }
}
```

### Custom ESLint Rule

```javascript
// .eslint/rules/layer-boundaries.js
module.exports = {
  meta: {
    type: "problem",
    docs: {
      description: "Enforce clean architecture layer boundaries",
    },
  },

  create(context) {
    const filename = context.getFilename();

    return {
      ImportDeclaration(node) {
        const importPath = node.source.value;

        // DTOs layer violations
        if (filename.includes("/dtos/")) {
          if (
            importPath.includes("@application") ||
            importPath.includes("@infra") ||
            importPath.includes("@app")
          ) {
            context.report({
              node,
              message: "DTOs layer cannot import from other internal layers",
            });
          }
        }

        // Application layer violations
        if (filename.includes("/application/")) {
          if (importPath.includes("@infra") || importPath.includes("@app")) {
            context.report({
              node,
              message: "Application layer cannot import Infrastructure or UI",
            });
          }
        }

        // Infrastructure violations
        if (filename.includes("/infra/")) {
          if (
            importPath.includes("@app/features") ||
            importPath.includes("@app/pages")
          ) {
            context.report({
              node,
              message: "Infrastructure cannot import specific UI components",
            });
          }
        }
      },
    };
  },
};
```

## Padrões de Import

### Entre Camadas Diferentes (Path Aliases Obrigatório)

```typescript
// ✅ CORRETO - Path aliases para camadas diferentes
import { TransactionResponseDto } from "@dtos/transaction/response/TransactionResponseDto";
import { CreateTransactionCommand } from "@application/commands/transaction/CreateTransactionCommand";
import { HttpCreateTransactionAdapter } from "@infra/http/adapters/mutations/transaction/HttpCreateTransactionAdapter";

// ❌ EVITAR - Imports relativos entre camadas
import { TransactionResponseDto } from "../../../dtos/transaction/response/TransactionResponseDto";
import { CreateTransactionCommand } from "../../application/commands/transaction/CreateTransactionCommand";
```

### Mesma Camada (Imports Relativos Recomendados)

```typescript
// ✅ CORRETO - Imports relativos na mesma camada
// application/commands/transaction/CreateTransactionCommand.ts
import { CreateTransactionRequestDto } from "@dtos/transaction/request/CreateTransactionRequestDto";
import { ICreateTransactionPort } from "../ports/mutations/transaction/ICreateTransactionPort";
import { CreateTransactionValidator } from "../validators/transaction/CreateTransactionValidator";

// app/features/transactions/transaction-list.component.ts
import { TransactionCardComponent } from "./transaction-card.component";
import { TransactionFilters } from "./types/TransactionFilters";
```

### Imports de Third-Party Libraries

```typescript
// ✅ DTOs - Apenas utilitários puros
import { format } from "date-fns"; // ✅ Pure utility
import { cloneDeep } from "lodash"; // ✅ Pure utility

// ❌ DTOs - Libraries com side effects
import { HttpClient } from "@angular/common/http"; // ❌ Side effects
import { Injectable } from "@angular/core"; // ❌ Framework

// ✅ Application - Utilitários + abstrações
import { format } from "date-fns"; // ✅ Pure utility

// ❌ Application - Implementações concretas
import { HttpClient } from "@angular/common/http"; // ❌ Concrete implementation

// ✅ Infrastructure - Qualquer biblioteca
import { HttpClient } from "@angular/common/http"; // ✅
import { Injectable } from "@angular/core"; // ✅
import axios from "axios"; // ✅

// ✅ UI - Angular + qualquer biblioteca
import { Component } from "@angular/core"; // ✅
import { FormBuilder } from "@angular/forms"; // ✅
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

### Provider Configuration (UI Layer)

```typescript
// app/providers/commands-queries.provider.ts
export function provideCommandsAndQueries(): Provider[] {
  return [
    // Commands (concretos)
    CreateTransactionCommand,
    UpdateBudgetCommand,
    DeleteTransactionCommand,

    // Queries (concretos)
    GetBudgetSummaryQuery,
    GetTransactionListQuery,
    GetBudgetByIdQuery,

    // Port -> Adapter bindings (1 interface por operação)
    {
      provide: ICreateBudgetPort,
      useClass: HttpCreateBudgetAdapter,
    },
    {
      provide: IGetBudgetByIdPort,
      useClass: HttpGetBudgetByIdAdapter,
    },
    {
      provide: ICreateTransactionPort,
      useClass: HttpCreateTransactionAdapter,
    },
    {
      provide: ILocalStorePort,
      useClass: IndexedDBAdapter,
    },
  ];
}
```

### Constructor Injection Strategy

```typescript
// ✅ CORRETO - Application layer usa interfaces
export class CreateTransactionCommand {
  constructor(
    private port: ICreateTransactionPort  // Interface
  ) {}
}

// ✅ CORRETO - Infrastructure implementa interfaces
@Injectable({ providedIn: 'root' })
export class HttpCreateTransactionAdapter implements ICreateTransactionPort {
  constructor(
    private httpClient: IHttpClient  // Também interface
  ) {}
}

// ✅ CORRETO - UI injeta commands/queries concretos
@Component({...})
export class CreateTransactionPage {
  private createTransactionCommand = inject(CreateTransactionCommand); // Concreto
}
```

## Testes e Boundaries

### Unit Tests - Mock Interfaces

```typescript
// ✅ Application layer tests
describe("CreateTransactionCommand", () => {
  let mockPort: jest.Mocked<ICreateTransactionPort>;

  beforeEach(() => {
    mockPort = {
      execute: jest.fn(),
    } as jest.Mocked<ICreateTransactionPort>;
  });

  // Tests não conhecem implementação concreta
});
```

### Integration Tests - Real Implementations

```typescript
// ✅ Infrastructure layer tests
describe("HttpCreateTransactionAdapter", () => {
  let adapter: HttpCreateTransactionAdapter;
  let httpClient: IHttpClient; // Pode ser mock HTTP client

  beforeEach(() => {
    httpClient = new MockHttpClient();
    adapter = new HttpCreateTransactionAdapter(httpClient);
  });

  // Testa implementação concreta
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

- [Directory Structure](./directory-structure.md) - Organização física das camadas
- [Layer Responsibilities](./layer-responsibilities.md) - O que cada camada deve fazer
- [DTO-First Principles](./dto-first-principles.md) - Princípios fundamentais da arquitetura
- [Testing Strategy](./testing-strategy.md) - Como testar respeitando boundaries
