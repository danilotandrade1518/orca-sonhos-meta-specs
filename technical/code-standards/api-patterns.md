# API Patterns - Padrões de API e Endpoints

## 🌐 Padrões API e Endpoints

### Estilo de Endpoints (Command-Style)

```typescript
// ✅ Mutações: POST orientado a comandos (obrigatório)
POST /budget/create-budget
POST /transaction/create-transaction
POST /transaction/mark-transaction-late  
POST /credit-card-bill/pay-credit-card-bill
POST /envelope/update-envelope-limit
POST /account/transfer-between-accounts

// ✅ Consultas: GET com recursos RESTful
GET /budget/{budgetId}
GET /transaction/{transactionId}
GET /budget/{budgetId}/transactions
GET /budget/{budgetId}/accounts
GET /credit-card/{cardId}/bills
GET /user/{userId}/budgets

// ❌ Evitar verbos em recursos GET
// GET /budget/get-budget/{id}
// GET /transaction/find-by-budget/{budgetId}

// ❌ Evitar PUT/PATCH para operações de negócio
// PUT /transaction/{id}/status
// PATCH /transaction/{id}
```

### Controllers Alinhados com Commands

```typescript
// ✅ Controllers seguem padrão command-style
@Controller('/transaction')
export class TransactionController {
  constructor(
    private readonly createUseCase: CreateTransactionUseCase,
    private readonly markLateUseCase: MarkTransactionLateUseCase,
    private readonly getByIdUseCase: GetTransactionByIdUseCase,
    private readonly findByBudgetUseCase: FindTransactionsByBudgetUseCase
  ) {}
  
  @Post('/create-transaction')
  @ApiOperation({ summary: 'Create a new transaction' })
  @ApiResponse({ status: 201, description: 'Transaction created successfully' })
  async createTransaction(
    @Body() dto: CreateTransactionDto,
    @GetUser() userId: string
  ): Promise<ApiResponse<{ transactionId: string }>> {
    const result = await this.createUseCase.execute(dto, userId);
    
    return result.fold(
      error => this.handleError(error),
      transactionId => this.success({ transactionId: transactionId.value })
    );
  }
  
  @Post('/mark-transaction-late')
  @ApiOperation({ summary: 'Mark a transaction as late' })
  async markTransactionLate(
    @Body() dto: MarkTransactionLateDto,
    @GetUser() userId: string
  ): Promise<ApiResponse<void>> {
    const transactionId = new TransactionId(dto.transactionId);
    const result = await this.markLateUseCase.execute(transactionId, userId);
    
    return result.fold(
      error => this.handleError(error),
      () => this.success(void 0)
    );
  }
  
  @Get('/:id')
  @ApiOperation({ summary: 'Get transaction by ID' })
  async getTransaction(
    @Param('id') id: string,
    @GetUser() userId: string
  ): Promise<ApiResponse<TransactionDto>> {
    const transactionId = new TransactionId(id);
    const result = await this.getByIdUseCase.execute(transactionId, userId);
    
    return result.fold(
      error => this.handleError(error),
      transaction => this.success(this.mapToDto(transaction))
    );
  }
  
  @Get('/budget/:budgetId')
  @ApiOperation({ summary: 'Find transactions by budget' })
  async findByBudget(
    @Param('budgetId') budgetId: string,
    @Query() criteria: FindTransactionsCriteriaDto,
    @GetUser() userId: string
  ): Promise<ApiResponse<TransactionDto[]>> {
    const result = await this.findByBudgetUseCase.execute(
      new BudgetId(budgetId),
      this.mapToCriteria(criteria),
      userId
    );
    
    return result.fold(
      error => this.handleError(error),
      transactions => this.success(transactions.map(t => this.mapToDto(t)))
    );
  }
  
  private handleError(error: ApplicationError): ApiResponse<never> {
    switch (error.constructor) {
      case UnauthorizedError:
        throw new UnauthorizedException(error.message);
      case NotFoundError:
        throw new NotFoundException(error.message);
      case ValidationError:
      case DomainError:
        throw new BadRequestException(error.message);
      default:
        throw new InternalServerErrorException('Internal server error');
    }
  }
  
  private success<T>(data: T): ApiResponse<T> {
    return {
      success: true,
      data,
      timestamp: new Date().toISOString()
    };
  }
}
```

### DTOs e Validação

```typescript
// ✅ DTOs com validação robusta
export class CreateTransactionDto {
  @ApiProperty({ description: 'Transaction amount in cents', example: 1500 })
  @IsNumber()
  @Min(1)
  @Max(999999999) // Max 9.999.999,99
  amountCents: number;
  
  @ApiProperty({ description: 'Transaction description', example: 'Grocery shopping' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  @Transform(({ value }) => value?.trim())
  description: string;
  
  @ApiProperty({ description: 'Budget ID', example: 'budget-123' })
  @IsString()
  @IsUUID()
  budgetId: string;
  
  @ApiProperty({ description: 'Category ID', example: 'cat-456', required: false })
  @IsOptional()
  @IsString()
  @IsUUID()
  categoryId?: string;
  
  @ApiProperty({ description: 'Transaction date', example: '2024-12-15T10:30:00Z' })
  @IsOptional()
  @IsISO8601()
  @Transform(({ value }) => value ? new Date(value) : new Date())
  date?: Date;
}

export class MarkTransactionLateDto {
  @ApiProperty({ description: 'Transaction ID to mark as late' })
  @IsString()
  @IsUUID()
  transactionId: string;
  
  @ApiProperty({ description: 'Reason for marking late', required: false })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  reason?: string;
}

export class FindTransactionsCriteriaDto {
  @ApiProperty({ description: 'Page number', example: 1, required: false })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;
  
  @ApiProperty({ description: 'Page size', example: 25, required: false })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  pageSize?: number = 25;
  
  @ApiProperty({ description: 'Filter by status', required: false })
  @IsOptional()
  @IsEnum(TransactionStatus)
  status?: TransactionStatus;
  
  @ApiProperty({ description: 'Filter by category ID', required: false })
  @IsOptional()
  @IsString()
  @IsUUID()
  categoryId?: string;
  
  @ApiProperty({ description: 'Filter by date from', required: false })
  @IsOptional()
  @IsISO8601()
  @Transform(({ value }) => value ? new Date(value) : undefined)
  dateFrom?: Date;
  
  @ApiProperty({ description: 'Filter by date to', required: false })
  @IsOptional()
  @IsISO8601()
  @Transform(({ value }) => value ? new Date(value) : undefined)
  dateTo?: Date;
  
  @ApiProperty({ description: 'Search in description', required: false })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  search?: string;
}
```

### Response Patterns

```typescript
// ✅ Response wrapper padronizado
export interface ApiResponse<T> {
  success: boolean;
  data: T;
  timestamp: string;
  errors?: ApiError[];
}

export interface ApiError {
  code: string;
  message: string;
  field?: string;
  details?: Record<string, any>;
}

// ✅ Success responses
export interface TransactionDto {
  id: string;
  amountCents: number;
  description: string;
  status: TransactionStatus;
  budgetId: string;
  categoryId?: string;
  date: string; // ISO 8601
  createdAt: string; // ISO 8601
  updatedAt: string; // ISO 8601
}

export interface PaginatedResponse<T> {
  items: T[];
  pagination: {
    page: number;
    pageSize: number;
    totalItems: number;
    totalPages: number;
    hasNext: boolean;
    hasPrevious: boolean;
  };
}

// ✅ Error responses
export class ApiErrorBuilder {
  static validationError(details: ValidationError[]): ApiError {
    return {
      code: 'VALIDATION_ERROR',
      message: 'Request validation failed',
      details: details.reduce((acc, error) => ({
        ...acc,
        [error.property]: error.constraints
      }), {})
    };
  }
  
  static domainError(error: DomainError): ApiError {
    return {
      code: error.code,
      message: error.message,
      details: error.details
    };
  }
  
  static notFoundError(resource: string, id: string): ApiError {
    return {
      code: 'NOT_FOUND',
      message: `${resource} not found`,
      details: { id }
    };
  }
  
  static unauthorizedError(): ApiError {
    return {
      code: 'UNAUTHORIZED',
      message: 'Access denied'
    };
  }
}
```

### OpenAPI Documentation

```typescript
// ✅ OpenAPI configuration completa
@ApiTags('Transactions')
@ApiSecurity('bearer')
@ApiBearerAuth()
@Controller('/transaction')
export class TransactionController {
  
  @Post('/create-transaction')
  @ApiOperation({ 
    summary: 'Create a new transaction',
    description: 'Creates a new transaction in the specified budget with proper authorization checks'
  })
  @ApiResponse({ 
    status: 201, 
    description: 'Transaction created successfully',
    type: TransactionDto,
    schema: {
      example: {
        success: true,
        data: {
          id: 'txn-123',
          amountCents: 1500,
          description: 'Grocery shopping',
          status: 'pending',
          budgetId: 'budget-456',
          categoryId: 'cat-789',
          date: '2024-12-15T10:30:00Z',
          createdAt: '2024-12-15T10:30:00Z',
          updatedAt: '2024-12-15T10:30:00Z'
        },
        timestamp: '2024-12-15T10:30:00Z'
      }
    }
  })
  @ApiResponse({ 
    status: 400, 
    description: 'Validation error or domain error',
    schema: {
      example: {
        success: false,
        errors: [{
          code: 'VALIDATION_ERROR',
          message: 'Request validation failed',
          details: {
            amountCents: ['must be a positive number'],
            description: ['should not be empty']
          }
        }],
        timestamp: '2024-12-15T10:30:00Z'
      }
    }
  })
  @ApiResponse({ 
    status: 401, 
    description: 'Unauthorized - invalid or missing token'
  })
  @ApiResponse({ 
    status: 403, 
    description: 'Forbidden - user cannot manage transactions in this budget'
  })
  async createTransaction(
    @Body() dto: CreateTransactionDto,
    @GetUser() userId: string
  ): Promise<ApiResponse<TransactionDto>> {
    // implementation
  }
}
```

### Error Handling Middleware

```typescript
// ✅ Global error handling
@Catch()
export class GlobalExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(GlobalExceptionFilter.name);
  
  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();
    
    const { status, error } = this.getErrorDetails(exception);
    
    const errorResponse: ApiResponse<never> = {
      success: false,
      errors: [error],
      timestamp: new Date().toISOString()
    };
    
    // Log error details
    this.logger.error(
      `${request.method} ${request.url} - ${status} - ${error.message}`,
      exception instanceof Error ? exception.stack : exception
    );
    
    response.status(status).json(errorResponse);
  }
  
  private getErrorDetails(exception: unknown): { status: number; error: ApiError } {
    if (exception instanceof HttpException) {
      return {
        status: exception.getStatus(),
        error: {
          code: this.getErrorCode(exception),
          message: exception.message
        }
      };
    }
    
    if (exception instanceof ApplicationError) {
      return {
        status: this.getStatusForApplicationError(exception),
        error: ApiErrorBuilder.domainError(exception)
      };
    }
    
    // Unknown error
    return {
      status: 500,
      error: {
        code: 'INTERNAL_SERVER_ERROR',
        message: 'An unexpected error occurred'
      }
    };
  }
  
  private getStatusForApplicationError(error: ApplicationError): number {
    switch (error.constructor) {
      case UnauthorizedError:
        return 401;
      case ForbiddenError:
        return 403;
      case NotFoundError:
        return 404;
      case ValidationError:
      case DomainError:
        return 400;
      case ConflictError:
        return 409;
      default:
        return 500;
    }
  }
}
```

### Rate Limiting e Security

```typescript
// ✅ Rate limiting por endpoint
@Controller('/transaction')
@UseGuards(ThrottlerGuard)
export class TransactionController {
  
  @Post('/create-transaction')
  @Throttle({ default: { limit: 10, ttl: 60000 } }) // 10 requests per minute
  async createTransaction(/* ... */): Promise<ApiResponse<TransactionDto>> {
    // implementation
  }
  
  @Post('/mark-transaction-late')
  @Throttle({ default: { limit: 20, ttl: 60000 } }) // 20 requests per minute
  async markTransactionLate(/* ... */): Promise<ApiResponse<void>> {
    // implementation
  }
  
  @Get('/:id')
  @Throttle({ default: { limit: 100, ttl: 60000 } }) // 100 requests per minute for reads
  async getTransaction(/* ... */): Promise<ApiResponse<TransactionDto>> {
    // implementation
  }
}

// ✅ Request validation middleware
@Injectable()
export class RequestValidationPipe implements PipeTransform {
  transform(value: any, metadata: ArgumentMetadata): any {
    if (metadata.type === 'body') {
      // Sanitize input
      value = this.sanitizeInput(value);
      
      // Additional business validation
      this.validateBusinessRules(value, metadata);
    }
    
    return value;
  }
  
  private sanitizeInput(input: any): any {
    if (typeof input === 'string') {
      return input.trim().replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '');
    }
    
    if (Array.isArray(input)) {
      return input.map(item => this.sanitizeInput(item));
    }
    
    if (input && typeof input === 'object') {
      const sanitized: any = {};
      for (const [key, value] of Object.entries(input)) {
        sanitized[key] = this.sanitizeInput(value);
      }
      return sanitized;
    }
    
    return input;
  }
}
```

### API Versioning

```typescript
// ✅ Versioning strategy
@Controller({ path: 'transaction', version: '1' })
@ApiTags('Transactions v1')
export class TransactionV1Controller {
  // V1 implementation
}

@Controller({ path: 'transaction', version: '2' })
@ApiTags('Transactions v2')
export class TransactionV2Controller {
  // V2 implementation with breaking changes
}

// ✅ Version configuration
const app = await NestFactory.create(AppModule);
app.enableVersioning({
  type: VersioningType.HEADER,
  header: 'X-API-Version',
  defaultVersion: '1'
});
```

---

**Padrões obrigatórios para APIs:**
- ✅ **Command-style** endpoints para mutações (POST)
- ✅ **RESTful** resources para consultas (GET)
- ✅ **Either pattern** nos controllers
- ✅ **DTO validation** robusta
- ✅ **OpenAPI documentation** completa
- ✅ **Error handling** padronizado
- ✅ **Rate limiting** configurado
- ✅ **Request sanitization** obrigatória

**Próximos tópicos:**
- **[Security Standards](./security-standards.md)** - Padrões de segurança
- **[Testing Standards](./testing-standards.md)** - Padrões de testes