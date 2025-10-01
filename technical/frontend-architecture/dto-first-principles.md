# Princípios da DTO-First Architecture

---

**Metadados Estruturados para IA/RAG:**

```yaml
document_type: "technical_architecture"
domain: "frontend_architecture"
audience: ["frontend_developers", "architects", "tech_leads"]
complexity: "intermediate"
tags: ["dto_first", "architecture_principles", "frontend", "typescript"]
related_docs:
  ["overview.md", "dto-conventions.md", "backend-integration.md"]
ai_context: "Core principles and guidelines for DTO-First Architecture in frontend applications"
technologies: ["TypeScript", "Angular", "DTOs"]
patterns: ["DTO-First", "API-First", "Backend-as-Truth"]
last_updated: "2025-01-24"
```

---

## Visão Geral

A **DTO-First Architecture** é uma abordagem arquitetural que prioriza **Data Transfer Objects (DTOs)** como a base fundamental da comunicação entre frontend e backend, eliminando camadas intermediárias desnecessárias e simplificando o desenvolvimento.

## Princípios Fundamentais

### 1. DTOs como Cidadãos de Primeira Classe

**Conceito**: DTOs não são apenas estruturas de dados, mas sim a **linguagem comum** entre frontend e backend.

**Implementação**:
- DTOs são interfaces TypeScript puras
- Representam contratos exatos da API
- Estado da aplicação trabalha diretamente com DTOs
- Componentes recebem e exibem DTOs sem transformações

**Exemplo**:
```typescript
// ✅ DTO como base do estado
interface BudgetResponseDto {
  readonly id: string;
  readonly name: string;
  readonly limitInCents: number;
  readonly currentUsageInCents: number;
  readonly participants: string[];
  readonly createdAt: string;
  readonly updatedAt: string;
}

// ✅ Componente usando DTO diretamente
@Component({...})
export class BudgetCardComponent {
  budget = input.required<BudgetResponseDto>();
  
  protected usagePercentage = computed(() => 
    (this.budget().currentUsageInCents / this.budget().limitInCents) * 100
  );
}
```

### 2. Backend como Fonte da Verdade

**Conceito**: Todas as regras de negócio, validações complexas e lógica de domínio residem no backend.

**Benefícios**:
- Eliminação de duplicação de lógica
- Consistência garantida entre clientes
- Simplicidade no frontend
- Facilidade de manutenção

**Implementação**:
- Frontend confia nos dados vindos da API
- Validações complexas delegadas ao backend
- Regras de negócio não são reimplementadas no cliente
- DTOs espelham exatamente a estrutura do backend

### 3. Simplicidade sobre Abstração

**Conceito**: Preferir soluções diretas e simples sobre abstrações complexas desnecessárias.

**Aplicação**:
- Evitar mappers complexos quando DTOs já atendem
- Usar transformações leves apenas quando necessário
- Preferir código direto sobre padrões elaborados
- Focar na funcionalidade, não na arquitetura

**Exemplo**:
```typescript
// ❌ Complexo desnecessário
class BudgetMapper {
  static toDomain(dto: BudgetResponseDto): Budget {
    return new Budget(
      dto.id,
      dto.name,
      Money.fromCents(dto.limitInCents),
      // ... mais transformações
    );
  }
}

// ✅ Simples e direto
// Usar BudgetResponseDto diretamente
const budget: BudgetResponseDto = await getBudgetById(id);
```

### 4. Alinhamento Total com API

**Conceito**: Frontend e backend evoluem juntos através de contratos bem definidos.

**Implementação**:
- DTOs são gerados ou sincronizados automaticamente quando possível
- Mudanças na API refletem imediatamente no frontend
- Versionamento de DTOs quando necessário
- Documentação de API como fonte de verdade

## Tipos de Dados Padronizados

### Money (Valores Monetários)

**Representação**: `number` em centavos
**Justificativa**: Evita problemas de precisão de ponto flutuante

```typescript
// ✅ Correto
type Money = number; // R$ 10,50 = 1050 centavos

interface TransactionResponseDto {
  readonly amountInCents: Money; // 1050
}

// ❌ Evitar
interface TransactionResponseDto {
  readonly amount: number; // 10.50 (problemas de precisão)
}
```

### Datas

**Representação**: `string` em formato ISO 8601
**Justificativa**: Padrão universal, fácil de serializar/deserializar

```typescript
// ✅ Correto
type DateString = string; // "2024-01-15T10:30:00.000Z"

interface BudgetResponseDto {
  readonly createdAt: DateString;
  readonly updatedAt: DateString;
}

// ❌ Evitar
interface BudgetResponseDto {
  readonly createdAt: Date; // Problemas de serialização
}
```

### Enums

**Representação**: `string` literals
**Justificativa**: Type-safe, fácil de serializar, compatível com JSON

```typescript
// ✅ Correto
type TransactionType = "INCOME" | "EXPENSE";
type BudgetStatus = "ACTIVE" | "INACTIVE" | "ARCHIVED";

interface TransactionResponseDto {
  readonly type: TransactionType;
  readonly status: BudgetStatus;
}

// ❌ Evitar
enum TransactionType {
  INCOME = "INCOME",
  EXPENSE = "EXPENSE"
}
```

### IDs

**Representação**: `string` UUIDs
**Justificativa**: Padrão universal, não sequencial, seguro

```typescript
// ✅ Correto
interface BaseEntityDto {
  readonly id: string; // UUID v4
}

// ❌ Evitar
interface BaseEntityDto {
  readonly id: number; // Sequencial, problemas de segurança
}
```

## Padrões de Validação

### Validações Client-Side (UX)

**Quando usar**: Para melhorar a experiência do usuário
**Exemplos**: Validação de formulários, feedback imediato

```typescript
// ✅ Validação client-side para UX
export class CreateTransactionValidator {
  static validate(dto: CreateTransactionRequestDto): ValidationResult {
    const errors: string[] = [];

    if (!dto.description?.trim()) {
      errors.push("Descrição é obrigatória");
    }

    if (!dto.amountInCents || dto.amountInCents <= 0) {
      errors.push("Valor deve ser maior que zero");
    }

    return {
      hasError: errors.length > 0,
      errors,
    };
  }
}
```

### Validações Server-Side (Segurança)

**Quando usar**: Para garantir integridade e segurança dos dados
**Exemplos**: Regras de negócio, validações de autorização

```typescript
// ✅ Backend valida regras de negócio
// Frontend apenas propaga erros
const result = await createTransactionCommand.execute(dto);
if (result.hasError) {
  // Mostrar erro do backend
  this.showError(result.error.message);
}
```

## Padrões de Transformação

### Transformações Leves (Quando Necessário)

**Quando usar**: Apenas quando formato da API difere do necessário para UI

```typescript
// ✅ Transformação leve para exibição
export class MoneyFormatter {
  static toDisplayString(amountInCents: number): string {
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: 'BRL'
    }).format(amountInCents / 100);
  }
}

// ✅ Transformação de data para exibição
export class DateFormatter {
  static toDisplayDate(isoString: string): string {
    return new Date(isoString).toLocaleDateString('pt-BR');
  }
}
```

### Evitar Transformações Complexas

**Quando evitar**: Quando DTO já atende às necessidades da UI

```typescript
// ❌ Transformação desnecessária
class BudgetTransformer {
  static toViewModel(dto: BudgetResponseDto): BudgetViewModel {
    return {
      id: dto.id,
      name: dto.name,
      limit: dto.limitInCents / 100, // Desnecessário
      usage: dto.currentUsageInCents / 100, // Desnecessário
      // ... mais campos
    };
  }
}

// ✅ Usar DTO diretamente
// Calcular valores na UI quando necessário
protected usagePercentage = computed(() => 
  (this.budget().currentUsageInCents / this.budget().limitInCents) * 100
);
```

## Organização de DTOs

### Por Contexto de Negócio

**Estrutura**: Organizar DTOs por entidade/contexto de negócio

```
/dtos
  /budget
    /request
      - CreateBudgetRequestDto.ts
      - UpdateBudgetRequestDto.ts
    /response
      - BudgetResponseDto.ts
      - BudgetListResponseDto.ts
  /transaction
    /request
      - CreateTransactionRequestDto.ts
      - UpdateTransactionRequestDto.ts
    /response
      - TransactionResponseDto.ts
      - TransactionListResponseDto.ts
  /shared
    - Money.ts
    - DateString.ts
    - BaseEntity.ts
```

### Convenções de Nomenclatura

**Request DTOs**: `{Action}{Entity}RequestDto`
**Response DTOs**: `{Entity}ResponseDto` ou `{Entity}ListResponseDto`
**Shared Types**: Nome descritivo (`Money`, `DateString`, `TransactionType`)

```typescript
// ✅ Convenções
interface CreateBudgetRequestDto { ... }
interface UpdateBudgetRequestDto { ... }
interface BudgetResponseDto { ... }
interface BudgetListResponseDto { ... }
type Money = number;
type DateString = string;
```

## Trade-offs e Benefícios

### Benefícios

✅ **Simplicidade**: Código mais direto e fácil de entender
✅ **Alinhamento**: Frontend e backend sempre sincronizados
✅ **Manutenibilidade**: Mudanças na API propagam diretamente
✅ **Performance**: Menos transformações e mapeamentos
✅ **Desenvolvimento**: Menos boilerplate, foco no que importa
✅ **Testabilidade**: DTOs são fáceis de mockar e testar

### Trade-offs

❌ **Menos Isolamento**: Regras de negócio centralizadas no backend
❌ **Dependência de Rede**: Validações complexas requerem chamadas HTTP
❌ **Menos Flexibilidade**: Frontend limitado aos contratos de API
❌ **Acoplamento**: Mudanças na API podem quebrar o frontend

### Mitigações

- **Validações Client-Side**: Para UX (formulários, feedback imediato)
- **Caching Inteligente**: Para reduzir dependência de rede
- **Contratos Bem Definidos**: OpenAPI/Swagger para sincronização
- **Testes de Integração**: Para garantir alinhamento com backend
- **Versionamento**: Para evoluções controladas da API

## Quando NÃO Usar DTO-First

### Cenários Inadequados

- **Aplicações Offline-First**: Quando lógica de negócio complexa é necessária no cliente
- **Múltiplos Backends**: Quando frontend precisa agregação de dados de várias fontes
- **Regras de Negócio Complexas**: Quando validações complexas são necessárias no cliente
- **Performance Crítica**: Quando transformações custosas são necessárias

### Alternativas

- **Clean Architecture Tradicional**: Para aplicações com lógica de domínio complexa
- **CQRS + Event Sourcing**: Para aplicações com alta complexidade de domínio
- **Micro-Frontends**: Para aplicações com múltiplas equipes independentes

## Evolução e Migração

### Estratégia de Migração

1. **Identificar DTOs Existentes**: Mapear contratos de API atuais
2. **Criar Estrutura Base**: Implementar organização de DTOs
3. **Migrar Gradualmente**: Por contexto/entidade
4. **Remover Camadas Antigas**: Eliminar Models e mappers desnecessários
5. **Validar Alinhamento**: Garantir sincronização com backend

### Monitoramento

- **Métricas de Performance**: Tempo de resposta, uso de memória
- **Qualidade de Código**: Complexidade, manutenibilidade
- **Alinhamento com Backend**: Sincronização de contratos
- **Satisfação da Equipe**: Facilidade de desenvolvimento

---

**Ver também:**

- [DTO Conventions](./dto-conventions.md) - Convenções detalhadas para DTOs
- [Backend Integration](./backend-integration.md) - Integração com APIs
- [Overview](./overview.md) - Visão geral da arquitetura
