# Integração com Backend

## Alinhamento Arquitetural

O frontend está totalmente alinhado com a arquitetura backend, seguindo os mesmos padrões:

- **CQRS**: Separação entre Commands (mutations) e Queries (reads)
- **Command-Style Endpoints**: `POST /<context>/<action>` para mutações
- **Either Pattern**: Tratamento de erros consistente
- **Domain Alignment**: Mesmo vocabulário ubíquo

## Contratos de API

### Command Endpoints (Mutations)

Todos os commands seguem o padrão `POST /<aggregate>/<action>`:

```typescript
// Exemplos de endpoints de command
POST /transaction/create
POST /transaction/update  
POST /transaction/delete
POST /account/create
POST /account/transfer-money
POST /budget/create
POST /budget/add-participant
POST /envelope/allocate-money
POST /goal/create
POST /credit-card/create
POST /credit-card-bill/pay
```

### Query Endpoints (Reads)

```typescript
// Exemplos de endpoints de query
GET /budget/{id}/summary?period=current_month
GET /transaction/list?budgetId=123&limit=50
GET /account/{id}
GET /envelope/list?budgetId=123
GET /credit-card/{id}/current-bill
GET /goal/list?budgetId=123
```

## Port Definitions (Application Layer)

### Service Ports por Contexto

```typescript
// application/ports/IBudgetServicePort.ts
export interface IBudgetServicePort {
  // Commands
  create(budget: Budget): Promise<Either<ServiceError, void>>;
  update(budget: Budget): Promise<Either<ServiceError, void>>;
  delete(id: string): Promise<Either<ServiceError, void>>;
  addParticipant(budgetId: string, userId: string): Promise<Either<ServiceError, void>>;
  
  // Queries  
  getById(id: string): Promise<Either<ServiceError, Budget>>;
  getByUserId(userId: string): Promise<Either<ServiceError, Budget[]>>;
  getSummary(budgetId: string, period: string): Promise<Either<ServiceError, BudgetSummaryDto>>;
}

// application/ports/ITransactionServicePort.ts
export interface ITransactionServicePort {
  // Commands
  create(transaction: Transaction): Promise<Either<ServiceError, void>>;
  update(transaction: Transaction): Promise<Either<ServiceError, void>>;
  delete(id: string): Promise<Either<ServiceError, void>>;
  
  // Queries
  getById(id: string): Promise<Either<ServiceError, Transaction>>;
  getByBudget(budgetId: string, params?: TransactionQueryParams): Promise<Either<ServiceError, Transaction[]>>;
  getByAccount(accountId: string, params?: TransactionQueryParams): Promise<Either<ServiceError, Transaction[]>>;
}

// application/ports/IAccountServicePort.ts
export interface IAccountServicePort {
  // Commands  
  create(account: Account): Promise<Either<ServiceError, void>>;
  update(account: Account): Promise<Either<ServiceError, void>>;
  delete(id: string): Promise<Either<ServiceError, void>>;
  transferMoney(params: TransferMoneyParams): Promise<Either<ServiceError, void>>;
  
  // Queries
  getById(id: string): Promise<Either<ServiceError, Account>>;
  getByBudget(budgetId: string): Promise<Either<ServiceError, Account[]>>;
}
```

## HTTP Client Personalizado

### IHttpClient Interface
```typescript
// infra/http/IHttpClient.ts
export interface IHttpClient {
  get<T>(url: string, options?: HttpOptions): Promise<T>;
  post<T>(url: string, data?: unknown, options?: HttpOptions): Promise<T>;
  put<T>(url: string, data?: unknown, options?: HttpOptions): Promise<T>;
  delete<T>(url: string, options?: HttpOptions): Promise<T>;
}

export interface HttpOptions {
  headers?: Record<string, string>;
  timeout?: number;
  signal?: AbortSignal;
}
```

### FetchHttpClient Implementation
```typescript
// infra/http/FetchHttpClient.ts
@Injectable({ providedIn: 'root' })
export class FetchHttpClient implements IHttpClient {
  private readonly baseUrl: string;
  private readonly defaultTimeout = 30000; // 30 segundos

  constructor(
    private tokenProvider: IAuthTokenProvider,
    @Inject('API_BASE_URL') baseUrl = '/api'
  ) {
    this.baseUrl = baseUrl;
  }

  async get<T>(url: string, options?: HttpOptions): Promise<T> {
    return this.makeRequest<T>('GET', url, undefined, options);
  }

  async post<T>(url: string, data?: unknown, options?: HttpOptions): Promise<T> {
    return this.makeRequest<T>('POST', url, data, options);
  }

  private async makeRequest<T>(
    method: string,
    url: string,
    data?: unknown,
    options?: HttpOptions
  ): Promise<T> {
    const fullUrl = `${this.baseUrl}${url}`;
    
    // Preparar headers
    const headers = await this.buildHeaders(options?.headers);
    
    // Preparar request
    const requestInit: RequestInit = {
      method,
      headers,
      signal: options?.signal
    };
    
    // Adicionar body para métodos que suportam
    if (data && ['POST', 'PUT', 'PATCH'].includes(method)) {
      requestInit.body = JSON.stringify(data);
    }
    
    // Timeout handling
    const timeoutSignal = this.createTimeoutSignal(options?.timeout);
    if (timeoutSignal && !options?.signal) {
      requestInit.signal = timeoutSignal;
    }
    
    try {
      const response = await fetch(fullUrl, requestInit);
      return await this.handleResponse<T>(response);
    } catch (error) {
      throw this.handleRequestError(error);
    }
  }

  private async buildHeaders(customHeaders?: Record<string, string>): Promise<HeadersInit> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...customHeaders
    };
    
    // Anexar token de autenticação se disponível
    const token = await this.tokenProvider.getToken();
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }
    
    return headers;
  }

  private async handleResponse<T>(response: Response): Promise<T> {
    // Verificar status de sucesso
    if (!response.ok) {
      throw await this.createHttpError(response);
    }
    
    // Lidar com 204 No Content
    if (response.status === 204) {
      return undefined as T;
    }
    
    // Verificar se tem conteúdo
    const contentType = response.headers.get('content-type');
    if (!contentType?.includes('application/json')) {
      if (response.status === 200 && !contentType) {
        // 200 OK sem conteúdo - válido para alguns commands
        return undefined as T;
      }
      throw new HttpError('Invalid content type', response.status);
    }
    
    try {
      return await response.json();
    } catch (error) {
      throw new HttpError('Invalid JSON response', response.status);
    }
  }

  private async createHttpError(response: Response): Promise<HttpError> {
    let errorData: any = null;
    
    try {
      // Tentar parsear corpo da resposta de erro
      errorData = await response.json();
    } catch {
      // Ignorar erro de parsing
    }
    
    const message = errorData?.message || `HTTP ${response.status} ${response.statusText}`;
    
    return new HttpError(message, response.status, errorData);
  }

  private createTimeoutSignal(timeout?: number): AbortSignal | null {
    const timeoutMs = timeout || this.defaultTimeout;
    
    if (!timeoutMs) return null;
    
    const controller = new AbortController();
    setTimeout(() => controller.abort(), timeoutMs);
    
    return controller.signal;
  }

  private handleRequestError(error: unknown): HttpError {
    if (error instanceof HttpError) {
      return error;
    }
    
    if (error instanceof DOMException && error.name === 'AbortError') {
      return new HttpError('Request timeout', 408);
    }
    
    if (error instanceof TypeError && error.message.includes('fetch')) {
      return new HttpError('Network error', 0);
    }
    
    return new HttpError('Unknown error', 0);
  }
}
```

## HTTP Adapters (Infrastructure)

### Budget Service Adapter
```typescript
// infra/adapters/http/HttpBudgetServiceAdapter.ts
@Injectable({ providedIn: 'root' })
export class HttpBudgetServiceAdapter implements IBudgetServicePort {
  constructor(private httpClient: IHttpClient) {}

  async create(budget: Budget): Promise<Either<ServiceError, void>> {
    try {
      const createDto = BudgetApiMapper.toCreateDto(budget);
      
      await this.httpClient.post('/budget/create', createDto);
      
      return Either.success(undefined);
    } catch (error) {
      return Either.error(this.handleError(error));
    }
  }

  async update(budget: Budget): Promise<Either<ServiceError, void>> {
    try {
      const updateDto = BudgetApiMapper.toUpdateDto(budget);
      
      await this.httpClient.post('/budget/update', {
        id: budget.id,
        ...updateDto
      });
      
      return Either.success(undefined);
    } catch (error) {
      return Either.error(this.handleError(error));
    }
  }

  async getById(id: string): Promise<Either<ServiceError, Budget>> {
    try {
      const response = await this.httpClient.get<BudgetApiDto>(`/budget/${id}`);
      const budget = BudgetApiMapper.toDomain(response);
      
      return Either.success(budget);
    } catch (error) {
      return Either.error(this.handleError(error));
    }
  }

  async getSummary(
    budgetId: string, 
    period: string
  ): Promise<Either<ServiceError, BudgetSummaryDto>> {
    try {
      const response = await this.httpClient.get<BudgetSummaryApiDto>(
        `/budget/${budgetId}/summary?period=${period}`
      );
      
      const summary = BudgetSummaryMapper.fromApiDto(response);
      
      return Either.success(summary);
    } catch (error) {
      return Either.error(this.handleError(error));
    }
  }

  private handleError(error: unknown): ServiceError {
    if (error instanceof HttpError) {
      switch (error.status) {
        case 400:
          return new ValidationError('Invalid budget data');
        case 401:
          return new UnauthorizedError('access budget');
        case 403:
          return new ForbiddenError('budget access');
        case 404:
          return new NotFoundError('Budget not found');
        case 409:
          return new ConflictError('Budget conflict');
        case 0:
          return new NetworkError('No connection');
        default:
          return new ServiceError(`HTTP ${error.status}: ${error.message}`);
      }
    }
    
    return new ServiceError('Unknown error');
  }
}
```

### Transaction Service Adapter  
```typescript
// infra/adapters/http/HttpTransactionServiceAdapter.ts
@Injectable({ providedIn: 'root' })
export class HttpTransactionServiceAdapter implements ITransactionServicePort {
  constructor(private httpClient: IHttpClient) {}

  async create(transaction: Transaction): Promise<Either<ServiceError, void>> {
    try {
      const createDto: CreateTransactionApiDto = {
        account_id: transaction.accountId,
        budget_id: transaction.budgetId,
        amount_in_cents: transaction.amount.cents,
        description: transaction.description,
        transaction_type: transaction.type.value,
        category_id: transaction.categoryId,
        transaction_date: transaction.date.toISOString()
      };
      
      await this.httpClient.post('/transaction/create', createDto);
      
      return Either.success(undefined);
    } catch (error) {
      return Either.error(this.handleTransactionError(error));
    }
  }

  async getByBudget(
    budgetId: string,
    params?: TransactionQueryParams
  ): Promise<Either<ServiceError, Transaction[]>> {
    try {
      const queryParams = this.buildQueryString(params);
      const url = `/transaction/list?budgetId=${budgetId}${queryParams}`;
      
      const response = await this.httpClient.get<TransactionListApiDto>(url);
      const transactions = response.transactions.map(dto => 
        TransactionApiMapper.toDomain(dto)
      );
      
      return Either.success(transactions);
    } catch (error) {
      return Either.error(this.handleTransactionError(error));
    }
  }

  private buildQueryString(params?: TransactionQueryParams): string {
    if (!params) return '';
    
    const searchParams = new URLSearchParams();
    
    if (params.limit) {
      searchParams.set('limit', params.limit.toString());
    }
    
    if (params.offset) {
      searchParams.set('offset', params.offset.toString());
    }
    
    if (params.startDate) {
      searchParams.set('startDate', params.startDate.toISOString());
    }
    
    if (params.endDate) {
      searchParams.set('endDate', params.endDate.toISOString());
    }
    
    if (params.categoryId) {
      searchParams.set('categoryId', params.categoryId);
    }
    
    return searchParams.toString() ? `&${searchParams.toString()}` : '';
  }
}
```

## API Mappers (Data Transformation)

### Money Value Handling
```typescript
// infra/mappers/MoneyMapper.ts
export class MoneyMapper {
  static toApiCents(money: Money): number {
    return money.cents;
  }
  
  static fromApiCents(cents: number): Money {
    return Money.fromCents(cents);
  }
  
  static toApiReais(money: Money): number {
    return money.reais;
  }
  
  static fromApiReais(reais: number): Money {
    return Money.fromReais(reais);
  }
}
```

### Domain ↔ API Mapping
```typescript
// infra/mappers/TransactionApiMapper.ts
export class TransactionApiMapper {
  static toDomain(dto: TransactionApiDto): Transaction {
    return Transaction.fromSnapshot({
      id: dto.id,
      accountId: dto.account_id,
      budgetId: dto.budget_id,
      amount: MoneyMapper.fromApiCents(dto.amount_in_cents),
      description: dto.description,
      type: TransactionType.fromString(dto.transaction_type),
      categoryId: dto.category_id,
      date: new Date(dto.transaction_date),
      createdAt: new Date(dto.created_at),
      updatedAt: new Date(dto.updated_at)
    });
  }
  
  static toCreateDto(transaction: Transaction): CreateTransactionApiDto {
    return {
      account_id: transaction.accountId,
      budget_id: transaction.budgetId,
      amount_in_cents: MoneyMapper.toApiCents(transaction.amount),
      description: transaction.description,
      transaction_type: transaction.type.value,
      category_id: transaction.categoryId,
      transaction_date: transaction.date.toISOString()
    };
  }
}
```

## Error Handling & Retry

### HTTP Error Types
```typescript
// infra/errors/HttpError.ts
export class HttpError extends Error {
  constructor(
    message: string,
    public readonly status: number,
    public readonly data?: any
  ) {
    super(message);
    this.name = 'HttpError';
  }
}

export class NetworkError extends HttpError {
  constructor(message = 'Network error') {
    super(message, 0);
    this.name = 'NetworkError';
  }
}

export class TimeoutError extends HttpError {
  constructor(message = 'Request timeout') {
    super(message, 408);
    this.name = 'TimeoutError';
  }
}
```

### Retry Strategy
```typescript
// infra/http/RetryHttpClient.ts - Decorator pattern
export class RetryHttpClient implements IHttpClient {
  constructor(
    private baseClient: IHttpClient,
    private retryConfig: RetryConfig = DEFAULT_RETRY_CONFIG
  ) {}

  async get<T>(url: string, options?: HttpOptions): Promise<T> {
    return this.executeWithRetry(() => this.baseClient.get<T>(url, options));
  }

  async post<T>(url: string, data?: unknown, options?: HttpOptions): Promise<T> {
    return this.executeWithRetry(() => this.baseClient.post<T>(url, data, options));
  }

  private async executeWithRetry<T>(operation: () => Promise<T>): Promise<T> {
    let lastError: any;
    
    for (let attempt = 0; attempt <= this.retryConfig.maxAttempts; attempt++) {
      try {
        return await operation();
      } catch (error) {
        lastError = error;
        
        if (!this.shouldRetry(error, attempt)) {
          throw error;
        }
        
        await this.delay(this.calculateDelay(attempt));
      }
    }
    
    throw lastError;
  }

  private shouldRetry(error: unknown, attempt: number): boolean {
    if (attempt >= this.retryConfig.maxAttempts) return false;
    
    if (error instanceof NetworkError) return true;
    if (error instanceof TimeoutError) return true;
    
    if (error instanceof HttpError) {
      // Retry em 5xx, mas não em 4xx
      return error.status >= 500;
    }
    
    return false;
  }

  private calculateDelay(attempt: number): number {
    const baseDelay = this.retryConfig.baseDelay;
    const exponentialDelay = baseDelay * Math.pow(2, attempt);
    const jitter = Math.random() * 1000; // Adicionar jitter para evitar thundering herd
    
    return Math.min(exponentialDelay + jitter, this.retryConfig.maxDelay);
  }
}
```

## Request/Response Interceptors

### Request Interceptor
```typescript
// infra/http/interceptors/RequestInterceptor.ts
export interface IRequestInterceptor {
  intercept(url: string, options: HttpOptions): Promise<HttpOptions>;
}

@Injectable()
export class AuthRequestInterceptor implements IRequestInterceptor {
  constructor(private tokenProvider: IAuthTokenProvider) {}

  async intercept(url: string, options: HttpOptions): Promise<HttpOptions> {
    const token = await this.tokenProvider.getToken();
    
    if (token) {
      return {
        ...options,
        headers: {
          ...options.headers,
          'Authorization': `Bearer ${token}`
        }
      };
    }
    
    return options;
  }
}

@Injectable()
export class LoggingRequestInterceptor implements IRequestInterceptor {
  async intercept(url: string, options: HttpOptions): Promise<HttpOptions> {
    console.log(`[HTTP] ${options.method || 'GET'} ${url}`);
    return options;
  }
}
```

### Response Interceptor
```typescript
// infra/http/interceptors/ResponseInterceptor.ts
export interface IResponseInterceptor {
  intercept<T>(response: T, error?: Error): Promise<T>;
}

@Injectable()
export class ErrorResponseInterceptor implements IResponseInterceptor {
  constructor(
    private authService: IAuthService,
    private notificationService: INotificationService
  ) {}

  async intercept<T>(response: T, error?: Error): Promise<T> {
    if (error instanceof HttpError) {
      switch (error.status) {
        case 401:
          // Token expirado - tentar refresh ou logout
          await this.handleUnauthorized();
          break;
          
        case 403:
          this.notificationService.error('Acesso negado', 'Você não tem permissão para esta operação');
          break;
          
        case 500:
          this.notificationService.error('Erro do servidor', 'Tente novamente em alguns instantes');
          break;
      }
    }
    
    if (error) {
      throw error;
    }
    
    return response;
  }

  private async handleUnauthorized(): Promise<void> {
    // Tentar renovar token ou forçar relogin
    await this.authService.signOut();
  }
}
```

---

**Ver também:**
- [Authentication](./authentication.md) - Como tokens são gerenciados e enviados
- [Data Flow](./data-flow.md) - Fluxos de Commands e Queries detalhados
- [Offline Strategy](./offline-strategy.md) - Integração offline com sync de comandos