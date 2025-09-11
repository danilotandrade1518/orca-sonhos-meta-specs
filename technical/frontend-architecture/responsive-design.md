# Mobile-First e Responsividade

## Filosofia Mobile-First

- **Design prioritário**: Layouts projetados primeiro para telas pequenas
- **Progressive Enhancement**: Aprimoramento progressivo para telas maiores  
- **Content First**: Conteúdo essencial acima da dobra
- **Touch-Friendly**: Alvos de toque adequados e gestos naturais

## Breakpoints e Design Tokens

### Sistema de Breakpoints

```scss
// shared/theme/_breakpoints.scss
:root {
  /* Breakpoints móveis primeiro */
  --os-breakpoint-xs: 0px;      /* Extra small devices */
  --os-breakpoint-sm: 576px;    /* Small devices (landscape phones) */
  --os-breakpoint-md: 768px;    /* Medium devices (tablets) */
  --os-breakpoint-lg: 992px;    /* Large devices (laptops) */
  --os-breakpoint-xl: 1200px;   /* Extra large devices (desktops) */
  --os-breakpoint-xxl: 1400px;  /* Extra extra large devices */
}

/* Media query mixins */
@mixin mobile-only {
  @media (max-width: 575.98px) { @content; }
}

@mixin tablet-up {
  @media (min-width: 576px) { @content; }
}

@mixin desktop-up {
  @media (min-width: 992px) { @content; }
}

@mixin large-desktop-up {
  @media (min-width: 1200px) { @content; }
}
```

### CDK Layout Module Integration

```typescript
// app/services/breakpoint.service.ts
@Injectable({ providedIn: 'root' })
export class BreakpointService {
  private breakpointObserver = inject(BreakpointObserver);
  
  // Reactive breakpoint signals
  readonly isMobile = signal(false);
  readonly isTablet = signal(false);
  readonly isDesktop = signal(false);

  // Breakpoint queries
  private readonly MOBILE = '(max-width: 575.98px)';
  private readonly TABLET = '(min-width: 576px) and (max-width: 991.98px)';
  private readonly DESKTOP = '(min-width: 992px)';

  constructor() {
    // Observe breakpoint changes
    this.breakpointObserver.observe(this.MOBILE).subscribe(result => {
      this.isMobile.set(result.matches);
    });
    
    this.breakpointObserver.observe(this.TABLET).subscribe(result => {
      this.isTablet.set(result.matches);
    });
    
    this.breakpointObserver.observe(this.DESKTOP).subscribe(result => {
      this.isDesktop.set(result.matches);
    });
  }

  // Computed device type
  readonly deviceType = computed(() => {
    if (this.isMobile()) return 'mobile';
    if (this.isTablet()) return 'tablet';
    return 'desktop';
  });

  // Orientation detection
  readonly isPortrait = computed(() => {
    return this.breakpointObserver.isMatched('(orientation: portrait)');
  });

  readonly isLandscape = computed(() => {
    return this.breakpointObserver.isMatched('(orientation: landscape)');
  });
}
```

## Componentes Responsivos

### Layout Components

```typescript
// shared/ui-components/organisms/os-layout/os-layout.component.ts
@Component({
  selector: 'os-layout',
  template: `
    <div class="os-layout" [class]="layoutClass()">
      <!-- Mobile Header -->
      @if (breakpoint.isMobile()) {
        <header class="os-layout__header os-layout__header--mobile">
          <os-button 
            variant="tertiary" 
            icon="menu"
            (osClick)="toggleSidebar()"
            [attr.aria-label]="'Toggle navigation'"
            class="os-layout__menu-toggle" />
          
          <div class="os-layout__title">
            <ng-content select="[slot=mobile-title]" />
          </div>
          
          <div class="os-layout__actions">
            <ng-content select="[slot=header-actions]" />
          </div>
        </header>
      }
      
      <!-- Desktop/Tablet Header -->
      @if (!breakpoint.isMobile()) {
        <header class="os-layout__header os-layout__header--desktop">
          <div class="os-layout__brand">
            <ng-content select="[slot=brand]" />
          </div>
          
          <nav class="os-layout__nav">
            <ng-content select="[slot=navigation]" />
          </nav>
          
          <div class="os-layout__user">
            <ng-content select="[slot=user-menu]" />
          </div>
        </header>
      }

      <!-- Sidebar (Mobile) -->
      @if (breakpoint.isMobile()) {
        <aside 
          class="os-layout__sidebar"
          [class.os-layout__sidebar--open]="sidebarOpen()"
          [attr.aria-hidden]="!sidebarOpen()"
          (click)="closeSidebar()">
          
          <div class="os-layout__sidebar-content" (click)="$event.stopPropagation()">
            <ng-content select="[slot=sidebar-content]" />
          </div>
        </aside>
      }

      <!-- Main Content -->
      <main class="os-layout__main" [inert]="breakpoint.isMobile() && sidebarOpen()">
        <ng-content />
      </main>
    </div>
  `,
  styleUrls: ['./os-layout.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class OsLayoutComponent {
  protected breakpoint = inject(BreakpointService);
  
  protected sidebarOpen = signal(false);
  
  protected layoutClass = computed(() => [
    'os-layout',
    `os-layout--${this.breakpoint.deviceType()}`,
    this.breakpoint.isPortrait() ? 'os-layout--portrait' : 'os-layout--landscape'
  ].join(' '));

  protected toggleSidebar(): void {
    this.sidebarOpen.update(open => !open);
  }

  protected closeSidebar(): void {
    this.sidebarOpen.set(false);
  }
}
```

### Responsive Data Table

```typescript
// shared/ui-components/organisms/os-data-table/os-data-table.component.ts
@Component({
  selector: 'os-data-table',
  template: `
    @if (breakpoint.isMobile()) {
      <!-- Mobile Card Layout -->
      <div class="os-data-table os-data-table--mobile">
        @for (item of data(); track trackFn(0, item)) {
          <os-card class="os-data-table__mobile-card">
            <os-card-content>
              @for (column of visibleColumns(); track column.key) {
                <div class="os-data-table__mobile-row">
                  <span class="os-data-table__mobile-label">{{ column.label }}</span>
                  <span class="os-data-table__mobile-value">
                    <ng-container [ngTemplateOutlet]="column.template || defaultCell" 
                                  [ngTemplateOutletContext]="{$implicit: item, column: column}" />
                  </span>
                </div>
              }
            </os-card-content>
          </os-card>
        }
      </div>
    } @else {
      <!-- Desktop Table Layout -->
      <div class="os-data-table os-data-table--desktop">
        <table class="os-data-table__table">
          <thead>
            <tr>
              @for (column of columns(); track column.key) {
                <th 
                  class="os-data-table__header"
                  [class.os-data-table__header--sortable]="column.sortable"
                  [class.os-data-table__header--hidden]="!isColumnVisible(column)"
                  (click)="column.sortable && sort(column.key)">
                  {{ column.label }}
                  
                  @if (column.sortable && sortColumn() === column.key) {
                    <os-icon 
                      [name]="sortDirection() === 'asc' ? 'arrow-up' : 'arrow-down'"
                      class="os-data-table__sort-icon" />
                  }
                </th>
              }
            </tr>
          </thead>
          
          <tbody>
            @for (item of sortedData(); track trackFn(0, item)) {
              <tr class="os-data-table__row">
                @for (column of columns(); track column.key) {
                  <td 
                    class="os-data-table__cell"
                    [class.os-data-table__cell--hidden]="!isColumnVisible(column)">
                    <ng-container [ngTemplateOutlet]="column.template || defaultCell" 
                                  [ngTemplateOutletContext]="{$implicit: item, column: column}" />
                  </td>
                }
              </tr>
            }
          </tbody>
        </table>
      </div>
    }
  `,
  styleUrls: ['./os-data-table.component.scss']
})
export class OsDataTableComponent<T> {
  protected breakpoint = inject(BreakpointService);
  
  data = input.required<T[]>();
  columns = input.required<TableColumn<T>[]>();
  trackFn = input<TrackByFunction<T>>((index, item) => item);
  
  // Responsive column visibility
  protected visibleColumns = computed(() => {
    return this.columns().filter(column => this.isColumnVisible(column));
  });
  
  protected isColumnVisible(column: TableColumn<T>): boolean {
    if (!column.responsive) return true;
    
    const device = this.breakpoint.deviceType();
    return column.responsive.includes(device);
  }
}

interface TableColumn<T> {
  key: keyof T;
  label: string;
  sortable?: boolean;
  template?: TemplateRef<any>;
  responsive?: Array<'mobile' | 'tablet' | 'desktop'>; // Show only on specified devices
}
```

### Responsive Forms

```typescript
// shared/ui-components/molecules/os-form-layout/os-form-layout.component.ts
@Component({
  selector: 'os-form-layout',
  template: `
    <div class="os-form-layout" [class]="formLayoutClass()">
      <ng-content />
    </div>
  `,
  styles: [`
    .os-form-layout {
      display: grid;
      gap: var(--os-spacing-md);
      
      /* Mobile: Single column */
      grid-template-columns: 1fr;
      
      @include tablet-up {
        /* Tablet: Two columns for shorter forms */
        &.os-form-layout--two-column {
          grid-template-columns: 1fr 1fr;
        }
      }
      
      @include desktop-up {
        /* Desktop: More complex layouts */
        &.os-form-layout--three-column {
          grid-template-columns: 1fr 1fr 1fr;
        }
        
        &.os-form-layout--sidebar {
          grid-template-columns: 2fr 1fr;
        }
      }
    }
  `]
})
export class OsFormLayoutComponent {
  protected breakpoint = inject(BreakpointService);
  
  layout = input<'single' | 'two-column' | 'three-column' | 'sidebar'>('single');
  
  protected formLayoutClass = computed(() => {
    const device = this.breakpoint.deviceType();
    const layout = this.layout();
    
    // Force single column on mobile regardless of layout prop
    if (device === 'mobile') {
      return 'os-form-layout os-form-layout--single';
    }
    
    return `os-form-layout os-form-layout--${layout}`;
  });
}
```

## Performance para Mobile

### Lazy Loading Otimizado

```typescript
// app/app.routes.ts
export const routes: Routes = [
  {
    path: 'dashboard',
    loadComponent: () => import('./features/dashboard/dashboard.page').then(m => m.DashboardPage),
    data: { preload: true } // Preload para página principal
  },
  {
    path: 'transactions',
    loadChildren: () => import('./features/transactions/transactions.routes').then(m => m.routes),
    data: { preload: false } // Lazy load por demanda
  },
  {
    path: 'reports',
    loadChildren: () => import('./features/reports/reports.routes').then(m => m.routes),
    data: { preload: false } // Usado menos frequentemente
  }
];
```

### Virtual Scrolling para Listas Grandes

```typescript
// features/transactions/components/transaction-virtual-list.component.ts
@Component({
  selector: 'app-transaction-virtual-list',
  template: `
    <cdk-virtual-scroll-viewport 
      itemSize="72" 
      class="transaction-viewport"
      [style.height]="viewportHeight()">
      
      <div *cdkVirtualFor="let transaction of transactions(); trackBy: trackByFn">
        <os-transaction-card 
          [transaction]="transaction"
          [compact]="breakpoint.isMobile()"
          (onClick)="selectTransaction(transaction)" />
      </div>
    </cdk-virtual-scroll-viewport>
  `,
  styles: [`
    .transaction-viewport {
      width: 100%;
      
      /* Mobile: Smaller item size */
      @include mobile-only {
        --item-size: 64px;
      }
    }
  `]
})
export class TransactionVirtualListComponent {
  protected breakpoint = inject(BreakpointService);
  
  transactions = input.required<Transaction[]>();
  
  protected viewportHeight = computed(() => {
    // Adjust viewport height based on screen size
    const device = this.breakpoint.deviceType();
    switch (device) {
      case 'mobile': return '60vh';
      case 'tablet': return '70vh'; 
      default: return '80vh';
    }
  });
  
  protected trackByFn = (index: number, transaction: Transaction) => transaction.id;
}
```

### Image Optimization

```typescript
// shared/ui-components/atoms/os-image/os-image.component.ts
@Component({
  selector: 'os-image',
  template: `
    <img 
      [ngSrc]="src()"
      [alt]="alt()"
      [width]="computedWidth()"
      [height]="computedHeight()"
      [sizes]="computedSizes()"
      [priority]="priority()"
      class="os-image"
      [class]="imageClass()" />
  `,
  styles: [`
    .os-image {
      max-width: 100%;
      height: auto;
      
      &.os-image--responsive {
        width: 100%;
        object-fit: cover;
      }
      
      &.os-image--avatar {
        border-radius: 50%;
        aspect-ratio: 1;
      }
    }
  `]
})
export class OsImageComponent {
  protected breakpoint = inject(BreakpointService);
  
  src = input.required<string>();
  alt = input.required<string>();
  width = input<number>();
  height = input<number>();
  priority = input(false);
  responsive = input(true);
  
  protected computedWidth = computed(() => {
    const baseWidth = this.width() || 300;
    
    // Scale down for mobile
    if (this.breakpoint.isMobile() && this.responsive()) {
      return Math.min(baseWidth, 320);
    }
    
    return baseWidth;
  });
  
  protected computedHeight = computed(() => {
    const baseHeight = this.height() || 200;
    
    // Maintain aspect ratio when scaling
    if (this.breakpoint.isMobile() && this.responsive() && this.width()) {
      const scale = this.computedWidth() / this.width()!;
      return Math.round(baseHeight * scale);
    }
    
    return baseHeight;
  });
  
  protected computedSizes = computed(() => {
    if (!this.responsive()) return undefined;
    
    // Responsive sizes attribute
    return '(max-width: 576px) 100vw, (max-width: 992px) 50vw, 33vw';
  });
  
  protected imageClass = computed(() => [
    'os-image',
    this.responsive() ? 'os-image--responsive' : ''
  ].filter(Boolean).join(' '));
}
```

## Touch e Gestos

### Touch-Friendly Targets

```scss
// Design tokens para touch targets
:root {
  --os-touch-target-min: 44px;     /* Apple HIG minimum */
  --os-touch-target-ideal: 48px;   /* Material Design recommendation */
  --os-finger-spacing: 8px;        /* Minimum spacing between targets */
}

.os-button {
  min-height: var(--os-touch-target-ideal);
  min-width: var(--os-touch-target-ideal);
  
  /* Increase touch area without visual change */
  position: relative;
  
  &::after {
    content: '';
    position: absolute;
    top: 50%;
    left: 50%;
    min-height: var(--os-touch-target-ideal);
    min-width: var(--os-touch-target-ideal);
    transform: translate(-50%, -50%);
  }
  
  @include mobile-only {
    padding: var(--os-spacing-sm) var(--os-spacing-md);
    margin: var(--os-finger-spacing);
  }
}
```

### Swipe Gestures (CDK Drag Drop)

```typescript
// shared/ui-components/molecules/os-swipe-card/os-swipe-card.component.ts
@Component({
  selector: 'os-swipe-card',
  template: `
    <div 
      class="os-swipe-card"
      cdkDrag
      [cdkDragDisabled]="!breakpoint.isMobile()"
      (cdkDragEnded)="handleSwipe($event)">
      
      <div class="os-swipe-card__content">
        <ng-content />
      </div>
      
      <!-- Swipe Actions (Mobile Only) -->
      @if (breakpoint.isMobile()) {
        <div class="os-swipe-card__actions os-swipe-card__actions--left">
          <ng-content select="[slot=left-actions]" />
        </div>
        
        <div class="os-swipe-card__actions os-swipe-card__actions--right">
          <ng-content select="[slot=right-actions]" />
        </div>
      }
    </div>
  `,
  styleUrls: ['./os-swipe-card.component.scss']
})
export class OsSwipeCardComponent {
  protected breakpoint = inject(BreakpointService);
  
  onSwipeLeft = output<void>();
  onSwipeRight = output<void>();
  
  protected handleSwipe(event: CdkDragEnd): void {
    const distance = event.distance;
    const threshold = 100; // Minimum swipe distance
    
    if (Math.abs(distance.x) > threshold) {
      if (distance.x > 0) {
        this.onSwipeRight.emit();
      } else {
        this.onSwipeLeft.emit();
      }
    }
    
    // Reset position
    event.source.reset();
  }
}
```

## Accessibility e Responsividade

### Reduced Motion Support

```scss
// Respect user's motion preferences
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

### Focus Management

```typescript
// shared/services/focus-management.service.ts
@Injectable({ providedIn: 'root' })
export class FocusManagementService {
  private breakpoint = inject(BreakpointService);
  
  // Focus first interactive element in container
  focusFirstInteractive(container: HTMLElement): void {
    const firstFocusable = container.querySelector(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    ) as HTMLElement;
    
    if (firstFocusable) {
      firstFocusable.focus();
    }
  }
  
  // Trap focus within modal on mobile
  trapFocus(container: HTMLElement): () => void {
    if (!this.breakpoint.isMobile()) {
      return () => {}; // No-op on desktop
    }
    
    const focusableElements = container.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    ) as NodeListOf<HTMLElement>;
    
    const firstFocusable = focusableElements[0];
    const lastFocusable = focusableElements[focusableElements.length - 1];
    
    const handleTabKey = (event: KeyboardEvent) => {
      if (event.key === 'Tab') {
        if (event.shiftKey) {
          if (document.activeElement === firstFocusable) {
            lastFocusable.focus();
            event.preventDefault();
          }
        } else {
          if (document.activeElement === lastFocusable) {
            firstFocusable.focus();
            event.preventDefault();
          }
        }
      }
    };
    
    container.addEventListener('keydown', handleTabKey);
    
    return () => {
      container.removeEventListener('keydown', handleTabKey);
    };
  }
}
```

---

**Ver também:**
- [UI System](./ui-system.md) - Componentes responsivos do Design System
- [Performance](./performance.md) - Otimizações específicas para mobile
- [Accessibility](./accessibility.md) - Padrões de acessibilidade responsiva