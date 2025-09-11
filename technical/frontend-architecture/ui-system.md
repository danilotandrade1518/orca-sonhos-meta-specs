# Sistema de UI (Angular Material + Abstração)

## Decisão Arquitetural

Para o **MVP**, adotamos Angular Material como base de UI com **camada de abstração personalizada** para balancear velocidade de desenvolvimento e flexibilidade futura.

### Motivação da Strategy

| Aspecto | Angular Material | Abstração OrçaSonhos |
|---------|------------------|---------------------|
| **Velocidade** | ✅ Componentes prontos | ✅ Desenvolvimento rápido |
| **Consistência** | ✅ Design System maduro | ✅ Identidade própria |
| **Acessibilidade** | ✅ A11y integrada | ✅ Padrões garantidos |
| **Customização** | ⚠️ Limitada ao Material | ✅ Total controle |
| **Migração Futura** | ❌ Breaking changes | ✅ API estável |
| **Manutenção** | ⚠️ Acoplamento direto | ✅ Isolamento |

**Estratégia**: Temporária para MVP com path de migração preparado para Design System próprio.

## Arquitetura da Camada de Abstração

### Estrutura de Componentes (`/shared/ui-components`)

```
/atoms/                    # Componentes básicos
├── os-button/            # Buttons com variantes próprias
├── os-input/             # Inputs com validação integrada  
├── os-icon/              # Ícones com biblioteca própria
├── os-badge/             # Status indicators
├── os-avatar/            # User avatars
└── os-spinner/           # Loading indicators

/molecules/               # Composições de atoms
├── os-form-field/        # Input + label + validation
├── os-card/              # Content containers
├── os-search-box/        # Search with suggestions
├── os-money-display/     # Money formatting
├── os-date-picker/       # Date selection
└── os-dropdown/          # Select with options

/organisms/               # Componentes complexos  
├── os-data-table/        # Tables with sorting/filtering
├── os-navigation/        # App navigation  
├── os-modal/             # Dialogs and overlays
├── os-page-header/       # Page titles and actions
├── os-sidebar/           # Side navigation
└── os-footer/            # Page footers
```

### Exemplo: Componente Atom

```typescript
// atoms/os-button/os-button.component.ts
@Component({
  selector: 'os-button',
  template: `
    <button 
      mat-button
      [color]="matColor()"
      [disabled]="disabled() || loading()"
      [class]="buttonClass()"
      (click)="handleClick($event)">
      
      @if (loading()) {
        <mat-spinner diameter="16" class="os-button__spinner" />
      }
      
      @if (icon() && !loading()) {
        <os-icon [name]="icon()" />
      }
      
      <span class="os-button__content">
        <ng-content />
      </span>
    </button>
  `,
  styleUrls: ['./os-button.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class OsButtonComponent {
  // Public API - OrçaSonhos específica
  variant = input<'primary' | 'secondary' | 'tertiary' | 'danger'>('primary');
  size = input<'small' | 'medium' | 'large'>('medium');
  disabled = input(false);
  loading = input(false);
  icon = input<string>();
  fullWidth = input(false);
  
  onClick = output<MouseEvent>();

  // Internal state e computed properties
  protected matColor = computed(() => {
    const variant = this.variant();
    switch (variant) {
      case 'primary': return 'primary';
      case 'danger': return 'warn';
      case 'secondary': return 'accent';
      default: return undefined;
    }
  });

  protected buttonClass = computed(() => {
    return [
      'os-button',
      `os-button--${this.variant()}`,
      `os-button--${this.size()}`,
      this.fullWidth() ? 'os-button--full-width' : '',
      this.loading() ? 'os-button--loading' : ''
    ].filter(Boolean).join(' ');
  });

  protected handleClick(event: MouseEvent) {
    if (!this.disabled() && !this.loading()) {
      this.onClick.emit(event);
    }
  }
}
```

### Exemplo: Componente Molecule

```typescript
// molecules/os-form-field/os-form-field.component.ts
@Component({
  selector: 'os-form-field',
  template: `
    <mat-form-field [appearance]="appearance()" class="os-form-field">
      <mat-label>{{ label() }}</mat-label>
      
      <ng-content select="[slot=input]" />
      
      @if (hint()) {
        <mat-hint>{{ hint() }}</mat-hint>
      }
      
      @if (error()) {
        <mat-error>{{ error() }}</mat-error>
      }
      
      <ng-content select="[slot=suffix]" />
    </mat-form-field>
  `,
  styleUrls: ['./os-form-field.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class OsFormFieldComponent {
  label = input.required<string>();
  hint = input<string>();
  error = input<string>();
  appearance = input<'fill' | 'outline'>('outline');
  required = input(false);
}
```

## Sistema de Tema e Design Tokens

### Estrutura de Tema (`/shared/theme`)

```
/theme/
├── _tokens.scss          # Design tokens (cores, spacing, typography)
├── _material-theme.scss  # Customização do tema Material
├── _components.scss      # Estilos específicos dos componentes os-*
├── _globals.scss         # Estilos globais e utilitários
└── theme.scss           # Entry point (importado no angular.json)
```

### Design Tokens

```scss
// _tokens.scss
:root {
  /* === Brand Colors === */
  --os-color-primary-50: #E8F5E8;
  --os-color-primary-100: #C8E6C9; 
  --os-color-primary-500: #2E7D32;  /* Primary */
  --os-color-primary-700: #1B5E20;
  --os-color-primary-900: #0D4211;

  --os-color-secondary-500: #1565C0; /* Secondary */
  --os-color-accent-500: #FF8F00;    /* Accent */
  --os-color-danger-500: #D32F2F;    /* Danger */

  /* === Semantic Colors === */
  --os-color-success: #388E3C;
  --os-color-warning: #F57C00;
  --os-color-info: #1976D2;
  --os-color-error: #D32F2F;

  /* === Neutral Colors === */
  --os-color-gray-50: #FAFAFA;
  --os-color-gray-100: #F5F5F5;
  --os-color-gray-200: #EEEEEE;
  --os-color-gray-500: #9E9E9E;
  --os-color-gray-700: #616161;
  --os-color-gray-900: #212121;

  /* === Spacing Scale === */
  --os-spacing-xs: 4px;
  --os-spacing-sm: 8px;
  --os-spacing-md: 16px;
  --os-spacing-lg: 24px;
  --os-spacing-xl: 32px;
  --os-spacing-2xl: 48px;
  --os-spacing-3xl: 64px;

  /* === Typography === */
  --os-font-family: 'Roboto', sans-serif;
  --os-font-size-xs: 12px;
  --os-font-size-sm: 14px;
  --os-font-size-md: 16px;
  --os-font-size-lg: 18px;
  --os-font-size-xl: 24px;
  --os-font-size-2xl: 32px;

  --os-font-weight-regular: 400;
  --os-font-weight-medium: 500;
  --os-font-weight-bold: 700;

  /* === Border Radius === */
  --os-radius-sm: 4px;
  --os-radius-md: 8px;  
  --os-radius-lg: 12px;
  --os-radius-full: 9999px;

  /* === Shadows === */
  --os-shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
  --os-shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  --os-shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
}
```

### Customização do Material Theme

```scss
// _material-theme.scss
@use '@angular/material' as mat;

// Define paletas customizadas baseadas nos tokens
$os-primary: mat.define-palette((
  50: var(--os-color-primary-50),
  100: var(--os-color-primary-100),
  500: var(--os-color-primary-500),
  700: var(--os-color-primary-700),
  900: var(--os-color-primary-900),
  contrast: (
    50: rgba(0, 0, 0, 0.87),
    100: rgba(0, 0, 0, 0.87),
    500: white,
    700: white,
    900: white,
  )
));

$os-accent: mat.define-palette((
  500: var(--os-color-accent-500),
  // ... outras variações
));

$os-warn: mat.define-palette((
  500: var(--os-color-danger-500),
  // ... outras variações  
));

// Criar tema customizado
$os-theme: mat.define-light-theme((
  color: (
    primary: $os-primary,
    accent: $os-accent,
    warn: $os-warn,
  ),
  typography: mat.define-typography-config(
    $font-family: var(--os-font-family),
    $body-1: mat.define-typography-level(var(--os-font-size-md), 1.5, var(--os-font-weight-regular))
  ),
  density: 0
));

// Aplicar tema
@include mat.all-component-themes($os-theme);
```

## Angular Material + CDK Integration

### Módulos Utilizados

#### Material Components
```typescript
// app/shared/ui-components/material.imports.ts
export const MATERIAL_IMPORTS = [
  // Layout
  MatToolbarModule,
  MatSidenavModule,
  MatGridListModule,
  MatCardModule,
  MatDividerModule,
  
  // Navigation  
  MatMenuModule,
  MatTabsModule,
  MatStepperModule,
  
  // Form Controls
  MatFormFieldModule,
  MatInputModule,
  MatSelectModule,
  MatCheckboxModule,
  MatRadioModule,
  MatSlideToggleModule,
  MatSliderModule,
  MatDatepickerModule,
  
  // Buttons & Indicators
  MatButtonModule,
  MatButtonToggleModule,
  MatIconModule,
  MatBadgeModule,
  MatChipsModule,
  MatProgressSpinnerModule,
  MatProgressBarModule,
  
  // Popups & Modals
  MatDialogModule,
  MatSnackBarModule,
  MatTooltipModule,
  MatBottomSheetModule,
  
  // Data Tables
  MatTableModule,
  MatPaginatorModule,
  MatSortModule,
] as const;
```

#### CDK Features para OrçaSonhos
```typescript
// CDK imports específicos para necessidades do app
export const CDK_IMPORTS = [
  A11yModule,           // Accessibility helpers
  BidiModule,           // Bidirectional text support
  ObserversModule,      // Intersection/resize observers
  OverlayModule,        // Tooltip/dropdown positioning
  PortalModule,         // Dynamic component rendering
  ScrollingModule,      // Virtual scrolling para listas grandes
  DragDropModule,       // Reordenação de metas/categorias
  ClipboardModule,      // Copy/paste functionality
  LayoutModule,         // Breakpoint observer para responsividade
] as const;
```

### Funcionalidades CDK Específicas

#### Virtual Scrolling para Transações
```typescript
// Uso em listas grandes de transações
@Component({
  template: `
    <cdk-virtual-scroll-viewport itemSize="72" class="transaction-viewport">
      <div *cdkVirtualFor="let transaction of transactions(); trackBy: trackByFn">
        <os-transaction-item [transaction]="transaction" />
      </div>
    </cdk-virtual-scroll-viewport>
  `
})
export class TransactionListComponent {
  transactions = input.required<Transaction[]>();
  
  trackByFn = (index: number, transaction: Transaction) => transaction.id;
}
```

#### Drag & Drop para Reordenação  
```typescript
// Reordenação de metas/categorias
@Component({
  template: `
    <div cdkDropList (cdkDropListDropped)="drop($event)">
      @for (goal of goals(); track goal.id) {
        <div cdkDrag class="goal-item">
          <os-goal-card [goal]="goal" />
        </div>
      }
    </div>
  `
})
export class GoalListComponent {
  goals = signal<Goal[]>([]);
  
  drop(event: CdkDragDrop<Goal[]>) {
    moveItemInArray(this.goals(), event.previousIndex, event.currentIndex);
    this.goals.set([...this.goals()]); // Trigger update
  }
}
```

#### Breakpoint Observer para Responsividade
```typescript
// Responsividade reativa com CDK
@Injectable({ providedIn: 'root' })
export class BreakpointService {
  private breakpointObserver = inject(BreakpointObserver);
  
  isMobile = this.breakpointObserver
    .observe('(max-width: 768px)')
    .pipe(map(result => result.matches));
    
  isTablet = this.breakpointObserver
    .observe('(min-width: 769px) and (max-width: 1024px)')
    .pipe(map(result => result.matches));
}
```

## Nomenclatura e Convenções

### Prefixos e Naming
```typescript
// ✅ Componentes com prefixo 'os-'
<os-button variant="primary">Click me</os-button>
<os-input label="Nome" placeholder="Digite seu nome" />
<os-card title="Orçamento Mensal">Conteúdo</os-card>

// ✅ Eventos com prefixo 'os' 
@Output() osClick = new EventEmitter<MouseEvent>();
@Output() osChange = new EventEmitter<string>();
@Output() osSubmit = new EventEmitter<FormData>();

// ✅ CSS Classes com prefixo '.os-'
.os-button { /* estilos do button */ }
.os-button--primary { /* variante primary */ }
.os-button--loading { /* estado loading */ }
```

### API Guidelines
```typescript
// ✅ Props com nomes semânticos próprios
@Component({
  selector: 'os-button',
  inputs: ['variant', 'size', 'disabled', 'loading'] // Não 'color', 'mat-*'
})

// ✅ Variantes específicas do OrçaSonhos
variant: 'primary' | 'secondary' | 'tertiary' | 'danger'  // Não 'mat-primary'

// ✅ Tamanhos consistentes
size: 'small' | 'medium' | 'large'  // Não 'mat-mini', 'mat-fab'
```

## Migração Futura

### Strategy de Migração para Design System Próprio

#### Fase 1: API Estável (Atual)
```typescript
// Interface pública permanece estável
@Component({ selector: 'os-button' })
export class OsButtonComponent {
  variant = input<'primary' | 'secondary' | 'danger'>('primary');
  // API não muda
}
```

#### Fase 2: Trocar Implementação Interna
```typescript
// ANTES (Material)
template: `<button mat-button [color]="matColor">Content</button>`

// DEPOIS (Web Components próprios)  
template: `<os-button-native [variant]="variant()">Content</os-button-native>`

// Interface pública idêntica - zero breaking changes
```

#### Fase 3: Componentes Independentes
```typescript
// Migração gradual componente por componente
// Features continuam funcionando normalmente
// Temas e tokens migram junto

// Bundle size reduction - apenas componentes usados
// Performance - componentes otimizados para OrçaSonhos
// Branding - 100% identidade própria
```

### Vantagens da Abstração

| Aspecto | Sem Abstração | Com Abstração |
|---------|---------------|---------------|
| **Migração** | Reescrever features | Trocar implementação |
| **Consistência** | Dependente do Material | Controlada pelo DS |
| **API Changes** | Breaking changes | API estável |
| **Customização** | Limitada | Total flexibilidade |
| **Testing** | Mock Material | Mock interfaces próprias |
| **Bundle Size** | Todo Material | Apenas componentes usados |

---

**Ver também:**
- [Responsive Design](./responsive-design.md) - Como os componentes se adaptam a diferentes telas
- [Accessibility](./accessibility.md) - Padrões de acessibilidade nos componentes
- [Naming Conventions](./naming-conventions.md) - Convenções detalhadas de nomenclatura