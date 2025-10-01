# Convenções de DTOs

---

**Metadados Estruturados para IA/RAG:**

```yaml
document_type: "technical_architecture"
domain: "frontend_architecture"
audience: ["frontend_developers", "architects", "tech_leads"]
complexity: "intermediate"
tags: ["dto_conventions", "naming_conventions", "typescript", "api_contracts"]
related_docs:
  ["dto-first-principles.md", "naming-conventions.md", "backend-integration.md"]
ai_context: "Detailed conventions and standards for DTOs in DTO-First Architecture"
technologies: ["TypeScript", "DTOs", "API Contracts"]
patterns: ["DTO-First", "API-First", "Naming Conventions"]
last_updated: "2025-01-24"
```

---

## Visão Geral

Este documento estabelece convenções padronizadas para **Data Transfer Objects (DTOs)** no contexto da DTO-First Architecture, garantindo consistência, clareza e manutenibilidade em todo o projeto.

## Estrutura de Diretórios

### Organização por Contexto

DTOs são organizados por **contexto de negócio** (entidade/agregado), não por tipo técnico:

```
/dtos
  /budget                    # Contexto: Budget Management
    /request                 # DTOs de entrada (para o backend)
      - CreateBudgetRequestDto.ts
      - UpdateBudgetRequestDto.ts
      - AddParticipantRequestDto.ts
      - RemoveParticipantRequestDto.ts
    /response                # DTOs de saída (do backend)
      - BudgetResponseDto.ts
      - BudgetListResponseDto.ts
      - BudgetSummaryResponseDto.ts
    /index.ts               # Re-exports centralizados
  /transaction              # Contexto: Transaction Management
    /request
      - CreateTransactionRequestDto.ts
      - UpdateTransactionRequestDto.ts
      - DeleteTransactionRequestDto.ts
    /response
      - TransactionResponseDto.ts
      - TransactionListResponseDto.ts
      - TransactionSummaryResponseDto.ts
    /index.ts
  /account                  # Contexto: Account Management
    /request
      - CreateAccountRequestDto.ts
      - UpdateAccountRequestDto.ts
    /response
      - AccountResponseDto.ts
      - AccountListResponseDto.ts
    /index.ts
  /shared                   # Tipos compartilhados entre contextos
    - Money.ts
    - DateString.ts
    - BaseEntity.ts
    - TransactionType.ts
    - BudgetStatus.ts
    - index.ts
  /index.ts                # Re-exports globais
```

### Convenções de Pastas

- **kebab-case**: Todas as pastas em kebab-case (`credit-card`, `transaction`)
- **Singular**: Nome da entidade no singular (`budget`, `transaction`, `account`)
- **Contexto claro**: Nome deve refletir o contexto de negócio
- **Hierarquia simples**: Máximo 3 níveis de profundidade

## Convenções de Nomenclatura

### Arquivos

#### Request DTOs
**Padrão**: `{Action}{Entity}RequestDto.ts`

```typescript
// ✅ Convenções corretas
CreateBudgetRequestDto.ts
UpdateBudgetRequestDto.ts
AddParticipantRequestDto.ts
RemoveParticipantRequestDto.ts
DeleteTransactionRequestDto.ts

// ❌ Evitar
BudgetCreateRequestDto.ts        // Ordem incorreta
CreateBudgetDto.ts               // Sem sufixo Request
BudgetCreateRequest.ts           // Sem sufixo Dto
```

#### Response DTOs
**Padrão**: `{Entity}{Suffix}ResponseDto.ts`

```typescript
// ✅ Convenções corretas
BudgetResponseDto.ts             // Entidade única
BudgetListResponseDto.ts         // Lista de entidades
BudgetSummaryResponseDto.ts      // Resumo/agregação
TransactionResponseDto.ts
TransactionListResponseDto.ts
TransactionSummaryResponseDto.ts

// ❌ Evitar
BudgetDto.ts                     // Muito genérico
BudgetListDto.ts                 // Sem sufixo Response
BudgetDataResponseDto.ts         // Sufixo desnecessário
```

#### Shared Types
**Padrão**: Nome descritivo + `.ts`

```typescript
// ✅ Convenções corretas
Money.ts
DateString.ts
BaseEntity.ts
TransactionType.ts
BudgetStatus.ts
AccountType.ts

// ❌ Evitar
MoneyType.ts                     // Sufixo desnecessário
Date.ts                          // Muito genérico
Base.ts                          // Muito genérico
```

### Interfaces e Types

#### Request DTOs
**Padrão**: `{Action}{Entity}RequestDto`

```typescript
// ✅ Convenções corretas
export interface CreateBudgetRequestDto {
  readonly name: string;
  readonly limitInCents: number;
  readonly description?: string;
}

export interface UpdateBudgetRequestDto {
  readonly id: string;
  readonly name?: string;
  readonly limitInCents?: number;
  readonly description?: string;
}

export interface AddParticipantRequestDto {
  readonly budgetId: string;
  readonly userId: string;
  readonly role: "ADMIN" | "MEMBER";
}
```

#### Response DTOs
**Padrão**: `{Entity}{Suffix}ResponseDto`

```typescript
// ✅ Convenções corretas
export interface BudgetResponseDto {
  readonly id: string;
  readonly name: string;
  readonly limitInCents: number;
  readonly currentUsageInCents: number;
  readonly participants: BudgetParticipantDto[];
  readonly createdAt: string;
  readonly updatedAt: string;
}

export interface BudgetListResponseDto {
  readonly budgets: BudgetResponseDto[];
  readonly total: number;
  readonly page: number;
  readonly pageSize: number;
}

export interface BudgetSummaryResponseDto {
  readonly totalBudgets: number;
  readonly activeBudgets: number;
  readonly totalLimitInCents: number;
  readonly totalUsageInCents: number;
}
```

#### Shared Types
**Padrão**: Nome descritivo sem sufixos

```typescript
// ✅ Convenções corretas
export type Money = number;
export type DateString = string;
export type TransactionType = "INCOME" | "EXPENSE";
export type BudgetStatus = "ACTIVE" | "INACTIVE" | "ARCHIVED";

export interface BaseEntityDto {
  readonly id: string;
  readonly createdAt: string;
  readonly updatedAt: string;
}
```

### Propriedades

#### Nomenclatura de Campos
**Padrão**: `camelCase` com sufixos descritivos

```typescript
// ✅ Convenções corretas
export interface TransactionResponseDto {
  readonly id: string;                    // ID único
  readonly accountId: string;             // ID da conta
  readonly budgetId: string;              // ID do orçamento
  readonly amountInCents: number;         // Valor em centavos
  readonly description: string;           // Descrição
  readonly type: TransactionType;         // Tipo da transação
  readonly categoryId?: string;           // ID da categoria (opcional)
  readonly date: DateString;              // Data da transação
  readonly createdAt: string;             // Data de criação
  readonly updatedAt: string;             // Data de atualização
}

// ❌ Evitar
export interface TransactionResponseDto {
  readonly transactionId: string;         // Redundante (já está em Transaction)
  readonly amount: number;                // Sem unidade clara
  readonly desc: string;                  // Abreviação desnecessária
  readonly transactionType: TransactionType; // Redundante
  readonly created_at: string;            // snake_case inconsistente
}
```

#### Sufixos Padronizados

| Sufixo | Uso | Exemplo |
|--------|-----|---------|
| `InCents` | Valores monetários | `amountInCents`, `limitInCents` |
| `Id` | Identificadores | `accountId`, `budgetId` |
| `At` | Timestamps | `createdAt`, `updatedAt` |
| `Count` | Contadores | `participantCount`, `transactionCount` |
| `Percentage` | Percentuais | `usagePercentage`, `progressPercentage` |
| `List` | Listas | `budgetList`, `transactionList` |
| `Summary` | Resumos | `budgetSummary`, `accountSummary` |

## Estrutura de DTOs

### Request DTOs

#### Estrutura Padrão
```typescript
export interface {Action}{Entity}RequestDto {
  // IDs obrigatórios (quando aplicável)
  readonly id?: string;                    // Para updates
  
  // Dados principais
  readonly {fieldName}: {Type};
  
  // Dados opcionais
  readonly {optionalField}?: {Type};
  
  // Relacionamentos (IDs)
  readonly {relatedEntityId}: string;
}
```

#### Exemplo Completo
```typescript
export interface CreateTransactionRequestDto {
  // Relacionamentos obrigatórios
  readonly accountId: string;
  readonly budgetId: string;
  
  // Dados principais
  readonly amountInCents: number;
  readonly description: string;
  readonly type: TransactionType;
  
  // Dados opcionais
  readonly categoryId?: string;
  readonly date?: DateString;
  readonly notes?: string;
}
```

### Response DTOs

#### Estrutura Padrão
```typescript
export interface {Entity}ResponseDto extends BaseEntityDto {
  // Dados principais
  readonly {fieldName}: {Type};
  
  // Dados calculados (quando aplicável)
  readonly {calculatedField}: {Type};
  
  // Relacionamentos (objetos completos)
  readonly {relatedEntity}: {RelatedEntityDto};
  
  // Listas de relacionamentos
  readonly {relatedEntities}: {RelatedEntityDto}[];
}
```

#### Exemplo Completo
```typescript
export interface BudgetResponseDto extends BaseEntityDto {
  // Dados principais
  readonly name: string;
  readonly description?: string;
  readonly limitInCents: number;
  
  // Dados calculados
  readonly currentUsageInCents: number;
  readonly usagePercentage: number;
  readonly remainingInCents: number;
  
  // Relacionamentos
  readonly owner: UserDto;
  readonly participants: BudgetParticipantDto[];
  readonly categories: CategoryDto[];
  
  // Metadados
  readonly status: BudgetStatus;
  readonly isActive: boolean;
}
```

### List Response DTOs

#### Estrutura Padrão
```typescript
export interface {Entity}ListResponseDto {
  // Lista de entidades
  readonly {entities}: {Entity}ResponseDto[];
  
  // Metadados de paginação
  readonly total: number;
  readonly page: number;
  readonly pageSize: number;
  readonly totalPages: number;
  
  // Metadados de filtros (quando aplicável)
  readonly filters?: {FilterType};
}
```

#### Exemplo Completo
```typescript
export interface TransactionListResponseDto {
  readonly transactions: TransactionResponseDto[];
  readonly total: number;
  readonly page: number;
  readonly pageSize: number;
  readonly totalPages: number;
  
  // Filtros aplicados
  readonly filters?: {
    readonly accountId?: string;
    readonly budgetId?: string;
    readonly type?: TransactionType;
    readonly dateFrom?: DateString;
    readonly dateTo?: DateString;
  };
}
```

## Tipos Compartilhados

### Money (Valores Monetários)

```typescript
// ✅ Definição padrão
export type Money = number;

// ✅ Uso em DTOs
export interface TransactionResponseDto {
  readonly amountInCents: Money;          // 1050 = R$ 10,50
  readonly limitInCents: Money;           // 50000 = R$ 500,00
}

// ✅ Helpers para formatação (quando necessário)
export class MoneyFormatter {
  static toDisplayString(amountInCents: Money): string {
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: 'BRL'
    }).format(amountInCents / 100);
  }
  
  static toCents(amount: number): Money {
    return Math.round(amount * 100);
  }
}
```

### DateString (Datas)

```typescript
// ✅ Definição padrão
export type DateString = string; // ISO 8601 format

// ✅ Uso em DTOs
export interface BaseEntityDto {
  readonly createdAt: DateString;         // "2024-01-15T10:30:00.000Z"
  readonly updatedAt: DateString;         // "2024-01-15T10:30:00.000Z"
}

// ✅ Helpers para formatação (quando necessário)
export class DateFormatter {
  static toDisplayDate(isoString: DateString): string {
    return new Date(isoString).toLocaleDateString('pt-BR');
  }
  
  static toDisplayDateTime(isoString: DateString): string {
    return new Date(isoString).toLocaleString('pt-BR');
  }
}
```

### Enums como String Literals

```typescript
// ✅ Convenção correta
export type TransactionType = "INCOME" | "EXPENSE";
export type BudgetStatus = "ACTIVE" | "INACTIVE" | "ARCHIVED";
export type AccountType = "CHECKING" | "SAVINGS" | "INVESTMENT";
export type UserRole = "ADMIN" | "MEMBER" | "VIEWER";

// ✅ Uso em DTOs
export interface TransactionResponseDto {
  readonly type: TransactionType;
  readonly status: BudgetStatus;
}

// ❌ Evitar enums TypeScript tradicionais
export enum TransactionType {
  INCOME = "INCOME",
  EXPENSE = "EXPENSE"
}
```

### BaseEntity

```typescript
// ✅ Estrutura padrão
export interface BaseEntityDto {
  readonly id: string;                    // UUID v4
  readonly createdAt: DateString;         // ISO 8601
  readonly updatedAt: DateString;         // ISO 8601
}

// ✅ Uso em DTOs
export interface BudgetResponseDto extends BaseEntityDto {
  readonly name: string;
  readonly limitInCents: Money;
  // ... outros campos
}
```

## Re-exports e Indexes

### Estrutura de Indexes

#### Por Contexto
```typescript
// /dtos/budget/index.ts
export * from './request/CreateBudgetRequestDto';
export * from './request/UpdateBudgetRequestDto';
export * from './request/AddParticipantRequestDto';
export * from './request/RemoveParticipantRequestDto';

export * from './response/BudgetResponseDto';
export * from './response/BudgetListResponseDto';
export * from './response/BudgetSummaryResponseDto';
```

#### Shared Types
```typescript
// /dtos/shared/index.ts
export * from './Money';
export * from './DateString';
export * from './BaseEntity';
export * from './TransactionType';
export * from './BudgetStatus';
export * from './AccountType';
export * from './UserRole';
```

#### Global
```typescript
// /dtos/index.ts
export * from './shared';

export * from './budget';
export * from './transaction';
export * from './account';
export * from './credit-card';
export * from './goal';
export * from './envelope';
```

### Convenções de Import

#### Imports Específicos (Preferível)
```typescript
// ✅ Import específico
import { CreateBudgetRequestDto } from '@dtos/budget/request/CreateBudgetRequestDto';
import { BudgetResponseDto } from '@dtos/budget/response/BudgetResponseDto';
import { Money } from '@dtos/shared/Money';
```

#### Imports por Contexto (Quando Múltiplos)
```typescript
// ✅ Import por contexto
import { 
  CreateBudgetRequestDto,
  UpdateBudgetRequestDto,
  BudgetResponseDto,
  BudgetListResponseDto 
} from '@dtos/budget';
```

#### Imports Globais (Evitar)
```typescript
// ❌ Evitar imports globais
import { CreateBudgetRequestDto } from '@dtos';
```

## Versionamento de DTOs

### Estratégia de Versionamento

#### Backward Compatibility
- **Adicionar campos**: Sempre opcionais inicialmente
- **Remover campos**: Deprecar antes de remover
- **Alterar tipos**: Criar nova versão do DTO

#### Exemplo de Evolução
```typescript
// v1.0 - DTO original
export interface BudgetResponseDto {
  readonly id: string;
  readonly name: string;
  readonly limitInCents: number;
  readonly createdAt: string;
  readonly updatedAt: string;
}

// v1.1 - Adicionando campo opcional
export interface BudgetResponseDto {
  readonly id: string;
  readonly name: string;
  readonly limitInCents: number;
  readonly description?: string;        // ✅ Novo campo opcional
  readonly createdAt: string;
  readonly updatedAt: string;
}

// v2.0 - Nova versão com breaking changes
export interface BudgetResponseDtoV2 {
  readonly id: string;
  readonly name: string;
  readonly limitInCents: number;
  readonly description?: string;
  readonly participants: BudgetParticipantDto[]; // ✅ Novo campo obrigatório
  readonly createdAt: DateString;                // ✅ Tipo alterado
  readonly updatedAt: DateString;                // ✅ Tipo alterado
}
```

### Documentação de Mudanças

```typescript
// ✅ Documentar mudanças
export interface BudgetResponseDto {
  readonly id: string;
  readonly name: string;
  readonly limitInCents: number;
  
  /**
   * @deprecated Use participants array instead
   * @since v1.0
   * @removed v2.0
   */
  readonly participantCount?: number;
  
  /**
   * @since v1.1
   */
  readonly description?: string;
  
  /**
   * @since v2.0
   */
  readonly participants: BudgetParticipantDto[];
  
  readonly createdAt: string;
  readonly updatedAt: string;
}
```

## Sincronização com Backend

### Contratos de API

#### OpenAPI/Swagger
- **Geração automática**: DTOs gerados a partir de OpenAPI
- **Validação**: Schemas validados contra API real
- **Sincronização**: Atualizações automáticas quando API muda

#### Exemplo de Configuração
```yaml
# openapi-generator.yml
generatorName: typescript-axios
inputSpec: https://api.orcasonhos.com/openapi.json
outputDir: ./src/dtos/generated
additionalProperties:
  modelPropertyNaming: camelCase
  withInterfaces: true
  supportsES6: true
```

### Validação de Contratos

#### Testes de Integração
```typescript
// ✅ Teste de validação de contrato
describe('Budget DTOs', () => {
  it('should match API contract', async () => {
    const response = await apiClient.get('/budgets/123');
    const budget: BudgetResponseDto = response.data;
    
    // Validação de estrutura
    expect(budget).toHaveProperty('id');
    expect(budget).toHaveProperty('name');
    expect(budget).toHaveProperty('limitInCents');
    expect(budget).toHaveProperty('createdAt');
    expect(budget).toHaveProperty('updatedAt');
    
    // Validação de tipos
    expect(typeof budget.id).toBe('string');
    expect(typeof budget.name).toBe('string');
    expect(typeof budget.limitInCents).toBe('number');
    expect(typeof budget.createdAt).toBe('string');
    expect(typeof budget.updatedAt).toBe('string');
  });
});
```

## Boas Práticas

### ✅ Fazer

- **Usar readonly**: Todas as propriedades devem ser readonly
- **Nomes descritivos**: Evitar abreviações desnecessárias
- **Consistência**: Seguir convenções estabelecidas
- **Documentação**: Documentar mudanças e deprecações
- **Validação**: Validar contratos com backend
- **Versionamento**: Controlar evolução dos DTOs

### ❌ Evitar

- **Mutabilidade**: Evitar propriedades mutáveis
- **Abreviações**: Evitar nomes como `desc`, `id`, `amt`
- **Inconsistência**: Misturar convenções diferentes
- **Breaking Changes**: Alterar DTOs sem versionamento
- **Duplicação**: Duplicar lógica entre DTOs
- **Complexidade**: Evitar estruturas desnecessariamente complexas

---

**Ver também:**

- [DTO-First Principles](./dto-first-principles.md) - Princípios fundamentais
- [Naming Conventions](./naming-conventions.md) - Convenções gerais de nomenclatura
- [Backend Integration](./backend-integration.md) - Integração com APIs
