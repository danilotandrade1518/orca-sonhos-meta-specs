# Overview - Padrões de Código OrçaSonhos

## 🎯 Visão Geral

Este documento define os padrões de código, convenções de nomenclatura, estrutura e boas práticas para o desenvolvimento do projeto OrçaSonhos. O objetivo é garantir consistência, legibilidade e manutenibilidade em todo o codebase, tanto no frontend (Angular/TypeScript) quanto no backend (Node.js/Express/TypeScript).

## 🌍 Linguagem e Idioma

**OBRIGATÓRIO**: Todo o código deve ser escrito em **inglês**:
- Nomes de variáveis, funções, classes, interfaces, comentários, mensagens de commit
- Arquivos, pastas, documentação de código
- Logs e mensagens de erro técnicas

**Exceções**: Apenas conteúdo voltado ao usuário final (textos de UI, mensagens de validação, etc.) em português.

```typescript
// ✅ CORRETO - Inglês obrigatório
export class TransactionService {
  public createTransaction(dto: CreateTransactionDto): Promise<Either<Error, Transaction>> {
    // implementation
  }
  
  private validateAmount(amount: Money): Either<ValidationError, void> {
    // validation logic
  }
}

// ❌ INCORRETO - Português no código
export class ServicoTransacao {
  public criarTransacao(dto: CriarTransacaoDto): Promise<Either<Error, Transacao>> {
    // implementação
  }
}
```

## 🏗️ Princípios Fundamentais

### 1. Clean Architecture
- Separação clara entre camadas (Domain, Application, Infrastructure, UI)
- Inversão de dependências entre camadas
- Domain layer independente de frameworks

### 2. Padrão Either
- **Obrigatório**: Usar `Either<Error, Success>` ao invés de `throw/try/catch`
- Tratamento explícito de erros em todas as camadas
- Composição funcional de operações que podem falhar

### 3. English-First
- Todo código interno em inglês
- Apenas UI final em português
- Consistência na comunicação técnica

### 4. TypeScript Strict
- Configuração strict habilitada
- Tipos explícitos e verificação rigorosa
- Evitar `any` e tipos implícitos

## 📁 Estrutura do Codebase

### Frontend (Angular)
```
/src
  /models              # 🔵 Domain layer (TypeScript puro)
  /application         # 🟡 Use cases e orquestração
  /infra              # 🟠 Adapters e implementações
  /app                # 🟢 Angular UI layer
```

### Backend (Node.js)
```
/src
  /domain             # 🔵 Aggregates, entities, value objects
  /application        # 🟡 Use cases, ports, DTOs
  /infrastructure     # 🟠 Repositories, adapters, database
  /api               # 🟢 Controllers, middleware, routes
```

## 🚀 Padrões Modernos

### Angular
- **Signals** para estado reativo
- **inject()** ao invés de constructor injection
- **Control flow** nativo (@if, @for, @switch)
- **ChangeDetectionStrategy.OnPush** obrigatório
- **Standalone components** como padrão

### TypeScript
- **function-based APIs** quando disponível
- **Computed values** para derivações
- **Path aliases** entre camadas
- **Strict mode** habilitado

## ⚡ Qualidade e Performance

### Code Quality
- **ESLint + Prettier** obrigatórios
- **Boundary rules** entre camadas
- **No comments** como regra geral
- **AAA pattern** para testes

### Performance
- **Lazy loading** por features
- **Tree shaking** otimizado
- **Bundle splitting** apropriado
- **OnPush strategy** universal

## 🔒 Segurança

### Validação
- **Value Objects** para validação de domínio
- **Input sanitization** obrigatória
- **Type safety** rigorosa

### Authentication
- **Firebase Auth** integrado
- **JWT tokens** para autorização
- **Headers seguros** configurados

---

**Próximos passos:**
- **[Naming Conventions](./naming-conventions.md)** - Como nomear classes, métodos e variáveis
- **[Class Structure](./class-structure.md)** - Organização interna de classes
- **[Error Handling](./error-handling.md)** - Padrão Either obrigatório