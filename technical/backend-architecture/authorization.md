# Autorização e Multi-tenancy

## Modelo de Autorização Simplificado

Para o MVP, adotamos um modelo de autorização **flat** por orçamento, priorizando simplicidade e rapidez de implementação sobre granularidade de permissões.

### Características do Modelo
- **Participantes**: Lista de User IDs no agregado Budget
- **Permissões**: Todos os participantes têm **acesso total** ao orçamento
- **Operações**: Qualquer participante pode realizar qualquer ação dentro do orçamento
- **Isolamento**: Dados de um Budget não são visíveis em outros Budgets

## Multi-tenancy por Budget

### Conceito
- **Usuário pode participar** de múltiplos Budgets
- **Isolamento total**: Dados de um Budget não são visíveis em outro
- **Controle de acesso**: `Budget.participants` define quem tem acesso
- **Validação obrigatória**: Todo Use Case valida se `userId` está em `Budget.participants`

### Estrutura do Budget
```typescript
export class Budget {
  private constructor(
    private readonly _id: string,
    private _name: string,
    private _participants: string[], // User IDs autorizados
    private _settings: BudgetSettings,
    private readonly _createdAt: Date,
  ) {}

  public hasParticipant(userId: string): boolean {
    return this._participants.includes(userId);
  }

  public addParticipant(userId: string): void {
    if (!this.hasParticipant(userId)) {
      this._participants.push(userId);
    }
  }

  public removeParticipant(userId: string): void {
    this._participants = this._participants.filter(id => id !== userId);
  }

  get participants(): readonly string[] {
    return this._participants;
  }
}
```

## Implementação da Autorização

### Interface do Serviço
```typescript
export interface IBudgetAuthorizationService {
  canUserAccessBudget(userId: string, budgetId: string): Promise<Either<AuthorizationError, boolean>>;
  getUserBudgets(userId: string): Promise<Either<AuthorizationError, BudgetSummary[]>>;
}
```

### Implementação Concreta
```typescript
export class BudgetAuthorizationService implements IBudgetAuthorizationService {
  constructor(
    private getBudgetRepository: IGetBudgetRepository
  ) {}

  async canUserAccessBudget(
    userId: string, 
    budgetId: string
  ): Promise<Either<AuthorizationError, boolean>> {
    try {
      const budgetResult = await this.getBudgetRepository.execute(budgetId);
      
      if (budgetResult.hasError) {
        return Either.error(
          new AuthorizationError('Budget not found', userId, budgetId)
        );
      }

      const budget = budgetResult.data!;
      const canAccess = budget.hasParticipant(userId);

      if (!canAccess) {
        return Either.error(
          new ForbiddenError(`Budget ${budgetId}`, userId)
        );
      }

      return Either.success(true);
    } catch (error) {
      return Either.error(
        new AuthorizationError('Failed to verify budget access', userId, budgetId)
      );
    }
  }

  async getUserBudgets(userId: string): Promise<Either<AuthorizationError, BudgetSummary[]>> {
    try {
      // Busca todos os budgets onde o usuário é participante
      const budgets = await this.findBudgetRepository.findByParticipant(userId);
      
      if (budgets.hasError) {
        return Either.error(
          new AuthorizationError('Failed to fetch user budgets', userId)
        );
      }

      const summaries = budgets.data!.map(budget => ({
        id: budget.id,
        name: budget.name,
        participantCount: budget.participants.length,
        isOwner: budget.participants[0] === userId, // Primeiro participante é owner
        createdAt: budget.createdAt,
      }));

      return Either.success(summaries);
    } catch (error) {
      return Either.error(
        new AuthorizationError('Failed to get user budgets', userId)
      );
    }
  }
}
```

## Uso em Use Cases

### Padrão Obrigatório de Validação
```typescript
export class CreateTransactionUseCase {
  constructor(
    private authService: IBudgetAuthorizationService,
    private addTransactionRepository: IAddTransactionRepository,
  ) {}

  async execute(dto: CreateTransactionDto, userId: string): Promise<Either<ApplicationError, void>> {
    // 1. VALIDAÇÃO OBRIGATÓRIA - Todo Use Case deve fazer isso
    const authResult = await this.authService.canUserAccessBudget(
      userId, 
      dto.budgetId
    );
    
    if (authResult.hasError) {
      return Either.error(
        new ApplicationError(authResult.errors[0].message, 'AUTHORIZATION_FAILED')
      );
    }

    // 2. Prosseguir com a operação de negócio
    const transaction = Transaction.create(dto);
    const result = await this.addTransactionRepository.execute(transaction);
    
    return result;
  }
}
```

### Validação em Queries
```typescript
export class GetBudgetSummaryQueryHandler {
  constructor(
    private authService: IBudgetAuthorizationService,
    private budgetSummaryDao: IBudgetSummaryDao,
  ) {}

  async handle(query: GetBudgetSummaryQuery, userId: string): Promise<Either<QueryError, BudgetSummaryDto>> {
    // Validação também obrigatória em queries sensíveis
    const authResult = await this.authService.canUserAccessBudget(
      userId, 
      query.budgetId
    );
    
    if (authResult.hasError) {
      return Either.error(
        new QueryError('Not authorized to access this budget')
      );
    }

    try {
      const summary = await this.budgetSummaryDao.getBudgetSummary(
        query.budgetId,
        query.period
      );
      
      return Either.success(summary);
    } catch (error) {
      return Either.error(new QueryError('Failed to get budget summary', error));
    }
  }
}
```

## Middleware de Autorização (Opcional)

### Authorization Decorator
```typescript
// budget-auth.decorator.ts
export const RequireBudgetAccess = () => {
  return (target: any, propertyName: string, descriptor: PropertyDescriptor) => {
    const method = descriptor.value;
    
    descriptor.value = async function (...args: any[]) {
      const req = args.find(arg => arg && arg.userId); // Request object
      const body = args.find(arg => arg && arg.budgetId); // DTO with budgetId
      
      if (!req?.userId || !body?.budgetId) {
        throw new UnauthorizedError('Missing user or budget information');
      }
      
      const authService = this.authService as IBudgetAuthorizationService;
      const authResult = await authService.canUserAccessBudget(
        req.userId,
        body.budgetId
      );
      
      if (authResult.hasError) {
        throw new ForbiddenError(`Budget ${body.budgetId}`, req.userId);
      }
      
      return method.apply(this, args);
    };
  };
};

// Uso no controller
@Controller('/transaction')
export class TransactionController {
  @Post('/create-transaction')
  @RequireBudgetAccess()
  async createTransaction(
    @Body() body: CreateTransactionRequest,
    @Req() req: Request
  ): Promise<DefaultResponse<void>> {
    // Autorização já foi validada pelo decorator
    const dto = this.mapToDto(body);
    const result = await this.createTransactionUseCase.execute(dto, req.userId);
    return this.defaultResponseBuilder.build(result);
  }
}
```

## Performance e Cache

### Cache de Autorização
```typescript
export class CachedBudgetAuthorizationService implements IBudgetAuthorizationService {
  private cache = new Map<string, { canAccess: boolean; expiresAt: number }>();
  private readonly CACHE_TTL = 5 * 60 * 1000; // 5 minutos

  constructor(
    private baseBudgetAuthService: IBudgetAuthorizationService
  ) {}

  async canUserAccessBudget(
    userId: string, 
    budgetId: string
  ): Promise<Either<AuthorizationError, boolean>> {
    const cacheKey = `${userId}:${budgetId}`;
    const cached = this.cache.get(cacheKey);
    
    if (cached && cached.expiresAt > Date.now()) {
      return Either.success(cached.canAccess);
    }

    const result = await this.baseBudgetAuthService.canUserAccessBudget(userId, budgetId);
    
    if (!result.hasError) {
      this.cache.set(cacheKey, {
        canAccess: result.data!,
        expiresAt: Date.now() + this.CACHE_TTL
      });
    }

    return result;
  }

  invalidateUserCache(userId: string): void {
    for (const [key] of this.cache) {
      if (key.startsWith(`${userId}:`)) {
        this.cache.delete(key);
      }
    }
  }
}
```

## Erros de Autorização

### Tipos Específicos
```typescript
export class AuthorizationError extends BaseError {
  constructor(
    message: string,
    public readonly userId?: string,
    public readonly resourceId?: string
  ) {
    super(message, 'AUTHORIZATION_ERROR');
  }
}

export class UnauthorizedError extends AuthorizationError {
  constructor(operation?: string) {
    super(`Unauthorized${operation ? ` to ${operation}` : ''}`, 'UNAUTHORIZED');
  }
}

export class ForbiddenError extends AuthorizationError {
  constructor(resource: string, userId?: string) {
    super(`Access forbidden to ${resource}`, 'FORBIDDEN', userId, resource);
  }
}

export class BudgetNotFoundError extends AuthorizationError {
  constructor(budgetId: string, userId?: string) {
    super(`Budget ${budgetId} not found or access denied`, 'BUDGET_NOT_FOUND', userId, budgetId);
  }
}
```

### Tratamento no Controller
```typescript
@Controller()
export class BaseController {
  protected handleAuthError(error: AuthorizationError): DefaultResponse<never> {
    const errorMappings = {
      'UNAUTHORIZED': { status: 401, message: 'Authentication required' },
      'FORBIDDEN': { status: 403, message: 'Access denied to this resource' },
      'BUDGET_NOT_FOUND': { status: 404, message: 'Budget not found' },
      'AUTHORIZATION_ERROR': { status: 500, message: 'Authorization service error' },
    };

    const mapping = errorMappings[error.code] || errorMappings['AUTHORIZATION_ERROR'];

    return {
      success: false,
      errors: [{
        code: error.code,
        message: mapping.message,
        details: error.message
      }],
      timestamp: new Date().toISOString()
    };
  }
}
```

## Gestão de Participantes

### Use Cases de Gestão
```typescript
export class InviteUserToBudgetUseCase {
  constructor(
    private authService: IBudgetAuthorizationService,
    private getBudgetRepository: IGetBudgetRepository,
    private saveBudgetRepository: ISaveBudgetRepository,
  ) {}

  async execute(dto: InviteUserDto, requestingUserId: string): Promise<Either<ApplicationError, void>> {
    // Validar se usuário pode convidar (é participante do budget)
    const authResult = await this.authService.canUserAccessBudget(
      requestingUserId,
      dto.budgetId
    );
    
    if (authResult.hasError) {
      return Either.error(new ApplicationError('Cannot invite to this budget'));
    }

    // Buscar budget e adicionar participante
    const budgetResult = await this.getBudgetRepository.execute(dto.budgetId);
    if (budgetResult.hasError) {
      return Either.error(new ApplicationError('Budget not found'));
    }

    const budget = budgetResult.data!;
    budget.addParticipant(dto.invitedUserId);

    const saveResult = await this.saveBudgetRepository.execute(budget);
    return saveResult;
  }
}

export class RemoveUserFromBudgetUseCase {
  // Implementação similar para remoção
}
```

## Evolução Futura

### Modelo Atual Permite Evolução Para:

**Roles Diferenciados**
```typescript
enum BudgetRole {
  OWNER = 'OWNER',
  ADMIN = 'ADMIN', 
  MEMBER = 'MEMBER',
  VIEWER = 'VIEWER'
}

interface BudgetParticipant {
  userId: string;
  role: BudgetRole;
  addedAt: Date;
  addedBy: string;
}
```

**Permissões Granulares**
```typescript
interface BudgetPermissions {
  canCreateTransaction: boolean;
  canDeleteTransaction: boolean;
  canManageCategories: boolean;
  canInviteUsers: boolean;
  canManageBudget: boolean;
}

const ROLE_PERMISSIONS: Record<BudgetRole, BudgetPermissions> = {
  [BudgetRole.OWNER]: { /* todas as permissões */ },
  [BudgetRole.MEMBER]: { /* permissões limitadas */ },
  // etc.
};
```

**Convites e Aprovações**
```typescript
interface BudgetInvitation {
  id: string;
  budgetId: string;
  invitedEmail: string;
  invitedBy: string;
  role: BudgetRole;
  status: 'PENDING' | 'ACCEPTED' | 'REJECTED' | 'EXPIRED';
  createdAt: Date;
  expiresAt: Date;
}
```

## Testes

### Cenários de Teste Obrigatórios
```typescript
describe('BudgetAuthorizationService', () => {
  it('should allow access when user is participant', async () => {
    // Arrange
    const budget = Budget.create({ participants: [userId] });
    mockGetBudgetRepository.execute.mockResolvedValue(Either.success(budget));

    // Act
    const result = await authService.canUserAccessBudget(userId, budgetId);

    // Assert
    expect(result.hasError).toBe(false);
    expect(result.data).toBe(true);
  });

  it('should deny access when user is not participant', async () => {
    // Arrange
    const budget = Budget.create({ participants: ['other-user'] });
    mockGetBudgetRepository.execute.mockResolvedValue(Either.success(budget));

    // Act
    const result = await authService.canUserAccessBudget(userId, budgetId);

    // Assert
    expect(result.hasError).toBe(true);
    expect(result.errors[0]).toBeInstanceOf(ForbiddenError);
  });

  it('should handle non-existent budget', async () => {
    // Test budget not found scenarios
  });
});
```

---

**Ver também:**
- [Authentication](./authentication.md) - Autenticação Firebase que precede autorização
- [Domain Model](./domain-model.md) - Estrutura do agregado Budget
- [Error Handling](./error-handling.md) - Tratamento de erros de autorização