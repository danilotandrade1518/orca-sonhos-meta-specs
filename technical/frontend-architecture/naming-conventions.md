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

### DTOs e Application Layer (PascalCase)

```typescript
// ✅ DTOs (Data Transfer Objects)
export interface CreateTransactionRequestDto { }
export interface TransactionResponseDto { }
export interface BudgetListResponseDto { }
export interface Money { } // Shared type
export interface DateString { } // Shared type

// ✅ Commands (Application Layer)
export class CreateTransactionCommand { }
export class UpdateBudgetCommand { }
export class DeleteTransactionCommand { }

// ✅ Queries (Application Layer)
export class GetBudgetSummaryQuery { }
export class GetTransactionListQuery { }
export class GetBudgetByIdQuery { }

// ✅ Validators (Application Layer)
export class CreateTransactionValidator { }
export class UpdateBudgetValidator { }

// ✅ Transformers (Application Layer)
export class TransactionTransformer { }
export class BudgetTransformer { }
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
// ✅ Ports (Application Layer) - 1 interface por operação
export interface ICreateBudgetPort { }
export interface IUpdateBudgetPort { }
export interface IDeleteBudgetPort { }
export interface IGetBudgetByIdPort { }
export interface IGetBudgetListPort { }

// ✅ Infrastructure Contracts
export interface IHttpClient { }
export interface ILocalStorePort { }
export interface IAuthTokenProvider { }

// ✅ Event Handlers (se necessário)
export interface ITransactionCreatedHandler { }
export interface IBudgetUpdatedHandler { }
```

### Sufixos Específicos para Clareza

```typescript
// ✅ Ports por Operação (Padrão Command)
ICreateBudgetPort
IUpdateBudgetPort
IDeleteBudgetPort
IGetBudgetByIdPort
IGetBudgetListPort
IGetBudgetSummaryPort

// ✅ Infrastructure Ports
ILocalStorePort
INetworkStatusPort
ICachePort

// ✅ Event Handlers
ITransactionCreatedHandler
IBudgetUpdatedHandler
```

## Padrões de Arquivos

### DTOs e Application (PascalCase)

```typescript
// ✅ DTOs (Data Transfer Objects)
CreateTransactionRequestDto.ts
TransactionResponseDto.ts
BudgetListResponseDto.ts
Money.ts
DateString.ts

// ✅ Commands (Application Layer)
CreateTransactionCommand.ts
UpdateBudgetCommand.ts
DeleteTransactionCommand.ts

// ✅ Queries (Application Layer)
GetBudgetSummaryQuery.ts
GetTransactionListQuery.ts
GetBudgetByIdQuery.ts

// ✅ Ports (1 interface por operação)
ICreateBudgetPort.ts
IUpdateBudgetPort.ts
IGetBudgetByIdPort.ts
IGetBudgetListPort.ts

// ✅ Validators
CreateTransactionValidator.ts
UpdateBudgetValidator.ts
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
// ✅ HTTP Adapters (1 adapter por port)
HttpCreateBudgetAdapter.ts
HttpUpdateBudgetAdapter.ts
HttpGetBudgetByIdAdapter.ts
HttpGetBudgetListAdapter.ts
HttpCreateTransactionAdapter.ts

// ✅ Storage Adapters
LocalStoreAdapter.ts
IndexedDBAdapter.ts
FirebaseAuthAdapter.ts

// ✅ Mappers (apenas quando necessário)
DisplayMapper.ts
DateFormatter.ts
MoneyFormatter.ts
```

## Padrões de Pastas

### Todas em kebab-case

```
/dtos
/commands
/queries
/validators
/transformers
/ports
/ui-components
/auth-services
```

### Organização por Contexto

```
/dtos
  /budget
    /request
    /response
  /transaction
    /request
    /response
  /shared

/application
  /commands
    /budget
    /transaction
  /queries
    /budget
    /transaction
  /ports
    /mutations
    /queries

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
      "@dtos/*": ["dtos/*"],
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
// ✅ Application importando DTOs
import { CreateTransactionRequestDto } from '@dtos/transaction/request/CreateTransactionRequestDto';
import { BudgetResponseDto } from '@dtos/budget/response/BudgetResponseDto';
import { Money } from '@dtos/shared/Money';

// ✅ Infra implementando Application (1 interface por operação)
import { ICreateBudgetPort } from '@application/ports/mutations/budget/ICreateBudgetPort';
import { IGetBudgetByIdPort } from '@application/ports/queries/budget/IGetBudgetByIdPort';

// ✅ UI consumindo Application (padrão Command)
import { CreateBudgetCommand } from '@application/commands/budget/CreateBudgetCommand';
import { GetBudgetByIdQuery } from '@application/queries/budget/GetBudgetByIdQuery';
```

#### Mesma Camada (Imports Relativos)
```typescript
// ✅ Dentro de commands/budget
import { CreateBudgetRequestDto } from '@dtos/budget/request/CreateBudgetRequestDto';
import { ICreateBudgetPort } from '../../ports/mutations/budget/ICreateBudgetPort';
import { CreateBudgetValidator } from '../../validators/budget/CreateBudgetValidator';

// ✅ Dentro de queries/budget
import { BudgetResponseDto } from '@dtos/budget/response/BudgetResponseDto';
import { IGetBudgetByIdPort } from '../../ports/queries/budget/IGetBudgetByIdPort';

// ✅ Dentro de components
import { BudgetCardComponent } from './budget-card.component';
import { BudgetService } from '../services/budget.service';
```

## Git e Versionamento

### Commit Messages

```
feat: add CreateTransactionCommand with DTO validation
fix: handle insufficient balance error in Transaction DTO
refactor: extract HTTP error handling to dedicated service  
docs: update frontend architecture documentation for DTO-First
test: add integration tests for HttpCreateBudgetAdapter
style: apply consistent naming conventions to UI components
```

### Branch Naming

```
feature/create-transaction-command
feature/budget-summary-query
bugfix/money-input-validation
refactor/http-client-error-handling
docs/dto-first-architecture-update
```

---

**Ver também:**
- [Directory Structure](./directory-structure.md) - Como organizar arquivos fisicamente
- [Layer Responsibilities](./layer-responsibilities.md) - Responsabilidades por camada  
- [DTO Conventions](./dto-conventions.md) - Convenções específicas para DTOs
- [UI System](./ui-system.md) - Convenções específicas do Design System