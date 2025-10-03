# Padrões de Import e Dependências - Feature-Based Architecture

## 🎯 Path Aliases vs Imports Relativos

### ✅ Path Aliases: Entre Features e Camadas

Use **path aliases** quando importar entre features diferentes ou de camadas arquiteturais diferentes:

```typescript
// ✅ CORRETO - Path aliases entre features
import { CreateTransactionDto } from "@dtos/CreateTransactionDto";
import { TransactionDto } from "@dtos/TransactionDto";
import { ITransactionRepository } from "@application/ports/ITransactionRepository";
import { HttpTransactionAdapter } from "@infra/adapters/HttpTransactionAdapter";

// ✅ Features → DTOs
import { CreateTransactionDto } from "@dtos/CreateTransactionDto";
import { TransactionDto } from "@dtos/TransactionDto";

// ✅ Features → Application
import { CreateTransactionUseCase } from "@application/use-cases/CreateTransactionUseCase";
import { TransactionServicePort } from "@application/ports/TransactionServicePort";

// ✅ Features → Shared
import { OsButtonComponent } from "@shared/ui-components/os-button.component";
import { OsCardComponent } from "@shared/ui-components/os-card.component";

// ✅ Features → Core
import { AuthService } from "@core/services/auth.service";
import { ErrorHandlerService } from "@core/services/error-handler.service";

// ✅ Features → Other Features (comunicação)
import { FeatureCommunicationService } from "@core/services/feature-communication.service";
```

### ✅ Imports Relativos: Dentro da Mesma Feature

Use **imports relativos** quando importar dentro da mesma feature:

```typescript
// ✅ CORRETO - Imports relativos na mesma feature

// Feature: transactions
import { TransactionListComponent } from "./components/transaction-list.component";
import { TransactionFormComponent } from "./components/transaction-form.component";
import { TransactionDetailComponent } from "./components/transaction-detail.component";

// Feature: transactions/services
import { TransactionStateService } from "./services/transaction-state.service";
import { TransactionApiService } from "./services/transaction-api.service";

// Feature: transactions/models
import { TransactionModel } from "./models/transaction.model";
import { TransactionFilters } from "./models/transaction-filters.model";

// Feature: shared (dentro da mesma feature)
import { BaseFormComponent } from "../shared/base-form.component";
import { TransactionCardComponent } from "./components/transaction-card.component";
```

## 📁 Organização de Imports

**Ordem obrigatória** dos imports para Feature-Based Architecture:

```typescript
// 1. 🌐 Bibliotecas externas (Node.js/npm packages)
import { Component, inject, signal } from "@angular/core";
import { FormBuilder, Validators } from "@angular/forms";
import { Either, left, right } from "fp-ts/lib/Either";
import { pipe } from "fp-ts/lib/function";

// 2. 🏗️ Camadas internas (ordem: DTOs → Application → Infrastructure)
import { CreateTransactionDto } from "@dtos/CreateTransactionDto"; // DTOs
import { TransactionDto } from "@dtos/TransactionDto"; // DTOs
import { CreateTransactionUseCase } from "@application/use-cases/CreateTransactionUseCase"; // Application
import { ITransactionServicePort } from "@application/ports/ITransactionServicePort"; // Application

// 3. 🎯 Core e Shared (ordem: Core → Shared)
import { AuthService } from "@core/services/auth.service";
import { ErrorHandlerService } from "@core/services/error-handler.service";
import { OsButtonComponent } from "@shared/ui-components/os-button.component";
import { OsCardComponent } from "@shared/ui-components/os-card.component";

// 4. 🔗 Imports relativos da mesma feature (proximidade: shared → específicos)
import { BaseFormComponent } from "../shared/base-form.component";
import { TransactionFormData } from "./models/transaction-form-data.model";
import { TransactionFormValidator } from "./validators/transaction-form.validator";
```

### Exemplo Completo - Feature-Based Architecture

```typescript
// features/transactions/components/transaction-form.component.ts
// 1. External libraries
import {
  Component,
  ChangeDetectionStrategy,
  inject,
  signal,
  computed,
  input,
  output,
} from "@angular/core";
import {
  FormBuilder,
  FormGroup,
  Validators,
  ReactiveFormsModule,
} from "@angular/forms";
import { Router } from "@angular/router";
import { Either } from "fp-ts/lib/Either";

// 2. Internal layers (DTOs → Application)
import { CreateTransactionDto } from "@dtos/CreateTransactionDto";
import { TransactionDto } from "@dtos/TransactionDto";
import { CreateTransactionUseCase } from "@application/use-cases/CreateTransactionUseCase";
import { ITransactionServicePort } from "@application/ports/ITransactionServicePort";

// 3. Core e Shared
import { AuthService } from "@core/services/auth.service";
import { ErrorHandlerService } from "@core/services/error-handler.service";
import { OsButtonComponent } from "@shared/ui-components/os-button.component";
import { OsCardComponent } from "@shared/ui-components/os-card.component";

// 4. Relative imports (mesma feature)
import { BaseFormComponent } from "../shared/base-form.component";
import { TransactionFormData } from "./models/transaction-form-data.model";
import { TransactionFormValidator } from "./validators/transaction-form.validator";

@Component({
  selector: "os-transaction-form",
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ReactiveFormsModule, OsButtonComponent],
  template: `...`,
})
export class TransactionFormComponent extends BaseFormComponent {
  // implementation
}
```

## 🚫 Anti-Patterns a Evitar

### ❌ Imports Relativos Entre Features

```typescript
// ❌ EVITAR - Imports relativos entre features diferentes
import { BudgetService } from "../../../features/budgets/services/budget.service";
import { GoalService } from "../../../features/goals/services/goal.service";

// ✅ PREFERIR - Path aliases ou comunicação via Core
import { FeatureCommunicationService } from "@core/services/feature-communication.service";
import { BudgetService } from "@core/services/budget.service";
```

### ❌ Path Aliases Dentro da Mesma Feature

```typescript
// ❌ EVITAR - Path aliases na mesma feature (quando desnecessário)
import { TransactionValidator } from "@features/transactions/validators/transaction.validator";
import { TransactionModel } from "@features/transactions/models/transaction.model";

// ✅ PREFERIR - Imports relativos na mesma feature
import { TransactionValidator } from "./validators/transaction.validator";
import { TransactionModel } from "./models/transaction.model";
```

### ❌ Imports Diretos Entre Features

```typescript
// ❌ EVITAR - Import direto entre features
import { BudgetStateService } from "@features/budgets/services/budget-state.service";
import { GoalStateService } from "@features/goals/services/goal-state.service";

// ✅ PREFERIR - Comunicação via Core/Shared
import { FeatureCommunicationService } from "@core/services/feature-communication.service";
import { FeatureEventBus } from "@core/services/feature-event-bus.service";
```

### ❌ Imports Desordenados

```typescript
// ❌ EVITAR - Ordem aleatória
import { TransactionFormData } from "./types"; // Relativo
import { Component } from "@angular/core"; // Externo
import { CreateTransactionDto } from "@dtos/CreateTransactionDto"; // Interno
import { BaseComponent } from "../shared/BaseComponent"; // Relativo

// ✅ CORRETO - Ordem estruturada
import { Component } from "@angular/core"; // 1. Externo
import { CreateTransactionDto } from "@dtos/CreateTransactionDto"; // 2. Interno
import { BaseComponent } from "../shared/BaseComponent"; // 3. Relativo
import { TransactionFormData } from "./types"; // 3. Relativo
```

## ⚙️ Configuração de Path Aliases

### TypeScript Configuration - Feature-Based

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
      "@core/*": ["app/core/*"],
      "@shared/*": ["app/shared/*"],
      "@features/*": ["app/features/*"]
    }
  }
}
```

### ESLint Enforcement - Feature-Based

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
          "builtin", // Node.js built-in modules
          "external", // npm packages
          "internal", // Path aliases (@dtos, @application, @core, @shared, @features)
          "parent", // ../
          "sibling", // ./
          "index" // ./index
        ],
        "newlines-between": "always",
        "alphabetize": {
          "order": "asc",
          "caseInsensitive": true
        }
      }
    ],

    // Enforce path aliases between features and layers
    "import/no-relative-parent-imports": [
      "error",
      {
        "ignore": [
          "./src/dtos/**/*", // DTOs can use relative
          "./src/application/**/*", // Application can use relative
          "./src/app/features/**/*" // Features can use relative within feature
        ]
      }
    ],

    // Prevent direct imports between features
    "import/no-restricted-paths": [
      "error",
      {
        "zones": [
          {
            "target": "./src/app/features/*/",
            "from": "./src/app/features/*/",
            "except": ["./src/app/features/*/shared/"]
          }
        ]
      }
    ]
  }
}
```

## 🏗️ Estratégias por Camada - Feature-Based

### DTOs (Data Transfer Objects)

```typescript
// dtos/CreateTransactionDto.ts
// ✅ Apenas imports relativos + bibliotecas puras
import { Either } from "fp-ts/lib/Either"; // External pure
import { format } from "date-fns"; // External pure

import { UpdateTransactionDto } from "./UpdateTransactionDto"; // Relative same layer
import { TransactionDto } from "./TransactionDto";
import { TransactionCriteriaDto } from "./TransactionCriteriaDto";

// ❌ NÃO pode importar outras camadas
// import { CreateTransactionUseCase } from '@application/...'; ❌
// import { HttpClient } from '@infra/...'; ❌
```

### Application

```typescript
// application/use-cases/CreateTransactionUseCase.ts
// ✅ Importa DTOs + bibliotecas + relativos na mesma camada
import { Either } from "fp-ts/lib/Either"; // External

import { CreateTransactionDto } from "@dtos/CreateTransactionDto"; // DTOs
import { TransactionDto } from "@dtos/TransactionDto"; // DTOs

import { ITransactionServicePort } from "../ports/ITransactionServicePort"; // Relative same layer
import { TransactionValidator } from "./validators/TransactionValidator";

// ❌ NÃO pode importar Infrastructure ou UI
// import { HttpTransactionAdapter } from '@infra/...'; ❌
// import { TransactionFormComponent } from '@app/...'; ❌
```

### Infrastructure

```typescript
// infra/adapters/HttpTransactionAdapter.ts
// ✅ Importa Application + DTOs + bibliotecas + relativos
import { Injectable } from "@angular/core"; // External
import { HttpClient } from "@angular/common/http"; // External

import { CreateTransactionDto } from "@dtos/CreateTransactionDto"; // DTOs
import { ITransactionServicePort } from "@application/ports/ITransactionServicePort"; // Application
import { TransactionDto } from "@dtos/TransactionDto";

import { BaseHttpAdapter } from "./BaseHttpAdapter"; // Relative same layer
import { HttpClientMapper } from "./HttpClientMapper";
```

### Core Services

```typescript
// app/core/services/auth.service.ts
// ✅ Pode importar DTOs + Application + bibliotecas + relativos
import { Injectable } from "@angular/core"; // External
import { HttpClient } from "@angular/common/http"; // External

import { UserDto } from "@dtos/UserDto"; // DTOs
import { IAuthServicePort } from "@application/ports/IAuthServicePort"; // Application

import { BaseService } from "./base.service"; // Relative same layer
import { TokenManager } from "./token-manager";
```

### Shared Components

```typescript
// app/shared/ui-components/os-button.component.ts
// ✅ Pode importar Core + bibliotecas + relativos
import { Component, Input, Output } from "@angular/core"; // External

import { BaseComponent } from "../base.component"; // Relative same layer
import { ButtonTheme } from "../types/button-theme";

// ❌ NÃO pode importar Features diretamente
// import { TransactionService } from '@features/transactions/...'; ❌
```

### Feature Components

```typescript
// app/features/transactions/components/transaction-form.component.ts
// ✅ Pode importar todas as camadas + Angular + relativos
import { Component, inject } from "@angular/core"; // External

import { CreateTransactionDto } from "@dtos/CreateTransactionDto"; // DTOs
import { CreateTransactionUseCase } from "@application/use-cases/CreateTransactionUseCase"; // Application

import { AuthService } from "@core/services/auth.service"; // Core
import { OsButtonComponent } from "@shared/ui-components/os-button.component"; // Shared

import { BaseFormComponent } from "../shared/base-form.component"; // Relative same feature
import { TransactionFormData } from "./models/transaction-form-data.model";
```

## 🔄 Imports de Third-Party Libraries

### DTOs Layer - Apenas Pure Functions

```typescript
// ✅ PERMITIDO - Libraries puras
import { format, parse } from "date-fns"; // Pure date utilities
import { cloneDeep, isEmpty } from "lodash"; // Pure utilities
import { Either, left, right } from "fp-ts/lib/Either"; // Pure functional

// ❌ PROIBIDO - Libraries com side effects
import { HttpClient } from "@angular/common/http"; // HTTP side effects
import { Injectable } from "@angular/core"; // Framework dependency
```

### Application Layer - Abstractions Only

```typescript
// ✅ PERMITIDO - Pure utilities + DTOs
import { Either } from "fp-ts/lib/Either"; // Pure functional
import { format } from "date-fns"; // Pure utility

// ❌ PROIBIDO - Implementações concretas
import { HttpClient } from "@angular/common/http"; // Concrete HTTP implementation
import { Injectable } from "@angular/core"; // Framework specific
```

### Infrastructure Layer - Qualquer Library

```typescript
// ✅ PERMITIDO - Qualquer biblioteca
import { Injectable } from "@angular/core"; // Framework
import { HttpClient } from "@angular/common/http"; // HTTP client
import axios from "axios"; // Alternative HTTP
import { Pool } from "pg"; // Database client
import { createHash } from "crypto"; // Node.js built-in
```

### UI Layer - Angular + Qualquer Library

```typescript
// ✅ PERMITIDO - Angular + qualquer biblioteca UI
import { Component, OnInit } from "@angular/core"; // Framework
import { FormBuilder, Validators } from "@angular/forms"; // Angular forms
import { Observable, Subject } from "rxjs"; // Reactive streams
import { MatDialog } from "@angular/material/dialog"; // Material UI
```

## 📝 Exemplos Práticos

### Use Case com Múltiplas Dependências

```typescript
// application/use-cases/TransferBetweenAccountsUseCase.ts
import { Either } from "fp-ts/lib/Either";
import { pipe } from "fp-ts/lib/function";

import { TransferBetweenAccountsDto } from "@dtos/TransferBetweenAccountsDto";
import { AccountDto } from "@dtos/AccountDto";
import { TransactionDto } from "@dtos/TransactionDto";

import { IAuthorizationService } from "../ports/IAuthorizationService";
import { IAccountRepository } from "../ports/IAccountRepository";
import { ITransactionRepository } from "../ports/ITransactionRepository";
import { ApplicationError } from "../errors/ApplicationError";
import { UnauthorizedError } from "../errors/UnauthorizedError";

import { BaseUseCase } from "./BaseUseCase";
import { TransferValidator } from "./validators/TransferValidator";
```

### Component com Design System

```typescript
// app/features/budget/budget-overview.component.ts
import {
  Component,
  ChangeDetectionStrategy,
  inject,
  signal,
  computed,
} from "@angular/core";
import { Router } from "@angular/router";

import { BudgetDto } from "@dtos/BudgetDto";
import { TransactionDto } from "@dtos/TransactionDto";
import { GetBudgetSummaryQueryHandler } from "@application/query-handlers/GetBudgetSummaryQueryHandler";

import { BasePageComponent } from "../shared/base-page.component";
import { OsCardComponent } from "../shared/design-system/os-card.component";
import { OsButtonComponent } from "../shared/design-system/os-button.component";
import { BudgetSummaryWidget } from "./widgets/budget-summary.widget";
import { TransactionListWidget } from "./widgets/transaction-list.widget";
```

---

**Ver também:**

- **[Naming Conventions](./naming-conventions.md)** - Como nomear arquivos e imports
- **[Validation Rules](./validation-rules.md)** - ESLint boundary rules
- **[Class Structure](./class-structure.md)** - Organização interna das classes
- **[DTO Conventions](./dto-conventions.md)** - Convenções para DTOs
