# Convenções de Nomenclatura

## Regra Fundamental de Idioma

- **Todo código deve ser escrito em inglês**
- **Variáveis, métodos, classes**: Inglês
- **Mensagens de erro, logs**: Inglês  
- **Comentários (se necessário)**: Inglês
- **Documentação técnica**: Português (como esta)

```typescript
// ✅ CORRETO - Inglês
export class CreateTransactionUseCase {
  async execute(dto: CreateTransactionDto): Promise<Either<ApplicationError, void>> {
    const validationResult = this.validateInput(dto);
    if (validationResult.hasError) {
      return Either.error(new ApplicationError('Invalid transaction data'));
    }
    // ...
  }
}

// ❌ EVITAR - Português
export class CriarTransacaoUseCase {
  async executar(dto: CriarTransacaoDto): Promise<Either<ErroAplicacao, void>> {
    const resultadoValidacao = this.validarEntrada(dto);
    // ...
  }
}
```

## Padrões de Classes

### Models e Application Layer (PascalCase)

```typescript
// ✅ Domain Models
export class Transaction { }
export class Money { }
export class Budget { }
export class Account { }

// ✅ Use Cases
export class CreateTransactionUseCase { }
export class UpdateBudgetUseCase { }
export class TransferBetweenAccountsUseCase { }

// ✅ Query Handlers  
export class GetBudgetSummaryQueryHandler { }
export class GetTransactionListQueryHandler { }

// ✅ Domain Services
export class BudgetLimitPolicy { }
export class TransferValidationService { }

// ✅ Value Objects
export class TransactionType { }
export class AccountType { }
export class Email { }
```

### Angular Components (kebab-case)

```typescript
// ✅ Pages
create-transaction.page.ts
budget-summary.page.ts
account-list.page.ts

// ✅ Components
transaction-card.component.ts
budget-overview.component.ts
money-input.component.ts

// ✅ UI Components (Design System)
os-button.component.ts
os-input.component.ts
os-modal.component.ts
```

## Padrões de Interfaces

### Prefixo `I` Obrigatório

```typescript
// ✅ Ports (Application Layer)
export interface IBudgetServicePort { }
export interface ITransactionServicePort { }
export interface IAccountServicePort { }

// ✅ Infrastructure Contracts
export interface IHttpClient { }
export interface ILocalStorePort { }
export interface IAuthTokenProvider { }

// ✅ Domain Contracts
export interface IEventBus { }
export interface IDomainEventHandler { }
```

### Sufixos Específicos para Clareza

```typescript
// ✅ Service Ports
IBudgetServicePort
ITransactionServicePort
IAccountServicePort

// ✅ Infrastructure Ports
ILocalStorePort
INetworkStatusPort
ICachePort

// ✅ Event Handlers
ITransactionCreatedHandler
IBudgetUpdatedHandler

// ✅ Repositories (se usados)
ITransactionRepositoryPort
IBudgetRepositoryPort
```

## Padrões de Arquivos

### Models e Application (PascalCase)

```typescript
// ✅ Use Cases
CreateTransactionUseCase.ts
UpdateBudgetUseCase.ts
GetBudgetSummaryQueryHandler.ts

// ✅ Domain Models
Transaction.ts
Budget.ts
Money.ts
TransactionType.ts

// ✅ Ports
IBudgetServicePort.ts
ITransactionServicePort.ts

// ✅ DTOs
CreateTransactionDto.ts
BudgetSummaryDto.ts
```

### Angular UI (kebab-case)

```typescript
// ✅ Components
transaction-list.component.ts
budget-card.component.ts
money-display.component.ts

// ✅ Pages
create-transaction.page.ts
budget-summary.page.ts
dashboard.page.ts

// ✅ Services Angular
auth-state.service.ts
notification.service.ts
```

### Infrastructure (PascalCase para classes, kebab-case para arquivos)

```typescript
// ✅ Adapters
HttpBudgetServiceAdapter.ts
FirebaseAuthAdapter.ts
IndexedDBAdapter.ts

// ✅ Mappers
TransactionApiMapper.ts
BudgetApiMapper.ts
MoneyMapper.ts
```

## Padrões de Pastas

### Todas em kebab-case

```
/use-cases
/query-handlers  
/domain-services
/value-objects
/ui-components
/backend-architecture
/auth-services
```

### Organização por Contexto

```
/features
  /budgets
  /transactions
  /accounts
  /credit-cards
  /goals
  
/shared
  /ui-components
  /theme
  /guards
  /pipes
```

## Padrões de Métodos

### camelCase para Todos os Métodos

```typescript
// ✅ Use Cases e Services
execute()
handle()
create()
update()
delete()
validate()

// ✅ Domain Models
debit()
credit() 
canTransfer()
addParticipant()
calculateBalance()

// ✅ Query Methods
getById()
getByBudget()
getSummary()
findByPeriod()
```

### Prefixos Verbais Específicos

```typescript
// ✅ Factories
create() - Para factory methods
build() - Para builders
from() - Para conversões (Money.fromCents())

// ✅ Validações  
can() - Para políticas (canTransfer(), canDelete())
is() - Para predicados (isValid(), isEmpty())
has() - Para verificações (hasBalance(), hasPermission())

// ✅ Conversões
to() - Para mapeamento (toDto(), toApiFormat())
from() - Para parsing (fromDto(), fromApiResponse())
```

## Web Components (Design System)

### Prefixo `os-` (OrçaSonhos)

```html
<!-- ✅ Atoms -->
<os-button variant="primary">Click</os-button>
<os-input label="Nome" placeholder="Digite..." />
<os-icon name="plus" />
<os-badge variant="success">Active</os-badge>

<!-- ✅ Molecules -->
<os-form-field label="Valor" error="Required">
  <os-money-input slot="input" />
</os-form-field>

<os-card title="Orçamento">
  <os-card-content>Content</os-card-content>
</os-card>

<!-- ✅ Organisms -->
<os-data-table [data]="transactions" [columns]="columns" />
<os-modal [isOpen]="showModal">Modal content</os-modal>
```

### Eventos com Prefixo `os`

```typescript
// ✅ Event Outputs
@Output() osClick = new EventEmitter<MouseEvent>();
@Output() osChange = new EventEmitter<string>();
@Output() osSubmit = new EventEmitter<FormData>();
@Output() osSelect = new EventEmitter<Option>();

// ✅ Uso em templates
<os-button (osClick)="handleClick()">Button</os-button>
<os-input (osChange)="handleChange($event)" />
```

### CSS Classes

```scss
// ✅ Componentes
.os-button { }
.os-button--primary { }
.os-button--loading { }

.os-input { }
.os-input--error { }
.os-input--disabled { }

// ✅ Estados
.os-card--elevated { }
.os-modal--fullscreen { }
.os-table--striped { }
```

## Padrões de Variantes

### Variantes Semânticas

```typescript
// ✅ Button variants
type ButtonVariant = 'primary' | 'secondary' | 'tertiary' | 'danger';

// ✅ Alert variants  
type AlertVariant = 'success' | 'warning' | 'error' | 'info';

// ✅ Badge variants
type BadgeVariant = 'success' | 'warning' | 'danger' | 'neutral';

// ✅ Size variants
type Size = 'small' | 'medium' | 'large';
```

### Evitar Nomes Técnicos do Material

```typescript
// ✅ USAR - Semântica própria
variant: 'primary' | 'secondary' | 'danger'
size: 'small' | 'medium' | 'large'  
appearance: 'filled' | 'outlined'

// ❌ EVITAR - Nomenclatura do Material
color: 'mat-primary' | 'mat-accent'
density: 'mat-dense' | 'mat-compact'
```

## Padrões de Props/Inputs

### Modern Angular (Functions)

```typescript
// ✅ Usar input()/output() functions
export class OsButtonComponent {
  variant = input<ButtonVariant>('primary');
  disabled = input(false);  
  loading = input(false);
  
  onClick = output<MouseEvent>();
  
  // ❌ Evitar decorators
  // @Input() variant: ButtonVariant = 'primary';
  // @Output() onClick = new EventEmitter<MouseEvent>();
}
```

### Required vs Optional

```typescript
// ✅ Required inputs
label = input.required<string>();
data = input.required<Transaction[]>();

// ✅ Optional com default
variant = input<ButtonVariant>('primary');
disabled = input(false);
size = input<Size>('medium');

// ✅ Optional sem default  
icon = input<string>();
tooltip = input<string>();
```

## Padrões de Testes

### Arquivos de Teste

```typescript
// ✅ Unit tests (mesmo diretório)  
CreateTransactionUseCase.spec.ts
Transaction.spec.ts
Money.spec.ts

// ✅ Integration tests
HttpBudgetServiceAdapter.integration.spec.ts
IndexedDBAdapter.integration.spec.ts

// ✅ Component tests
os-button.component.spec.ts
transaction-card.component.spec.ts
```

### Estrutura de Describe/It

```typescript
// ✅ Padrão BDD style
describe('CreateTransactionUseCase', () => {
  describe('when creating a valid transaction', () => {
    it('should create transaction successfully', async () => {
      // Arrange
      const dto = createValidTransactionDto();
      
      // Act  
      const result = await useCase.execute(dto);
      
      // Assert
      expect(result.hasError).toBe(false);
    });
  });

  describe('when validation fails', () => {
    it('should return validation error for empty description', async () => {
      // Test error scenarios
    });
  });

  describe('when repository fails', () => {
    it('should handle repository errors gracefully', async () => {
      // Test failure scenarios  
    });
  });
});
```

## Path Aliases e Imports

### Configuração tsconfig.json

```json
{
  "compilerOptions": {
    "baseUrl": "./src",
    "paths": {
      "@models/*": ["models/*"],
      "@application/*": ["application/*"], 
      "@infra/*": ["infra/*"],
      "@app/*": ["app/*"],
      "@shared/*": ["app/shared/*"],
      "@mocks/*": ["mocks/*"],
      "@environments/*": ["environments/*"]
    }
  }
}
```

### Regras de Import

#### Entre Camadas Diferentes (Path Aliases)
```typescript
// ✅ Application importando Domain
import { Transaction } from '@models/entities/Transaction';
import { Money } from '@models/value-objects/Money';

// ✅ Infra implementando Application
import { IBudgetServicePort } from '@application/ports/IBudgetServicePort';
import { CreateBudgetDto } from '@application/dtos/CreateBudgetDto';

// ✅ UI consumindo Application  
import { CreateBudgetUseCase } from '@application/use-cases/CreateBudgetUseCase';
```

#### Mesma Camada (Imports Relativos)
```typescript
// ✅ Dentro de use-cases
import { CreateBudgetDto } from '../dtos/CreateBudgetDto';
import { BudgetValidator } from './validators/BudgetValidator';

// ✅ Dentro de components
import { BudgetCardComponent } from './budget-card.component';
import { BudgetService } from '../services/budget.service';
```

## Git e Versionamento

### Commit Messages

```
feat: add CreateTransactionUseCase with validation
fix: handle insufficient balance error in Account domain model
refactor: extract HTTP error handling to dedicated service  
docs: update frontend architecture documentation
test: add integration tests for HttpBudgetServiceAdapter
style: apply consistent naming conventions to UI components
```

### Branch Naming

```
feature/create-transaction-use-case
feature/budget-summary-page
bugfix/money-input-validation
refactor/http-client-error-handling
docs/frontend-architecture-update
```

---

**Ver também:**
- [Directory Structure](./directory-structure.md) - Como organizar arquivos fisicamente
- [Layer Responsibilities](./layer-responsibilities.md) - Responsabilidades por camada  
- [UI System](./ui-system.md) - Convenções específicas do Design System