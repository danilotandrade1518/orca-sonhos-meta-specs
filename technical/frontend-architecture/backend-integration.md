# Integração com Backend

## Alinhamento Arquitetural

O frontend está totalmente alinhado com a arquitetura backend através da **DTO-First Architecture**:

- **CQRS**: Separação entre Commands (mutations) e Queries (reads)
- **Command-Style Endpoints**: `POST /<context>/<action>` para mutações
- **Either Pattern**: Tratamento de erros consistente
- **DTO-First**: DTOs fluem diretamente entre frontend e backend
- **API Alignment**: Contratos de API como fonte da verdade

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

### Ports por Operação (Padrão Command)

```typescript
// application/ports/mutations/budget/ICreateBudgetPort.ts
export interface ICreateBudgetPort {
  execute(request: CreateBudgetRequestDto): Promise<Either<ServiceError, void>>;
}

// application/ports/mutations/budget/IUpdateBudgetPort.ts
export interface IUpdateBudgetPort {
  execute(request: UpdateBudgetRequestDto): Promise<Either<ServiceError, void>>;
}

// application/ports/mutations/budget/IDeleteBudgetPort.ts
export interface IDeleteBudgetPort {
  execute(id: string): Promise<Either<ServiceError, void>>;
}

// application/ports/mutations/budget/IAddParticipantPort.ts
export interface IAddParticipantPort {
  execute(request: AddParticipantRequestDto): Promise<Either<ServiceError, void>>;
}

// application/ports/queries/budget/IGetBudgetByIdPort.ts
export interface IGetBudgetByIdPort {
  execute(id: string): Promise<Either<ServiceError, BudgetResponseDto>>;
}

// application/ports/queries/budget/IGetBudgetListPort.ts
export interface IGetBudgetListPort {
  execute(request: GetBudgetListRequest): Promise<Either<ServiceError, BudgetListResponseDto>>;
}

// application/ports/queries/budget/IGetBudgetSummaryPort.ts
export interface IGetBudgetSummaryPort {
  execute(request: GetBudgetSummaryRequest): Promise<Either<ServiceError, BudgetSummaryResponseDto>>;
}

// application/ports/mutations/transaction/ICreateTransactionPort.ts
export interface ICreateTransactionPort {
  execute(request: CreateTransactionRequestDto): Promise<Either<ServiceError, void>>;
}

// application/ports/mutations/transaction/IUpdateTransactionPort.ts
export interface IUpdateTransactionPort {
  execute(request: UpdateTransactionRequestDto): Promise<Either<ServiceError, void>>;
}

// application/ports/mutations/transaction/IDeleteTransactionPort.ts
export interface IDeleteTransactionPort {
  execute(id: string): Promise<Either<ServiceError, void>>;
}

// application/ports/queries/transaction/IGetTransactionByIdPort.ts
export interface IGetTransactionByIdPort {
  execute(id: string): Promise<Either<ServiceError, TransactionResponseDto>>;
}

// application/ports/queries/transaction/IGetTransactionListPort.ts
export interface IGetTransactionListPort {
  execute(request: GetTransactionListRequest): Promise<Either<ServiceError, TransactionListResponseDto>>;
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

### Budget Adapters (1 Adapter por Port)

```typescript
// infra/http/adapters/mutations/budget/HttpCreateBudgetAdapter.ts
@Injectable({ providedIn: 'root' })
export class HttpCreateBudgetAdapter implements ICreateBudgetPort {
  constructor(private httpClient: IHttpClient) {}

  async execute(request: CreateBudgetRequestDto): Promise<Either<ServiceError, void>> {
    try {
      // DTOs fluem diretamente - sem mapeamentos
      await this.httpClient.post('/budget/create', request);
      
      return Either.success(undefined);
    } catch (error) {
      return Either.error(this.handleError(error));
    }
  }

  private handleError(error: unknown): ServiceError {
    if (error instanceof HttpError) {
      switch (error.status) {
        case 400:
          return new ValidationError('Dados inválidos');
        case 401:
          return new UnauthorizedError('acessar orçamento');
        case 403:
          return new ForbiddenError('acesso ao orçamento');
        case 409:
          return new ConflictError('Conflito no orçamento');
        case 0:
          return new NetworkError('Sem conexão');
        default:
          return new ServiceError(`HTTP ${error.status}: ${error.message}`);
      }
    }
    
    return new ServiceError('Erro desconhecido');
  }
}

// infra/http/adapters/mutations/budget/HttpUpdateBudgetAdapter.ts
@Injectable({ providedIn: 'root' })
export class HttpUpdateBudgetAdapter implements IUpdateBudgetPort {
  constructor(private httpClient: IHttpClient) {}

  async execute(request: UpdateBudgetRequestDto): Promise<Either<ServiceError, void>> {
    try {
      // DTOs fluem diretamente
      await this.httpClient.post('/budget/update', request);
      
      return Either.success(undefined);
    } catch (error) {
      return Either.error(this.handleError(error));
    }
  }

  private handleError(error: unknown): ServiceError {
    // ... mesmo tratamento de erro
  }
}

// infra/http/adapters/queries/budget/HttpGetBudgetByIdAdapter.ts
@Injectable({ providedIn: 'root' })
export class HttpGetBudgetByIdAdapter implements IGetBudgetByIdPort {
  constructor(private httpClient: IHttpClient) {}

  async execute(id: string): Promise<Either<ServiceError, BudgetResponseDto>> {
    try {
      // DTOs fluem diretamente
      const response = await this.httpClient.get<BudgetResponseDto>(`/budget/${id}`);
      
      return Either.success(response);
    } catch (error) {
      return Either.error(this.handleError(error));
    }
  }

  private handleError(error: unknown): ServiceError {
    // ... tratamento de erro
  }
}

// infra/http/adapters/queries/budget/HttpGetBudgetSummaryAdapter.ts
@Injectable({ providedIn: 'root' })
export class HttpGetBudgetSummaryAdapter implements IGetBudgetSummaryPort {
  constructor(private httpClient: IHttpClient) {}

  async execute(request: GetBudgetSummaryRequest): Promise<Either<ServiceError, BudgetSummaryResponseDto>> {
    try {
      // DTOs fluem diretamente
      const response = await this.httpClient.get<BudgetSummaryResponseDto>(
        `/budget/${request.budgetId}/summary?period=${request.period}`
      );
      
      return Either.success(response);
    } catch (error) {
      return Either.error(this.handleError(error));
    }
  }

  private handleError(error: unknown): ServiceError {
    // ... tratamento de erro
  }
}
```

### Transaction Adapters (1 Adapter por Port)

```typescript
// infra/http/adapters/mutations/transaction/HttpCreateTransactionAdapter.ts
@Injectable({ providedIn: 'root' })
export class HttpCreateTransactionAdapter implements ICreateTransactionPort {
  constructor(private httpClient: IHttpClient) {}

  async execute(request: CreateTransactionRequestDto): Promise<Either<ServiceError, void>> {
    try {
      // DTOs fluem diretamente - sem mapeamentos
      await this.httpClient.post('/transaction/create', request);
      
      return Either.success(undefined);
    } catch (error) {
      return Either.error(this.handleError(error));
    }
  }

  private handleError(error: unknown): ServiceError {
    // ... tratamento de erro
  }
}

// infra/http/adapters/queries/transaction/HttpGetTransactionListAdapter.ts
@Injectable({ providedIn: 'root' })
export class HttpGetTransactionListAdapter implements IGetTransactionListPort {
  constructor(private httpClient: IHttpClient) {}

  async execute(request: GetTransactionListRequest): Promise<Either<ServiceError, TransactionListResponseDto>> {
    try {
      // DTOs fluem diretamente
      const queryParams = this.buildQueryString(request);
      const url = `/transaction/list?${queryParams}`;
      
      const response = await this.httpClient.get<TransactionListResponseDto>(url);
      
      return Either.success(response);
    } catch (error) {
      return Either.error(this.handleError(error));
    }
  }

  private buildQueryString(request: GetTransactionListRequest): string {
    const searchParams = new URLSearchParams();
    
    if (request.budgetId) {
      searchParams.set('budgetId', request.budgetId);
    }
    
    if (request.accountId) {
      searchParams.set('accountId', request.accountId);
    }
    
    if (request.limit) {
      searchParams.set('limit', request.limit.toString());
    }
    
    if (request.offset) {
      searchParams.set('offset', request.offset.toString());
    }
    
    if (request.startDate) {
      searchParams.set('startDate', request.startDate);
    }
    
    if (request.endDate) {
      searchParams.set('endDate', request.endDate);
    }
    
    if (request.categoryId) {
      searchParams.set('categoryId', request.categoryId);
    }
    
    return searchParams.toString();
  }

  private handleError(error: unknown): ServiceError {
    // ... tratamento de erro
  }
}
```

## DTO-First Integration

### DTOs como Contratos Diretos

Na DTO-First Architecture, os DTOs são os contratos diretos entre frontend e backend, eliminando a necessidade de mapeamentos complexos:

```typescript
// DTOs fluem diretamente entre as camadas
// Request DTOs → Backend API
// Response DTOs ← Backend API

// Exemplo: CreateTransactionRequestDto
export interface CreateTransactionRequestDto {
  readonly accountId: string;
  readonly budgetId: string;
  readonly amountInCents: number; // Money como number (centavos)
  readonly description: string;
  readonly type: "INCOME" | "EXPENSE"; // Enum como string literal
  readonly categoryId?: string;
  readonly date?: string; // ISO date string
}

// Exemplo: TransactionResponseDto
export interface TransactionResponseDto {
  readonly id: string;
  readonly accountId: string;
  readonly budgetId: string;
  readonly amountInCents: number;
  readonly description: string;
  readonly type: "INCOME" | "EXPENSE";
  readonly categoryId?: string;
  readonly date: string;
  readonly createdAt: string;
  readonly updatedAt: string;
}
```

### Transformações Leves (Quando Necessário)

Apenas quando formato da API difere do necessário para UI:

```typescript
// infra/mappers/DisplayMapper.ts
export class DisplayMapper {
  // Formatação para exibição (quando necessário)
  static toDisplayMoney(amountInCents: number): string {
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: 'BRL'
    }).format(amountInCents / 100);
  }
  
  static toDisplayDate(isoString: string): string {
    return new Date(isoString).toLocaleDateString('pt-BR');
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
- [DTO-First Principles](./dto-first-principles.md) - Princípios fundamentais da arquitetura
- [DTO Conventions](./dto-conventions.md) - Convenções para DTOs
- [Offline Strategy](./offline-strategy.md) - Integração offline com sync de comandos