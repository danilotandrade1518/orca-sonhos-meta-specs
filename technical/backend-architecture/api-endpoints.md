# Padrão de Endpoints para Mutations

## Motivação para Command-Style

Adotamos um modelo de domínio rico (DDD) com agregados, invariantes e regras explícitas em Use Cases. A tentativa de expressar estas operações via REST puro (verbs + resources canônicos) resultaria em:

- **Ambiguidade** de verbos HTTP para operações específicas (`mark-transaction-late`, `cancel-scheduled-transaction`, `transfer-between-envelopes`)
- **Sobrecarga semântica** de múltiplos endpoints PATCH/PUT semanticamente distintos sobre o mesmo recurso
- **Risco de anemic domain** ao tentar forçar operações complexas dentro de CRUD genérico

Para preservar a clareza de intenção e alinhar com o modelo Command (próximo de CQRS), adotamos um estilo orientado a comandos para mutações.

## Padrão Definido

### Regras Fundamentais
- **Todos os endpoints de mutação usam HTTP POST**
- **Formato da rota**: `/<aggregate|context>/<action-name>`
- **O nome da ação** reflete diretamente o caso de uso (classe do UseCase) com kebab-case
- **Request Body** segue o DTO do Use Case
- **Response** segue o `UseCaseResponse` encapsulado pelo `DefaultResponseBuilder`

### Exemplos de Endpoints
```
POST /budget/create-budget
POST /transaction/mark-transaction-late
POST /transaction/cancel-scheduled-transaction
POST /credit-card-bill/pay-credit-card-bill
POST /envelope/transfer-between-envelopes
POST /account/transfer-between-accounts
POST /goal/add-amount-to-goal
POST /goal/remove-amount-from-goal
```

## Implementação

### Controller Structure
```typescript
@Controller('/transaction')
export class TransactionController {
  constructor(
    private readonly createTransactionUseCase: CreateTransactionUseCase,
    private readonly markTransactionLateUseCase: MarkTransactionLateUseCase,
    private readonly cancelScheduledTransactionUseCase: CancelScheduledTransactionUseCase,
    private readonly defaultResponseBuilder: DefaultResponseBuilder,
  ) {}

  @Post('/create-transaction')
  async createTransaction(
    @Body() body: CreateTransactionRequest,
    @Headers('authorization') authHeader: string,
  ): Promise<DefaultResponse<void>> {
    const userId = await this.extractUserIdFromToken(authHeader);
    const dto = this.mapToUseCaseDto(body);
    
    const result = await this.createTransactionUseCase.execute(dto, userId);
    
    return this.defaultResponseBuilder.build(result);
  }

  @Post('/mark-transaction-late')
  async markTransactionLate(
    @Body() body: MarkTransactionLateRequest,
    @Headers('authorization') authHeader: string,
  ): Promise<DefaultResponse<void>> {
    const userId = await this.extractUserIdFromToken(authHeader);
    const dto = this.mapToMarkLateDto(body);
    
    const result = await this.markTransactionLateUseCase.execute(dto, userId);
    
    return this.defaultResponseBuilder.build(result);
  }

  @Post('/cancel-scheduled-transaction')
  async cancelScheduledTransaction(
    @Body() body: CancelScheduledTransactionRequest,
    @Headers('authorization') authHeader: string,
  ): Promise<DefaultResponse<void>> {
    const userId = await this.extractUserIdFromToken(authHeader);
    const dto = this.mapToCancelDto(body);
    
    const result = await this.cancelScheduledTransactionUseCase.execute(dto, userId);
    
    return this.defaultResponseBuilder.build(result);
  }
}
```

### Request/Response DTOs
```typescript
// Request DTOs (HTTP layer)
export interface CreateTransactionRequest {
  accountId: string;
  categoryId: string;
  amount: number;
  description: string;
  transactionDate: string; // ISO date string
  type: 'INCOME' | 'EXPENSE';
}

export interface MarkTransactionLateRequest {
  transactionId: string;
  budgetId: string;
  reason?: string;
}

// Use Case DTOs (Application layer)
export interface CreateTransactionDto {
  accountId: string;
  categoryId: string;
  budgetId: string;
  amount: number;
  description: string;
  transactionDate: Date;
  type: TransactionTypeEnum;
}

export interface MarkTransactionLateDto {
  transactionId: string;
  budgetId: string;
  reason?: string;
}
```

### DefaultResponseBuilder
```typescript
export interface DefaultResponse<T> {
  success: boolean;
  data?: T;
  errors?: ErrorDetail[];
  timestamp: string;
}

export interface ErrorDetail {
  code: string;
  message: string;
  field?: string;
}

export class DefaultResponseBuilder {
  build<T>(result: Either<ApplicationError, T>): DefaultResponse<T> {
    if (result.hasError) {
      return {
        success: false,
        errors: result.errors.map(error => ({
          code: error.code,
          message: error.message,
          field: this.extractFieldFromError(error),
        })),
        timestamp: new Date().toISOString(),
      };
    }

    return {
      success: true,
      data: result.data!,
      timestamp: new Date().toISOString(),
    };
  }

  private extractFieldFromError(error: ApplicationError): string | undefined {
    // Lógica para extrair campo relacionado ao erro
    if (error.message.includes('accountId')) return 'accountId';
    if (error.message.includes('amount')) return 'amount';
    return undefined;
  }
}
```

## Convenções de Nomenclatura

### Padrões de Action Names
- **CRUD direto**: `create-`, `update-`, `delete-`
  - `create-transaction`
  - `update-account` 
  - `delete-category`

- **Verbos de negócio específicos**: Use o verbo que expressa a operação de domínio
  - `mark-transaction-late`
  - `pay-credit-card-bill`
  - `reopen-credit-card-bill`
  - `transfer-between-accounts`
  - `add-amount-to-goal`
  - `remove-amount-from-goal`

- **Convenções gerais**:
  - Sempre **kebab-case**
  - Evitar abreviações obscuras
  - Preferir verbos claros e específicos
  - Incluir contexto quando necessário (`transfer-between-accounts` vs apenas `transfer`)

## Tratamento de Autorização

### Authorization no Use Case
```typescript
export class CreateTransactionUseCase {
  constructor(
    private authService: IBudgetAuthorizationService,
    // ... outros dependencies
  ) {}

  async execute(dto: CreateTransactionDto, userId: string): Promise<Either<ApplicationError, void>> {
    // 1. Autorização aplicada no Use Case
    const canAccess = await this.authService.canUserAccessBudget(
      userId, 
      dto.budgetId
    );
    if (!canAccess) {
      return Either.error(new UnauthorizedError('Cannot access this budget'));
    }

    // 2. Prosseguir com a operação...
    const result = await this.performOperation(dto);
    return result;
  }
}
```

### Middleware de Autenticação
```typescript
@Middleware()
export class AuthenticationMiddleware {
  async use(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const authHeader = req.headers.authorization;
      if (!authHeader?.startsWith('Bearer ')) {
        throw new UnauthorizedError('Missing or invalid authorization header');
      }

      const token = authHeader.substring(7);
      const userId = await this.firebaseAuthService.verifyToken(token);
      
      // Adiciona userId ao request para uso no controller
      (req as any).userId = userId;
      
      next();
    } catch (error) {
      res.status(401).json({
        success: false,
        errors: [{
          code: 'AUTH_INVALID',
          message: 'Invalid or expired token'
        }],
        timestamp: new Date().toISOString()
      });
    }
  }
}
```

## Idempotência

### Operações Naturalmente Idempotentes
```typescript
// Exemplo: Marcar transação como atrasada
@Post('/mark-transaction-late')
async markTransactionLate(@Body() body: MarkTransactionLateRequest) {
  // Se a transação já está marcada como atrasada, a operação não faz nada
  // A lógica de domínio na entidade garante a idempotência
  const result = await this.markTransactionLateUseCase.execute(dto, userId);
  return this.defaultResponseBuilder.build(result);
}
```

### Operações Não-Idempotentes
```typescript
// Para comandos não idempotentes (futuramente)
@Post('/pay-credit-card-bill')
async payCreditCardBill(
  @Body() body: PayCreditCardBillRequest,
  @Headers('idempotency-key') idempotencyKey?: string
) {
  if (idempotencyKey) {
    // Verificar se operação já foi executada com esta chave
    const existingResult = await this.idempotencyService.getResult(idempotencyKey);
    if (existingResult) {
      return existingResult;
    }
  }
  
  const result = await this.payCreditCardBillUseCase.execute(dto, userId);
  
  if (idempotencyKey && !result.hasError) {
    // Armazenar resultado para futuras chamadas
    await this.idempotencyService.storeResult(idempotencyKey, result);
  }
  
  return this.defaultResponseBuilder.build(result);
}
```

## Validação de Entrada

### DTOs com Validação
```typescript
import { IsString, IsNumber, IsPositive, IsEnum, IsDateString, IsUUID } from 'class-validator';

export class CreateTransactionRequest {
  @IsUUID()
  accountId: string;

  @IsUUID()
  categoryId: string;

  @IsNumber()
  @IsPositive()
  amount: number;

  @IsString()
  description: string;

  @IsDateString()
  transactionDate: string;

  @IsEnum(['INCOME', 'EXPENSE'])
  type: 'INCOME' | 'EXPENSE';
}
```

### Middleware de Validação
```typescript
@UsePipes(new ValidationPipe({ 
  whitelist: true, 
  forbidNonWhitelisted: true,
  transform: true 
}))
@Post('/create-transaction')
async createTransaction(@Body() body: CreateTransactionRequest) {
  // Body já foi validado pelo ValidationPipe
  // ...
}
```

## Benefícios da Abordagem

| Aspecto | Benefício |
|---------|-----------|
| **Clareza semântica** | Cada endpoint comunica explicitamente a intenção do caso de uso |
| **Evolução** | Facilita adicionar novas operações sem quebrar contratos REST genéricos |
| **Alinhamento DDD** | Mantém o ubiquitous language entre domínio e interface |
| **Simplicidade de Autorização** | Policies podem mapear 1:1 para ações |
| **Consistência de Erros** | `Either` + `DefaultResponseBuilder` padronizados |

## Trade-offs / Consequências

### Considerações
- **Menos aderente** a expectativas REST puras / ferramentas automáticas de geração
- **Documentação explícita** necessária (OpenAPI/Swagger adaptado)
- **Aumento potencial** de número de endpoints (mitigado por agrupamento por contexto)

### Mitigações
- OpenAPI documentation detalhada para cada endpoint
- Agrupamento lógico por agregado/contexto
- Padronização rigorosa de nomenclatura

## Versionamento (Futuro)

### Estratégia de Versionamento
- **Atual**: Sem prefixo de versão (considerado v1 implícito)
- **Futuro**: Prefixo `/v2/` quando necessário breaking changes
- **Evolução**: Criar novo action name OU novo namespace

```typescript
// Evolução sem breaking change
POST /transaction/create-transaction        // Atual
POST /transaction/create-transaction-v2     // Nova versão

// Ou namespace completo
POST /v2/transaction/create-transaction     // Nova versão major
```

---

**Ver também:**
- [Data Flow](./data-flow.md) - Como requests fluem pela arquitetura
- [Authentication](./authentication.md) - Fluxo de autenticação Firebase
- [Authorization](./authorization.md) - Controle de acesso por Budget