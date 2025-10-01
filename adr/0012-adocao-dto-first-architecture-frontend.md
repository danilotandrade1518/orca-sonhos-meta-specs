# ADR-0012: Adoção de DTO-First Architecture no Frontend

## Status
Aceito

## Contexto

O frontend do Orca Sonhos atualmente está planejado para seguir uma arquitetura **Model-First**, onde:

- Domain Models são a base da aplicação (Budget, Transaction, Account, etc.)
- Value Objects encapsulam regras de negócio (Money, TransactionType, etc.)
- Clean Architecture tradicional com camada de Domain isolada
- Mappers complexos entre Domain Models e DTOs de API

### Problemas Identificados

1. **Duplicação de Lógica**: Regras de negócio duplicadas entre frontend e backend
2. **Complexidade Desnecessária**: Mappers e transformações complexas para casos simples
3. **Desalinhamento**: Frontend e backend evoluem independentemente, causando inconsistências
4. **Overhead de Manutenção**: Mudanças na API requerem atualizações em múltiplas camadas
5. **Over-Engineering**: Frontend não precisa de toda a complexidade de Domain Models

### Alternativas Consideradas

#### A. Manter Clean Architecture Tradicional
- **Prós**: Isolamento de regras de negócio, testabilidade
- **Contras**: Complexidade excessiva, duplicação de lógica, overhead de manutenção

#### B. Redux/NgRx com State Normalizado
- **Prós**: Estado previsível, ferramentas de debugging
- **Contras**: Boilerplate excessivo, complexidade para casos simples, não resolve duplicação de lógica

#### C. DTO-First Architecture
- **Prós**: Simplicidade, alinhamento total com backend, menor overhead
- **Contras**: Menos isolamento de regras de negócio (delegadas ao backend)

## Decisão

Adotar **DTO-First Architecture** no frontend, onde:

### Princípios Fundamentais

1. **DTOs como Cidadãos de Primeira Classe**
   - DTOs representam contratos com o backend
   - Estado da aplicação trabalha diretamente com DTOs
   - Componentes recebem e exibem DTOs

2. **Eliminação da Camada Models**
   - Sem Domain Models no frontend
   - Sem Value Objects (Money, TransactionType, etc.)
   - Sem regras de negócio complexas no cliente

3. **Application Layer Simplificada**
   - Use Cases focam em orquestração de chamadas HTTP
   - Validações básicas de formulário (client-side)
   - Transformações leves de dados quando necessário
   - Mappers apenas para conversão de formatos (quando absolutamente necessário)

4. **Backend como Fonte da Verdade**
   - Todas as regras de negócio ficam no backend
   - Frontend confia nos contratos de API
   - Validações complexas delegadas ao servidor

### Estrutura de Camadas

```
┌─────────────────────────────────────┐
│             UI (Angular)            │ ← Componentes, páginas, estado local
├─────────────────────────────────────┤
│        Infra (HTTP Adapters)        │ ← HTTP clients, storage, auth
├─────────────────────────────────────┤
│    Application (Use Cases)          │ ← Orquestração e validações básicas
├─────────────────────────────────────┤
│           DTOs (Contratos)          │ ← Interfaces TypeScript alinhadas à API
└─────────────────────────────────────┘
```

### Tipos de Dados Simplificados

- **Money**: `number` (centavos) - R$ 10,50 = 1050
- **Datas**: `string` ISO - `"2024-01-15T10:30:00.000Z"`
- **Enums**: `string` literals - `"INCOME" | "EXPENSE"`
- **IDs**: `string` UUIDs

## Consequências

### Positivas

- ✅ **Simplicidade**: Código mais direto e fácil de entender
- ✅ **Alinhamento**: Frontend e backend sempre sincronizados
- ✅ **Manutenibilidade**: Mudanças na API propagam diretamente
- ✅ **Performance**: Menos transformações e mapeamentos
- ✅ **Desenvolvimento**: Menos boilerplate, foco no que importa

### Negativas

- ❌ **Menos Isolamento**: Regras de negócio centralizadas no backend
- ❌ **Dependência de Rede**: Validações complexas requerem chamadas HTTP
- ❌ **Menos Flexibilidade**: Frontend limitado aos contratos de API

### Mitigações

- **Validações Client-Side**: Para UX (formulários, feedback imediato)
- **Caching Inteligente**: Para reduzir dependência de rede
- **Contratos Bem Definidos**: OpenAPI/Swagger para sincronização
- **Testes de Integração**: Para garantir alinhamento com backend

## Implementação

### Fase 1: Documentação
- [x] ADR 0012 (este documento)
- [ ] Atualizar documentação de arquitetura frontend
- [ ] Definir convenções de DTOs
- [ ] Estabelecer padrões de validação

### Fase 2: Estrutura Base
- [ ] Criar estrutura de diretórios `/dtos`
- [ ] Implementar DTOs base (Request/Response)
- [ ] Configurar path aliases `@dtos/*`

### Fase 3: Application Layer
- [ ] Refatorar Use Cases para trabalhar com DTOs
- [ ] Implementar validadores client-side básicos
- [ ] Simplificar mappers (quando necessário)

### Fase 4: UI Layer
- [ ] Atualizar componentes para usar DTOs diretamente
- [ ] Implementar estado local com DTOs
- [ ] Remover dependências de Domain Models

## Referências

- [Clean Architecture - Robert Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [DTO Pattern - Martin Fowler](https://martinfowler.com/eaaCatalog/dataTransferObject.html)
- [Frontend Architecture Patterns](https://martinfowler.com/articles/frontend-architecture.html)

---

**Data**: 2024-01-15  
**Autor**: Equipe de Arquitetura  
**Revisores**: Tech Lead, Product Owner
