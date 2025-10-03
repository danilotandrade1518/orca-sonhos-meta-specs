# Exemplos de Features - Feature-Based Architecture

---

**Metadados Estruturados para IA/RAG:**

```yaml
document_type: "feature_examples"
domain: "frontend_architecture"
audience: ["developers", "tech_leads", "architects"]
complexity: "intermediate"
tags: ["examples", "feature_based", "angular", "typescript", "patterns"]
related_docs:
  ["implementation-guide.md", "feature-organization.md", "state-management.md"]
ai_context: "Complete feature examples for Feature-Based Architecture implementation"
feature_types: ["simple", "complex", "with_state", "with_forms"]
last_updated: "2025-01-24"
```

---

## Visão Geral

Este documento apresenta exemplos práticos e completos de features implementadas seguindo a **Feature-Based Architecture** no projeto OrçaSonhos.

## Exemplo 1: Feature Simples - Dashboard

### Estrutura de Arquivos

```
/app/features/dashboard/
├── /components/
│   └── /molecules/
│       └── /summary-card/
│           ├── summary-card.component.ts
│           ├── summary-card.component.html
│           └── summary-card.component.scss
├── /pages/
│   └── /dashboard-home/
│       ├── dashboard-home.component.ts
│       ├── dashboard-home.component.html
│       └── dashboard-home.component.scss
├── /services/
│   └── dashboard.service.ts
├── /types/
│   └── dashboard.types.ts
├── dashboard-routing.module.ts
├── dashboard.module.ts
└── index.ts
```

### Dashboard Types

```typescript
// /app/features/dashboard/types/dashboard.types.ts
export interface DashboardSummary {
  totalBudgets: number;
  totalTransactions: number;
  totalGoals: number;
  monthlyExpenses: number;
  monthlyIncome: number;
}

export interface RecentTransaction {
  id: string;
  description: string;
  amount: number;
  date: string;
  category: string;
}

export interface BudgetProgress {
  id: string;
  name: string;
  used: number;
  limit: number;
  percentage: number;
}
```

### Dashboard Service

```typescript
// /app/features/dashboard/services/dashboard.service.ts
import { Injectable, inject } from "@angular/core";
import { Observable, combineLatest } from "rxjs";
import { map } from "rxjs/operators";

import { ApiService } from "@services/api.service";
import {
  DashboardSummary,
  RecentTransaction,
  BudgetProgress,
} from "../types/dashboard.types";

@Injectable({
  providedIn: "root",
})
export class DashboardService {
  private readonly apiService = inject(ApiService);

  getDashboardSummary(): Observable<DashboardSummary> {
    return this.apiService.get<DashboardSummary>("/dashboard/summary");
  }

  getRecentTransactions(limit: number = 5): Observable<RecentTransaction[]> {
    return this.apiService.get<RecentTransaction[]>(
      `/transactions/recent?limit=${limit}`
    );
  }

  getBudgetProgress(): Observable<BudgetProgress[]> {
    return this.apiService.get<BudgetProgress[]>("/budgets/progress");
  }

  getDashboardData(): Observable<{
    summary: DashboardSummary;
    recentTransactions: RecentTransaction[];
    budgetProgress: BudgetProgress[];
  }> {
    return combineLatest({
      summary: this.getDashboardSummary(),
      recentTransactions: this.getRecentTransactions(),
      budgetProgress: this.getBudgetProgress(),
    });
  }
}
```

### Summary Card Component

```typescript
// /app/features/dashboard/components/molecules/summary-card/summary-card.component.ts
import { Component, Input } from "@angular/core";
import { CommonModule } from "@angular/common";

import { SharedModule } from "@shared/shared.module";

@Component({
  selector: "app-summary-card",
  standalone: false,
  imports: [CommonModule, SharedModule],
  template: `
    <mat-card class="summary-card">
      <mat-card-content>
        <div class="card-header">
          <mat-icon [class]="iconClass">{{ icon }}</mat-icon>
          <h3>{{ title }}</h3>
        </div>
        <div class="card-value">
          <span class="value">{{ value | currency : "BRL" }}</span>
          @if (change !== undefined) {
          <span
            class="change"
            [class.positive]="change > 0"
            [class.negative]="change < 0"
          >
            {{ change > 0 ? "+" : "" }}{{ change | percent : "1.1-1" }}
          </span>
          }
        </div>
        @if (subtitle) {
        <p class="subtitle">{{ subtitle }}</p>
        }
      </mat-card-content>
    </mat-card>
  `,
  styleUrls: ["./summary-card.component.scss"],
})
export class SummaryCardComponent {
  @Input({ required: true }) title!: string;
  @Input({ required: true }) value!: number;
  @Input() icon!: string;
  @Input() iconClass?: string;
  @Input() change?: number;
  @Input() subtitle?: string;
}
```

### Dashboard Home Component

```typescript
// /app/features/dashboard/pages/dashboard-home/dashboard-home.component.ts
import { Component, OnInit, inject } from "@angular/core";
import { CommonModule } from "@angular/common";
import { RouterModule } from "@angular/router";

import { SharedModule } from "@shared/shared.module";
import { DashboardService } from "../../services/dashboard.service";
import { SummaryCardComponent } from "../../components/molecules/summary-card/summary-card.component";
import {
  DashboardSummary,
  RecentTransaction,
  BudgetProgress,
} from "../../types/dashboard.types";

@Component({
  selector: "app-dashboard-home",
  standalone: false,
  imports: [CommonModule, RouterModule, SharedModule, SummaryCardComponent],
  template: `
    <div class="dashboard">
      <h1>Dashboard</h1>

      <!-- Summary Cards -->
      <div class="summary-grid">
        <app-summary-card
          title="Orçamentos"
          [value]="summary?.totalBudgets || 0"
          icon="account_balance_wallet"
          [change]="0.12"
          subtitle="Total de orçamentos ativos"
        />
        <app-summary-card
          title="Transações"
          [value]="summary?.totalTransactions || 0"
          icon="receipt_long"
          [change]="-0.05"
          subtitle="Este mês"
        />
        <app-summary-card
          title="Metas"
          [value]="summary?.totalGoals || 0"
          icon="flag"
          [change]="0.08"
          subtitle="Metas ativas"
        />
        <app-summary-card
          title="Receitas"
          [value]="summary?.monthlyIncome || 0"
          icon="trending_up"
          [change]="0.15"
          subtitle="Este mês"
        />
      </div>

      <!-- Recent Transactions -->
      <mat-card class="recent-transactions">
        <mat-card-header>
          <mat-card-title>Transações Recentes</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          @if (recentTransactions.length > 0) {
          <div class="transaction-list">
            @for (transaction of recentTransactions; track transaction.id) {
            <div class="transaction-item">
              <div class="transaction-info">
                <span class="description">{{ transaction.description }}</span>
                <span class="category">{{ transaction.category }}</span>
              </div>
              <div class="transaction-amount">
                <span
                  [class.positive]="transaction.amount > 0"
                  [class.negative]="transaction.amount < 0"
                >
                  {{ transaction.amount | currency : "BRL" }}
                </span>
                <span class="date">{{
                  transaction.date | date : "short"
                }}</span>
              </div>
            </div>
            }
          </div>
          } @else {
          <p class="no-data">Nenhuma transação recente</p>
          }
        </mat-card-content>
      </mat-card>

      <!-- Budget Progress -->
      <mat-card class="budget-progress">
        <mat-card-header>
          <mat-card-title>Progresso dos Orçamentos</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          @if (budgetProgress.length > 0) {
          <div class="progress-list">
            @for (budget of budgetProgress; track budget.id) {
            <div class="progress-item">
              <div class="progress-header">
                <span class="budget-name">{{ budget.name }}</span>
                <span class="budget-percentage">{{
                  budget.percentage | percent : "1.0-0"
                }}</span>
              </div>
              <mat-progress-bar
                [value]="budget.percentage"
                [color]="getProgressColor(budget.percentage)"
                mode="determinate"
              ></mat-progress-bar>
              <div class="progress-details">
                <span
                  >{{ budget.used | currency : "BRL" }} de
                  {{ budget.limit | currency : "BRL" }}</span
                >
              </div>
            </div>
            }
          </div>
          } @else {
          <p class="no-data">Nenhum orçamento ativo</p>
          }
        </mat-card-content>
      </mat-card>
    </div>
  `,
  styleUrls: ["./dashboard-home.component.scss"],
})
export class DashboardHomeComponent implements OnInit {
  private readonly dashboardService = inject(DashboardService);

  summary: DashboardSummary | null = null;
  recentTransactions: RecentTransaction[] = [];
  budgetProgress: BudgetProgress[] = [];

  ngOnInit(): void {
    this.loadDashboardData();
  }

  private loadDashboardData(): void {
    this.dashboardService.getDashboardData().subscribe({
      next: (data) => {
        this.summary = data.summary;
        this.recentTransactions = data.recentTransactions;
        this.budgetProgress = data.budgetProgress;
      },
      error: (error) => {
        console.error("Erro ao carregar dados do dashboard:", error);
      },
    });
  }

  getProgressColor(percentage: number): string {
    if (percentage >= 100) return "warn";
    if (percentage >= 80) return "accent";
    return "primary";
  }
}
```

## Exemplo 2: Feature Complexa - Budgets

### Estrutura de Arquivos

```
/app/features/budgets/
├── /components/
│   ├── /atoms/
│   │   ├── /budget-amount/
│   │   └── /budget-period/
│   ├── /molecules/
│   │   ├── /budget-card/
│   │   ├── /budget-form/
│   │   └── /budget-progress/
│   └── /organisms/
│       ├── /budget-list/
│       └── /budget-detail/
├── /pages/
│   ├── /budget-list/
│   ├── /budget-detail/
│   └── /budget-create/
├── /services/
│   ├── /commands/
│   │   ├── create-budget.command.ts
│   │   ├── update-budget.command.ts
│   │   └── delete-budget.command.ts
│   ├── /queries/
│   │   ├── get-budgets.query.ts
│   │   └── get-budget.query.ts
│   └── budget.service.ts
├── /state/
│   └── budget.state.ts
├── /types/
│   └── budget.types.ts
├── /guards/
│   └── budget-detail.guard.ts
├── /resolvers/
│   └── budget.resolver.ts
├── budgets-routing.module.ts
├── budgets.module.ts
└── index.ts
```

### Budget Types

```typescript
// /app/features/budgets/types/budget.types.ts
export interface Budget {
  id: string;
  name: string;
  description?: string;
  category: BudgetCategory;
  amount: number;
  usedAmount: number;
  period: BudgetPeriod;
  startDate: string;
  endDate: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface BudgetCategory {
  id: string;
  name: string;
  color: string;
  icon: string;
}

export type BudgetPeriod = "weekly" | "monthly" | "yearly";

export interface CreateBudgetRequest {
  name: string;
  description?: string;
  categoryId: string;
  amount: number;
  period: BudgetPeriod;
  startDate: string;
  endDate: string;
}

export interface UpdateBudgetRequest {
  name?: string;
  description?: string;
  categoryId?: string;
  amount?: number;
  period?: BudgetPeriod;
  startDate?: string;
  endDate?: string;
  isActive?: boolean;
}

export interface BudgetFilters {
  categoryId?: string;
  period?: BudgetPeriod;
  isActive?: boolean;
  search?: string;
}
```

### Budget State

```typescript
// /app/features/budgets/state/budget.state.ts
import { Injectable, signal, computed } from "@angular/core";
import { Budget, BudgetFilters } from "../types/budget.types";

@Injectable({
  providedIn: "root",
})
export class BudgetState {
  private readonly _budgets = signal<Budget[]>([]);
  private readonly _loading = signal(false);
  private readonly _error = signal<string | null>(null);
  private readonly _filters = signal<BudgetFilters>({});
  private readonly _selectedBudget = signal<Budget | null>(null);

  // Readonly signals
  readonly budgets = this._budgets.asReadonly();
  readonly loading = this._loading.asReadonly();
  readonly error = this._error.asReadonly();
  readonly filters = this._filters.asReadonly();
  readonly selectedBudget = this._selectedBudget.asReadonly();

  // Computed signals
  readonly filteredBudgets = computed(() => {
    const budgets = this._budgets();
    const filters = this._filters();

    return budgets.filter((budget) => {
      if (filters.categoryId && budget.category.id !== filters.categoryId)
        return false;
      if (filters.period && budget.period !== filters.period) return false;
      if (
        filters.isActive !== undefined &&
        budget.isActive !== filters.isActive
      )
        return false;
      if (
        filters.search &&
        !budget.name.toLowerCase().includes(filters.search.toLowerCase())
      )
        return false;
      return true;
    });
  });

  readonly activeBudgets = computed(() =>
    this._budgets().filter((budget) => budget.isActive)
  );

  readonly totalBudgetAmount = computed(() =>
    this.activeBudgets().reduce((total, budget) => total + budget.amount, 0)
  );

  readonly totalUsedAmount = computed(() =>
    this.activeBudgets().reduce((total, budget) => total + budget.usedAmount, 0)
  );

  // Actions
  setBudgets(budgets: Budget[]): void {
    this._budgets.set(budgets);
  }

  addBudget(budget: Budget): void {
    this._budgets.update((current) => [...current, budget]);
  }

  updateBudget(updatedBudget: Budget): void {
    this._budgets.update((current) =>
      current.map((budget) =>
        budget.id === updatedBudget.id ? updatedBudget : budget
      )
    );
  }

  removeBudget(id: string): void {
    this._budgets.update((current) =>
      current.filter((budget) => budget.id !== id)
    );
  }

  setSelectedBudget(budget: Budget | null): void {
    this._selectedBudget.set(budget);
  }

  setFilters(filters: Partial<BudgetFilters>): void {
    this._filters.update((current) => ({ ...current, ...filters }));
  }

  clearFilters(): void {
    this._filters.set({});
  }

  setLoading(loading: boolean): void {
    this._loading.set(loading);
  }

  setError(error: string | null): void {
    this._error.set(error);
  }
}
```

### Budget Service

```typescript
// /app/features/budgets/services/budget.service.ts
import { Injectable, inject } from "@angular/core";
import { Observable, throwError } from "rxjs";
import { catchError, tap } from "rxjs/operators";

import { ApiService } from "@services/api.service";
import { BudgetState } from "../state/budget.state";
import {
  Budget,
  CreateBudgetRequest,
  UpdateBudgetRequest,
  BudgetFilters,
} from "../types/budget.types";

@Injectable({
  providedIn: "root",
})
export class BudgetService {
  private readonly apiService = inject(ApiService);
  private readonly budgetState = inject(BudgetState);

  getBudgets(filters?: BudgetFilters): Observable<Budget[]> {
    this.budgetState.setLoading(true);
    this.budgetState.setError(null);

    const params = this.buildQueryParams(filters);

    return this.apiService.get<Budget[]>(`/budgets${params}`).pipe(
      tap((budgets) => {
        this.budgetState.setBudgets(budgets);
        this.budgetState.setLoading(false);
      }),
      catchError((error) => {
        this.budgetState.setError("Erro ao carregar orçamentos");
        this.budgetState.setLoading(false);
        return throwError(() => error);
      })
    );
  }

  getBudget(id: string): Observable<Budget> {
    this.budgetState.setLoading(true);
    this.budgetState.setError(null);

    return this.apiService.get<Budget>(`/budgets/${id}`).pipe(
      tap((budget) => {
        this.budgetState.setSelectedBudget(budget);
        this.budgetState.setLoading(false);
      }),
      catchError((error) => {
        this.budgetState.setError("Erro ao carregar orçamento");
        this.budgetState.setLoading(false);
        return throwError(() => error);
      })
    );
  }

  createBudget(request: CreateBudgetRequest): Observable<Budget> {
    this.budgetState.setLoading(true);
    this.budgetState.setError(null);

    return this.apiService.post<Budget>("/budgets", request).pipe(
      tap((budget) => {
        this.budgetState.addBudget(budget);
        this.budgetState.setLoading(false);
      }),
      catchError((error) => {
        this.budgetState.setError("Erro ao criar orçamento");
        this.budgetState.setLoading(false);
        return throwError(() => error);
      })
    );
  }

  updateBudget(id: string, request: UpdateBudgetRequest): Observable<Budget> {
    this.budgetState.setLoading(true);
    this.budgetState.setError(null);

    return this.apiService.put<Budget>(`/budgets/${id}`, request).pipe(
      tap((budget) => {
        this.budgetState.updateBudget(budget);
        this.budgetState.setLoading(false);
      }),
      catchError((error) => {
        this.budgetState.setError("Erro ao atualizar orçamento");
        this.budgetState.setLoading(false);
        return throwError(() => error);
      })
    );
  }

  deleteBudget(id: string): Observable<void> {
    this.budgetState.setLoading(true);
    this.budgetState.setError(null);

    return this.apiService.delete<void>(`/budgets/${id}`).pipe(
      tap(() => {
        this.budgetState.removeBudget(id);
        this.budgetState.setLoading(false);
      }),
      catchError((error) => {
        this.budgetState.setError("Erro ao excluir orçamento");
        this.budgetState.setLoading(false);
        return throwError(() => error);
      })
    );
  }

  private buildQueryParams(filters?: BudgetFilters): string {
    if (!filters) return "";

    const params = new URLSearchParams();

    if (filters.categoryId) params.append("categoryId", filters.categoryId);
    if (filters.period) params.append("period", filters.period);
    if (filters.isActive !== undefined)
      params.append("isActive", filters.isActive.toString());
    if (filters.search) params.append("search", filters.search);

    const queryString = params.toString();
    return queryString ? `?${queryString}` : "";
  }
}
```

### Budget Form Component

```typescript
// /app/features/budgets/components/molecules/budget-form/budget-form.component.ts
import {
  Component,
  Input,
  Output,
  EventEmitter,
  OnInit,
  inject,
} from "@angular/core";
import { CommonModule } from "@angular/common";
import {
  FormBuilder,
  FormGroup,
  Validators,
  ReactiveFormsModule,
} from "@angular/forms";

import { SharedModule } from "@shared/shared.module";
import {
  Budget,
  CreateBudgetRequest,
  UpdateBudgetRequest,
  BudgetCategory,
} from "../../types/budget.types";

@Component({
  selector: "app-budget-form",
  standalone: false,
  imports: [CommonModule, ReactiveFormsModule, SharedModule],
  template: `
    <form [formGroup]="budgetForm" (ngSubmit)="onSubmit()" class="budget-form">
      <mat-card>
        <mat-card-header>
          <mat-card-title>{{
            isEdit ? "Editar Orçamento" : "Novo Orçamento"
          }}</mat-card-title>
        </mat-card-header>

        <mat-card-content>
          <div class="form-row">
            <mat-form-field appearance="outline" class="full-width">
              <mat-label>Nome</mat-label>
              <input
                matInput
                formControlName="name"
                placeholder="Ex: Orçamento de Alimentação"
              />
              @if (budgetForm.get('name')?.hasError('required')) {
              <mat-error>Nome é obrigatório</mat-error>
              }
            </mat-form-field>
          </div>

          <div class="form-row">
            <mat-form-field appearance="outline" class="full-width">
              <mat-label>Descrição</mat-label>
              <textarea
                matInput
                formControlName="description"
                rows="3"
                placeholder="Descrição opcional"
              ></textarea>
            </mat-form-field>
          </div>

          <div class="form-row">
            <mat-form-field appearance="outline">
              <mat-label>Categoria</mat-label>
              <mat-select formControlName="categoryId">
                @for (category of categories; track category.id) {
                <mat-option [value]="category.id">
                  <mat-icon>{{ category.icon }}</mat-icon>
                  {{ category.name }}
                </mat-option>
                }
              </mat-select>
              @if (budgetForm.get('categoryId')?.hasError('required')) {
              <mat-error>Categoria é obrigatória</mat-error>
              }
            </mat-form-field>

            <mat-form-field appearance="outline">
              <mat-label>Valor</mat-label>
              <input
                matInput
                type="number"
                formControlName="amount"
                placeholder="0.00"
              />
              <span matPrefix>R$&nbsp;</span>
              @if (budgetForm.get('amount')?.hasError('required')) {
              <mat-error>Valor é obrigatório</mat-error>
              } @if (budgetForm.get('amount')?.hasError('min')) {
              <mat-error>Valor deve ser maior que zero</mat-error>
              }
            </mat-form-field>
          </div>

          <div class="form-row">
            <mat-form-field appearance="outline">
              <mat-label>Período</mat-label>
              <mat-select formControlName="period">
                <mat-option value="weekly">Semanal</mat-option>
                <mat-option value="monthly">Mensal</mat-option>
                <mat-option value="yearly">Anual</mat-option>
              </mat-select>
              @if (budgetForm.get('period')?.hasError('required')) {
              <mat-error>Período é obrigatório</mat-error>
              }
            </mat-form-field>

            <mat-form-field appearance="outline">
              <mat-label>Data Início</mat-label>
              <input
                matInput
                [matDatepicker]="startPicker"
                formControlName="startDate"
              />
              <mat-datepicker-toggle
                matSuffix
                [for]="startPicker"
              ></mat-datepicker-toggle>
              <mat-datepicker #startPicker></mat-datepicker>
              @if (budgetForm.get('startDate')?.hasError('required')) {
              <mat-error>Data de início é obrigatória</mat-error>
              }
            </mat-form-field>

            <mat-form-field appearance="outline">
              <mat-label>Data Fim</mat-label>
              <input
                matInput
                [matDatepicker]="endPicker"
                formControlName="endDate"
              />
              <mat-datepicker-toggle
                matSuffix
                [for]="endPicker"
              ></mat-datepicker-toggle>
              <mat-datepicker #endPicker></mat-datepicker>
              @if (budgetForm.get('endDate')?.hasError('required')) {
              <mat-error>Data de fim é obrigatória</mat-error>
              }
            </mat-form-field>
          </div>

          @if (isEdit) {
          <div class="form-row">
            <mat-checkbox formControlName="isActive">
              Orçamento ativo
            </mat-checkbox>
          </div>
          }
        </mat-card-content>

        <mat-card-actions>
          <button mat-button type="button" (click)="onCancel.emit()">
            Cancelar
          </button>
          <button
            mat-raised-button
            color="primary"
            type="submit"
            [disabled]="budgetForm.invalid || loading"
          >
            {{ isEdit ? "Atualizar" : "Criar" }}
          </button>
        </mat-card-actions>
      </mat-card>
    </form>
  `,
  styleUrls: ["./budget-form.component.scss"],
})
export class BudgetFormComponent implements OnInit {
  @Input() budget?: Budget;
  @Input() categories: BudgetCategory[] = [];
  @Input() loading = false;
  @Output() save = new EventEmitter<
    CreateBudgetRequest | UpdateBudgetRequest
  >();
  @Output() cancel = new EventEmitter<void>();

  onCancel = this.cancel;

  budgetForm!: FormGroup;
  isEdit = false;

  private readonly fb = inject(FormBuilder);

  ngOnInit(): void {
    this.isEdit = !!this.budget;
    this.buildForm();
  }

  private buildForm(): void {
    this.budgetForm = this.fb.group({
      name: [this.budget?.name || "", [Validators.required]],
      description: [this.budget?.description || ""],
      categoryId: [this.budget?.category.id || "", [Validators.required]],
      amount: [
        this.budget?.amount || 0,
        [Validators.required, Validators.min(0.01)],
      ],
      period: [this.budget?.period || "monthly", [Validators.required]],
      startDate: [this.budget?.startDate || "", [Validators.required]],
      endDate: [this.budget?.endDate || "", [Validators.required]],
      isActive: [this.budget?.isActive ?? true],
    });
  }

  onSubmit(): void {
    if (this.budgetForm.valid) {
      const formValue = this.budgetForm.value;

      if (this.isEdit) {
        const updateRequest: UpdateBudgetRequest = {
          name: formValue.name,
          description: formValue.description,
          categoryId: formValue.categoryId,
          amount: formValue.amount,
          period: formValue.period,
          startDate: formValue.startDate,
          endDate: formValue.endDate,
          isActive: formValue.isActive,
        };
        this.save.emit(updateRequest);
      } else {
        const createRequest: CreateBudgetRequest = {
          name: formValue.name,
          description: formValue.description,
          categoryId: formValue.categoryId,
          amount: formValue.amount,
          period: formValue.period,
          startDate: formValue.startDate,
          endDate: formValue.endDate,
        };
        this.save.emit(createRequest);
      }
    }
  }
}
```

## Exemplo 3: Feature com Estado Complexo - Transactions

### Transaction State

```typescript
// /app/features/transactions/state/transaction.state.ts
import { Injectable, signal, computed } from "@angular/core";
import {
  Transaction,
  TransactionFilters,
  TransactionSummary,
} from "../types/transaction.types";

@Injectable({
  providedIn: "root",
})
export class TransactionState {
  private readonly _transactions = signal<Transaction[]>([]);
  private readonly _loading = signal(false);
  private readonly _error = signal<string | null>(null);
  private readonly _filters = signal<TransactionFilters>({});
  private readonly _selectedTransaction = signal<Transaction | null>(null);
  private readonly _summary = signal<TransactionSummary | null>(null);

  // Readonly signals
  readonly transactions = this._transactions.asReadonly();
  readonly loading = this._loading.asReadonly();
  readonly error = this._error.asReadonly();
  readonly filters = this._filters.asReadonly();
  readonly selectedTransaction = this._selectedTransaction.asReadonly();
  readonly summary = this._summary.asReadonly();

  // Computed signals
  readonly filteredTransactions = computed(() => {
    const transactions = this._transactions();
    const filters = this._filters();

    return transactions.filter((transaction) => {
      if (filters.categoryId && transaction.categoryId !== filters.categoryId)
        return false;
      if (filters.type && transaction.type !== filters.type) return false;
      if (
        filters.dateFrom &&
        new Date(transaction.date) < new Date(filters.dateFrom)
      )
        return false;
      if (
        filters.dateTo &&
        new Date(transaction.date) > new Date(filters.dateTo)
      )
        return false;
      if (filters.amountMin && transaction.amount < filters.amountMin)
        return false;
      if (filters.amountMax && transaction.amount > filters.amountMax)
        return false;
      if (
        filters.search &&
        !transaction.description
          .toLowerCase()
          .includes(filters.search.toLowerCase())
      )
        return false;
      return true;
    });
  });

  readonly totalIncome = computed(() =>
    this.filteredTransactions()
      .filter((t) => t.type === "income")
      .reduce((total, t) => total + t.amount, 0)
  );

  readonly totalExpenses = computed(() =>
    this.filteredTransactions()
      .filter((t) => t.type === "expense")
      .reduce((total, t) => total + t.amount, 0)
  );

  readonly netAmount = computed(
    () => this.totalIncome() - this.totalExpenses()
  );

  // Actions
  setTransactions(transactions: Transaction[]): void {
    this._transactions.set(transactions);
  }

  addTransaction(transaction: Transaction): void {
    this._transactions.update((current) => [transaction, ...current]);
  }

  updateTransaction(updatedTransaction: Transaction): void {
    this._transactions.update((current) =>
      current.map((transaction) =>
        transaction.id === updatedTransaction.id
          ? updatedTransaction
          : transaction
      )
    );
  }

  removeTransaction(id: string): void {
    this._transactions.update((current) =>
      current.filter((transaction) => transaction.id !== id)
    );
  }

  setSelectedTransaction(transaction: Transaction | null): void {
    this._selectedTransaction.set(transaction);
  }

  setFilters(filters: Partial<TransactionFilters>): void {
    this._filters.update((current) => ({ ...current, ...filters }));
  }

  clearFilters(): void {
    this._filters.set({});
  }

  setSummary(summary: TransactionSummary): void {
    this._summary.set(summary);
  }

  setLoading(loading: boolean): void {
    this._loading.set(loading);
  }

  setError(error: string | null): void {
    this._error.set(error);
  }
}
```

## Padrões de Implementação

### 1. Estrutura Consistente

Todas as features seguem a mesma estrutura:

```
/features/{feature-name}/
├── /components/          # Componentes específicos
├── /pages/              # Páginas da feature
├── /services/           # Serviços e lógica de negócio
├── /state/              # Estado local da feature
├── /types/              # Tipos TypeScript
├── /guards/             # Guards específicos
├── /resolvers/          # Resolvers específicos
├── {feature}.routing.ts # Roteamento
├── {feature}.module.ts  # Módulo da feature
└── index.ts             # Exports públicos
```

### 2. Gerenciamento de Estado

- Use **Angular Signals** para estado reativo
- Mantenha estado local por feature
- Use computed signals para valores derivados
- Implemente actions claras para mutações

### 3. Serviços e API

- Separe Commands (mutações) de Queries (consultas)
- Use DTOs para contratos de API
- Implemente tratamento de erro consistente
- Mantenha loading states

### 4. Componentes

- Use Atomic Design (atoms, molecules, organisms)
- Mantenha componentes focados e reutilizáveis
- Use OnPush change detection quando possível
- Implemente testes unitários

### 5. Roteamento

- Use lazy loading para features
- Implemente guards quando necessário
- Use resolvers para dados pré-carregados
- Mantenha rotas aninhadas organizadas

## Boas Práticas

### Nomenclatura

- **Features**: kebab-case (`budgets`, `credit-cards`)
- **Componentes**: PascalCase (`BudgetCardComponent`)
- **Serviços**: PascalCase + Service (`BudgetService`)
- **Arquivos**: kebab-case (`budget-card.component.ts`)

### Imports

```typescript
// Ordem de imports
import { Component } from "@angular/core"; // Angular core
import { CommonModule } from "@angular/common"; // Angular common
import { RouterModule } from "@angular/router"; // Angular router

import { SharedModule } from "@shared/shared.module"; // Shared modules
import { BudgetService } from "../services/budget.service"; // Feature services
import { Budget } from "../types/budget.types"; // Feature types
```

### Testes

```typescript
// Estrutura de teste
describe("ComponentName", () => {
  let component: ComponentName;
  let fixture: ComponentFixture<ComponentName>;
  let service: jasmine.SpyObj<ServiceName>;

  beforeEach(async () => {
    const serviceSpy = jasmine.createSpyObj("ServiceName", ["method"]);

    await TestBed.configureTestingModule({
      imports: [ComponentName],
      providers: [{ provide: ServiceName, useValue: serviceSpy }],
    }).compileComponents();

    fixture = TestBed.createComponent(ComponentName);
    component = fixture.componentInstance;
    service = TestBed.inject(ServiceName) as jasmine.SpyObj<ServiceName>;
  });

  it("should create", () => {
    expect(component).toBeTruthy();
  });
});
```

## Conclusão

Estes exemplos demonstram como implementar features seguindo a **Feature-Based Architecture** no projeto OrçaSonhos. Cada feature é independente, testável e mantém os princípios de Clean Architecture e DTO-First.

Para implementar uma nova feature, use estes exemplos como base e adapte conforme suas necessidades específicas.
