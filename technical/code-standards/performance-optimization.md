# Performance Optimization - Otimização de Performance

## ⚡ Performance e Otimização

### Angular Signals para Performance

```typescript
// ✅ Usar signals para estado reativo e performance otimizada
export class TransactionListComponent {
  // Signals base
  readonly transactions = signal<Transaction[]>([]);
  readonly searchTerm = signal('');
  readonly selectedCategory = signal<string | null>(null);
  readonly pageSize = signal(25);
  readonly currentPage = signal(0);
  
  // Computed values - calculados apenas quando dependências mudam
  readonly filteredTransactions = computed(() => {
    const transactions = this.transactions();
    const searchTerm = this.searchTerm().toLowerCase();
    const categoryId = this.selectedCategory();
    
    return transactions.filter(t => {
      const matchesSearch = t.description.toLowerCase().includes(searchTerm);
      const matchesCategory = !categoryId || t.categoryId === categoryId;
      return matchesSearch && matchesCategory;
    });
  });
  
  readonly paginatedTransactions = computed(() => {
    const filtered = this.filteredTransactions();
    const pageSize = this.pageSize();
    const currentPage = this.currentPage();
    const startIndex = currentPage * pageSize;
    
    return filtered.slice(startIndex, startIndex + pageSize);
  });
  
  readonly totalPages = computed(() => 
    Math.ceil(this.filteredTransactions().length / this.pageSize())
  );
  
  readonly hasNextPage = computed(() => 
    this.currentPage() < this.totalPages() - 1
  );
  
  readonly hasPreviousPage = computed(() => 
    this.currentPage() > 0
  );
  
  // Summary computations
  readonly totalAmount = computed(() => 
    this.filteredTransactions()
      .reduce((sum, t) => sum.add(t.amount), Money.zero())
  );
  
  readonly transactionsByCategory = computed(() => {
    const transactions = this.filteredTransactions();
    const grouped = new Map<string, Transaction[]>();
    
    transactions.forEach(t => {
      const category = t.categoryId;
      if (!grouped.has(category)) {
        grouped.set(category, []);
      }
      grouped.get(category)!.push(t);
    });
    
    return grouped;
  });
  
  // Effects para side effects de performance
  constructor() {
    // Debounce search para evitar computações excessivas
    effect((onCleanup) => {
      const searchTerm = this.searchTerm();
      
      const timeoutId = setTimeout(() => {
        this.performSearch(searchTerm);
      }, 300);
      
      onCleanup(() => clearTimeout(timeoutId));
    });
    
    // Reset page quando filtros mudam
    effect(() => {
      this.searchTerm(); // Track dependency
      this.selectedCategory(); // Track dependency
      
      this.currentPage.set(0);
    });
  }
  
  // Métodos de otimização
  trackByTransactionId(index: number, transaction: Transaction): string {
    return transaction.id;
  }
  
  trackByCategoryId(index: number, category: { id: string; name: string }): string {
    return category.id;
  }
}
```

### Lazy Loading e Tree Shaking

```typescript
// ✅ Lazy loading por feature com preload estratégico
const routes: Routes = [
  {
    path: 'dashboard',
    loadComponent: () => import('./features/dashboard/dashboard.page').then(m => m.DashboardPage),
    data: { preload: true } // Preload páginas críticas
  },
  {
    path: 'transactions',
    loadChildren: () => import('./features/transactions/transaction.routes').then(m => m.TRANSACTION_ROUTES),
    data: { preload: true }
  },
  {
    path: 'reports',
    loadChildren: () => import('./features/reports/report.routes').then(m => m.REPORT_ROUTES),
    data: { preload: false } // Carregar apenas sob demanda
  },
  {
    path: 'settings',
    loadChildren: () => import('./features/settings/settings.routes').then(m => m.SETTINGS_ROUTES),
    data: { preload: false }
  }
];

// ✅ Preload strategy customizada
@Injectable({ providedIn: 'root' })
export class CustomPreloadStrategy implements PreloadingStrategy {
  preload(route: Route, load: () => Observable<any>): Observable<any> {
    // Preload apenas rotas marcadas como preload: true
    if (route.data && route.data['preload']) {
      return load();
    }
    return of(null);
  }
}

// ✅ Imports específicos para tree shaking
import { Either } from 'fp-ts/lib/Either';
import { pipe } from 'fp-ts/lib/function';
import { map, switchMap } from 'rxjs/operators'; // Específicos, não de 'rxjs'

// ❌ Evitar imports que prejudicam tree shaking
// import * as fp from 'fp-ts'; // Import tudo
// import { operators } from 'rxjs'; // Import tudo
```

### Bundle Splitting e Code Splitting

```typescript
// ✅ Vendor chunks otimizados (vite.config.ts)
export default defineConfig({
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          // Framework core
          'vendor-angular': ['@angular/core', '@angular/common', '@angular/platform-browser'],
          
          // Angular features
          'vendor-angular-forms': ['@angular/forms'],
          'vendor-angular-router': ['@angular/router'],
          'vendor-angular-material': ['@angular/material'],
          
          // Utilities
          'vendor-fp': ['fp-ts'],
          'vendor-rxjs': ['rxjs'],
          
          // Charts (apenas se usado)
          'vendor-charts': ['chart.js', 'ng2-charts']
        }
      }
    }
  }
});

// ✅ Dynamic imports para features condicionais
export class AdvancedAnalyticsComponent {
  private readonly chartService = inject(ChartService);
  
  async loadChartLibrary(): Promise<void> {
    if (!this.shouldShowCharts()) return;
    
    // Carrega biblioteca apenas quando necessário
    const { Chart } = await import('chart.js/auto');
    this.initializeCharts(Chart);
  }
  
  async loadReportExporter(): Promise<void> {
    // Carrega exportador apenas quando usuário clica
    const { PdfExporter } = await import('./utils/pdf-exporter');
    const { ExcelExporter } = await import('./utils/excel-exporter');
    
    this.setupExporters(new PdfExporter(), new ExcelExporter());
  }
}
```

### OnPush Strategy Universal

```typescript
// ✅ OnPush obrigatório em todos os componentes
@Component({
  selector: 'os-transaction-card',
  changeDetection: ChangeDetectionStrategy.OnPush, // ← SEMPRE
  template: `
    <div class="transaction-card" [class.selected]="selected()">
      <div class="amount" [style.color]="amountColor()">
        {{ transaction().amount | currency:'BRL' }}
      </div>
      <div class="description">{{ transaction().description }}</div>
      <div class="date">{{ transaction().date | date:'short' }}</div>
    </div>
  `
})
export class TransactionCardComponent {
  // ✅ Input signals para OnPush otimizado
  readonly transaction = input.required<Transaction>();
  readonly selected = input(false);
  
  // ✅ Computed values são atualizados automaticamente com OnPush
  readonly amountColor = computed(() => 
    this.transaction().amount.isPositive() ? '#22C55E' : '#EF4444'
  );
  
  // Events não quebram OnPush
  readonly click = output<Transaction>();
  
  onClick(): void {
    this.click.emit(this.transaction());
  }
}

// ✅ Lista com OnPush e trackBy
@Component({
  selector: 'os-transaction-list',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @for (transaction of transactions(); track trackByTransactionId($index, transaction)) {
      <os-transaction-card
        [transaction]="transaction"
        [selected]="isSelected(transaction.id)"
        (click)="onTransactionClick(transaction)"
      />
    }
  `
})
export class TransactionListComponent {
  readonly transactions = input.required<Transaction[]>();
  readonly selectedIds = input<Set<string>>(new Set());
  
  readonly transactionClick = output<Transaction>();
  
  // ✅ TrackBy function para performance
  trackByTransactionId(index: number, transaction: Transaction): string {
    return transaction.id;
  }
  
  isSelected(id: string): boolean {
    return this.selectedIds().has(id);
  }
  
  onTransactionClick(transaction: Transaction): void {
    this.transactionClick.emit(transaction);
  }
}
```

### Virtual Scrolling para Listas Grandes

```typescript
// ✅ Virtual scrolling para performance com listas grandes
@Component({
  selector: 'os-large-transaction-list',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ScrollingModule],
  template: `
    <cdk-virtual-scroll-viewport 
      itemSize="72" 
      class="transaction-viewport"
      [style.height.px]="viewportHeight()">
      
      @for (transaction of transactions(); track trackByTransactionId($index, transaction); let index = $index) {
        <os-transaction-card
          [transaction]="transaction"
          [selected]="isSelected(transaction.id)"
          [index]="index"
          (click)="onTransactionClick(transaction)"
        />
      }
    </cdk-virtual-scroll-viewport>
  `,
  styles: [`
    .transaction-viewport {
      border: 1px solid #ccc;
      border-radius: 4px;
    }
  `]
})
export class LargeTransactionListComponent {
  readonly transactions = input.required<Transaction[]>();
  readonly selectedIds = input<Set<string>>(new Set());
  readonly viewportHeight = input(400);
  
  readonly transactionClick = output<Transaction>();
  
  trackByTransactionId(index: number, transaction: Transaction): string {
    return transaction.id;
  }
  
  isSelected(id: string): boolean {
    return this.selectedIds().has(id);
  }
  
  onTransactionClick(transaction: Transaction): void {
    this.transactionClick.emit(transaction);
  }
}
```

### Image e Asset Optimization

```typescript
// ✅ Lazy loading de imagens
@Component({
  selector: 'os-user-avatar',
  template: `
    <img 
      [src]="optimizedImageUrl()"
      [alt]="user().name"
      [loading]="loadingStrategy()"
      [style.width.px]="size()"
      [style.height.px]="size()"
      class="user-avatar"
      (error)="onImageError()"
    />
  `
})
export class UserAvatarComponent {
  readonly user = input.required<User>();
  readonly size = input(48);
  readonly lazy = input(true);
  
  readonly loadingStrategy = computed(() => 
    this.lazy() ? 'lazy' : 'eager'
  );
  
  readonly optimizedImageUrl = computed(() => {
    const user = this.user();
    const size = this.size();
    
    // Otimizar URL da imagem baseado no tamanho
    if (user.avatarUrl) {
      return `${user.avatarUrl}?w=${size}&h=${size}&f=webp&q=80`;
    }
    
    // Fallback para gravatar
    return `https://www.gravatar.com/avatar/${user.emailHash}?s=${size}&d=identicon`;
  });
  
  onImageError(): void {
    // Fallback para imagem padrão
    console.warn('Failed to load user avatar');
  }
}
```

### Service Worker e Caching

```typescript
// ✅ Service Worker para cache inteligente
@Injectable({ providedIn: 'root' })
export class CacheOptimizationService {
  private readonly swUpdate = inject(SwUpdate);
  
  constructor() {
    if (this.swUpdate.isEnabled) {
      // Check for updates every 6 hours
      interval(6 * 60 * 60 * 1000).subscribe(() => 
        this.swUpdate.checkForUpdate()
      );
      
      // Handle updates
      this.swUpdate.versionUpdates.subscribe(event => {
        if (event.type === 'VERSION_READY') {
          this.handleVersionUpdate();
        }
      });
    }
  }
  
  private async handleVersionUpdate(): Promise<void> {
    const updateAvailable = await this.showUpdateDialog();
    if (updateAvailable) {
      window.location.reload();
    }
  }
  
  private showUpdateDialog(): Promise<boolean> {
    // Show user-friendly update notification
    return Promise.resolve(confirm('Nova versão disponível. Atualizar agora?'));
  }
}

// ✅ HTTP Cache com interceptor
export const cacheInterceptor: HttpInterceptorFn = (req, next) => {
  // Cache apenas GET requests
  if (req.method === 'GET') {
    const cachedResponse = getCachedResponse(req.url);
    if (cachedResponse) {
      return of(cachedResponse);
    }
  }
  
  return next(req).pipe(
    tap(response => {
      // Cache successful GET responses
      if (req.method === 'GET' && response.status === 200) {
        setCachedResponse(req.url, response);
      }
    })
  );
};

// ✅ Memory management
@Component({
  selector: 'os-memory-optimized',
  template: `...`
})
export class MemoryOptimizedComponent {
  private readonly destroyRef = inject(DestroyRef);
  
  constructor() {
    // ✅ Cleanup automático com DestroyRef
    this.someObservable$
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe(data => this.handleData(data));
  }
  
  private handleData(data: any): void {
    // Process data
  }
}
```

### Performance Monitoring

```typescript
// ✅ Performance monitoring service
@Injectable({ providedIn: 'root' })
export class PerformanceMonitoringService {
  private readonly performanceEntries = signal<PerformanceEntry[]>([]);
  
  constructor() {
    if (typeof window !== 'undefined' && 'performance' in window) {
      this.startMonitoring();
    }
  }
  
  private startMonitoring(): void {
    // Monitor navigation timing
    const observer = new PerformanceObserver((list) => {
      const entries = list.getEntries();
      this.performanceEntries.update(current => [...current, ...entries]);
      
      entries.forEach(entry => {
        if (entry.entryType === 'navigation') {
          this.logNavigationMetrics(entry as PerformanceNavigationTiming);
        }
        
        if (entry.entryType === 'largest-contentful-paint') {
          this.logLCPMetrics(entry);
        }
      });
    });
    
    observer.observe({ entryTypes: ['navigation', 'largest-contentful-paint', 'first-input'] });
  }
  
  private logNavigationMetrics(entry: PerformanceNavigationTiming): void {
    const metrics = {
      domContentLoaded: entry.domContentLoadedEventEnd - entry.domContentLoadedEventStart,
      load: entry.loadEventEnd - entry.loadEventStart,
      ttfb: entry.responseStart - entry.requestStart,
      dom: entry.domComplete - entry.domLoading
    };
    
    console.log('Navigation Metrics:', metrics);
  }
  
  private logLCPMetrics(entry: PerformanceEntry): void {
    console.log('Largest Contentful Paint:', entry.startTime);
  }
  
  measureComponentRender(componentName: string): void {
    performance.mark(`${componentName}-start`);
    
    // Use in component after render
    requestAnimationFrame(() => {
      performance.mark(`${componentName}-end`);
      performance.measure(
        `${componentName}-render`,
        `${componentName}-start`,
        `${componentName}-end`
      );
    });
  }
}
```

---

**Estratégias principais de performance:**
- ✅ **Signals** para reatividade otimizada
- ✅ **OnPush** universal para change detection
- ✅ **Lazy loading** inteligente por features
- ✅ **Virtual scrolling** para listas grandes
- ✅ **Bundle splitting** otimizado
- ✅ **Tree shaking** com imports específicos
- ✅ **Service Worker** para cache
- ✅ **Performance monitoring** integrado

**Próximos tópicos:**
- **[Architectural Patterns](./architectural-patterns.md)** - Padrões arquiteturais
- **[Testing Standards](./testing-standards.md)** - Padrões de testes