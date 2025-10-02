# Gerenciamento de Estado

## Visão Geral

O gerenciamento de estado no OrçaSonhos utiliza **Angular Signals** como tecnologia principal, organizado por **features** e mantendo os princípios **DTO-First**. A arquitetura prioriza estado local por feature, com estado global apenas quando necessário.

## Estratégia de Estado

### 1. Estado Local por Feature (Padrão)

```typescript
// features/budgets/state/budget.state.ts
@Injectable({ providedIn: "root" })
export class BudgetState {
  // Estado primário
  private _budgets = signal<BudgetResponseDto[]>([]);
  private _currentBudget = signal<BudgetResponseDto | null>(null);
  private _loading = signal(false);
  private _error = signal<string | null>(null);

  // Estado de filtros
  private _filters = signal<BudgetFilters>({
    status: "all",
    dateRange: null,
    searchTerm: "",
  });

  // Estado de paginação
  private _pagination = signal<PaginationState>({
    page: 0,
    pageSize: 10,
    totalItems: 0,
  });

  // Readonly signals para exposição
  readonly budgets = this._budgets.asReadonly();
  readonly currentBudget = this._currentBudget.asReadonly();
  readonly loading = this._loading.asReadonly();
  readonly error = this._error.asReadonly();
  readonly filters = this._filters.asReadonly();
  readonly pagination = this._pagination.asReadonly();

  // Computed signals
  readonly filteredBudgets = computed(() => {
    const budgets = this._budgets();
    const filters = this._filters();

    return budgets.filter((budget) => {
      if (filters.status !== "all" && budget.status !== filters.status) {
        return false;
      }

      if (
        filters.searchTerm &&
        !budget.name.toLowerCase().includes(filters.searchTerm.toLowerCase())
      ) {
        return false;
      }

      return true;
    });
  });

  readonly hasBudgets = computed(() => this._budgets().length > 0);
  readonly isEmpty = computed(
    () => !this._loading() && this._budgets().length === 0
  );

  // Actions
  setBudgets(budgets: BudgetResponseDto[]): void {
    this._budgets.set(budgets);
  }

  addBudget(budget: BudgetResponseDto): void {
    this._budgets.update((current) => [...current, budget]);
  }

  updateBudget(updatedBudget: BudgetResponseDto): void {
    this._budgets.update((current) =>
      current.map((budget) =>
        budget.id === updatedBudget.id ? updatedBudget : budget
      )
    );
  }

  removeBudget(budgetId: string): void {
    this._budgets.update((current) =>
      current.filter((budget) => budget.id !== budgetId)
    );
  }

  setCurrentBudget(budget: BudgetResponseDto | null): void {
    this._currentBudget.set(budget);
  }

  setLoading(loading: boolean): void {
    this._loading.set(loading);
  }

  setError(error: string | null): void {
    this._error.set(error);
  }

  updateFilters(filters: Partial<BudgetFilters>): void {
    this._filters.update((current) => ({ ...current, ...filters }));
  }

  updatePagination(pagination: Partial<PaginationState>): void {
    this._pagination.update((current) => ({ ...current, ...pagination }));
  }

  clearError(): void {
    this._error.set(null);
  }

  reset(): void {
    this._budgets.set([]);
    this._currentBudget.set(null);
    this._loading.set(false);
    this._error.set(null);
    this._filters.set({
      status: "all",
      dateRange: null,
      searchTerm: "",
    });
    this._pagination.set({
      page: 0,
      pageSize: 10,
      totalItems: 0,
    });
  }
}
```

### 2. Estado Global (Apenas quando necessário)

```typescript
// shared/services/global-state.service.ts
@Injectable({ providedIn: "root" })
export class GlobalStateService {
  // Usuário autenticado
  private _currentUser = signal<AuthUserResponseDto | null>(null);
  readonly currentUser = this._currentUser.asReadonly();

  // Configurações da aplicação
  private _appConfig = signal<AppConfigResponseDto | null>(null);
  readonly appConfig = this._appConfig.asReadonly();

  // Budget ativo (contexto global)
  private _activeBudget = signal<BudgetResponseDto | null>(null);
  readonly activeBudget = this._activeBudget.asReadonly();

  // Notificações globais
  private _notifications = signal<NotificationDto[]>([]);
  readonly notifications = this._notifications.asReadonly();

  // Computed signals
  readonly isAuthenticated = computed(() => !!this._currentUser());
  readonly hasActiveBudget = computed(() => !!this._activeBudget());
  readonly unreadNotifications = computed(() =>
    this._notifications().filter((n) => !n.read)
  );

  // Actions
  setCurrentUser(user: AuthUserResponseDto | null): void {
    this._currentUser.set(user);
  }

  setAppConfig(config: AppConfigResponseDto | null): void {
    this._appConfig.set(config);
  }

  setActiveBudget(budget: BudgetResponseDto | null): void {
    this._activeBudget.set(budget);
    // Notificar outras features sobre mudança
    this.eventBus.emit("budget.changed", budget);
  }

  addNotification(notification: NotificationDto): void {
    this._notifications.update((current) => [...current, notification]);
  }

  markNotificationAsRead(notificationId: string): void {
    this._notifications.update((current) =>
      current.map((n) => (n.id === notificationId ? { ...n, read: true } : n))
    );
  }

  clearNotifications(): void {
    this._notifications.set([]);
  }
}
```

## Cache por Feature

### 1. Cache Local

```typescript
// features/budgets/services/budget-cache.service.ts
@Injectable({ providedIn: "root" })
export class BudgetCacheService {
  private cache = new Map<string, CacheEntry<BudgetResponseDto>>();
  private readonly TTL = 5 * 60 * 1000; // 5 minutos

  getCachedBudget(id: string): BudgetResponseDto | null {
    const cached = this.cache.get(id);

    if (!cached) return null;

    if (Date.now() > cached.expiresAt) {
      this.cache.delete(id);
      return null;
    }

    return cached.data;
  }

  setCachedBudget(budget: BudgetResponseDto): void {
    this.cache.set(budget.id, {
      data: budget,
      expiresAt: Date.now() + this.TTL,
    });
  }

  getCachedBudgetList(filters: BudgetFilters): BudgetResponseDto[] | null {
    const key = this.generateCacheKey(filters);
    const cached = this.cache.get(key);

    if (!cached) return null;

    if (Date.now() > cached.expiresAt) {
      this.cache.delete(key);
      return null;
    }

    return cached.data as BudgetResponseDto[];
  }

  setCachedBudgetList(
    budgets: BudgetResponseDto[],
    filters: BudgetFilters
  ): void {
    const key = this.generateCacheKey(filters);
    this.cache.set(key, {
      data: budgets,
      expiresAt: Date.now() + this.TTL,
    });
  }

  invalidateCache(budgetId?: string): void {
    if (budgetId) {
      this.cache.delete(budgetId);
      // Invalidar listas que podem conter este budget
      for (const key of this.cache.keys()) {
        if (key.startsWith("budget-list-")) {
          this.cache.delete(key);
        }
      }
    } else {
      this.cache.clear();
    }
  }

  private generateCacheKey(filters: BudgetFilters): string {
    return `budget-list-${JSON.stringify(filters)}`;
  }
}
```

### 2. Cache Compartilhado

```typescript
// shared/services/shared-cache.service.ts
@Injectable({ providedIn: "root" })
export class SharedCacheService {
  private cache = new Map<string, CacheEntry<any>>();
  private readonly DEFAULT_TTL = 5 * 60 * 1000; // 5 minutos

  get<T>(key: string): T | null {
    const entry = this.cache.get(key);

    if (!entry) return null;

    if (Date.now() > entry.expiresAt) {
      this.cache.delete(key);
      return null;
    }

    return entry.data;
  }

  set<T>(key: string, data: T, ttl: number = this.DEFAULT_TTL): void {
    this.cache.set(key, {
      data,
      expiresAt: Date.now() + ttl,
    });
  }

  invalidate(pattern: string): void {
    for (const key of this.cache.keys()) {
      if (key.includes(pattern)) {
        this.cache.delete(key);
      }
    }
  }

  clear(): void {
    this.cache.clear();
  }

  getSize(): number {
    return this.cache.size;
  }

  getKeys(): string[] {
    return Array.from(this.cache.keys());
  }
}
```

## Padrões de Estado

### 1. Estado de Loading

```typescript
// shared/types/loading-state.type.ts
export interface LoadingState {
  loading: boolean;
  error: string | null;
}

export class LoadingStateManager {
  private _loading = signal(false);
  private _error = signal<string | null>(null);

  readonly loading = this._loading.asReadonly();
  readonly error = this._error.asReadonly();
  readonly hasError = computed(() => !!this._error());

  setLoading(loading: boolean): void {
    this._loading.set(loading);
  }

  setError(error: string | null): void {
    this._error.set(error);
  }

  clearError(): void {
    this._error.set(null);
  }

  async execute<T>(operation: () => Promise<T>): Promise<T | null> {
    this.setLoading(true);
    this.clearError();

    try {
      const result = await operation();
      return result;
    } catch (error) {
      this.setError(
        error instanceof Error ? error.message : "Erro desconhecido"
      );
      return null;
    } finally {
      this.setLoading(false);
    }
  }
}
```

### 2. Estado de Formulário

```typescript
// shared/types/form-state.type.ts
export interface FormState<T> {
  data: T;
  errors: Record<keyof T, string>;
  touched: Record<keyof T, boolean>;
  dirty: boolean;
  valid: boolean;
}

export class FormStateManager<T> {
  private _data = signal<T>({} as T);
  private _errors = signal<Record<keyof T, string>>(
    {} as Record<keyof T, string>
  );
  private _touched = signal<Record<keyof T, boolean>>(
    {} as Record<keyof T, boolean>
  );
  private _dirty = signal(false);
  private _valid = signal(true);

  readonly data = this._data.asReadonly();
  readonly errors = this._errors.asReadonly();
  readonly touched = this._touched.asReadonly();
  readonly dirty = this._dirty.asReadonly();
  readonly valid = this._valid.asReadonly();

  setData(data: T): void {
    this._data.set(data);
    this._dirty.set(true);
  }

  updateField<K extends keyof T>(field: K, value: T[K]): void {
    this._data.update((current) => ({ ...current, [field]: value }));
    this._dirty.set(true);
    this._touched.update((current) => ({ ...current, [field]: true }));
  }

  setError<K extends keyof T>(field: K, error: string): void {
    this._errors.update((current) => ({ ...current, [field]: error }));
    this._valid.set(false);
  }

  clearError<K extends keyof T>(field: K): void {
    this._errors.update((current) => ({ ...current, [field]: "" }));
    this._valid.set(true);
  }

  reset(): void {
    this._data.set({} as T);
    this._errors.set({} as Record<keyof T, string>);
    this._touched.set({} as Record<keyof T, boolean>);
    this._dirty.set(false);
    this._valid.set(true);
  }
}
```

## Comunicação entre Features

### 1. Event Bus para Estado

```typescript
// shared/services/event-bus.service.ts
@Injectable({ providedIn: "root" })
export class EventBusService {
  private eventSubject = new Subject<FeatureEvent>();

  emit(event: string, data?: any): void {
    this.eventSubject.next({
      type: event,
      data,
      timestamp: Date.now(),
      source: this.getCurrentFeature(),
    });
  }

  on(eventType: string): Observable<FeatureEvent> {
    return this.eventSubject.pipe(filter((event) => event.type === eventType));
  }

  // Eventos específicos para estado
  emitStateChange(feature: string, state: string, data: any): void {
    this.emit(`${feature}.state.${state}`, data);
  }

  onStateChange(feature: string, state: string): Observable<FeatureEvent> {
    return this.on(`${feature}.state.${state}`);
  }

  private getCurrentFeature(): string {
    // Implementar lógica para identificar feature atual
    return "unknown";
  }
}
```

### 2. Sincronização de Estado

```typescript
// features/transactions/state/transaction.state.ts
@Injectable({ providedIn: "root" })
export class TransactionState {
  private eventBus = inject(EventBusService);

  constructor() {
    // Escutar mudanças de budget para invalidar cache
    this.eventBus.on("budget.state.changed").subscribe((event) => {
      this.invalidateCache();
    });

    // Escutar mudanças de conta para invalidar cache
    this.eventBus.on("account.state.changed").subscribe((event) => {
      this.invalidateCache();
    });
  }

  // ... resto da implementação
}
```

## Persistência de Estado

### 1. Local Storage

```typescript
// shared/services/storage.service.ts
@Injectable({ providedIn: "root" })
export class StorageService {
  private readonly PREFIX = "orca-sonhos-";

  setItem<T>(key: string, value: T): void {
    try {
      const serialized = JSON.stringify(value);
      localStorage.setItem(this.PREFIX + key, serialized);
    } catch (error) {
      console.error("Erro ao salvar no localStorage:", error);
    }
  }

  getItem<T>(key: string): T | null {
    try {
      const item = localStorage.getItem(this.PREFIX + key);
      return item ? JSON.parse(item) : null;
    } catch (error) {
      console.error("Erro ao ler do localStorage:", error);
      return null;
    }
  }

  removeItem(key: string): void {
    localStorage.removeItem(this.PREFIX + key);
  }

  clear(): void {
    const keys = Object.keys(localStorage);
    keys.forEach((key) => {
      if (key.startsWith(this.PREFIX)) {
        localStorage.removeItem(key);
      }
    });
  }
}
```

### 2. Estado Persistente

```typescript
// shared/services/persistent-state.service.ts
@Injectable({ providedIn: "root" })
export class PersistentStateService {
  private storage = inject(StorageService);

  // Estado persistente do usuário
  private _userPreferences = signal<UserPreferencesDto | null>(null);
  readonly userPreferences = this._userPreferences.asReadonly();

  // Estado persistente da aplicação
  private _appState = signal<AppStateDto | null>(null);
  readonly appState = this._appState.asReadonly();

  constructor() {
    this.loadPersistentState();
  }

  private loadPersistentState(): void {
    const userPrefs =
      this.storage.getItem<UserPreferencesDto>("user-preferences");
    if (userPrefs) {
      this._userPreferences.set(userPrefs);
    }

    const appState = this.storage.getItem<AppStateDto>("app-state");
    if (appState) {
      this._appState.set(appState);
    }
  }

  setUserPreferences(preferences: UserPreferencesDto): void {
    this._userPreferences.set(preferences);
    this.storage.setItem("user-preferences", preferences);
  }

  setAppState(state: AppStateDto): void {
    this._appState.set(state);
    this.storage.setItem("app-state", state);
  }
}
```

## Testes de Estado

### 1. Testes Unitários

```typescript
// features/budgets/state/budget.state.spec.ts
describe("BudgetState", () => {
  let service: BudgetState;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(BudgetState);
  });

  it("should create", () => {
    expect(service).toBeTruthy();
  });

  it("should set budgets", () => {
    const budgets: BudgetResponseDto[] = [
      { id: "1", name: "Budget 1", status: "active" } as BudgetResponseDto,
    ];

    service.setBudgets(budgets);

    expect(service.budgets()).toEqual(budgets);
  });

  it("should filter budgets correctly", () => {
    const budgets: BudgetResponseDto[] = [
      { id: "1", name: "Budget 1", status: "active" } as BudgetResponseDto,
      { id: "2", name: "Budget 2", status: "inactive" } as BudgetResponseDto,
    ];

    service.setBudgets(budgets);
    service.updateFilters({ status: "active" });

    expect(service.filteredBudgets()).toHaveLength(1);
    expect(service.filteredBudgets()[0].id).toBe("1");
  });

  it("should compute hasBudgets correctly", () => {
    expect(service.hasBudgets()).toBeFalse();

    service.setBudgets([{ id: "1", name: "Budget 1" } as BudgetResponseDto]);

    expect(service.hasBudgets()).toBeTrue();
  });
});
```

### 2. Testes de Integração

```typescript
// features/budgets/components/budget-list/budget-list.component.spec.ts
describe("BudgetListComponent", () => {
  let component: BudgetListComponent;
  let fixture: ComponentFixture<BudgetListComponent>;
  let budgetState: BudgetState;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [BudgetListComponent],
      imports: [UiComponentsModule],
      providers: [BudgetState],
    }).compileComponents();

    fixture = TestBed.createComponent(BudgetListComponent);
    component = fixture.componentInstance;
    budgetState = TestBed.inject(BudgetState);
  });

  it("should display budgets from state", () => {
    const budgets: BudgetResponseDto[] = [
      { id: "1", name: "Budget 1" } as BudgetResponseDto,
    ];

    budgetState.setBudgets(budgets);
    fixture.detectChanges();

    const budgetCards = fixture.debugElement.queryAll(By.css("os-budget-card"));
    expect(budgetCards).toHaveLength(1);
  });

  it("should show loading state", () => {
    budgetState.setLoading(true);
    fixture.detectChanges();

    const loadingElement = fixture.debugElement.query(
      By.css("os-skeleton-card")
    );
    expect(loadingElement).toBeTruthy();
  });
});
```

## Boas Práticas

### 1. Organização de Estado

- Estado local por feature sempre que possível
- Estado global apenas para dados verdadeiramente compartilhados
- Use computed signals para derivar estado
- Mantenha estado imutável

### 2. Performance

- Use OnPush change detection
- Evite computed signals complexos
- Implemente cache inteligente
- Limpe estado quando não necessário

### 3. Testabilidade

- Teste estado isoladamente
- Use mocks para dependências
- Teste computed signals
- Valide side effects

### 4. Manutenibilidade

- Documente padrões de estado
- Use TypeScript para type safety
- Implemente logging para debug
- Versionamento de estado

---

**Ver também:**

- [Data Flow](./data-flow.md) - Fluxos de dados e integração
- [Feature Organization](./feature-organization.md) - Organização das features
- [Backend Integration](./backend-integration.md) - Integração com APIs
- [Testing Strategy](./testing-strategy.md) - Estratégias de teste
