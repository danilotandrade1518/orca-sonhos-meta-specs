# Regras de Dependência (Boundaries)

## Arquitetura de Dependências

A arquitetura frontend segue Clean Architecture com **inversão de dependências**, onde camadas internas não conhecem camadas externas.

```
┌─────────────────────────────────────┐
│          UI (Angular)               │ ← Pode importar tudo
├─────────────────────────────────────┤
│        Infra (Adapters)             │ ← Implementa Application
├─────────────────────────────────────┤
│    Application (Use Cases)          │ ← Usa Models, define Ports
├─────────────────────────────────────┤
│        Models (Domain)              │ ← Não depende de nada
└─────────────────────────────────────┘
```

## Regras por Camada

### 1. Models (Domain) - Isolamento Total

**Pode Importar:**
- ✅ Nada interno (apenas TypeScript stdlib)
- ✅ Utilitários puros (lodash, date-fns)

**NÃO Pode Importar:**
- ❌ Application layer
- ❌ Infrastructure layer  
- ❌ UI layer (Angular)
- ❌ Bibliotecas com side effects

```typescript
// ✅ PERMITIDO - Models
// models/entities/Transaction.ts
export class Transaction {
  // Apenas TypeScript puro + utilitários puros
  private constructor(
    private readonly _id: string,
    private readonly _amount: Money, // Outro domain model
    private readonly _date: Date     // Stdlib
  ) {}
}

// ❌ PROIBIDO - Models importando outras camadas
import { ITransactionRepository } from '@application/ports/ITransactionRepository'; // ❌
import { HttpClient } from '@angular/common/http'; // ❌
import { Component } from '@angular/core'; // ❌
```

### 2. Application - Usa Models, Define Ports

**Pode Importar:**
- ✅ Models (domain entities, value objects)
- ✅ Utilitários puros
- ✅ TypeScript stdlib

**NÃO Pode Importar:**
- ❌ Infrastructure implementations
- ❌ UI layer (Angular)
- ❌ HTTP libraries, storage libs

```typescript
// ✅ PERMITIDO - Application
// application/use-cases/CreateTransactionUseCase.ts
import { Transaction } from '@models/entities/Transaction';        // ✅ Domain
import { Money } from '@models/value-objects/Money';               // ✅ Domain
import { ITransactionServicePort } from './ports/ITransactionServicePort'; // ✅ Own layer

export class CreateTransactionUseCase {
  constructor(
    private transactionService: ITransactionServicePort  // Port interface, não implementação
  ) {}
}

// ❌ PROIBIDO - Application importando Infra ou UI
import { HttpTransactionServiceAdapter } from '@infra/adapters/HttpTransactionServiceAdapter'; // ❌
import { Component } from '@angular/core'; // ❌
```

### 3. Infrastructure - Implementa Application

**Pode Importar:**
- ✅ Application (ports, DTOs)
- ✅ Models (para mappers)
- ✅ Bibliotecas externas (HTTP, storage, etc.)
- ✅ Angular (se necessário para providers)

**NÃO Pode Importar:**
- ❌ UI components específicos
- ❌ Page components

```typescript
// ✅ PERMITIDO - Infrastructure  
// infra/adapters/http/HttpTransactionServiceAdapter.ts
import { ITransactionServicePort } from '@application/ports/ITransactionServicePort'; // ✅
import { Transaction } from '@models/entities/Transaction'; // ✅ Para mappers
import { HttpClient } from '@angular/common/http';          // ✅ External lib
import { Injectable } from '@angular/core';                // ✅ Para DI

@Injectable({ providedIn: 'root' })
export class HttpTransactionServiceAdapter implements ITransactionServicePort {
  constructor(private http: HttpClient) {} // ✅
}

// ❌ PROIBIDO - Infra importando UI específico
import { TransactionListComponent } from '@app/features/transactions/transaction-list.component'; // ❌
```

### 4. UI (Angular) - Pode Importar Tudo

**Pode Importar:**
- ✅ Application (use cases, query handlers)
- ✅ Models (para tipos)
- ✅ Infra (apenas para DI providers)
- ✅ Shared UI components
- ✅ Angular framework

```typescript
// ✅ PERMITIDO - UI
// app/features/transactions/pages/create-transaction.page.ts
import { CreateTransactionUseCase } from '@application/use-cases/CreateTransactionUseCase'; // ✅
import { Transaction } from '@models/entities/Transaction';     // ✅ Para tipos
import { Component, inject } from '@angular/core';             // ✅ Framework
import { OsButtonComponent } from '@shared/ui-components/atoms/os-button'; // ✅ Shared UI

@Component({...})
export class CreateTransactionPage {
  private createTransactionUseCase = inject(CreateTransactionUseCase); // ✅
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
      "@models/*": ["models/*"],
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
          // Models layer cannot import anything internal
          {
            "target": "./src/models/**/*",
            "from": [
              "./src/application/**/*",
              "./src/infra/**/*", 
              "./src/app/**/*"
            ],
            "message": "Models layer cannot import from other layers"
          },
          
          // Application cannot import Infra or UI
          {
            "target": "./src/application/**/*",
            "from": [
              "./src/infra/**/*",
              "./src/app/**/*"
            ],
            "message": "Application layer cannot import Infrastructure or UI"
          },
          
          // Infrastructure cannot import UI components
          {
            "target": "./src/infra/**/*",
            "from": [
              "./src/app/features/**/*",
              "./src/app/pages/**/*"
            ],
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
          "./src/models/**/*",     // Models can use relative imports within
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
    type: 'problem',
    docs: {
      description: 'Enforce clean architecture layer boundaries'
    }
  },
  
  create(context) {
    const filename = context.getFilename();
    
    return {
      ImportDeclaration(node) {
        const importPath = node.source.value;
        
        // Models layer violations
        if (filename.includes('/models/')) {
          if (importPath.includes('@application') || 
              importPath.includes('@infra') || 
              importPath.includes('@app')) {
            context.report({
              node,
              message: 'Models layer cannot import from other internal layers'
            });
          }
        }
        
        // Application layer violations
        if (filename.includes('/application/')) {
          if (importPath.includes('@infra') || importPath.includes('@app')) {
            context.report({
              node,
              message: 'Application layer cannot import Infrastructure or UI'
            });
          }
        }
        
        // Infrastructure violations
        if (filename.includes('/infra/')) {
          if (importPath.includes('@app/features') || 
              importPath.includes('@app/pages')) {
            context.report({
              node,
              message: 'Infrastructure cannot import specific UI components'
            });
          }
        }
      }
    };
  }
};
```

## Padrões de Import

### Entre Camadas Diferentes (Path Aliases Obrigatório)

```typescript
// ✅ CORRETO - Path aliases para camadas diferentes
import { Transaction } from '@models/entities/Transaction';
import { CreateTransactionUseCase } from '@application/use-cases/CreateTransactionUseCase';
import { HttpTransactionAdapter } from '@infra/adapters/HttpTransactionAdapter';

// ❌ EVITAR - Imports relativos entre camadas
import { Transaction } from '../../../models/entities/Transaction';
import { CreateTransactionUseCase } from '../../application/use-cases/CreateTransactionUseCase';
```

### Mesma Camada (Imports Relativos Recomendados)

```typescript
// ✅ CORRETO - Imports relativos na mesma camada
// application/use-cases/CreateTransactionUseCase.ts
import { CreateTransactionDto } from '../dtos/CreateTransactionDto';
import { TransactionValidator } from './validators/TransactionValidator';

// app/features/transactions/transaction-list.component.ts
import { TransactionCardComponent } from './transaction-card.component';
import { TransactionFilters } from './types/TransactionFilters';
```

### Imports de Third-Party Libraries

```typescript
// ✅ Models - Apenas utilitários puros
import { format } from 'date-fns';        // ✅ Pure utility
import { cloneDeep } from 'lodash';       // ✅ Pure utility

// ❌ Models - Libraries com side effects
import { HttpClient } from '@angular/common/http'; // ❌ Side effects
import { Injectable } from '@angular/core';        // ❌ Framework

// ✅ Application - Utilitários + abstrações
import { format } from 'date-fns';  // ✅ Pure utility

// ❌ Application - Implementações concretas  
import { HttpClient } from '@angular/common/http'; // ❌ Concrete implementation

// ✅ Infrastructure - Qualquer biblioteca
import { HttpClient } from '@angular/common/http'; // ✅
import { Injectable } from '@angular/core';        // ✅
import axios from 'axios';                         // ✅

// ✅ UI - Angular + qualquer biblioteca
import { Component } from '@angular/core';     // ✅
import { FormBuilder } from '@angular/forms';  // ✅
import { Observable } from 'rxjs';             // ✅
```

## Dependency Injection (DI) Strategy

### Interface Segregation

```typescript
// ✅ CORRETO - Interfaces específicas por necessidade
export interface IBudgetServicePort {
  getById(id: string): Promise<Either<ServiceError, Budget>>;
  create(budget: Budget): Promise<Either<ServiceError, void>>;
}

export interface IBudgetQueriesPort {
  getSummary(id: string): Promise<Either<QueryError, BudgetSummaryDto>>;
  getList(userId: string): Promise<Either<QueryError, Budget[]>>;
}

// ❌ EVITAR - Interface muito ampla
export interface IBudgetPort {
  // Muitos métodos misturados - commands e queries
  getById(id: string): Promise<Budget>;
  create(budget: Budget): Promise<void>;
  update(budget: Budget): Promise<void>;
  delete(id: string): Promise<void>;
  getSummary(id: string): Promise<BudgetSummary>;
  getTransactions(id: string): Promise<Transaction[]>;
  // ... mais 20 métodos
}
```

### Provider Configuration (UI Layer)

```typescript
// app/providers/use-cases.provider.ts
export function provideUseCases(): Provider[] {
  return [
    // Use Cases (concretos)
    CreateTransactionUseCase,
    UpdateBudgetUseCase,
    
    // Query Handlers (concretos)
    GetBudgetSummaryQueryHandler,
    
    // Port -> Adapter bindings
    { 
      provide: IBudgetServicePort, 
      useClass: HttpBudgetServiceAdapter 
    },
    { 
      provide: ITransactionServicePort, 
      useClass: HttpTransactionServiceAdapter 
    },
    {
      provide: ILocalStorePort,
      useClass: IndexedDBAdapter
    }
  ];
}
```

### Constructor Injection Strategy

```typescript
// ✅ CORRETO - Application layer usa interfaces
export class CreateTransactionUseCase {
  constructor(
    private transactionService: ITransactionServicePort,  // Interface
    private accountService: IAccountServicePort          // Interface
  ) {}
}

// ✅ CORRETO - Infrastructure implementa interfaces
@Injectable({ providedIn: 'root' })
export class HttpTransactionServiceAdapter implements ITransactionServicePort {
  constructor(
    private httpClient: IHttpClient  // Também interface
  ) {}
}

// ✅ CORRETO - UI injeta use cases concretos
@Component({...})
export class CreateTransactionPage {
  private createTransactionUseCase = inject(CreateTransactionUseCase); // Concreto
}
```

## Testes e Boundaries

### Unit Tests - Mock Interfaces

```typescript
// ✅ Application layer tests
describe('CreateTransactionUseCase', () => {
  let mockTransactionService: jest.Mocked<ITransactionServicePort>;
  
  beforeEach(() => {
    mockTransactionService = {
      create: jest.fn(),
      // ... outros métodos mockados
    } as jest.Mocked<ITransactionServicePort>;
  });
  
  // Tests não conhecem implementação concreta
});
```

### Integration Tests - Real Implementations

```typescript
// ✅ Infrastructure layer tests
describe('HttpTransactionServiceAdapter', () => {
  let adapter: HttpTransactionServiceAdapter;
  let httpClient: IHttpClient; // Pode ser mock HTTP client
  
  beforeEach(() => {
    httpClient = new MockHttpClient();
    adapter = new HttpTransactionServiceAdapter(httpClient);
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
          node-version: '18'
      
      - run: npm install
      - run: npm run validate:architecture
        name: Validate dependency boundaries
```

---

**Ver também:**
- [Directory Structure](./directory-structure.md) - Organização física das camadas
- [Layer Responsibilities](./layer-responsibilities.md) - O que cada camada deve fazer
- [Testing Strategy](./testing-strategy.md) - Como testar respeitando boundaries