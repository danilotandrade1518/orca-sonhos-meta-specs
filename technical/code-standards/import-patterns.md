# Padrões de Import e Dependências

## 🎯 Path Aliases vs Imports Relativos

### ✅ Path Aliases: Entre Camadas Diferentes

Use **path aliases** quando importar de camadas arquiteturais diferentes:

```typescript
// ✅ CORRETO - Path aliases entre camadas
import { Transaction } from '@models/entities/Transaction';
import { ITransactionRepository } from '@application/ports/ITransactionRepository';
import { HttpTransactionAdapter } from '@infra/adapters/HttpTransactionAdapter';
import { TransactionListComponent } from '@app/features/transactions/transaction-list.component';

// ✅ Domain → Application
import { CreateTransactionUseCase } from '@application/use-cases/CreateTransactionUseCase';
import { TransactionServicePort } from '@application/ports/TransactionServicePort';

// ✅ Application → Infrastructure
import { PostgresTransactionRepository } from '@infra/database/repositories/PostgresTransactionRepository';
import { HttpClient } from '@infra/http/HttpClient';

// ✅ Infrastructure → UI
import { TransactionFormComponent } from '@app/components/transaction-form/transaction-form.component';
```

### ✅ Imports Relativos: Dentro da Mesma Camada

Use **imports relativos** quando importar dentro da mesma camada:

```typescript
// ✅ CORRETO - Imports relativos na mesma camada

// Domain layer
import { Money } from '../value-objects/Money';
import { TransactionId } from './TransactionId';
import { TransactionStatus } from './TransactionStatus';

// Application layer  
import { CreateTransactionDto } from '../dtos/CreateTransactionDto';
import { TransactionValidator } from './validators/TransactionValidator';

// UI layer
import { TransactionCardComponent } from './transaction-card.component';
import { TransactionFilters } from './types/TransactionFilters';
import { BaseFormComponent } from '../shared/BaseFormComponent';
```

## 📁 Organização de Imports

**Ordem obrigatória** dos imports:

```typescript
// 1. 🌐 Bibliotecas externas (Node.js/npm packages)
import { Component, inject, signal } from '@angular/core';
import { FormBuilder, Validators } from '@angular/forms';
import { Either, left, right } from 'fp-ts/lib/Either';
import { pipe } from 'fp-ts/lib/function';

// 2. 🏗️ Camadas internas (ordem: Domain → Application → Infrastructure → UI)
import { Transaction } from '@models/entities/Transaction';                    // Domain
import { Money } from '@models/value-objects/Money';                           // Domain
import { CreateTransactionUseCase } from '@application/use-cases/CreateTransactionUseCase'; // Application
import { ITransactionServicePort } from '@application/ports/ITransactionServicePort';       // Application
import { HttpTransactionAdapter } from '@infra/adapters/HttpTransactionAdapter';           // Infrastructure

// 3. 🔗 Imports relativos da mesma camada (proximidade: shared → específicos)
import { BaseComponent } from '../shared/BaseComponent';
import { FormValidationHelper } from '../shared/FormValidationHelper';
import { TransactionFormData } from './types';
import { TransactionFormValidator } from './TransactionFormValidator';
```

### Exemplo Completo
```typescript
// transaction-form.component.ts
// 1. External libraries
import { 
  Component, 
  ChangeDetectionStrategy, 
  inject, 
  signal, 
  computed, 
  input, 
  output 
} from '@angular/core';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { Either } from 'fp-ts/lib/Either';

// 2. Internal layers (Domain → Application → Infrastructure)
import { Transaction } from '@models/entities/Transaction';
import { Money } from '@models/value-objects/Money';
import { TransactionId } from '@models/value-objects/TransactionId';
import { CreateTransactionUseCase } from '@application/use-cases/CreateTransactionUseCase';
import { CreateTransactionDto } from '@application/dtos/CreateTransactionDto';

// 3. Relative imports (shared → specific)
import { BaseFormComponent } from '../shared/base-form.component';
import { OsButtonComponent } from '../shared/os-button.component';
import { TransactionFormData } from './types';
import { TransactionFormValidator } from './transaction-form.validator';

@Component({
  selector: 'os-transaction-form',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ReactiveFormsModule, OsButtonComponent],
  template: `...`
})
export class TransactionFormComponent extends BaseFormComponent {
  // implementation
}
```

## 🚫 Anti-Patterns a Evitar

### ❌ Imports Relativos Entre Camadas
```typescript
// ❌ EVITAR - Imports relativos entre camadas diferentes
import { Transaction } from '../../../models/entities/Transaction';
import { CreateTransactionUseCase } from '../../application/use-cases/CreateTransactionUseCase';
import { HttpTransactionAdapter } from '../infra/adapters/HttpTransactionAdapter';

// ✅ PREFERIR - Path aliases
import { Transaction } from '@models/entities/Transaction';
import { CreateTransactionUseCase } from '@application/use-cases/CreateTransactionUseCase';
import { HttpTransactionAdapter } from '@infra/adapters/HttpTransactionAdapter';
```

### ❌ Path Aliases Dentro da Mesma Camada
```typescript
// ❌ EVITAR - Path aliases na mesma camada (quando desnecessário)
import { TransactionValidator } from '@application/validators/TransactionValidator';
import { CreateTransactionDto } from '@application/dtos/CreateTransactionDto';

// ✅ PREFERIR - Imports relativos na mesma camada  
import { TransactionValidator } from './validators/TransactionValidator';
import { CreateTransactionDto } from '../dtos/CreateTransactionDto';
```

### ❌ Imports Desordenados
```typescript
// ❌ EVITAR - Ordem aleatória
import { TransactionFormData } from './types';              // Relativo
import { Component } from '@angular/core';                  // Externo
import { Transaction } from '@models/entities/Transaction'; // Interno
import { BaseComponent } from '../shared/BaseComponent';    // Relativo

// ✅ CORRETO - Ordem estruturada
import { Component } from '@angular/core';                  // 1. Externo
import { Transaction } from '@models/entities/Transaction'; // 2. Interno
import { BaseComponent } from '../shared/BaseComponent';    // 3. Relativo
import { TransactionFormData } from './types';              // 3. Relativo
```

## ⚙️ Configuração de Path Aliases

### TypeScript Configuration
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

### ESLint Enforcement
```json
// .eslintrc.json
{
  "extends": ["@typescript-eslint/recommended"],
  "plugins": ["import"],
  "rules": {
    "import/order": [
      "error",
      {
        "groups": [
          "builtin",    // Node.js built-in modules
          "external",   // npm packages
          "internal",   // Path aliases (@models, @application, etc.)
          "parent",     // ../
          "sibling",    // ./
          "index"       // ./index
        ],
        "newlines-between": "always",
        "alphabetize": {
          "order": "asc",
          "caseInsensitive": true
        }
      }
    ],
    
    // Enforce path aliases between layers
    "import/no-relative-parent-imports": [
      "error",
      {
        "ignore": [
          "./src/models/**/*",       // Models can use relative
          "./src/application/**/*"   // Application can use relative  
        ]
      }
    ]
  }
}
```

## 🏗️ Estratégias por Camada

### Models (Domain)
```typescript
// models/entities/Transaction.ts
// ✅ Apenas imports relativos + bibliotecas puras
import { Either } from 'fp-ts/lib/Either';           // External pure
import { format } from 'date-fns';                   // External pure

import { Money } from '../value-objects/Money';      // Relative same layer
import { TransactionId } from '../value-objects/TransactionId'; 
import { TransactionStatus } from '../enums/TransactionStatus';

// ❌ NÃO pode importar outras camadas
// import { CreateTransactionUseCase } from '@application/...'; ❌
// import { HttpClient } from '@infra/...'; ❌
```

### Application
```typescript
// application/use-cases/CreateTransactionUseCase.ts
// ✅ Importa Domain + bibliotecas + relativos na mesma camada
import { Either } from 'fp-ts/lib/Either';           // External

import { Transaction } from '@models/entities/Transaction';      // Domain
import { Money } from '@models/value-objects/Money';             // Domain

import { CreateTransactionDto } from '../dtos/CreateTransactionDto'; // Relative same layer
import { ITransactionServicePort } from '../ports/ITransactionServicePort';

// ❌ NÃO pode importar Infrastructure ou UI
// import { HttpTransactionAdapter } from '@infra/...'; ❌
// import { TransactionFormComponent } from '@app/...'; ❌
```

### Infrastructure
```typescript
// infra/adapters/HttpTransactionAdapter.ts
// ✅ Importa Application + Domain + bibliotecas + relativos
import { Injectable } from '@angular/core';          // External
import { HttpClient } from '@angular/common/http';   // External

import { Transaction } from '@models/entities/Transaction';               // Domain
import { ITransactionServicePort } from '@application/ports/ITransactionServicePort'; // Application
import { CreateTransactionDto } from '@application/dtos/CreateTransactionDto';

import { BaseHttpAdapter } from './BaseHttpAdapter'; // Relative same layer
import { HttpClientMapper } from './HttpClientMapper';
```

### UI (Angular)
```typescript
// app/features/transactions/transaction-form.component.ts
// ✅ Pode importar todas as camadas + Angular + relativos
import { Component, inject } from '@angular/core';   // External

import { Transaction } from '@models/entities/Transaction';               // Domain
import { CreateTransactionUseCase } from '@application/use-cases/CreateTransactionUseCase'; // Application
import { CreateTransactionDto } from '@application/dtos/CreateTransactionDto';

import { BaseFormComponent } from '../shared/base-form.component'; // Relative UI
import { TransactionFormData } from './types';
```

## 🔄 Imports de Third-Party Libraries

### Domain Layer - Apenas Pure Functions
```typescript
// ✅ PERMITIDO - Libraries puras
import { format, parse } from 'date-fns';        // Pure date utilities
import { cloneDeep, isEmpty } from 'lodash';     // Pure utilities
import { Either, left, right } from 'fp-ts/lib/Either'; // Pure functional

// ❌ PROIBIDO - Libraries com side effects
import { HttpClient } from '@angular/common/http'; // HTTP side effects
import { Injectable } from '@angular/core';        // Framework dependency
```

### Application Layer - Abstractions Only
```typescript
// ✅ PERMITIDO - Pure utilities + domain
import { Either } from 'fp-ts/lib/Either';  // Pure functional
import { format } from 'date-fns';          // Pure utility

// ❌ PROIBIDO - Implementações concretas  
import { HttpClient } from '@angular/common/http'; // Concrete HTTP implementation
import { Injectable } from '@angular/core';        // Framework specific
```

### Infrastructure Layer - Qualquer Library
```typescript
// ✅ PERMITIDO - Qualquer biblioteca
import { Injectable } from '@angular/core';        // Framework
import { HttpClient } from '@angular/common/http'; // HTTP client
import axios from 'axios';                         // Alternative HTTP
import { Pool } from 'pg';                         // Database client
import { createHash } from 'crypto';               // Node.js built-in
```

### UI Layer - Angular + Qualquer Library
```typescript
// ✅ PERMITIDO - Angular + qualquer biblioteca UI
import { Component, OnInit } from '@angular/core';     // Framework
import { FormBuilder, Validators } from '@angular/forms'; // Angular forms
import { Observable, Subject } from 'rxjs';             // Reactive streams
import { MatDialog } from '@angular/material/dialog';   // Material UI
```

## 📝 Exemplos Práticos

### Use Case com Múltiplas Dependências
```typescript
// application/use-cases/TransferBetweenAccountsUseCase.ts
import { Either } from 'fp-ts/lib/Either';
import { pipe } from 'fp-ts/lib/function';

import { Account } from '@models/entities/Account';
import { Transaction } from '@models/entities/Transaction';  
import { Money } from '@models/value-objects/Money';
import { TransactionId } from '@models/value-objects/TransactionId';

import { TransferBetweenAccountsDto } from '../dtos/TransferBetweenAccountsDto';
import { IAuthorizationService } from '../ports/IAuthorizationService';
import { IAccountRepository } from '../ports/IAccountRepository';
import { ITransactionRepository } from '../ports/ITransactionRepository';
import { ApplicationError } from '../errors/ApplicationError';
import { UnauthorizedError } from '../errors/UnauthorizedError';

import { BaseUseCase } from './BaseUseCase';
import { TransferValidator } from './validators/TransferValidator';
```

### Component com Design System
```typescript
// app/features/budget/budget-overview.component.ts
import { 
  Component, 
  ChangeDetectionStrategy, 
  inject, 
  signal, 
  computed 
} from '@angular/core';
import { Router } from '@angular/router';

import { Budget } from '@models/entities/Budget';
import { Money } from '@models/value-objects/Money';
import { GetBudgetSummaryQueryHandler } from '@application/query-handlers/GetBudgetSummaryQueryHandler';

import { BasePageComponent } from '../shared/base-page.component';
import { OsCardComponent } from '../shared/design-system/os-card.component';
import { OsButtonComponent } from '../shared/design-system/os-button.component';
import { BudgetSummaryWidget } from './widgets/budget-summary.widget';
import { TransactionListWidget } from './widgets/transaction-list.widget';
```

---

**Ver também:**
- **[Naming Conventions](./naming-conventions.md)** - Como nomear arquivos e imports
- **[Validation Rules](./validation-rules.md)** - ESLint boundary rules
- **[Class Structure](./class-structure.md)** - Organização interna das classes