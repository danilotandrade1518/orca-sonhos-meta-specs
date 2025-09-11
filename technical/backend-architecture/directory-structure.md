# Organização dos Diretórios

## Estrutura Principal

```
/src
├── /domain                     # Agregados, Value Objects e regras de negócio
│   ├── /aggregates            # Cada agregado possui pasta própria
│   │   ├── /budget            # Agregado Budget
│   │   ├── /account           # Agregado Account  
│   │   ├── /transaction       # Agregado Transaction
│   │   ├── /category          # Agregado Category
│   │   ├── /credit-card       # Agregado CreditCard
│   │   ├── /credit-card-bill  # Agregado CreditCardBill
│   │   ├── /envelope          # Agregado Envelope
│   │   └── /goal              # Agregado Goal
│   └── /shared
│       └── /value-objects     # Value Objects globais reutilizáveis
├── /application
│   ├── /usecases             # Casos de uso (orquestração)
│   ├── /queries              # Query Handlers (consultas)
│   └── /contracts            # Interfaces de Repositórios e Serviços
├── /infra                    # Implementações de infraestrutura
│   ├── /database
│   ├── /external-services
│   └── /messaging
├── /interfaces
│   └── /web                  # Controllers HTTP (Express)
└── /config                   # Configurações gerais do projeto
```

## Detalhamento por Camada

### `/domain` - Coração da Aplicação

**Agregados (`/aggregates`)**
```
/aggregates/[aggregate-name]/
├── [AggregateRoot].ts          # Entidade raiz do agregado
├── [AggregateRoot].spec.ts     # Testes da entidade
├── /entities/                  # Entidades internas (se necessário)
├── /value-objects/             # VOs específicos do agregado
└── /services/                  # Domain Services específicos
    ├── [Operation]DomainService.ts
    └── [Operation]DomainService.spec.ts
```

**Value Objects Compartilhados (`/shared/value-objects`)**
- `Money.ts` - Valores monetários
- `Email.ts` - Endereços de email
- `DateRange.ts` - Períodos de tempo
- `Percentage.ts` - Valores percentuais

### `/application` - Orquestração

**Use Cases (`/usecases`)**
```
/usecases/[aggregate-name]/
├── [Operation]UseCase.ts       # Ex: CreateBudgetUseCase
├── [Operation]UseCase.spec.ts  # Testes unitários
└── /dtos/                      # DTOs específicos
    ├── [Operation]Dto.ts
    └── [Operation]ResponseDto.ts
```

**Query Handlers (`/queries`)**
```
/queries/[context]/
├── [QueryName]QueryHandler.ts  # Ex: GetBudgetSummaryQueryHandler
├── [QueryName]QueryHandler.spec.ts
└── /dtos/
    ├── [Query]QueryDto.ts
    └── [Query]ResponseDto.ts
```

**Contracts (`/contracts`)**
- `/repositories/` - Interfaces de repositórios
- `/services/` - Interfaces de serviços de domínio
- `/external/` - Interfaces para serviços externos

### `/infra` - Implementações Concretas

**Database (`/infra/database`)**
```
/database/
├── /pg/                        # PostgreSQL específico
│   ├── /repositories/          # Implementações de repositories
│   ├── /daos/                  # Data Access Objects para queries
│   ├── /unit-of-works/         # Unit of Work implementations
│   └── /migrations/            # Database migrations
└── /shared/                    # Código compartilhado
    ├── /mappers/               # Domain ↔ DTO mappers
    └── /connections/           # Database connections
```

**Serviços Externos (`/infra/external-services`)**
- `/firebase/` - Firebase Auth integration
- `/email/` - Email service providers
- `/storage/` - File storage services

### `/interfaces/web` - Entrada HTTP

```
/web/
├── /controllers/               # Express controllers
│   ├── /budget/
│   ├── /transaction/
│   └── /auth/
├── /middlewares/               # Middlewares personalizados
├── /routes/                    # Definição de rotas
└── /dtos/                      # DTOs para HTTP requests/responses
```

### `/config` - Configurações

- `database.ts` - Configuração do banco
- `firebase.ts` - Configuração do Firebase
- `environment.ts` - Variáveis de ambiente
- `logging.ts` - Configuração de logs

## Convenções de Nomenclatura

### Arquivos e Pastas
- **Arquivos**: `PascalCase.ts` (ex: `CreateBudgetUseCase.ts`)
- **Pastas**: `kebab-case` (ex: `use-cases`, `credit-card-bill`)
- **Testes**: `[FileName].spec.ts` (ex: `Budget.spec.ts`)

### Interfaces
- **Prefixo `I`**: `IUserRepository`, `IBudgetService`
- **Sufixos específicos**: 
  - `Repository` para persistência
  - `Service` para serviços de domínio
  - `UseCase` para casos de uso
  - `QueryHandler` para consultas

## Localização dos Testes

### Testes Unitários
Colocados na mesma pasta do código testado:
```
src/domain/aggregates/budget/Budget.ts
src/domain/aggregates/budget/Budget.spec.ts
```

### Testes de Integração  
Pasta `__tests__` dentro do módulo:
```
src/application/usecases/__tests__/CreateBudgetUseCase.integration.spec.ts
```

### Testes E2E
Pasta `__tests__` na raiz:
```
src/__tests__/e2e/budget.e2e.spec.ts
```

## Padrões de Imports

### Path Alias (Entre Camadas)
```typescript
// De Application para Domain
import { Budget } from '@/domain/aggregates/budget/Budget';
import { Money } from '@/domain/shared/value-objects/Money';
```

### Imports Relativos (Mesma Camada)
```typescript
// Dentro de use-cases
import { CreateBudgetDto } from './dtos/CreateBudgetDto';
import { UpdateBudgetUseCase } from './UpdateBudgetUseCase';
```

---

**Ver também:**
- [Layer Responsibilities](./layer-responsibilities.md) - Responsabilidades de cada camada
- [Conventions](./conventions.md) - Convenções detalhadas de nomenclatura e organização