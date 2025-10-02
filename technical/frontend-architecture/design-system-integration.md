# Integração do Design System

## Visão Geral

O Design System do OrçaSonhos é baseado no **Angular Material** com uma camada de abstração personalizada, permitindo migração futura e customização específica do domínio financeiro. A integração com a arquitetura **Feature-Based** garante consistência visual e facilita manutenção.

## Estrutura do Design System

### Organização por Atomic Design

```
/app/shared/ui-components/
├── /atoms/                        # Componentes atômicos
│   ├── /button/
│   │   ├── button.component.ts
│   │   ├── button.component.html
│   │   ├── button.component.scss
│   │   └── button.component.spec.ts
│   ├── /input/
│   ├── /badge/
│   ├── /icon/
│   └── /avatar/
├── /molecules/                    # Componentes moleculares
│   ├── /form-field/
│   ├── /search-box/
│   ├── /card-header/
│   └── /data-table/
├── /organisms/                    # Componentes complexos
│   ├── /data-table/
│   ├── /form-wizard/
│   ├── /chart-container/
│   └── /navigation-menu/
├── /templates/                    # Templates de layout
│   ├── /page-layout/
│   ├── /form-layout/
│   └── /dashboard-layout/
└── ui-components.module.ts
```

## Componentes do Design System

### 1. Atoms (Componentes Atômicos)

#### Button Component

```typescript
// shared/ui-components/atoms/button/button.component.ts
@Component({
  selector: "os-button",
  template: `
    <button
      mat-raised-button
      [color]="color"
      [disabled]="disabled"
      [type]="type"
      [class]="cssClass"
    >
      <mat-icon *ngIf="icon" [class]="iconClass">{{ icon }}</mat-icon>
      <ng-content></ng-content>
    </button>
  `,
  styleUrls: ["./button.component.scss"],
})
export class ButtonComponent {
  @Input() variant: "primary" | "secondary" | "tertiary" = "primary";
  @Input() size: "small" | "medium" | "large" = "medium";
  @Input() icon?: string;
  @Input() iconClass?: string;
  @Input() disabled = false;
  @Input() type: "button" | "submit" | "reset" = "button";
  @Input() loading = false;
  @Input() cssClass = "";

  get color(): string {
    return this.variant === "primary"
      ? "primary"
      : this.variant === "secondary"
      ? "accent"
      : "basic";
  }
}
```

#### Input Component

```typescript
// shared/ui-components/atoms/input/input.component.ts
@Component({
  selector: "os-input",
  template: `
    <mat-form-field [appearance]="appearance" [class]="cssClass">
      <mat-label *ngIf="label">{{ label }}</mat-label>
      <input
        matInput
        [type]="type"
        [placeholder]="placeholder"
        [disabled]="disabled"
        [readonly]="readonly"
        [value]="value"
        (input)="onInput($event)"
        (blur)="onBlur($event)"
        (focus)="onFocus($event)"
      />
      <mat-hint *ngIf="hint">{{ hint }}</mat-hint>
      <mat-error *ngIf="error">{{ error }}</mat-error>
    </mat-form-field>
  `,
  styleUrls: ["./input.component.scss"],
})
export class InputComponent {
  @Input() label?: string;
  @Input() placeholder?: string;
  @Input() type: string = "text";
  @Input() appearance: "fill" | "outline" = "outline";
  @Input() disabled = false;
  @Input() readonly = false;
  @Input() hint?: string;
  @Input() error?: string;
  @Input() cssClass = "";
  @Input() value = "";

  @Output() valueChange = new EventEmitter<string>();
  @Output() input = new EventEmitter<Event>();
  @Output() blur = new EventEmitter<Event>();
  @Output() focus = new EventEmitter<Event>();

  onInput(event: Event): void {
    const target = event.target as HTMLInputElement;
    this.value = target.value;
    this.valueChange.emit(this.value);
    this.input.emit(event);
  }

  onBlur(event: Event): void {
    this.blur.emit(event);
  }

  onFocus(event: Event): void {
    this.focus.emit(event);
  }
}
```

#### Money Input Component

```typescript
// shared/ui-components/atoms/money-input/money-input.component.ts
@Component({
  selector: "os-money-input",
  template: `
    <mat-form-field [appearance]="appearance" [class]="cssClass">
      <mat-label *ngIf="label">{{ label }}</mat-label>
      <input
        matInput
        type="text"
        [placeholder]="placeholder"
        [disabled]="disabled"
        [readonly]="readonly"
        [value]="displayValue"
        (input)="onInput($event)"
        (blur)="onBlur($event)"
        (focus)="onFocus($event)"
      />
      <span matPrefix>R$&nbsp;</span>
      <mat-hint *ngIf="hint">{{ hint }}</mat-hint>
      <mat-error *ngIf="error">{{ error }}</mat-error>
    </mat-form-field>
  `,
  styleUrls: ["./money-input.component.scss"],
})
export class MoneyInputComponent {
  @Input() label?: string;
  @Input() placeholder?: string;
  @Input() appearance: "fill" | "outline" = "outline";
  @Input() disabled = false;
  @Input() readonly = false;
  @Input() hint?: string;
  @Input() error?: string;
  @Input() cssClass = "";
  @Input() value = 0; // Valor em centavos

  @Output() valueChange = new EventEmitter<number>();
  @Output() input = new EventEmitter<Event>();
  @Output() blur = new EventEmitter<Event>();
  @Output() focus = new EventEmitter<Event>();

  get displayValue(): string {
    return this.formatCurrency(this.value);
  }

  onInput(event: Event): void {
    const target = event.target as HTMLInputElement;
    const numericValue = this.parseCurrency(target.value);
    this.value = numericValue;
    this.valueChange.emit(this.value);
    this.input.emit(event);
  }

  private formatCurrency(value: number): string {
    return (value / 100).toLocaleString("pt-BR", {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    });
  }

  private parseCurrency(value: string): number {
    const numericValue = value.replace(/[^\d]/g, "");
    return parseInt(numericValue) || 0;
  }
}
```

### 2. Molecules (Componentes Moleculares)

#### Form Field Component

```typescript
// shared/ui-components/molecules/form-field/form-field.component.ts
@Component({
  selector: "os-form-field",
  template: `
    <div class="form-field" [class]="cssClass">
      <label *ngIf="label" class="form-field__label">
        {{ label }}
        <span *ngIf="required" class="form-field__required">*</span>
      </label>

      <div class="form-field__input" [class]="inputClass">
        <ng-content select="[slot=input]"></ng-content>
      </div>

      <div *ngIf="error" class="form-field__error">
        <mat-icon>error</mat-icon>
        <span>{{ error }}</span>
      </div>

      <div *ngIf="hint && !error" class="form-field__hint">
        {{ hint }}
      </div>
    </div>
  `,
  styleUrls: ["./form-field.component.scss"],
})
export class FormFieldComponent {
  @Input() label?: string;
  @Input() required = false;
  @Input() error?: string;
  @Input() hint?: string;
  @Input() cssClass = "";
  @Input() inputClass = "";
}
```

#### Card Component

```typescript
// shared/ui-components/molecules/card/card.component.ts
@Component({
  selector: "os-card",
  template: `
    <mat-card [class]="cssClass">
      <mat-card-header *ngIf="title || subtitle">
        <mat-card-title>{{ title }}</mat-card-title>
        <mat-card-subtitle *ngIf="subtitle">{{ subtitle }}</mat-card-subtitle>
      </mat-card-header>

      <mat-card-content>
        <ng-content></ng-content>
      </mat-card-content>

      <mat-card-actions *ngIf="hasActions" align="end">
        <ng-content select="[slot=actions]"></ng-content>
      </mat-card-actions>
    </mat-card>
  `,
  styleUrls: ["./card.component.scss"],
})
export class CardComponent {
  @Input() title?: string;
  @Input() subtitle?: string;
  @Input() cssClass = "";

  @ContentChild("actions") hasActions = false;
}
```

### 3. Organisms (Componentes Complexos)

#### Data Table Component

```typescript
// shared/ui-components/organisms/data-table/data-table.component.ts
@Component({
  selector: "os-data-table",
  template: `
    <div class="data-table" [class]="cssClass">
      <div class="data-table__header" *ngIf="title">
        <h3>{{ title }}</h3>
        <div class="data-table__actions">
          <ng-content select="[slot=header-actions]"></ng-content>
        </div>
      </div>

      <div class="data-table__filters" *ngIf="hasFilters">
        <ng-content select="[slot=filters]"></ng-content>
      </div>

      <div class="data-table__content">
        <table mat-table [dataSource]="dataSource" [class]="tableClass">
          <ng-container
            *ngFor="let column of columns"
            [matColumnDef]="column.key"
          >
            <th mat-header-cell *matHeaderCellDef [class]="column.headerClass">
              {{ column.title }}
            </th>
            <td mat-cell *matCellDef="let element" [class]="column.cellClass">
              <ng-container [ngSwitch]="column.type">
                <span *ngSwitchCase="'text'">{{ element[column.key] }}</span>
                <span *ngSwitchCase="'currency'">{{
                  formatCurrency(element[column.key])
                }}</span>
                <span *ngSwitchCase="'date'">{{
                  formatDate(element[column.key])
                }}</span>
                <span *ngSwitchCase="'badge'">
                  <os-badge [variant]="getBadgeVariant(element[column.key])">
                    {{ element[column.key] }}
                  </os-badge>
                </span>
                <ng-container *ngSwitchDefault>
                  <ng-content
                    [select]="'[slot=cell-' + column.key + ']'"
                    [ngTemplateOutlet]="column.template"
                    [ngTemplateOutletContext]="{ $implicit: element }"
                  >
                  </ng-content>
                </ng-container>
              </ng-container>
            </td>
          </ng-container>

          <tr mat-header-row *matHeaderRowDef="displayedColumns"></tr>
          <tr mat-row *matRowDef="let row; columns: displayedColumns"></tr>
        </table>
      </div>

      <div class="data-table__pagination" *ngIf="pagination">
        <mat-paginator
          [length]="totalItems"
          [pageSize]="pageSize"
          [pageSizeOptions]="pageSizeOptions"
          (page)="onPageChange($event)"
        >
        </mat-paginator>
      </div>
    </div>
  `,
  styleUrls: ["./data-table.component.scss"],
})
export class DataTableComponent<T> {
  @Input() dataSource: T[] = [];
  @Input() columns: TableColumn[] = [];
  @Input() title?: string;
  @Input() pagination = false;
  @Input() pageSize = 10;
  @Input() pageSizeOptions = [5, 10, 25, 50];
  @Input() totalItems = 0;
  @Input() cssClass = "";
  @Input() tableClass = "";

  @Output() pageChange = new EventEmitter<PageEvent>();
  @Output() rowClick = new EventEmitter<T>();

  get displayedColumns(): string[] {
    return this.columns.map((col) => col.key);
  }

  get hasFilters(): boolean {
    return !!this.filters?.length;
  }

  onPageChange(event: PageEvent): void {
    this.pageChange.emit(event);
  }

  formatCurrency(value: number): string {
    return (value / 100).toLocaleString("pt-BR", {
      style: "currency",
      currency: "BRL",
    });
  }

  formatDate(value: string | Date): string {
    return new Date(value).toLocaleDateString("pt-BR");
  }
}
```

## Integração com Features

### 1. Uso em Features

```typescript
// features/budgets/components/molecules/budget-form/budget-form.component.ts
@Component({
  selector: "os-budget-form",
  template: `
    <form [formGroup]="form" (ngSubmit)="onSubmit()">
      <os-card>
        <os-card-header
          title="Criar Orçamento"
          subtitle="Defina os limites para suas categorias"
        >
          <os-button slot="actions" variant="secondary" (click)="onCancel()">
            Cancelar
          </os-button>
        </os-card-header>

        <os-card-content>
          <div class="budget-form__fields">
            <os-form-field
              label="Nome do Orçamento"
              [error]="getFieldError('name')"
              [required]="true"
            >
              <os-input
                slot="input"
                formControlName="name"
                placeholder="Ex: Orçamento Mensal"
                [error]="getFieldError('name')"
              />
            </os-form-field>

            <os-form-field
              label="Valor Total"
              [error]="getFieldError('totalAmount')"
              [required]="true"
            >
              <os-money-input
                slot="input"
                formControlName="totalAmount"
                placeholder="0,00"
              />
            </os-form-field>

            <os-form-field
              label="Período"
              [error]="getFieldError('period')"
              [required]="true"
            >
              <os-select
                slot="input"
                formControlName="period"
                [options]="periodOptions"
              />
            </os-form-field>
          </div>
        </os-card-content>

        <mat-card-actions slot="actions" align="end">
          <os-button
            type="submit"
            variant="primary"
            [loading]="submitting()"
            [disabled]="form.invalid"
          >
            Criar Orçamento
          </os-button>
        </mat-card-actions>
      </os-card>
    </form>
  `,
  styleUrls: ["./budget-form.component.scss"],
})
export class BudgetFormComponent {
  // Component implementation
}
```

### 2. Customização por Feature

```typescript
// features/budgets/budget-form.component.scss
.budget-form {
  &__fields {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 1rem;

    @media (max-width: 768px) {
      grid-template-columns: 1fr;
    }
  }

  // Customizações específicas do domínio de orçamentos
  os-form-field {
    &[data-field="totalAmount"] {
      .mat-form-field {
        font-size: 1.2rem;
        font-weight: 600;
      }
    }
  }
}
```

## Tema e Customização

### 1. Tema Principal

```typescript
// shared/theme/theme.scss
@use '@angular/material' as mat;

$primary-palette: mat.define-palette(mat.$blue-palette, 500, 100, 700);
$accent-palette: mat.define-palette(mat.$green-palette, 500, 100, 700);
$warn-palette: mat.define-palette(mat.$red-palette, 500, 100, 700);

$light-theme: mat.define-light-theme((
  color: (
    primary: $primary-palette,
    accent: $accent-palette,
    warn: $warn-palette,
  ),
  typography: mat.define-typography-config(),
  density: 0,
));

$dark-theme: mat.define-dark-theme((
  color: (
    primary: $primary-palette,
    accent: $accent-palette,
    warn: $warn-palette,
  ),
  typography: mat.define-typography-config(),
  density: 0,
));

@include mat.all-component-themes($light-theme);

.dark-theme {
  @include mat.all-component-colors($dark-theme);
}
```

### 2. Tokens de Design

```typescript
// shared/theme/design-tokens.scss
:root {
  // Cores
  --os-color-primary: #1976d2;
  --os-color-primary-light: #42a5f5;
  --os-color-primary-dark: #1565c0;

  --os-color-success: #4caf50;
  --os-color-warning: #ff9800;
  --os-color-error: #f44336;

  // Tipografia
  --os-font-family: 'Roboto', sans-serif;
  --os-font-size-xs: 0.75rem;
  --os-font-size-sm: 0.875rem;
  --os-font-size-md: 1rem;
  --os-font-size-lg: 1.125rem;
  --os-font-size-xl: 1.25rem;

  // Espaçamentos
  --os-spacing-xs: 0.25rem;
  --os-spacing-sm: 0.5rem;
  --os-spacing-md: 1rem;
  --os-spacing-lg: 1.5rem;
  --os-spacing-xl: 2rem;

  // Bordas
  --os-border-radius-sm: 4px;
  --os-border-radius-md: 8px;
  --os-border-radius-lg: 12px;

  // Sombras
  --os-shadow-sm: 0 1px 3px rgba(0, 0, 0, 0.12);
  --os-shadow-md: 0 4px 6px rgba(0, 0, 0, 0.1);
  --os-shadow-lg: 0 10px 15px rgba(0, 0, 0, 0.1);
}
```

## Estratégia de Migração

### 1. Fase 1: Abstração Angular Material

```typescript
// shared/ui-components/atoms/button/button.component.ts
@Component({
  selector: "os-button",
  template: `
    <button
      mat-raised-button
      [color]="color"
      [disabled]="disabled"
      [type]="type"
      [class]="cssClass"
    >
      <mat-icon *ngIf="icon" [class]="iconClass">{{ icon }}</mat-icon>
      <ng-content></ng-content>
    </button>
  `,
})
export class ButtonComponent {
  // Implementação atual usando Angular Material
}
```

### 2. Fase 2: Componentes Customizados

```typescript
// shared/ui-components/atoms/button/button.component.ts
@Component({
  selector: "os-button",
  template: `
    <button [class]="buttonClasses" [disabled]="disabled" [type]="type">
      <os-icon *ngIf="icon" [name]="icon" [class]="iconClass"></os-icon>
      <ng-content></ng-content>
    </button>
  `,
})
export class ButtonComponent {
  // Implementação futura com componentes customizados
}
```

## Testes do Design System

### 1. Testes Unitários

```typescript
// shared/ui-components/atoms/button/button.component.spec.ts
describe("ButtonComponent", () => {
  let component: ButtonComponent;
  let fixture: ComponentFixture<ButtonComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ButtonComponent],
      imports: [MatButtonModule, MatIconModule],
    }).compileComponents();

    fixture = TestBed.createComponent(ButtonComponent);
    component = fixture.componentInstance;
  });

  it("should create", () => {
    expect(component).toBeTruthy();
  });

  it("should apply correct variant classes", () => {
    component.variant = "primary";
    fixture.detectChanges();

    const button = fixture.debugElement.query(By.css("button"));
    expect(button.nativeElement.classList).toContain("mat-raised-button");
  });

  it("should emit click event", () => {
    spyOn(component.click, "emit");

    const button = fixture.debugElement.query(By.css("button"));
    button.nativeElement.click();

    expect(component.click.emit).toHaveBeenCalled();
  });
});
```

### 2. Testes de Integração

```typescript
// features/budgets/components/molecules/budget-form/budget-form.component.spec.ts
describe("BudgetFormComponent", () => {
  let component: BudgetFormComponent;
  let fixture: ComponentFixture<BudgetFormComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [BudgetFormComponent],
      imports: [
        ReactiveFormsModule,
        UiComponentsModule,
        MatCardModule,
        MatFormFieldModule,
      ],
    }).compileComponents();
  });

  it("should render form fields correctly", () => {
    fixture.detectChanges();

    const nameField = fixture.debugElement.query(
      By.css('os-form-field[data-field="name"]')
    );
    const amountField = fixture.debugElement.query(
      By.css('os-form-field[data-field="totalAmount"]')
    );

    expect(nameField).toBeTruthy();
    expect(amountField).toBeTruthy();
  });
});
```

## Boas Práticas

### 1. Consistência Visual

- Use sempre os componentes do Design System
- Mantenha consistência de espaçamentos e tipografia
- Aplique tokens de design consistentemente

### 2. Acessibilidade

- Sempre inclua labels e hints apropriados
- Use ARIA attributes quando necessário
- Teste navegação por teclado

### 3. Performance

- Lazy loading para componentes pesados
- OnPush change detection
- Otimização de bundle size

### 4. Manutenibilidade

- Documentação clara de cada componente
- Exemplos de uso
- Versionamento semântico

---

**Ver também:**

- [UI System](./ui-system.md) - Sistema de UI completo
- [Feature Organization](./feature-organization.md) - Organização das features
- [State Management](./state-management.md) - Gerenciamento de estado
- [Accessibility](./accessibility.md) - Requisitos de acessibilidade
