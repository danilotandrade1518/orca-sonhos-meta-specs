# Code Review Checklist - Lista de Verificação

## ✅ Checklist de Code Review

### 🏗️ Estrutura e Organização

- [ ] **Arquivos nomeados corretamente**
  - [ ] Classes: PascalCase (ex: `CreateTransactionUseCase.ts`)
  - [ ] Componentes Angular: kebab-case (ex: `transaction-form.component.ts`)
  - [ ] Pastas: kebab-case (ex: `use-cases/`, `value-objects/`)

- [ ] **Imports organizados adequadamente**
  - [ ] Bibliotecas externas primeiro
  - [ ] Imports internos por camada (domain → application → infra)
  - [ ] Imports relativos por último
  - [ ] Path aliases usados entre camadas diferentes

- [ ] **Métodos organizados na ordem correta**
  - [ ] 1. Propriedades públicas
  - [ ] 2. Propriedades privadas
  - [ ] 3. Construtor
  - [ ] 4. Métodos públicos
  - [ ] 5. Métodos estáticos
  - [ ] 6. Métodos privados

### 🔤 Nomenclatura

- [ ] **Todo código em inglês**
  - [ ] Classes, métodos, variáveis em inglês
  - [ ] Comentários em inglês (quando existirem)
  - [ ] Apenas UI final em português

- [ ] **Convenções seguidas**
  - [ ] Classes: PascalCase (ex: `TransactionService`)
  - [ ] Métodos/variáveis: camelCase (ex: `createTransaction`)
  - [ ] Constantes: SCREAMING_SNAKE_CASE (ex: `MAX_RETRY_ATTEMPTS`)
  - [ ] Interfaces: prefixo "I" (ex: `ITransactionRepository`)
  - [ ] Componentes Angular: prefixo "os-" (ex: `os-transaction-form`)

### 🏛️ Padrões Arquiteturais

- [ ] **Either usado ao invés de throw/try/catch**
  - [ ] Métodos retornam `Either<Error, Success>`
  - [ ] Tratamento explícito de erros
  - [ ] Composição funcional com `.fold()` ou `.map()`

- [ ] **Repositories separados corretamente**
  - [ ] `IAddRepository` para inserções
  - [ ] `ISaveRepository` para atualizações
  - [ ] `IGetRepository` para busca por ID
  - [ ] `IFindRepository` para consultas com critérios

- [ ] **Use Cases específicos para cada operação**
  - [ ] Um Use Case por operação de negócio
  - [ ] Dependências injetadas via construtor
  - [ ] Validação de autorização incluída

- [ ] **Unit of Work para operações transacionais**
  - [ ] Operações que afetam múltiplas entidades
  - [ ] Nomenclatura consistente: `[Operation]UnitOfWork`
  - [ ] Rollback automático em caso de erro

- [ ] **Boundary rules respeitadas entre camadas**
  - [ ] Domain não importa de Application/Infrastructure
  - [ ] Application não importa de UI
  - [ ] ESLint rules configuradas e passando

### 🅰️ Angular Específico

- [ ] **ChangeDetectionStrategy.OnPush obrigatório**
  - [ ] Todos os componentes usam OnPush
  - [ ] Signals usados para estado reativo
  - [ ] TrackBy functions para listas

- [ ] **Signals usados para estado reativo**
  - [ ] `signal()` para estado local
  - [ ] `computed()` para valores derivados
  - [ ] `effect()` para side effects

- [ ] **Control flow nativo**
  - [ ] `@if` ao invés de `*ngIf`
  - [ ] `@for` ao invés de `*ngFor`
  - [ ] `@switch` ao invés de `*ngSwitch`

- [ ] **inject() ao invés de constructor injection**
  - [ ] Serviços injetados com `inject()`
  - [ ] Constructor apenas para inicialização simples
  - [ ] DestroyRef para cleanup automático

- [ ] **input()/output() functions**
  - [ ] `input()` e `input.required()` para props
  - [ ] `output()` para eventos
  - [ ] Sem decorators @Input/@Output

### 💻 Qualidade de Código

- [ ] **Sem comentários desnecessários**
  - [ ] Código auto-explicativo
  - [ ] Comentários apenas quando solicitado explicitamente
  - [ ] JSDoc apenas para APIs públicas

- [ ] **Testes seguem padrão AAA**
  - [ ] Arrange: Configuração dos dados
  - [ ] Act: Execução da ação
  - [ ] Assert: Verificação dos resultados
  - [ ] Nomenclatura descritiva com "should"

- [ ] **Validações em Value Objects**
  - [ ] Input validation nas entidades de domínio
  - [ ] Either para retorno de validações
  - [ ] Sanitização de dados de entrada

- [ ] **Tratamento seguro de dados sensíveis**
  - [ ] Tokens não logados ou expostos
  - [ ] Senhas hasheadas adequadamente
  - [ ] Headers de segurança configurados

- [ ] **ESLint e Prettier aplicados**
  - [ ] Sem erros de linting
  - [ ] Formatação consistente
  - [ ] Imports organizados automaticamente

### 🔒 Segurança

- [ ] **Input sanitization implementada**
  - [ ] Validação contra XSS
  - [ ] Validação contra SQL injection
  - [ ] Escape de caracteres especiais

- [ ] **Authorization checks**
  - [ ] Verificação de permissões nos Use Cases
  - [ ] Headers de autenticação validados
  - [ ] Rate limiting configurado

- [ ] **Secure headers configurados**
  - [ ] X-Frame-Options: DENY
  - [ ] X-Content-Type-Options: nosniff
  - [ ] X-XSS-Protection: 1; mode=block
  - [ ] Referrer-Policy configurado

### 📊 Performance

- [ ] **OnPush strategy para performance**
  - [ ] Change detection otimizada
  - [ ] Signals para reatividade
  - [ ] Computed values ao invés de métodos no template

- [ ] **Lazy loading implementado**
  - [ ] Features carregadas sob demanda
  - [ ] Bundle splitting configurado
  - [ ] Tree shaking otimizado

- [ ] **TrackBy functions em listas**
  - [ ] Identificadores únicos para performance
  - [ ] Evita re-renderização desnecessária
  - [ ] Virtual scrolling para listas grandes

### 🧪 Testabilidade

- [ ] **Mocks apropriados**
  - [ ] Dependencies mockadas com jest.Mocked
  - [ ] Test factories para dados de teste
  - [ ] Builders para cenários complexos

- [ ] **Coverage adequada**
  - [ ] Casos de sucesso testados
  - [ ] Casos de erro testados
  - [ ] Edge cases considerados

- [ ] **Integration tests quando necessário**
  - [ ] Fluxos críticos cobertos
  - [ ] HTTP requests mockadas
  - [ ] Component interactions testadas

### 📝 Documentação

- [ ] **README atualizado se necessário**
  - [ ] Instruções de setup atualizadas
  - [ ] Dependências documentadas
  - [ ] Comandos de desenvolvimento listados

- [ ] **API documentation**
  - [ ] OpenAPI/Swagger atualizado
  - [ ] Exemplos de request/response
  - [ ] Error codes documentados

- [ ] **ADRs criadas para decisões arquiteturais**
  - [ ] Contexto explicado
  - [ ] Alternativas consideradas
  - [ ] Decisão justificada

## 🚨 Red Flags - Bloquear imediatamente

### ❌ Bloqueadores Críticos

- [ ] **Código em português** (exceto UI)
- [ ] **Uso de throw/try/catch** ao invés de Either
- [ ] **Imports diretos entre camadas proibidas**
  - Domain importando de Application
  - Application importando de UI
  - Models importando de Infrastructure

- [ ] **Componentes sem OnPush**
- [ ] **Secrets/tokens hardcoded** no código
- [ ] **SQL queries concatenadas** (SQL injection risk)
- [ ] **Dados de usuário não sanitizados**

### ⚠️ Avisos Importantes

- [ ] **Comentários óbvios ou redundantes**
- [ ] **Métodos muito longos** (>50 linhas)
- [ ] **Classes com muitas responsabilidades**
- [ ] **Testes ausentes para código crítico**
- [ ] **Performance issues** evidentes
- [ ] **Console.log** esquecidos no código

## 📋 Checklist por Tipo de Mudança

### 🆕 Feature Nova

- [ ] ✅ Estrutura e Organização
- [ ] ✅ Nomenclatura
- [ ] ✅ Padrões Arquiteturais
- [ ] ✅ Angular Específico (se aplicável)
- [ ] ✅ Qualidade de Código
- [ ] ✅ Segurança
- [ ] ✅ Performance
- [ ] ✅ Testabilidade
- [ ] ✅ Documentação

### 🐛 Bug Fix

- [ ] ✅ Estrutura e Organização
- [ ] ✅ Nomenclatura
- [ ] ✅ Padrões Arquiteturais
- [ ] ✅ Qualidade de Código
- [ ] ✅ Segurança (se relevante)
- [ ] ✅ Testabilidade
- [ ] Regression tests adicionados
- [ ] Root cause identificado

### 🔄 Refactoring

- [ ] ✅ Estrutura e Organização
- [ ] ✅ Nomenclatura
- [ ] ✅ Padrões Arquiteturais
- [ ] ✅ Performance
- [ ] ✅ Testabilidade
- [ ] Comportamento mantido
- [ ] Tests continuam passando

### 📚 Documentation

- [ ] ✅ Documentação
- [ ] Exemplos funcionais
- [ ] Links válidos
- [ ] Gramática e ortografia

### 🧪 Tests Only

- [ ] ✅ Testabilidade
- [ ] ✅ Nomenclatura (nos testes)
- [ ] Coverage aumentada
- [ ] Tests passando

## 🎯 Resumo de Aprovação

Para **aprovar** um PR, todos os itens marcados como obrigatórios (✅) devem estar corretos, e **nenhum Red Flag** deve estar presente.

Para **solicitar mudanças**, identifique claramente:
1. **Bloqueadores críticos** que impedem a aprovação
2. **Melhorias recomendadas** para qualidade
3. **Sugestões opcionais** para otimização

### Template de Review

```markdown
## Review Summary

### ✅ Approved Items
- [x] Estrutura e organização
- [x] Nomenclatura consistente
- [x] Either pattern utilizado

### ❌ Issues Found
- [ ] **BLOCKER**: Component sem OnPush strategy (linha 42)
- [ ] **IMPROVEMENT**: Método muito longo, considerar quebrar (linha 78-150)

### 💡 Suggestions
- Considerar usar computed() ao invés de método no template (linha 23)
- TrackBy function poderia melhorar performance da lista (linha 156)

### 🎯 Verdict
- [ ] Approve
- [x] Request Changes  
- [ ] Comment Only
```

---

**Este checklist deve ser usado sistematicamente em todos os code reviews para garantir consistência e qualidade no projeto OrçaSonhos.**