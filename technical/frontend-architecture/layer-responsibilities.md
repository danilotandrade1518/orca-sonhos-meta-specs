# Responsabilidades das Camadas

## 1. Features - Módulos de Funcionalidades

### Responsabilidades

- **Isolamento de Funcionalidades**: Cada feature é um módulo independente
- **Componentes Específicos**: Componentes Angular específicos da funcionalidade
- **Serviços Específicos**: Serviços e lógica de negócio da feature
- **Roteamento**: Roteamento específico da feature com lazy loading
- **Estado Local**: Gerenciamento de estado específico da feature
- **DTOs Específicos**: DTOs específicos da feature (quando necessário)

### Características

- **Lazy Loading**: Carregamento sob demanda para otimização de performance
- **Isolamento**: Dependências mínimas entre features
- **Escalabilidade**: Desenvolvimento paralelo de features
- **Manutenibilidade**: Código relacionado agrupado em uma localização
- **DTO-First**: Mantém princípios DTO-First dentro da feature

### Estrutura Interna de uma Feature

```
/features/budgets/
├── /components/           # Componentes específicos
│   ├── budget-list.component.ts
│   ├── budget-form.component.ts
│   └── budget-card.component.ts
├── /services/            # Serviços específicos
│   ├── budget.service.ts
│   └── budget-state.service.ts
├── /dtos/               # DTOs específicos (se necessário)
│   ├── request/
│   └── response/
├── budgets.module.ts    # Módulo da feature
└── budgets-routing.module.ts # Roteamento da feature
```

### Exemplos Práticos

#### Feature Module

```typescript
// features/budgets/budgets.module.ts
@NgModule({
  declarations: [BudgetListComponent, BudgetFormComponent, BudgetCardComponent],
  imports: [CommonModule, SharedModule, BudgetsRoutingModule],
  providers: [BudgetService, BudgetStateService],
})
export class BudgetsModule {}
```

#### Feature Service

```typescript
// features/budgets/services/budget.service.ts
@Injectable({ providedIn: "root" })
export class BudgetService {
  constructor(
    private createBudgetCommand: CreateBudgetCommand,
    private getBudgetListQuery: GetBudgetListQuery,
    private getBudgetByIdQuery: GetBudgetByIdQuery
  ) {}

  async createBudget(
    dto: CreateBudgetRequestDto
  ): Promise<Either<ServiceError, void>> {
    return this.createBudgetCommand.execute(dto);
  }

  async getBudgets(): Promise<Either<ServiceError, BudgetResponseDto[]>> {
    return this.getBudgetListQuery.execute({});
  }

  async getBudgetById(
    id: string
  ): Promise<Either<ServiceError, BudgetResponseDto>> {
    return this.getBudgetByIdQuery.execute(id);
  }
}
```

#### Feature State Service

```typescript
// features/budgets/services/budget-state.service.ts
@Injectable({ providedIn: "root" })
export class BudgetStateService {
  // Estado local da feature usando Angular Signals
  private budgets = signal<BudgetResponseDto[]>([]);
  private loading = signal(false);
  private error = signal<string | null>(null);

  // Getters públicos
  readonly budgets$ = this.budgets.asReadonly();
  readonly loading$ = this.loading.asReadonly();
  readonly error$ = this.error.asReadonly();

  // Actions
  setBudgets(budgets: BudgetResponseDto[]): void {
    this.budgets.set(budgets);
  }

  setLoading(loading: boolean): void {
    this.loading.set(loading);
  }

  setError(error: string | null): void {
    this.error.set(error);
  }

  clearError(): void {
    this.error.set(null);
  }
}
```

---

## 2. Core - Serviços Globais

### Responsabilidades

- **Singleton Services**: Serviços que existem uma única vez na aplicação
- **Global Configuration**: Configurações que afetam toda a aplicação
- **HTTP Interceptors**: Interceptadores globais para autenticação, logging, etc.
- **Route Guards**: Guards globais para autenticação e autorização
- **Bootstrap Services**: Serviços necessários para inicialização da aplicação

### Características

- **Singleton**: Inicializados uma única vez
- **Global**: Compartilhados entre todas as features
- **Infrastructure**: Serviços de infraestrutura e configuração
- **Cross-Cutting**: Funcionalidades que cortam todas as features

### Exemplos Práticos

#### Auth Service

```typescript
// core/services/auth.service.ts
@Injectable({ providedIn: "root" })
export class AuthService {
  private user = signal<User | null>(null);
  private isAuthenticated = signal(false);

  readonly user$ = this.user.asReadonly();
  readonly isAuthenticated$ = this.isAuthenticated.asReadonly();

  async login(
    email: string,
    password: string
  ): Promise<Either<AuthError, void>> {
    // Implementação de login
  }

  async logout(): Promise<void> {
    // Implementação de logout
  }

  getCurrentUser(): User | null {
    return this.user();
  }
}
```

#### HTTP Interceptor

```typescript
// core/interceptors/auth.interceptor.ts
@Injectable()
export class AuthInterceptor implements HttpInterceptor {
  constructor(private authService: AuthService) {}

  intercept(
    req: HttpRequest<any>,
    next: HttpHandler
  ): Observable<HttpEvent<any>> {
    const token = this.authService.getToken();

    if (token) {
      const authReq = req.clone({
        setHeaders: { Authorization: `Bearer ${token}` },
      });
      return next.handle(authReq);
    }

    return next.handle(req);
  }
}
```

---

## 3. Shared - Componentes e Utilitários Compartilhados

### Responsabilidades

- **UI Components**: Design System com abstração sobre Angular Material
- **Theme**: Customizações de tema Material Design
- **Pipes**: Pipes compartilhados entre features
- **Directives**: Directives compartilhadas entre features
- **Utils**: Utilitários e helpers compartilhados
- **Layouts**: Componentes de layout compartilhados

### Características

- **Reutilizáveis**: Usados por múltiplas features
- **Independentes**: Sem dependências de features específicas
- **Design System**: Abstração sobre Angular Material
- **Consistentes**: Padrões visuais e de comportamento uniformes

### Exemplos Práticos

#### UI Component (Atom)

```typescript
// shared/ui-components/atoms/os-button/os-button.component.ts
@Component({
  selector: "os-button",
  template: `
    <button
      mat-button
      [color]="matColor()"
      [disabled]="disabled()"
      [attr.aria-label]="ariaLabel()"
      (click)="onClick.emit($event)"
    >
      @if (loading()) {
      <mat-spinner diameter="16" />
      } @else {
      <ng-content />
      }
    </button>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OsButtonComponent {
  variant = input<"primary" | "secondary" | "danger">("primary");
  disabled = input(false);
  loading = input(false);
  ariaLabel = input<string>();

  onClick = output<MouseEvent>();

  protected matColor = computed(() => {
    const variant = this.variant();
    return variant === "primary"
      ? "primary"
      : variant === "danger"
      ? "warn"
      : "accent";
  });
}
```

#### Utility Service

```typescript
// shared/utils/date.util.ts
@Injectable({ providedIn: "root" })
export class DateUtil {
  formatDate(date: string | Date, format: "short" | "long" = "short"): string {
    const dateObj = typeof date === "string" ? new Date(date) : date;

    return format === "short"
      ? dateObj.toLocaleDateString("pt-BR")
      : dateObj.toLocaleDateString("pt-BR", {
          year: "numeric",
          month: "long",
          day: "numeric",
        });
  }

  formatCurrency(amountInCents: number): string {
    const amount = amountInCents / 100;
    return new Intl.NumberFormat("pt-BR", {
      style: "currency",
      currency: "BRL",
    }).format(amount);
  }
}
```

---

## 4. DTOs - Contratos de API

### Responsabilidades

- **Request DTOs**: Estruturas para dados enviados ao backend (`CreateTransactionRequestDto`)
- **Response DTOs**: Estruturas para dados recebidos do backend (`TransactionResponseDto`)
- **Shared Types**: Tipos compartilhados entre frontend e backend (`Money`, `DateString`)
- **API Contracts**: Interfaces TypeScript que espelham exatamente a API

### Características

- **Zero Dependencies**: Nenhuma dependência de framework ou biblioteca externa
- **Pure TypeScript**: Apenas interfaces e tipos
- **API Aligned**: Espelham exatamente os contratos do backend
- **Framework Agnostic**: Portável para qualquer plataforma

### Exemplos Práticos

#### Request DTO

```typescript
// dtos/request/CreateTransactionRequestDto.ts
export interface CreateTransactionRequestDto {
  readonly accountId: string;
  readonly budgetId: string;
  readonly amountInCents: number; // Money como number (centavos)
  readonly description: string;
  readonly type: "INCOME" | "EXPENSE"; // Enum como string literal
  readonly categoryId?: string;
  readonly date?: string; // ISO date string
}
```

#### Response DTO

```typescript
// dtos/response/TransactionResponseDto.ts
export interface TransactionResponseDto {
  readonly id: string;
  readonly accountId: string;
  readonly budgetId: string;
  readonly amountInCents: number;
  readonly description: string;
  readonly type: "INCOME" | "EXPENSE";
  readonly categoryId?: string;
  readonly date: string; // ISO date string
  readonly createdAt: string;
  readonly updatedAt: string;
}
```

#### Shared Types

```typescript
// dtos/shared/Money.ts
export type Money = number; // Sempre em centavos

// dtos/shared/DateString.ts
export type DateString = string; // ISO 8601 format

// dtos/shared/TransactionType.ts
export type TransactionType = "INCOME" | "EXPENSE";

// dtos/shared/BaseEntity.ts
export interface BaseEntityDto {
  readonly id: string;
  readonly createdAt: string;
  readonly updatedAt: string;
}
```

#### List Response DTO

```typescript
// dtos/response/BudgetListResponseDto.ts
export interface BudgetListResponseDto {
  readonly budgets: BudgetResponseDto[];
  readonly total: number;
  readonly page: number;
  readonly pageSize: number;
}
```

---

## 2. Application - Use Cases e Orquestração (TypeScript Puro)

### Responsabilidades

- **Commands**: Orquestração de operações de escrita (`CreateTransactionCommand`)
- **Queries**: Processamento de consultas (`GetBudgetSummaryQuery`)
- **Ports Definition**: 1 interface por operação (`ICreateBudgetPort`, `IGetBudgetByIdPort`)
- **Validators**: Validações client-side básicas para UX
- **Transformers**: Transformações leves de dados quando necessário

### Características

- **HTTP Orchestration**: Coordena chamadas para o backend
- **Framework Agnostic**: Sem dependências de Angular
- **Port Definitions**: Define contratos que Infra implementa
- **Simple Logic**: Validações básicas e transformações simples

### Exemplos Práticos

#### Command (Mutation)

```typescript
// application/commands/transaction/CreateTransactionCommand.ts
export class CreateTransactionCommand {
  constructor(private port: ICreateTransactionPort) {}

  async execute(
    dto: CreateTransactionRequestDto
  ): Promise<Either<ApplicationError, void>> {
    // 1. Validação client-side básica (para UX)
    const validation = CreateTransactionValidator.validate(dto);
    if (validation.hasError) {
      return Either.error(new ValidationError(validation.errors));
    }

    // 2. Chamar port (que implementa a operação)
    return this.port.execute(dto);
  }
}
```

#### Query (Read Operation)

```typescript
// application/queries/budget/GetBudgetSummaryQuery.ts
export class GetBudgetSummaryQuery {
  constructor(private port: IGetBudgetSummaryPort) {}

  async execute(
    request: GetBudgetSummaryRequest
  ): Promise<Either<QueryError, BudgetSummaryResponseDto>> {
    try {
      // Chamar port (que implementa a operação)
      return this.port.execute(request);
    } catch (error) {
      return Either.error(new QueryError("Failed to get budget summary"));
    }
  }
}
```

#### Port Definition (1 Interface por Operação)

```typescript
// application/ports/mutations/budget/ICreateBudgetPort.ts
export interface ICreateBudgetPort {
  execute(request: CreateBudgetRequestDto): Promise<Either<ServiceError, void>>;
}

// application/ports/queries/budget/IGetBudgetByIdPort.ts
export interface IGetBudgetByIdPort {
  execute(id: string): Promise<Either<ServiceError, BudgetResponseDto>>;
}

// application/ports/queries/budget/IGetBudgetSummaryPort.ts
export interface IGetBudgetSummaryPort {
  execute(
    request: GetBudgetSummaryRequest
  ): Promise<Either<ServiceError, BudgetSummaryResponseDto>>;
}
```

#### Validator

```typescript
// application/validators/CreateTransactionValidator.ts
export class CreateTransactionValidator {
  static validate(dto: CreateTransactionRequestDto): ValidationResult {
    const errors: string[] = [];

    if (!dto.accountId?.trim()) {
      errors.push("Account ID is required");
    }

    if (!dto.budgetId?.trim()) {
      errors.push("Budget ID is required");
    }

    if (!dto.amountInCents || dto.amountInCents <= 0) {
      errors.push("Amount must be greater than zero");
    }

    if (!dto.description?.trim()) {
      errors.push("Description is required");
    }

    if (!dto.type || !["INCOME", "EXPENSE"].includes(dto.type)) {
      errors.push("Type must be INCOME or EXPENSE");
    }

    return {
      hasError: errors.length > 0,
      errors,
    };
  }
}
```

---

## 3. Infra - Adapters e Implementações

### Responsabilidades

- **HTTP Adapters**: Implementação de Ports via HTTP/API (`HttpBudgetServiceAdapter`)
- **Storage Adapters**: Persistência local (`LocalStoreAdapter` com IndexedDB)
- **Auth Adapters**: Provedores de autenticação (`FirebaseAuthAdapter`)
- **Mappers**: Conversão de formatos apenas quando necessário
- **External Services**: Integrações com serviços externos

### Características

- **Port Implementations**: Implementa interfaces definidas em Application
- **External Dependencies**: Única camada que conhece APIs, storage, etc.
- **Framework Specific**: Pode usar Angular HttpClient, bibliotecas específicas
- **Error Translation**: Converte erros externos para Domain Errors
- **Direct DTOs**: Trabalha diretamente com DTOs na maioria dos casos

### Exemplos Práticos

#### HTTP Adapter (1 Adapter por Port)

```typescript
// infra/http/adapters/mutations/budget/HttpCreateBudgetAdapter.ts
@Injectable({ providedIn: "root" })
export class HttpCreateBudgetAdapter implements ICreateBudgetPort {
  constructor(private httpClient: IHttpClient) {}

  async execute(
    request: CreateBudgetRequestDto
  ): Promise<Either<ServiceError, void>> {
    try {
      await this.httpClient.post("/budget/create", request);
      return Either.success(undefined);
    } catch (error) {
      return Either.error(new ServiceError("Failed to create budget"));
    }
  }
}

// infra/http/adapters/queries/budget/HttpGetBudgetByIdAdapter.ts
@Injectable({ providedIn: "root" })
export class HttpGetBudgetByIdAdapter implements IGetBudgetByIdPort {
  constructor(private httpClient: IHttpClient) {}

  async execute(id: string): Promise<Either<ServiceError, BudgetResponseDto>> {
    try {
      const response = await this.httpClient.get<BudgetResponseDto>(
        `/budget/${id}`
      );
      return Either.success(response);
    } catch (error) {
      if (error.status === 404) {
        return Either.error(new BudgetNotFoundError(id));
      }
      return Either.error(new ServiceError("Failed to fetch budget"));
    }
  }
}
```

#### Storage Adapter

```typescript
// infra/adapters/storage/LocalStoreAdapter.ts
export class LocalStoreAdapter implements ILocalStorePort {
  private db: IDBDatabase | null = null;

  async get<T>(storeName: string, key: string): Promise<T | null> {
    const transaction = this.db!.transaction([storeName], "readonly");
    const store = transaction.objectStore(storeName);

    return new Promise((resolve, reject) => {
      const request = store.get(key);
      request.onsuccess = () => resolve(request.result || null);
      request.onerror = () => reject(request.error);
    });
  }

  async set<T>(storeName: string, key: string, value: T): Promise<void> {
    const transaction = this.db!.transaction([storeName], "readwrite");
    const store = transaction.objectStore(storeName);

    return new Promise((resolve, reject) => {
      const request = store.put(value, key);
      request.onsuccess = () => resolve();
      request.onerror = () => reject(request.error);
    });
  }
}
```

#### Mapper (Apenas quando necessário)

```typescript
// infra/mappers/DateMapper.ts
export class DateMapper {
  // Apenas quando API retorna formato diferente do esperado
  static toISOString(dateString: string): string {
    return new Date(dateString).toISOString();
  }

  static toDisplayFormat(isoString: string): string {
    return new Date(isoString).toLocaleDateString("pt-BR");
  }
}
```

---

## 4. UI (Angular) - Interface do Usuário

### Responsabilidades

- **Components**: Componentes Angular específicos por feature
- **Pages**: Componentes roteáveis que compõem widgets
- **Routing**: Navegação e lazy loading
- **State Management**: Estado local com Angular Signals usando DTOs
- **Dependency Injection**: Conecta Application layer via Providers

### Características

- **Framework Specific**: Totalmente Angular
- **Reactive**: Angular Signals para estado reativo
- **Stateless**: Delega lógica para Application layer
- **Presentation**: Foco em apresentação e interação
- **DTO-Based**: Trabalha diretamente com DTOs sem conversões

### Exemplos Práticos

#### Page Component

```typescript
// app/features/budgets/pages/budget-list.page.ts
@Component({
  selector: "app-budget-list",
  template: `
    <os-page-header title="Meus Orçamentos" />

    @if (loading()) {
    <os-skeleton-list />
    } @else if (budgets().length > 0) { @for (budget of budgets(); track
    budget.id) {
    <os-budget-card [budget]="budget" (onClick)="navigateToBudget(budget.id)" />
    } } @else {
    <os-empty-state
      message="Nenhum orçamento encontrado"
      (onActionClick)="createBudget()"
    />
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class BudgetListPage {
  private getBudgetListQuery = inject(GetBudgetListQuery);
  private router = inject(Router);

  // Estado local com signals usando DTOs
  protected budgets = signal<BudgetResponseDto[]>([]);
  protected loading = signal(false);
  protected error = signal<string | null>(null);

  // Estado computado
  protected isEmpty = computed(
    () => !this.loading() && this.budgets().length === 0
  );

  async ngOnInit() {
    await this.loadBudgets();
  }

  protected async loadBudgets() {
    this.loading.set(true);

    const result = await this.getBudgetListQuery.execute({});

    if (result.hasError) {
      this.error.set(result.error.message);
    } else {
      this.budgets.set(result.data!);
    }

    this.loading.set(false);
  }

  protected navigateToBudget(budgetId: string) {
    this.router.navigate(["/budgets", budgetId]);
  }

  protected createBudget() {
    this.router.navigate(["/budgets/create"]);
  }
}
```

#### Widget Component

```typescript
// app/features/budgets/components/budget-card.component.ts
@Component({
  selector: "app-budget-card",
  template: `
    <os-card [clickable]="true" (onClick)="onClick.emit()">
      <os-card-header>
        <h3>{{ budget().name }}</h3>
        <os-badge [variant]="statusVariant()">
          {{ statusText() }}
        </os-badge>
      </os-card-header>

      <os-card-content>
        <div class="budget-limit">
          <span>Limite: </span>
          <os-money [amountInCents]="budget().limitInCents" />
        </div>

        <div class="participants">{{ participantCount() }} participante(s)</div>
      </os-card-content>
    </os-card>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class BudgetCardComponent {
  // Modern Angular input/output usando DTO
  budget = input.required<BudgetResponseDto>();
  onClick = output<void>();

  // Estado computado
  protected participantCount = computed(
    () => this.budget().participants.length
  );

  protected statusVariant = computed(() => {
    const usage = this.budget().currentUsagePercentage;
    return usage > 90 ? "danger" : usage > 70 ? "warning" : "success";
  });

  protected statusText = computed(() => {
    const usage = this.budget().currentUsagePercentage;
    return `${usage}% utilizado`;
  });
}
```

#### Service (DI Provider)

```typescript
// app/providers/commands-queries.provider.ts
export function provideCommandsAndQueries(): Provider[] {
  return [
    // Commands
    CreateBudgetCommand,
    UpdateBudgetCommand,
    DeleteBudgetCommand,

    // Queries
    GetBudgetListQuery,
    GetBudgetByIdQuery,
    GetBudgetSummaryQuery,

    // Port implementations injection (1 por operação)
    {
      provide: ICreateBudgetPort,
      useClass: HttpCreateBudgetAdapter,
    },
    {
      provide: IGetBudgetByIdPort,
      useClass: HttpGetBudgetByIdAdapter,
    },
    {
      provide: IGetBudgetListPort,
      useClass: HttpGetBudgetListAdapter,
    },
  ];
}
```

---

## 5. Shared/UI-Components - Design System

### Responsabilidades

- **Abstraction Layer**: Encapsula Angular Material mantendo API própria
- **Design Tokens**: Centraliza cores, espaçamentos e tipografia
- **Accessibility**: Garante padrões a11y consistentes
- **Migration Path**: Permite migração futura sem breaking changes

### Características

- **Component API**: Interface própria, não Material diretamente
- **Theming**: Customização sobre Material Design
- **Atomic Design**: Atoms, Molecules, Organisms
- **Brand Consistency**: Identidade visual do OrçaSonhos

### Exemplos Práticos

#### Atom Component

```typescript
// app/shared/ui-components/atoms/os-button/os-button.component.ts
@Component({
  selector: "os-button",
  template: `
    <button
      mat-button
      [color]="matColor()"
      [disabled]="disabled()"
      [attr.aria-label]="ariaLabel()"
      (click)="onClick.emit($event)"
    >
      @if (loading()) {
      <mat-spinner diameter="16" />
      } @else {
      <ng-content />
      }
    </button>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OsButtonComponent {
  // Public API (OrçaSonhos specific)
  variant = input<"primary" | "secondary" | "danger">("primary");
  disabled = input(false);
  loading = input(false);
  ariaLabel = input<string>();

  onClick = output<MouseEvent>();

  // Internal Material mapping
  protected matColor = computed(() => {
    const variant = this.variant();
    return variant === "primary"
      ? "primary"
      : variant === "danger"
      ? "warn"
      : "accent";
  });
}
```

---

## Fluxo de Integração Entre Features

### Feature Internal Flow

```
[Feature Component]
    ↓ (user action - DTO)
[Feature Service]
    ↓ (orquestração)
[Command/Query]
    ↓ (validação básica)
[Port Interface]
    ↓ (execute method)
[HTTP Adapter]
    ↓ (POST/GET com DTO)
[Backend API]
```

### Inter-Feature Communication

```
[Feature A Component]
    ↓ (event/state change)
[Shared Service/State]
    ↓ (notificação)
[Feature B Component]
    ↓ (reação ao evento)
[Feature B Service]
    ↓ (atualização local)
[Feature B State]
```

### Shared Component Usage

```
[Feature Component]
    ↓ (template usage)
[Shared UI Component]
    ↓ (props/events)
[Feature Component]
    ↓ (handling)
[Feature Service]
```

## Regras de Comunicação Entre Features

### ✅ Permitido

- **Shared Components**: Features podem usar componentes shared
- **Core Services**: Features podem usar serviços globais (Auth, Config)
- **DTOs**: Features podem usar DTOs compartilhados
- **Events**: Features podem emitir eventos globais via services
- **State**: Features podem reagir a mudanças de estado global

### ❌ Evitar

- **Importação Direta**: Features não devem importar componentes de outras features
- **Dependências Circulares**: Features não devem depender umas das outras
- **Estado Compartilhado**: Evitar estado compartilhado entre features específicas

### 🔄 Alternativas Recomendadas

- **Shared Services**: Usar serviços compartilhados para comunicação
- **Event Bus**: Usar eventos para comunicação assíncrona
- **State Management**: Usar estado global apenas quando necessário
- **Props/Events**: Usar props e events para comunicação entre componentes

---

**Ver também:**

- [Directory Structure](./directory-structure.md) - Organização física das features
- [Feature Organization](./feature-organization.md) - Como organizar features independentes
- [Dependency Rules](./dependency-rules.md) - Regras de dependência entre features
- [Data Flow](./data-flow.md) - Fluxos de Commands e Queries detalhados
