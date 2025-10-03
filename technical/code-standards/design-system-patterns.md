# Design System Patterns - Padrões do Design System

## 🎨 Estrutura do Design System

### Organização por Atomic Design

```typescript
// /src/app/shared/ui-components/
// ├── ui-components.module.ts
// ├── index.ts
// ├── /atoms
// │   ├── os-button/
// │   │   ├── os-button.component.ts
// │   │   ├── os-button.component.html
// │   │   ├── os-button.component.scss
// │   │   └── os-button.component.spec.ts
// │   ├── os-input/
// │   ├── os-icon/
// │   └── os-spinner/
// ├── /molecules
// │   ├── os-form-field/
// │   ├── os-search-box/
// │   ├── os-data-table/
// │   └── os-card/
// ├── /organisms
// │   ├── os-navigation/
// │   ├── os-sidebar/
// │   ├── os-header/
// │   └── os-footer/
// └── /templates
//     ├── os-page-layout/
//     ├── os-dashboard-layout/
//     └── os-auth-layout/
```

### Design System Module

```typescript
// ui-components.module.ts
@NgModule({
  declarations: [
    // Atoms
    OsButtonComponent,
    OsInputComponent,
    OsIconComponent,
    OsSpinnerComponent,

    // Molecules
    OsFormFieldComponent,
    OsSearchBoxComponent,
    OsDataTableComponent,
    OsCardComponent,

    // Organisms
    OsNavigationComponent,
    OsSidebarComponent,
    OsHeaderComponent,
    OsFooterComponent,

    // Templates
    OsPageLayoutComponent,
    OsDashboardLayoutComponent,
    OsAuthLayoutComponent,
  ],
  imports: [
    CommonModule,
    ReactiveFormsModule,
    RouterModule,
    MatButtonModule,
    MatInputModule,
    MatIconModule,
    MatProgressSpinnerModule,
    MatCardModule,
    MatTableModule,
    MatToolbarModule,
    MatSidenavModule,
  ],
  exports: [
    // Atoms
    OsButtonComponent,
    OsInputComponent,
    OsIconComponent,
    OsSpinnerComponent,

    // Molecules
    OsFormFieldComponent,
    OsSearchBoxComponent,
    OsDataTableComponent,
    OsCardComponent,

    // Organisms
    OsNavigationComponent,
    OsSidebarComponent,
    OsHeaderComponent,
    OsFooterComponent,

    // Templates
    OsPageLayoutComponent,
    OsDashboardLayoutComponent,
    OsAuthLayoutComponent,
  ],
})
export class UiComponentsModule {}
```

## ⚛️ Atomic Design Patterns

### Atoms - Componentes Básicos

#### Button Component

```typescript
// os-button.component.ts
@Component({
  selector: "os-button",
  standalone: true,
  imports: [CommonModule, MatButtonModule],
  template: `
    <button
      mat-button
      [type]="type"
      [disabled]="disabled() || loading()"
      [class]="buttonClasses()"
      (click)="onClick($event)"
    >
      @if (loading()) {
      <os-spinner size="small" />
      } @else { @if (icon()) {
      <os-icon [name]="icon()" [size]="iconSize()" />
      } @if (text()) {
      <span>{{ text() }}</span>
      }
      <ng-content />
      }
    </button>
  `,
  styleUrls: ["./os-button.component.scss"],
})
export class OsButtonComponent {
  // ✅ Input signals
  readonly type = input<"button" | "submit" | "reset">("button");
  readonly variant = input<"primary" | "secondary" | "tertiary" | "danger">(
    "primary"
  );
  readonly size = input<"small" | "medium" | "large">("medium");
  readonly disabled = input(false);
  readonly loading = input(false);
  readonly icon = input<string | null>(null);
  readonly text = input<string | null>(null);
  readonly fullWidth = input(false);

  // ✅ Output signals
  readonly clicked = output<MouseEvent>();

  // ✅ Computed values
  readonly buttonClasses = computed(() => {
    const classes = ["os-button"];
    classes.push(`os-button--${this.variant()}`);
    classes.push(`os-button--${this.size()}`);

    if (this.fullWidth()) {
      classes.push("os-button--full-width");
    }

    if (this.loading()) {
      classes.push("os-button--loading");
    }

    return classes.join(" ");
  });

  readonly iconSize = computed(() => {
    const sizeMap = {
      small: "small",
      medium: "medium",
      large: "large",
    };
    return sizeMap[this.size()];
  });

  onClick(event: MouseEvent): void {
    if (!this.disabled() && !this.loading()) {
      this.clicked.emit(event);
    }
  }
}
```

#### Input Component

```typescript
// os-input.component.ts
@Component({
  selector: "os-input",
  standalone: true,
  imports: [CommonModule, MatInputModule, ReactiveFormsModule],
  template: `
    <mat-form-field [class]="formFieldClasses()">
      @if (label()) {
      <mat-label>{{ label() }}</mat-label>
      }

      <input
        matInput
        [type]="type()"
        [placeholder]="placeholder()"
        [disabled]="disabled()"
        [readonly]="readonly()"
        [value]="value()"
        [formControl]="control()"
        (input)="onInput($event)"
        (blur)="onBlur($event)"
        (focus)="onFocus($event)"
      />

      @if (hint()) {
      <mat-hint>{{ hint() }}</mat-hint>
      } @if (error()) {
      <mat-error>{{ error() }}</mat-error>
      } @if (icon()) {
      <mat-icon matSuffix>{{ icon() }}</mat-icon>
      }
    </mat-form-field>
  `,
  styleUrls: ["./os-input.component.scss"],
})
export class OsInputComponent {
  // ✅ Input signals
  readonly type = input<"text" | "email" | "password" | "number" | "tel">(
    "text"
  );
  readonly label = input<string | null>(null);
  readonly placeholder = input<string | null>(null);
  readonly hint = input<string | null>(null);
  readonly error = input<string | null>(null);
  readonly disabled = input(false);
  readonly readonly = input(false);
  readonly required = input(false);
  readonly value = input<string>("");
  readonly icon = input<string | null>(null);
  readonly control = input<FormControl | null>(null);

  // ✅ Output signals
  readonly input = output<Event>();
  readonly blur = output<FocusEvent>();
  readonly focus = output<FocusEvent>();
  readonly valueChange = output<string>();

  // ✅ Computed values
  readonly formFieldClasses = computed(() => {
    const classes = ["os-input"];

    if (this.error()) {
      classes.push("os-input--error");
    }

    if (this.disabled()) {
      classes.push("os-input--disabled");
    }

    if (this.readonly()) {
      classes.push("os-input--readonly");
    }

    return classes.join(" ");
  });

  onInput(event: Event): void {
    const target = event.target as HTMLInputElement;
    this.valueChange.emit(target.value);
    this.input.emit(event);
  }

  onBlur(event: FocusEvent): void {
    this.blur.emit(event);
  }

  onFocus(event: FocusEvent): void {
    this.focus.emit(event);
  }
}
```

### Molecules - Componentes Compostos

#### Form Field Component

```typescript
// os-form-field.component.ts
@Component({
  selector: "os-form-field",
  standalone: true,
  imports: [
    CommonModule,
    OsInputComponent,
    OsSelectComponent,
    OsTextareaComponent,
  ],
  template: `
    <div class="os-form-field" [class]="formFieldClasses()">
      @if (label()) {
      <label class="os-form-field__label" [for]="fieldId()">
        {{ label() }}
        @if (required()) {
        <span class="os-form-field__required">*</span>
        }
      </label>
      }

      <div class="os-form-field__control">
        @switch (type()) { @case ('input') {
        <os-input
          [id]="fieldId()"
          [type]="inputType()"
          [placeholder]="placeholder()"
          [disabled]="disabled()"
          [readonly]="readonly()"
          [value]="value()"
          [control]="control()"
          [error]="error()"
          (valueChange)="onValueChange($event)"
        />
        } @case ('select') {
        <os-select
          [id]="fieldId()"
          [options]="options()"
          [placeholder]="placeholder()"
          [disabled]="disabled()"
          [value]="value()"
          [control]="control()"
          [error]="error()"
          (valueChange)="onValueChange($event)"
        />
        } @case ('textarea') {
        <os-textarea
          [id]="fieldId()"
          [placeholder]="placeholder()"
          [disabled]="disabled()"
          [readonly]="readonly()"
          [value]="value()"
          [control]="control()"
          [error]="error()"
          (valueChange)="onValueChange($event)"
        />
        } }
      </div>

      @if (hint() && !error()) {
      <div class="os-form-field__hint">{{ hint() }}</div>
      } @if (error()) {
      <div class="os-form-field__error">{{ error() }}</div>
      }
    </div>
  `,
  styleUrls: ["./os-form-field.component.scss"],
})
export class OsFormFieldComponent {
  // ✅ Input signals
  readonly type = input<"input" | "select" | "textarea">("input");
  readonly inputType = input<"text" | "email" | "password" | "number" | "tel">(
    "text"
  );
  readonly label = input<string | null>(null);
  readonly placeholder = input<string | null>(null);
  readonly hint = input<string | null>(null);
  readonly error = input<string | null>(null);
  readonly disabled = input(false);
  readonly readonly = input(false);
  readonly required = input(false);
  readonly value = input<string>("");
  readonly options = input<SelectOption[]>([]);
  readonly control = input<FormControl | null>(null);

  // ✅ Output signals
  readonly valueChange = output<string>();

  // ✅ Computed values
  readonly fieldId = computed(
    () => `field-${Math.random().toString(36).substr(2, 9)}`
  );

  readonly formFieldClasses = computed(() => {
    const classes = ["os-form-field"];

    if (this.error()) {
      classes.push("os-form-field--error");
    }

    if (this.disabled()) {
      classes.push("os-form-field--disabled");
    }

    if (this.required()) {
      classes.push("os-form-field--required");
    }

    return classes.join(" ");
  });

  onValueChange(value: string): void {
    this.valueChange.emit(value);
  }
}
```

#### Data Table Component

```typescript
// os-data-table.component.ts
@Component({
  selector: "os-data-table",
  standalone: true,
  imports: [CommonModule, MatTableModule, MatCheckboxModule, OsButtonComponent],
  template: `
    <div class="os-data-table" [class]="tableClasses()">
      @if (loading()) {
      <div class="os-data-table__loading">
        <os-spinner size="large" />
        <p>{{ loadingText() }}</p>
      </div>
      } @else if (error()) {
      <div class="os-data-table__error">
        <os-icon name="error" size="large" />
        <p>{{ error() }}</p>
        @if (retryable()) {
        <os-button variant="secondary" (clicked)="onRetry()">
          Tentar Novamente
        </os-button>
        }
      </div>
      } @else if (data().length === 0) {
      <div class="os-data-table__empty">
        <os-icon name="inbox" size="large" />
        <p>{{ emptyText() }}</p>
        @if (emptyAction()) {
        <os-button variant="primary" (clicked)="onEmptyAction()">
          {{ emptyActionText() }}
        </os-button>
        }
      </div>
      } @else {
      <table mat-table [dataSource]="data()" class="os-data-table__table">
        @if (selectable()) {
        <ng-container matColumnDef="select">
          <th mat-header-cell *matHeaderCellDef>
            <mat-checkbox
              [checked]="isAllSelected()"
              [indeterminate]="isIndeterminate()"
              (change)="onSelectAll($event)"
            />
          </th>
          <td mat-cell *matCellDef="let row">
            <mat-checkbox
              [checked]="isSelected(row)"
              (change)="onSelectRow(row, $event)"
            />
          </td>
        </ng-container>
        } @for (column of columns(); track column.key) {
        <ng-container [matColumnDef]="column.key">
          <th mat-header-cell *matHeaderCellDef [class]="column.headerClass">
            {{ column.label }}
            @if (column.sortable) {
            <os-icon
              name="sort"
              [class]="getSortIconClass(column.key)"
              (click)="onSort(column.key)"
            />
            }
          </th>
          <td mat-cell *matCellDef="let row" [class]="column.cellClass">
            <ng-container [ngSwitch]="column.type">
              @switch ('text') {
              <span>{{ getCellValue(row, column.key) }}</span>
              } @switch ('date') {
              <span>{{ formatDate(getCellValue(row, column.key)) }}</span>
              } @switch ('currency') {
              <span>{{ formatCurrency(getCellValue(row, column.key)) }}</span>
              } @switch ('custom') {
              <ng-container
                [ngTemplateOutlet]="column.template"
                [ngTemplateOutletContext]="{ $implicit: row }"
              />
              }
            </ng-container>
          </td>
        </ng-container>
        }

        <tr mat-header-row *matHeaderRowDef="displayedColumns()"></tr>
        <tr
          mat-row
          *matRowDef="let row; columns: displayedColumns()"
          [class]="getRowClasses(row)"
          (click)="onRowClick(row)"
          (dblclick)="onRowDoubleClick(row)"
        />
      </table>

      @if (pagination()) {
      <mat-paginator
        [pageSize]="pageSize()"
        [pageSizeOptions]="pageSizeOptions()"
        [length]="totalItems()"
        (page)="onPageChange($event)"
      />
      } }
    </div>
  `,
  styleUrls: ["./os-data-table.component.scss"],
})
export class OsDataTableComponent<T = any> {
  // ✅ Input signals
  readonly data = input<T[]>([]);
  readonly columns = input<TableColumn[]>([]);
  readonly loading = input(false);
  readonly error = input<string | null>(null);
  readonly selectable = input(false);
  readonly pagination = input(false);
  readonly pageSize = input(10);
  readonly pageSizeOptions = input([5, 10, 25, 50]);
  readonly totalItems = input(0);
  readonly loadingText = input("Carregando...");
  readonly emptyText = input("Nenhum item encontrado");
  readonly emptyAction = input<(() => void) | null>(null);
  readonly emptyActionText = input("Adicionar Item");
  readonly retryable = input(false);

  // ✅ Output signals
  readonly rowClick = output<T>();
  readonly rowDoubleClick = output<T>();
  readonly rowSelect = output<{ row: T; selected: boolean }>();
  readonly selectAll = output<boolean>();
  readonly sort = output<{ column: string; direction: "asc" | "desc" }>();
  readonly pageChange = output<{ pageIndex: number; pageSize: number }>();
  readonly retry = output<void>();
  readonly emptyActionClick = output<void>();

  // ✅ Internal state
  private readonly selectedRows = signal<Set<T>>(new Set());
  private readonly sortColumn = signal<string | null>(null);
  private readonly sortDirection = signal<"asc" | "desc">("asc");

  // ✅ Computed values
  readonly displayedColumns = computed(() => {
    const cols = this.columns().map((c) => c.key);
    if (this.selectable()) {
      return ["select", ...cols];
    }
    return cols;
  });

  readonly tableClasses = computed(() => {
    const classes = ["os-data-table"];

    if (this.loading()) {
      classes.push("os-data-table--loading");
    }

    if (this.error()) {
      classes.push("os-data-table--error");
    }

    if (this.data().length === 0) {
      classes.push("os-data-table--empty");
    }

    return classes.join(" ");
  });

  readonly isAllSelected = computed(() => {
    return (
      this.data().length > 0 && this.selectedRows().size === this.data().length
    );
  });

  readonly isIndeterminate = computed(() => {
    const selectedCount = this.selectedRows().size;
    return selectedCount > 0 && selectedCount < this.data().length;
  });

  // ✅ Methods
  isSelected(row: T): boolean {
    return this.selectedRows().has(row);
  }

  getRowClasses(row: T): string {
    const classes = ["os-data-table__row"];

    if (this.isSelected(row)) {
      classes.push("os-data-table__row--selected");
    }

    return classes.join(" ");
  }

  getCellValue(row: T, key: string): any {
    return (row as any)[key];
  }

  formatDate(value: any): string {
    if (!value) return "";
    return new Date(value).toLocaleDateString("pt-BR");
  }

  formatCurrency(value: any): string {
    if (!value) return "";
    return new Intl.NumberFormat("pt-BR", {
      style: "currency",
      currency: "BRL",
    }).format(value);
  }

  getSortIconClass(column: string): string {
    const classes = ["os-data-table__sort-icon"];

    if (this.sortColumn() === column) {
      classes.push(`os-data-table__sort-icon--${this.sortDirection()}`);
    }

    return classes.join(" ");
  }

  // ✅ Event handlers
  onRowClick(row: T): void {
    this.rowClick.emit(row);
  }

  onRowDoubleClick(row: T): void {
    this.rowDoubleClick.emit(row);
  }

  onSelectRow(row: T, event: MatCheckboxChange): void {
    const selected = event.checked;
    const newSelected = new Set(this.selectedRows());

    if (selected) {
      newSelected.add(row);
    } else {
      newSelected.delete(row);
    }

    this.selectedRows.set(newSelected);
    this.rowSelect.emit({ row, selected });
  }

  onSelectAll(event: MatCheckboxChange): void {
    const selected = event.checked;

    if (selected) {
      const allRows = new Set(this.data());
      this.selectedRows.set(allRows);
    } else {
      this.selectedRows.set(new Set());
    }

    this.selectAll.emit(selected);
  }

  onSort(column: string): void {
    const currentColumn = this.sortColumn();
    const currentDirection = this.sortDirection();

    let newDirection: "asc" | "desc" = "asc";

    if (currentColumn === column) {
      newDirection = currentDirection === "asc" ? "desc" : "asc";
    }

    this.sortColumn.set(column);
    this.sortDirection.set(newDirection);
    this.sort.emit({ column, direction: newDirection });
  }

  onPageChange(event: PageEvent): void {
    this.pageChange.emit({
      pageIndex: event.pageIndex,
      pageSize: event.pageSize,
    });
  }

  onRetry(): void {
    this.retry.emit();
  }

  onEmptyAction(): void {
    this.emptyActionClick.emit();
  }
}

// ✅ Table Column Interface
export interface TableColumn {
  key: string;
  label: string;
  type: "text" | "date" | "currency" | "custom";
  sortable?: boolean;
  headerClass?: string;
  cellClass?: string;
  template?: TemplateRef<any>;
}
```

### Organisms - Componentes Complexos

#### Navigation Component

```typescript
// os-navigation.component.ts
@Component({
  selector: "os-navigation",
  standalone: true,
  imports: [CommonModule, RouterModule, OsButtonComponent, OsIconComponent],
  template: `
    <nav class="os-navigation" [class]="navigationClasses()">
      <div class="os-navigation__brand">
        <os-icon name="logo" size="large" />
        <span class="os-navigation__title">{{ title() }}</span>
      </div>

      <div class="os-navigation__menu">
        @for (item of menuItems(); track item.key) {
        <a
          class="os-navigation__item"
          [class]="getItemClasses(item)"
          [routerLink]="item.route"
          routerLinkActive="os-navigation__item--active"
          (click)="onItemClick(item)"
        >
          @if (item.icon) {
          <os-icon [name]="item.icon" size="medium" />
          }
          <span>{{ item.label }}</span>
          @if (item.badge) {
          <span class="os-navigation__badge">{{ item.badge }}</span>
          }
        </a>
        }
      </div>

      <div class="os-navigation__actions">
        @if (user()) {
        <div class="os-navigation__user">
          <os-icon name="user" size="medium" />
          <span>{{ user()?.name }}</span>
        </div>
        }

        <os-button
          variant="tertiary"
          [icon]="themeIcon()"
          (clicked)="onThemeToggle()"
        />

        <os-button
          variant="tertiary"
          [icon]="menuIcon()"
          (clicked)="onMenuToggle()"
        />
      </div>
    </nav>
  `,
  styleUrls: ["./os-navigation.component.scss"],
})
export class OsNavigationComponent {
  // ✅ Input signals
  readonly title = input("OrçaSonhos");
  readonly menuItems = input<NavigationItem[]>([]);
  readonly user = input<User | null>(null);
  readonly theme = input<"light" | "dark">("light");
  readonly collapsed = input(false);

  // ✅ Output signals
  readonly itemClick = output<NavigationItem>();
  readonly themeToggle = output<void>();
  readonly menuToggle = output<void>();

  // ✅ Computed values
  readonly navigationClasses = computed(() => {
    const classes = ["os-navigation"];

    if (this.collapsed()) {
      classes.push("os-navigation--collapsed");
    }

    if (this.theme() === "dark") {
      classes.push("os-navigation--dark");
    }

    return classes.join(" ");
  });

  readonly themeIcon = computed(() =>
    this.theme() === "light" ? "moon" : "sun"
  );

  readonly menuIcon = computed(() => (this.collapsed() ? "menu" : "close"));

  // ✅ Methods
  getItemClasses(item: NavigationItem): string {
    const classes = ["os-navigation__item"];

    if (item.disabled) {
      classes.push("os-navigation__item--disabled");
    }

    if (item.variant) {
      classes.push(`os-navigation__item--${item.variant}`);
    }

    return classes.join(" ");
  }

  // ✅ Event handlers
  onItemClick(item: NavigationItem): void {
    if (!item.disabled) {
      this.itemClick.emit(item);
    }
  }

  onThemeToggle(): void {
    this.themeToggle.emit();
  }

  onMenuToggle(): void {
    this.menuToggle.emit();
  }
}

// ✅ Navigation Item Interface
export interface NavigationItem {
  key: string;
  label: string;
  route: string;
  icon?: string;
  badge?: string | number;
  disabled?: boolean;
  variant?: "primary" | "secondary" | "danger";
}
```

## 🎨 Theme System

### Theme Service

```typescript
// theme.service.ts
@Injectable({ providedIn: "root" })
export class ThemeService {
  private readonly _theme = signal<"light" | "dark">("light");
  private readonly _primaryColor = signal("#1976d2");
  private readonly _accentColor = signal("#ff4081");

  readonly theme = this._theme.asReadonly();
  readonly primaryColor = this._primaryColor.asReadonly();
  readonly accentColor = this._accentColor.asReadonly();

  constructor() {
    // ✅ Load theme from localStorage
    const savedTheme = localStorage.getItem("os-theme");
    if (savedTheme && (savedTheme === "light" || savedTheme === "dark")) {
      this._theme.set(savedTheme);
    }

    // ✅ Apply theme on init
    this.applyTheme();
  }

  toggleTheme(): void {
    const newTheme = this._theme() === "light" ? "dark" : "light";
    this._theme.set(newTheme);
    localStorage.setItem("os-theme", newTheme);
    this.applyTheme();
  }

  setTheme(theme: "light" | "dark"): void {
    this._theme.set(theme);
    localStorage.setItem("os-theme", theme);
    this.applyTheme();
  }

  setPrimaryColor(color: string): void {
    this._primaryColor.set(color);
    this.applyTheme();
  }

  setAccentColor(color: string): void {
    this._accentColor.set(color);
    this.applyTheme();
  }

  private applyTheme(): void {
    const theme = this._theme();
    const primaryColor = this._primaryColor();
    const accentColor = this._accentColor();

    // ✅ Apply CSS custom properties
    document.documentElement.style.setProperty("--os-theme", theme);
    document.documentElement.style.setProperty(
      "--os-primary-color",
      primaryColor
    );
    document.documentElement.style.setProperty(
      "--os-accent-color",
      accentColor
    );

    // ✅ Apply Material theme
    this.applyMaterialTheme(theme, primaryColor, accentColor);
  }

  private applyMaterialTheme(
    theme: string,
    primary: string,
    accent: string
  ): void {
    // Material theme application logic
  }
}
```

### Theme CSS Variables

```scss
// theme.scss
:root {
  // ✅ Light theme (default)
  --os-theme: light;
  --os-primary-color: #1976d2;
  --os-accent-color: #ff4081;
  --os-background-color: #ffffff;
  --os-surface-color: #f5f5f5;
  --os-text-color: #212121;
  --os-text-secondary: #757575;
  --os-border-color: #e0e0e0;
  --os-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

[data-theme="dark"] {
  // ✅ Dark theme
  --os-theme: dark;
  --os-primary-color: #2196f3;
  --os-accent-color: #ff4081;
  --os-background-color: #121212;
  --os-surface-color: #1e1e1e;
  --os-text-color: #ffffff;
  --os-text-secondary: #b0b0b0;
  --os-border-color: #333333;
  --os-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
}

// ✅ Component theme variables
.os-button {
  --os-button-primary-bg: var(--os-primary-color);
  --os-button-primary-text: var(--os-background-color);
  --os-button-secondary-bg: var(--os-surface-color);
  --os-button-secondary-text: var(--os-text-color);
  --os-button-border: var(--os-border-color);
}

.os-input {
  --os-input-border: var(--os-border-color);
  --os-input-focus-border: var(--os-primary-color);
  --os-input-text: var(--os-text-color);
  --os-input-placeholder: var(--os-text-secondary);
}
```

## 🚫 Anti-Patterns a Evitar

### ❌ Componentes Muito Específicos

```typescript
// ❌ EVITAR - Componente muito específico
@Component({
  selector: "os-transaction-list-item",
  template: `...`,
})
export class TransactionListItemComponent {}

// ✅ PREFERIR - Componente genérico
@Component({
  selector: "os-list-item",
  template: `...`,
})
export class OsListItemComponent {}
```

### ❌ Lógica de Negócio no Design System

```typescript
// ❌ EVITAR - Lógica de negócio no componente
@Component({
  selector: "os-button",
  template: `...`,
})
export class OsButtonComponent {
  createTransaction(): void {
    // ❌ Lógica de negócio no Design System
    this.transactionService.create();
  }
}

// ✅ PREFERIR - Apenas apresentação
@Component({
  selector: "os-button",
  template: `...`,
})
export class OsButtonComponent {
  @Output() clicked = new EventEmitter<void>();

  onClick(): void {
    this.clicked.emit();
  }
}
```

### ❌ Dependências de Features

```typescript
// ❌ EVITAR - Dependência de feature específica
@Component({
  selector: "os-navigation",
  template: `...`,
})
export class OsNavigationComponent {
  constructor(
    private readonly transactionService: TransactionService // ❌
  ) {}
}

// ✅ PREFERIR - Dependências genéricas
@Component({
  selector: "os-navigation",
  template: `...`,
})
export class OsNavigationComponent {
  constructor(
    private readonly authService: AuthService // ✅
  ) {}
}
```

---

**Princípios do Design System obrigatórios:**

- ✅ **Atomic Design** - Organização por átomos, moléculas, organismos
- ✅ **Consistência** - Padrões visuais e comportamentais consistentes
- ✅ **Reutilização** - Componentes genéricos e reutilizáveis
- ✅ **Acessibilidade** - Suporte a acessibilidade nativo
- ✅ **Theming** - Sistema de temas flexível
- ✅ **Responsividade** - Design responsivo por padrão
- ✅ **Isolamento** - Sem dependências de features específicas

**Próximos tópicos:**

- **[Testing Standards](./testing-standards.md)** - Padrões de testes
- **[Performance Optimization](./performance-optimization.md)** - Otimização de performance
