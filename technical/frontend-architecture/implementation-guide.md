# Guia de Implementação - Feature-Based Architecture

---

**Metadados Estruturados para IA/RAG:**

```yaml
document_type: "implementation_guide"
domain: "frontend_architecture"
audience: ["developers", "tech_leads", "architects"]
complexity: "intermediate"
tags:
  [
    "implementation",
    "feature_based",
    "angular",
    "typescript",
    "guide",
    "best_practices",
  ]
related_docs:
  [
    "feature-organization.md",
    "design-system-integration.md",
    "state-management.md",
    "testing-strategy.md",
  ]
ai_context: "Complete implementation guide for Feature-Based Architecture in Angular"
implementation_phases: ["setup", "feature_creation", "integration", "testing"]
last_updated: "2025-01-24"
```

---

## Visão Geral

Este guia fornece instruções passo a passo para implementar a **Feature-Based Architecture** no projeto OrçaSonhos, mantendo os princípios **DTO-First** e Clean Architecture.

## Pré-requisitos

- Angular 20+ configurado
- TypeScript configurado
- ESLint com regras de boundary
- Path aliases configurados
- Design System base implementado

## Fase 1: Configuração Inicial

### 1.1 Estrutura de Pastas

Crie a estrutura base do projeto:

```bash
mkdir -p src/app/{core,shared,features,layouts,dtos,services}
mkdir -p src/app/core/{services,interceptors,guards}
mkdir -p src/app/shared/{ui-components,theme,pipes,directives,utils}
mkdir -p src/app/features/{dashboard,budgets,transactions,goals,accounts,credit-cards,reports,onboarding}
mkdir -p src/app/layouts/{main-layout,auth-layout}
mkdir -p src/app/dtos/{budget,transaction,goal,account,credit-card,shared}
mkdir -p src/app/services/{api,state,validation}
```

### 1.2 Configuração de Path Aliases

Atualize `tsconfig.json`:

```json
{
  "compilerOptions": {
    "baseUrl": "src",
    "paths": {
      "@app/*": ["app/*"],
      "@core/*": ["app/core/*"],
      "@shared/*": ["app/shared/*"],
      "@features/*": ["app/features/*"],
      "@layouts/*": ["app/layouts/*"],
      "@dtos/*": ["app/dtos/*"],
      "@services/*": ["app/services/*"],
      "@assets/*": ["assets/*"]
    }
  }
}
```

### 1.3 Configuração ESLint

Crie `eslint.feature-boundaries.js`:

```javascript
module.exports = {
  rules: {
    "import/no-restricted-paths": [
      "error",
      {
        zones: [
          {
            target: "./app/features/*",
            from: "./app/features/*",
            except: ["./app/features/shared/*"]
          },
          {
            target: "./app/core/*",
            from: "./app/features/*"
          },
          {
            target: "./app/shared/*",
            from: "./app/features/*"
          }
        ]
      }
    ]
  }
};
```

## Fase 2: Implementação do Core

### 2.1 Core Module

Crie `src/app/core/core.module.ts`:

```typescript
import { NgModule, Optional, SkipSelf } from "@angular/core";
import { CommonModule } from "@angular/common";
import { HTTP_INTERCEPTORS } from "@angular/common/http";

import { AuthService } from "./services/auth.service";
import { ApiService } from "./services/api.service";
import { AuthInterceptor } from "./interceptors/auth.interceptor";
import { ErrorInterceptor } from "./interceptors/error.interceptor";

@NgModule({
  declarations: [],
  imports: [CommonModule],
  providers: [
    AuthService,
    ApiService,
    {
      provide: HTTP_INTERCEPTORS,
      useClass: AuthInterceptor,
      multi: true
    },
    {
      provide: HTTP_INTERCEPTORS,
      useClass: ErrorInterceptor,
      multi: true
    }
  ]
})
export class CoreModule {
  constructor(@Optional() @SkipSelf() parentModule: CoreModule) {
    if (parentModule) {
      throw new Error("CoreModule já foi carregado. Importe apenas no AppModule.");
    }
  }
}
```

### 2.2 Serviços Core

Crie `src/app/core/services/auth.service.ts`:

```typescript
import { Injectable, signal, computed } from "@angular/core";
import { User } from "@dtos/shared/user.dto";

@Injectable({
  providedIn: "root"
})
export class AuthService {
  private readonly _user = signal<User | null>(null);
  private readonly _isAuthenticated = signal(false);

  readonly user = this._user.asReadonly();
  readonly isAuthenticated = this._isAuthenticated.asReadonly();

  login(user: User): void {
    this._user.set(user);
    this._isAuthenticated.set(true);
  }

  logout(): void {
    this._user.set(null);
    this._isAuthenticated.set(false);
  }
}
```

## Fase 3: Implementação do Shared

### 3.1 Shared Module

Crie `src/app/shared/shared.module.ts`:

```typescript
import { NgModule } from "@angular/core";
import { CommonModule } from "@angular/common";
import { ReactiveFormsModule } from "@angular/forms";

import { UiComponentsModule } from "./ui-components/ui-components.module";
import { ThemeModule } from "./theme/theme.module";

@NgModule({
  declarations: [],
  imports: [
    CommonModule,
    ReactiveFormsModule,
    UiComponentsModule,
    ThemeModule
  ],
  exports: [
    CommonModule,
    ReactiveFormsModule,
    UiComponentsModule,
    ThemeModule
  ]
})
export class SharedModule {}
```

### 3.2 Design System

Crie `src/app/shared/ui-components/ui-components.module.ts`:

```typescript
import { NgModule } from "@angular/core";
import { CommonModule } from "@angular/common";
import { MatButtonModule } from "@angular/material/button";
import { MatCardModule } from "@angular/material/card";
import { MatInputModule } from "@angular/material/input";

import { ButtonComponent } from "./atoms/button/button.component";
import { InputComponent } from "./atoms/input/input.component";
import { CardComponent } from "./molecules/card/card.component";

@NgModule({
  declarations: [
    ButtonComponent,
    InputComponent,
    CardComponent
  ],
  imports: [
    CommonModule,
    MatButtonModule,
    MatCardModule,
    MatInputModule
  ],
  exports: [
    ButtonComponent,
    InputComponent,
    CardComponent
  ]
})
export class UiComponentsModule {}
```

## Fase 4: Implementação de Features

### 4.1 Template de Feature

Crie uma nova feature seguindo o template:

```bash
mkdir -p src/app/features/budgets/{components,pages,services,state,types,utils,guards}
mkdir -p src/app/features/budgets/components/{atoms,molecules,organisms}
mkdir -p src/app/features/budgets/services/{commands,queries,ports}
```

### 4.2 Feature Module

Crie `src/app/features/budgets/budgets.module.ts`:

```typescript
import { NgModule } from "@angular/core";
import { CommonModule } from "@angular/common";
import { RouterModule } from "@angular/router";

import { SharedModule } from "@shared/shared.module";
import { BudgetsRoutingModule } from "./budgets-routing.module";

import { BudgetListComponent } from "./pages/budget-list/budget-list.component";
import { BudgetDetailComponent } from "./pages/budget-detail/budget-detail.component";
import { BudgetCardComponent } from "./components/molecules/budget-card/budget-card.component";
import { BudgetService } from "./services/budget.service";
import { BudgetState } from "./state/budget.state";

@NgModule({
  declarations: [
    BudgetListComponent,
    BudgetDetailComponent,
    BudgetCardComponent
  ],
  imports: [
    CommonModule,
    SharedModule,
    BudgetsRoutingModule
  ],
  providers: [
    BudgetService,
    BudgetState
  ]
})
export class BudgetsModule {}
```

### 4.3 Feature Routing

Crie `src/app/features/budgets/budgets-routing.module.ts`:

```typescript
import { NgModule } from "@angular/core";
import { RouterModule, Routes } from "@angular/router";

import { BudgetListComponent } from "./pages/budget-list/budget-list.component";
import { BudgetDetailComponent } from "./pages/budget-detail/budget-detail.component";

const routes: Routes = [
  {
    path: "",
    component: BudgetListComponent
  },
  {
    path: ":id",
    component: BudgetDetailComponent
  }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class BudgetsRoutingModule {}
```

### 4.4 Feature Service

Crie `src/app/features/budgets/services/budget.service.ts`:

```typescript
import { Injectable, inject } from "@angular/core";
import { Observable } from "rxjs";

import { ApiService } from "@services/api.service";
import { CreateBudgetDto, UpdateBudgetDto, BudgetDto } from "@dtos/budget";

@Injectable({
  providedIn: "root"
})
export class BudgetService {
  private readonly apiService = inject(ApiService);

  getBudgets(): Observable<BudgetDto[]> {
    return this.apiService.get<BudgetDto[]>("/budgets");
  }

  getBudget(id: string): Observable<BudgetDto> {
    return this.apiService.get<BudgetDto>(`/budgets/${id}`);
  }

  createBudget(dto: CreateBudgetDto): Observable<BudgetDto> {
    return this.apiService.post<BudgetDto>("/budgets", dto);
  }

  updateBudget(id: string, dto: UpdateBudgetDto): Observable<BudgetDto> {
    return this.apiService.put<BudgetDto>(`/budgets/${id}`, dto);
  }

  deleteBudget(id: string): Observable<void> {
    return this.apiService.delete<void>(`/budgets/${id}`);
  }
}
```

### 4.5 Feature State

Crie `src/app/features/budgets/state/budget.state.ts`:

```typescript
import { Injectable, signal, computed } from "@angular/core";
import { BudgetDto } from "@dtos/budget";

@Injectable({
  providedIn: "root"
})
export class BudgetState {
  private readonly _budgets = signal<BudgetDto[]>([]);
  private readonly _loading = signal(false);
  private readonly _error = signal<string | null>(null);

  readonly budgets = this._budgets.asReadonly();
  readonly loading = this._loading.asReadonly();
  readonly error = this._error.asReadonly();

  readonly hasBudgets = computed(() => this._budgets().length > 0);

  setBudgets(budgets: BudgetDto[]): void {
    this._budgets.set(budgets);
  }

  addBudget(budget: BudgetDto): void {
    this._budgets.update(current => [...current, budget]);
  }

  updateBudget(updatedBudget: BudgetDto): void {
    this._budgets.update(current =>
      current.map(budget =>
        budget.id === updatedBudget.id ? updatedBudget : budget
      )
    );
  }

  removeBudget(id: string): void {
    this._budgets.update(current =>
      current.filter(budget => budget.id !== id)
    );
  }

  setLoading(loading: boolean): void {
    this._loading.set(loading);
  }

  setError(error: string | null): void {
    this._error.set(error);
  }
}
```

## Fase 5: Implementação de Componentes

### 5.1 Componente de Página

Crie `src/app/features/budgets/pages/budget-list/budget-list.component.ts`:

```typescript
import { Component, OnInit, inject } from "@angular/core";
import { CommonModule } from "@angular/common";
import { RouterModule } from "@angular/router";

import { SharedModule } from "@shared/shared.module";
import { BudgetService } from "../../services/budget.service";
import { BudgetState } from "../../state/budget.state";
import { BudgetCardComponent } from "../../components/molecules/budget-card/budget-card.component";

@Component({
  selector: "app-budget-list",
  standalone: false,
  imports: [CommonModule, RouterModule, SharedModule, BudgetCardComponent],
  template: `
    <div class="budget-list">
      <h1>Orçamentos</h1>
      
      @if (budgetState.loading()) {
        <div class="loading">Carregando...</div>
      } @else if (budgetState.error()) {
        <div class="error">{{ budgetState.error() }}</div>
      } @else {
        <div class="budget-grid">
          @for (budget of budgetState.budgets(); track budget.id) {
            <app-budget-card
              [budget]="budget"
              (edit)="onEditBudget($event)"
              (delete)="onDeleteBudget($event)"
            />
          }
        </div>
      }
    </div>
  `,
  styleUrls: ["./budget-list.component.scss"]
})
export class BudgetListComponent implements OnInit {
  private readonly budgetService = inject(BudgetService);
  readonly budgetState = inject(BudgetState);

  ngOnInit(): void {
    this.loadBudgets();
  }

  private loadBudgets(): void {
    this.budgetState.setLoading(true);
    this.budgetState.setError(null);

    this.budgetService.getBudgets().subscribe({
      next: budgets => {
        this.budgetState.setBudgets(budgets);
        this.budgetState.setLoading(false);
      },
      error: error => {
        this.budgetState.setError("Erro ao carregar orçamentos");
        this.budgetState.setLoading(false);
      }
    });
  }

  onEditBudget(budgetId: string): void {
    // Navegar para edição
  }

  onDeleteBudget(budgetId: string): void {
    // Implementar exclusão
  }
}
```

### 5.2 Componente Molecular

Crie `src/app/features/budgets/components/molecules/budget-card/budget-card.component.ts`:

```typescript
import { Component, Input, Output, EventEmitter } from "@angular/core";
import { CommonModule } from "@angular/common";

import { SharedModule } from "@shared/shared.module";
import { BudgetDto } from "@dtos/budget";

@Component({
  selector: "app-budget-card",
  standalone: false,
  imports: [CommonModule, SharedModule],
  template: `
    <mat-card class="budget-card">
      <mat-card-header>
        <mat-card-title>{{ budget.name }}</mat-card-title>
        <mat-card-subtitle>{{ budget.category }}</mat-card-subtitle>
      </mat-card-header>
      
      <mat-card-content>
        <div class="budget-amount">
          <span class="amount">{{ budget.amount | currency:'BRL' }}</span>
          <span class="period">{{ budget.period }}</span>
        </div>
        
        <div class="budget-progress">
          <mat-progress-bar
            [value]="budget.usedAmount / budget.amount * 100"
            mode="determinate"
          ></mat-progress-bar>
          <span class="progress-text">
            {{ budget.usedAmount | currency:'BRL' }} de {{ budget.amount | currency:'BRL' }}
          </span>
        </div>
      </mat-card-content>
      
      <mat-card-actions>
        <button mat-button (click)="onEdit.emit(budget.id)">
          Editar
        </button>
        <button mat-button color="warn" (click)="onDelete.emit(budget.id)">
          Excluir
        </button>
      </mat-card-actions>
    </mat-card>
  `,
  styleUrls: ["./budget-card.component.scss"]
})
export class BudgetCardComponent {
  @Input({ required: true }) budget!: BudgetDto;
  @Output() edit = new EventEmitter<string>();
  @Output() delete = new EventEmitter<string>();

  onEdit = this.edit;
  onDelete = this.delete;
}
```

## Fase 6: Configuração de Roteamento

### 6.1 App Routing

Atualize `src/app/app-routing.module.ts`:

```typescript
import { NgModule } from "@angular/core";
import { RouterModule, Routes } from "@angular/router";

const routes: Routes = [
  {
    path: "",
    redirectTo: "/dashboard",
    pathMatch: "full"
  },
  {
    path: "dashboard",
    loadChildren: () =>
      import("@features/dashboard/dashboard.module").then(m => m.DashboardModule)
  },
  {
    path: "budgets",
    loadChildren: () =>
      import("@features/budgets/budgets.module").then(m => m.BudgetsModule)
  },
  {
    path: "transactions",
    loadChildren: () =>
      import("@features/transactions/transactions.module").then(m => m.TransactionsModule)
  },
  {
    path: "goals",
    loadChildren: () =>
      import("@features/goals/goals.module").then(m => m.GoalsModule)
  },
  {
    path: "accounts",
    loadChildren: () =>
      import("@features/accounts/accounts.module").then(m => m.AccountsModule)
  },
  {
    path: "credit-cards",
    loadChildren: () =>
      import("@features/credit-cards/credit-cards.module").then(m => m.CreditCardsModule)
  },
  {
    path: "reports",
    loadChildren: () =>
      import("@features/reports/reports.module").then(m => m.ReportsModule)
  },
  {
    path: "onboarding",
    loadChildren: () =>
      import("@features/onboarding/onboarding.module").then(m => m.OnboardingModule)
  },
  {
    path: "**",
    redirectTo: "/dashboard"
  }
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule {}
```

## Fase 7: Implementação de DTOs

### 7.1 DTOs de Budget

Crie `src/app/dtos/budget/budget.dto.ts`:

```typescript
export interface BudgetDto {
  id: string;
  name: string;
  category: string;
  amount: number;
  usedAmount: number;
  period: "monthly" | "yearly";
  startDate: string;
  endDate: string;
  createdAt: string;
  updatedAt: string;
}

export interface CreateBudgetDto {
  name: string;
  category: string;
  amount: number;
  period: "monthly" | "yearly";
  startDate: string;
  endDate: string;
}

export interface UpdateBudgetDto {
  name?: string;
  category?: string;
  amount?: number;
  period?: "monthly" | "yearly";
  startDate?: string;
  endDate?: string;
}
```

### 7.2 DTOs Compartilhados

Crie `src/app/dtos/shared/user.dto.ts`:

```typescript
export interface User {
  id: string;
  email: string;
  name: string;
  avatar?: string;
  createdAt: string;
  updatedAt: string;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface LoginResponse {
  user: User;
  token: string;
  refreshToken: string;
}
```

## Fase 8: Testes

### 8.1 Teste de Componente

Crie `src/app/features/budgets/pages/budget-list/budget-list.component.spec.ts`:

```typescript
import { ComponentFixture, TestBed } from "@angular/core/testing";
import { of, throwError } from "rxjs";

import { BudgetListComponent } from "./budget-list.component";
import { BudgetService } from "../../services/budget.service";
import { BudgetState } from "../../state/budget.state";
import { BudgetDto } from "@dtos/budget";

describe("BudgetListComponent", () => {
  let component: BudgetListComponent;
  let fixture: ComponentFixture<BudgetListComponent>;
  let budgetService: jasmine.SpyObj<BudgetService>;
  let budgetState: jasmine.SpyObj<BudgetState>;

  const mockBudgets: BudgetDto[] = [
    {
      id: "1",
      name: "Orçamento Teste",
      category: "Casa",
      amount: 1000,
      usedAmount: 500,
      period: "monthly",
      startDate: "2025-01-01",
      endDate: "2025-01-31",
      createdAt: "2025-01-01T00:00:00Z",
      updatedAt: "2025-01-01T00:00:00Z"
    }
  ];

  beforeEach(async () => {
    const budgetServiceSpy = jasmine.createSpyObj("BudgetService", ["getBudgets"]);
    const budgetStateSpy = jasmine.createSpyObj("BudgetState", [
      "setLoading",
      "setError",
      "setBudgets"
    ]);

    await TestBed.configureTestingModule({
      imports: [BudgetListComponent],
      providers: [
        { provide: BudgetService, useValue: budgetServiceSpy },
        { provide: BudgetState, useValue: budgetStateSpy }
      ]
    }).compileComponents();

    fixture = TestBed.createComponent(BudgetListComponent);
    component = fixture.componentInstance;
    budgetService = TestBed.inject(BudgetService) as jasmine.SpyObj<BudgetService>;
    budgetState = TestBed.inject(BudgetState) as jasmine.SpyObj<BudgetState>;
  });

  it("deve carregar orçamentos com sucesso", () => {
    budgetService.getBudgets.and.returnValue(of(mockBudgets));

    component.ngOnInit();

    expect(budgetState.setLoading).toHaveBeenCalledWith(true);
    expect(budgetState.setError).toHaveBeenCalledWith(null);
    expect(budgetState.setBudgets).toHaveBeenCalledWith(mockBudgets);
    expect(budgetState.setLoading).toHaveBeenCalledWith(false);
  });

  it("deve tratar erro ao carregar orçamentos", () => {
    budgetService.getBudgets.and.returnValue(throwError(() => new Error("Erro")));

    component.ngOnInit();

    expect(budgetState.setError).toHaveBeenCalledWith("Erro ao carregar orçamentos");
    expect(budgetState.setLoading).toHaveBeenCalledWith(false);
  });
});
```

## Fase 9: Validação e Deploy

### 9.1 Checklist de Validação

- [ ] Todas as features implementadas seguem o template padrão
- [ ] DTOs estão definidos e tipados corretamente
- [ ] Serviços seguem padrões de Command/Query
- [ ] Estado é gerenciado com Angular Signals
- [ ] Componentes usam Design System
- [ ] Roteamento lazy loading configurado
- [ ] Testes unitários implementados
- [ ] ESLint sem erros de boundary
- [ ] Build de produção funcionando

### 9.2 Scripts de Build

Atualize `package.json`:

```json
{
  "scripts": {
    "build": "ng build --configuration=production",
    "build:features": "ng build --configuration=production --output-hashing=all",
    "test": "ng test --watch=false --browsers=ChromeHeadless",
    "test:coverage": "ng test --watch=false --browsers=ChromeHeadless --code-coverage",
    "lint": "ng lint",
    "lint:fix": "ng lint --fix"
  }
}
```

## Boas Práticas

### 9.3 Convenções de Nomenclatura

- **Features**: kebab-case (`budgets`, `credit-cards`)
- **Componentes**: PascalCase (`BudgetCardComponent`)
- **Serviços**: PascalCase + Service (`BudgetService`)
- **DTOs**: PascalCase + Dto (`BudgetDto`)
- **Arquivos**: kebab-case (`budget-card.component.ts`)

### 9.4 Estrutura de Commits

```
feat(features/budgets): adicionar componente de lista de orçamentos
fix(shared/ui): corrigir estilo do botão primário
docs(architecture): atualizar guia de implementação
test(features/budgets): adicionar testes para BudgetService
```

### 9.5 Code Review

- Verificar se feature está isolada
- Validar uso correto de DTOs
- Confirmar implementação de testes
- Verificar conformidade com Design System
- Validar regras de boundary

## Troubleshooting

### Problemas Comuns

1. **Erro de Import Circular**
   - Verificar dependências entre features
   - Usar shared services quando necessário

2. **Lazy Loading não funciona**
   - Verificar configuração de rotas
   - Confirmar exports corretos nos módulos

3. **Estado não atualiza**
   - Verificar se está usando signals
   - Confirmar injeção correta de serviços

4. **Testes falhando**
   - Verificar mocks e spies
   - Confirmar configuração do TestBed

## Conclusão

Este guia fornece uma base sólida para implementar a Feature-Based Architecture no projeto OrçaSonhos. Siga as fases sequencialmente e adapte conforme necessário para suas necessidades específicas.

Para dúvidas ou problemas, consulte a documentação técnica relacionada ou entre em contato com a equipe de arquitetura.
