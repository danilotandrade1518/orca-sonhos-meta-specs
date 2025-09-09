# Visão Arquitetural do Backend

## 1. Visão Geral

Este documento descreve a arquitetura do backend do projeto OrçaSonhos, baseado em Node.js, Express, TypeScript, Clean Architecture e PostgreSQL.
Iremos utilizar alguns conceitos que vêm do DDD, que são:

- Aggregates
- Entities
- Value Objects
- Repositories

Iremos ainda utilizar a ideia central do CQRS.
A ideia aqui é tratar tudo que for mutação de estado em usecases/domain, e tudo que for query em QueryHandlers.
Não teremos inicialmente de forma obrigatória, projeção de views, apenas iremos consultar o banco diretamente pelos QueryHandlers.

## 2. Organização dos Diretórios

- `/src`
  - `/domain` — Agregados, Value Objects globais e regras de negócio
    - `/aggregates` — Cada agregado possui uma pasta própria, contendo suas entidades e value objects específicos
    - `/shared/value-objects` — Value Objects globais, reutilizáveis em todo o domínio
  - `/application/usecases` — Casos de uso (aplicação)
  - `/application/queries` - Query Handlers
  - `/application/contracts` - Interfaces de Repositórios e Serviços
  - `/infra` — Implementações de infraestrutura (banco, serviços externos)
  - `/interfaces/web` - Web controllers
  - `/config` — Configurações gerais do projeto

## 3. Responsabilidades das Camadas

- **Domain:** Agregados, entidades (dentro dos agregados), value objects (globais e específicos) e regras de negócio puras, sem dependências externas.
- **Use Cases:** Orquestram as regras de negócio, coordenando entidades e serviços. Use Cases irão utilizar:
  - **Repositories**: Para operações que salvam APENAS 1 agregado (mais simples)
  - **Unit of Work**: EXCLUSIVAMENTE para operações que salvam MAIS DE 1 agregado ao mesmo tempo
- **Queries:** Tratam views do sistema. Query Handlers normalmente irão utilizar DAO's para acesso ao banco de dados.
- **Web:** Pontos de entrada/saída HTTP, adapta dados para os casos de uso.
- **Infra:** Implementação de repositórios, unit of work, integrações externas, persistência.

### 3.1. Princípio da Granularidade Adequada

#### Repositories: Genéricos por Operação

- **IAddRepository**: Criação de entidades (INSERT)
- **ISaveRepository**: Atualização de entidades (UPDATE)
- **IGetRepository**: Busca por ID específico
- **IFindRepository**: Consultas específicas de negócio
- **IDeleteRepository**: Remoção de entidades (DELETE)

#### Use Cases: Específicos por Regra de Negócio

- **CreateTransactionUseCase**: Criar nova transação
- **MarkTransactionLateUseCase**: Marcar transação como atrasada
- **CancelScheduledTransactionUseCase**: Cancelar transação agendada
- **ReconcileAccountUseCase**: Reconciliar saldo da conta

Esta separação garante que:

- **Repositories** focam apenas em persistência
- **Use Cases** expressam claramente a operação de negócio
- **Entidades** encapsulam as regras de domínio
- **Maior reutilização** e **menor acoplamento**

## 4. Fluxo de Dados

### 4.1 Mutação de Estado

```
[Request] → [Controller] → [UseCase] → [Domain Services] → [Unit of Work] → [Database]
                     ↓
                [Response]
```

1. Uma requisição chega pela camada web (ex: controller Express).
2. O controller chama o caso de uso apropriado.
3. O caso de uso orquestra a operação usando Domain Services e Repositories.
4. Domain Services executam regras de negócio complexas.
5. Unit of Work garante atomicidade quando necessário.
6. Mudanças são persistidas no banco de dados.
7. A resposta retorna pela cadeia até o usuário.

### 4.2 Consultas (View Request)

```
[Request] → [Controller] → [Query Handler] → [DAO] → [Database]
                     ↓
                [Response]
```

1. Uma requisição chega pela camada web (ex: controller Express).
2. O controller chama a query handler apropriada.
3. A query handler consulta o banco através dos DAO's apropriados.
4. A camada de Infra fornece as implementações concretas (ex: acesso ao PostgreSQL através de DAO's).
5. A resposta retorna pela cadeia até o usuário.

## 5. Modelo de Domínio - Agregados do OrçaSonhos

### 5.1. Agregados Principais

O OrçaSonhos é modelado com os seguintes agregados independentes, todos conectados por referências de identidade ao Budget:

#### **Account** (Contas Financeiras)
- **Responsabilidade**: Representar onde o dinheiro está fisicamente armazenado
- **Características**: Saldo calculado, tipos variados (corrente, poupança, carteira)
- **Relacionamentos**: budgetId (referência)
- **Invariantes**: 
  - Saldo deve sempre bater com soma das Transactions
  - Nome único dentro do Budget

#### **Budget** (Orçamento)
- **Responsabilidade**: Container principal, gerenciar participantes e permissões
- **Características**: Lista de participantes (User IDs), configurações gerais
- **Relacionamentos**: Raiz de todos os outros agregados
- **Invariantes**: 
  - Participantes devem ter IDs válidos
  - Operações só podem ser realizadas por participantes autorizados

#### **Category** (Categorias)
- **Responsabilidade**: Classificação de transações e base para envelopes
- **Características**: Nome, tipo (necessidade/estilo de vida/prioridade financeira)
- **Relacionamentos**: budgetId (referência)
- **Invariantes**: Nome único dentro do Budget

#### **CreditCard** (Cartão de Crédito)
- **Responsabilidade**: Master data do cartão (limite, datas de fechamento)
- **Características**: Limite total, data fechamento, data vencimento
- **Relacionamentos**: budgetId (referência)

#### **CreditCardBill** (Fatura do Cartão)
- **Responsabilidade**: Representar fatura específica de um período
- **Características**: Valor total, datas, status (OPEN/CLOSED/PAID/OVERDUE)
- **Relacionamentos**: budgetId, creditCardId (referência)
- **Invariantes**: Valor deve sempre bater com Transactions do cartão no período

#### **Envelope** (Envelope de Gastos)
- **Responsabilidade**: Controlar "dinheiro separado" para gastos por categoria
- **Características**: Saldo próprio, limite de gastos
- **Relacionamentos**: budgetId, categoryId (referência)
- **Invariantes**: Deve estar vinculado a uma Category válida

#### **Goal** (Meta Financeira)
- **Responsabilidade**: Controlar progresso de objetivos financeiros com reserva física
- **Características**: Valor alvo, valor atual, conta de origem dos fundos
- **Relacionamentos**: budgetId, sourceAccountId (referência)
- **Invariantes**: 
  - currentAmount <= targetAmount
  - Account(sourceAccountId) deve ter saldo disponível >= currentAmount
  - Progresso deve ser rastreável via operações de aporte

#### **Transaction** (Transação Financeira)
- **Responsabilidade**: Registrar movimentações financeiras
- **Características**: Valor, data, categoria, status temporal (agendada/realizada/atrasada)
- **Relacionamentos**: budgetId, accountId, categoryId (referências)
- **Invariantes**: 
  - Sempre deve ter Account de destino
  - Valor deve ser > 0
  - Status deve ser consistente com data da transação

### 5.2. Separação de Responsabilidades

- **Budget**: Controle de acesso e participação
- **Account**: Armazenamento físico do dinheiro
- **Goal**: Reserva e rastreamento de objetivos
- **Transaction**: Movimentação e fluxo financeiro
- **CreditCard/CreditCardBill**: Gestão de crédito e faturas
- **Envelope**: Controle de gastos por categoria
- **Category**: Classificação e organização

### 5.3. Modelo de Reservas (Goal ↔ Account)

Goals implementam um modelo de **"reserva 1:1"**:
- Cada Goal aponta para uma única Account (`sourceAccountId`)
- O `currentAmount` da Goal representa quantia reservada daquela Account
- Account calcula: **Saldo Total** vs **Saldo Disponível** (descontando reservas)
- Operações: `AddAmountToGoalUseCase`, `RemoveAmountFromGoalUseCase`

**Operações de Deleção e Transferência:**
- Ao deletar um Account, o Goal vinculado será deletado automaticamente
- Será implementada funcionalidade para transferir Goal para outra Account antes da deleção
- Use Case: `TransferGoalToAccountUseCase` para mover Goal entre Accounts

```typescript
// Exemplo conceitual
class Goal {
  targetAmount: Money;    // Meta a atingir
  currentAmount: Money;   // Valor já reservado
  sourceAccountId: string; // Conta onde está fisicamente
}

class Account {
  balance: Money;                    // Saldo total
  getAvailableBalance(): Money {     // Saldo disponível
    return balance - getTotalReservedForGoals();
  }
}
```

## 6. Estratégia de Queries e Performance

### 6.1. SQL Nativo para Todas as Queries

- **Decisão**: Não utilizaremos ORM para queries
- **Implementação**: SQL nativo via Query Handlers + DAOs
- **Benefícios**: 
  - Performance otimizada para casos específicos
  - Controle total sobre queries complexas
  - Facilita relatórios que cruzam múltiplos agregados

### 6.2. Consultas Complexas

Para relatórios que envolvem múltiplos agregados:
- **Query Handlers específicos** por caso de uso
- **JOINs otimizados** diretamente no SQL
- **Paginação** implementada via LIMIT/OFFSET
- **Views do banco** apenas se necessário para performance

### 6.3. Sem Projeções Iniciais

- Consultas diretas ao banco de dados transacional
- Views materializadas apenas se performance exigir no futuro
- Foco em queries otimizadas via índices e SQL eficiente

## 9. DAO vs Repository

- **Repository:** Representa uma coleção de agregados (entidades) e encapsula regras de negócio relacionadas à persistência. Utilizado principalmente em operações de mutação (criação, atualização, remoção) e segue contratos definidos na camada de domínio.
- **DAO (Data Access Object):** Focado em consultas (queries) e otimizado para leitura de dados. Utilizado em Query Handlers para buscar informações diretamente do PostgreSQL utilizando SQL nativo, podendo retornar dados em formatos específicos para views.

## 8. Autorização e Multi-tenancy

### 8.1. Modelo de Autorização Simplificado

Para o MVP, adotamos um modelo de autorização **flat** por orçamento:
- **Participantes**: Lista de User IDs no agregado Budget
- **Permissões**: Todos os participantes têm **acesso total** ao orçamento
- **Operações**: Qualquer participante pode realizar qualquer ação dentro do orçamento

### 8.2. Multi-tenancy por Budget

- **Usuário pode participar** de múltiplos Budgets
- **Isolamento**: Dados de um Budget não são visíveis em outro
- **Controle**: Budget.participants define quem tem acesso
- **Validação**: Todo Use Case valida se userId está em Budget.participants

### 8.3. Implementação

```typescript
interface IBudgetAuthorizationService {
  canUserAccessBudget(userId: string, budgetId: string): Promise<boolean>;
}

// Uso em Use Cases
class CreateTransactionUseCase {
  async execute(dto: CreateTransactionDto, userId: string) {
    const canAccess = await this.authService.canUserAccessBudget(
      userId, 
      dto.budgetId
    );
    if (!canAccess) throw new UnauthorizedError();
    
    // Prosseguir com a operação...
  }
}
```

### 8.4. Evolução Futura

Modelo atual permite evolução para:
- **Roles diferenciados** (admin, member, viewer)
- **Permissões granulares** por tipo de operação
- **Convites e aprovações** para novos participantes

### 9.1. Padrão Repository Refinado: Separação de Responsabilidades

Para garantir melhor aderência ao **Single Responsibility Principle** e maior clareza arquitetural, adotamos uma separação específica entre diferentes tipos de operações de repository:

#### Add vs Save Repositories

- **IAddRepository**: Interface para **criação** de novos agregados no sistema

  - Utilizado quando se trata de persistir entidades completamente novas
  - Exemplo: `IAddTransactionRepository` para criar novas transações
  - Use Cases típicos: `CreateTransactionUseCase`, `CreateAccountUseCase`

- **ISaveRepository**: Interface para **atualização** de agregados existentes
  - Utilizado quando se trata de modificar o estado de entidades já persistidas
  - Exemplo: `ISaveTransactionRepository` para atualizar transações existentes
  - Use Cases típicos: `MarkTransactionLateUseCase`, `CancelScheduledTransactionUseCase`

#### Exemplo de Implementação

```typescript
// Interface para criação de novas transações
export interface IAddTransactionRepository {
  execute(transaction: Transaction): Promise<Either<RepositoryError, void>>;
}

// Interface para atualização de transações existentes
export interface ISaveTransactionRepository {
  execute(transaction: Transaction): Promise<Either<RepositoryError, void>>;
}

// Use Case de criação utiliza Add Repository
export class CreateTransactionUseCase {
  constructor(
    private readonly addTransactionRepository: IAddTransactionRepository,
  ) {}

  async execute(dto: CreateTransactionDto) {
    const transaction = Transaction.create(dto);
    await this.addTransactionRepository.execute(transaction);
    // ... resto da implementação
  }
}

// Use Case de atualização utiliza Save Repository
export class MarkTransactionLateUseCase {
  constructor(
    private readonly getTransactionRepository: IGetTransactionRepository,
    private readonly saveTransactionRepository: ISaveTransactionRepository,
  ) {}

  async execute(dto: MarkTransactionLateDto) {
    const transaction = await this.getTransactionRepository.execute(
      dto.transactionId,
    );
    transaction.markAsLate();
    await this.saveTransactionRepository.execute(transaction);
    // ... resto da implementação
  }
}
```

#### Vantagens da Separação

1. **Clareza de Intenção**: Fica explícito se a operação é de criação ou atualização
2. **Single Responsibility**: Cada interface tem uma responsabilidade específica
3. **Testabilidade**: Stubs de teste mais específicos e focados
4. **Evolução**: Permite implementações diferentes para criação vs atualização se necessário
5. **Documentação Viva**: O código serve como documentação da intenção arquitetural

#### Repositórios de Consulta

- **IGetRepository**: Interface para busca de agregados específicos
  - Exemplo: `IGetTransactionRepository`, `IGetAccountRepository`
  - Retorna entidades completas do domínio
- **IFindRepository**: Interface para consultas específicas de negócio
  - Exemplo: `IFindTransactionRepository`
  - Pode retornar listas filtradas ou consultas complexas

Esta organização garante que cada repository tenha uma responsabilidade bem definida e que os Use Cases expressem claramente suas intenções através dos tipos de repository que utilizam.

### 9.2. Diretrizes Importantes

#### ⚠️ EVITAR: Repositories de Mutação Específicos

Não crie repositories para operações específicas de domínio:

```typescript
// ❌ EVITAR - Repository muito específico
export interface IMarkTransactionLateRepository {
  execute(transactionId: string): Promise<Either<RepositoryError, void>>;
}

// ❌ EVITAR - Repository assumindo lógica de domínio
export interface ICancelScheduledTransactionRepository {
  execute(
    transactionId: string,
    reason: string,
  ): Promise<Either<RepositoryError, void>>;
}
```

**Problemas:**

- Explosão de interfaces para cada operação específica
- Repository assumindo responsabilidades de domínio
- Violação do Single Responsibility Principle
- Dificuldade de manutenção e teste

#### ✅ PREFERIR: Use Cases Específicos + Repositories Genéricos

```typescript
// ✅ CORRETO: Use Case específico + Repositories genéricos
export class MarkTransactionLateUseCase {
  constructor(
    private readonly getTransactionRepository: IGetTransactionRepository,
    private readonly saveTransactionRepository: ISaveTransactionRepository,
  ) {}

  async execute(dto: MarkTransactionLateDto) {
    const transaction = await this.getTransactionRepository.execute(
      dto.transactionId,
    );
    transaction.markAsLate(); // ← Regra de domínio na entidade
    await this.saveTransactionRepository.execute(transaction); // ← Persistência genérica
  }
}
```

**Vantagens:**

- Repositories focados apenas em persistência
- Use Cases expressam claramente a operação de negócio
- Entidades encapsulam as regras de domínio
- Maior reutilização e menor acoplamento

## 10. Unit of Work Pattern

### 10.1. Conceito

O padrão **Unit of Work** mantém uma lista de objetos afetados por uma transação de negócio e coordena a escrita das mudanças, resolvendo problemas de concorrência. Em nosso contexto, é especialmente útil para operações que envolvem múltiplos agregados ou múltiplas operações que devem ser executadas atomicamente.

### 10.2. Quando Utilizar

O Unit of Work deve ser utilizado **EXCLUSIVAMENTE** em cenários onde é necessário salvar **MAIS DE 1 AGREGADO** ao mesmo tempo, garantindo atomicidade entre as operações:

- **Múltiplos Agregados**: Quando a operação envolve modificações em diferentes agregados que precisam ser consistentes
- **Operações de Transferência**: Como transferências entre contas, que envolvem débito em uma conta e crédito em outra
- **Operações Atômicas Complexas**: Quando uma operação de negócio requer múltiplas escritas no banco que devem ser executadas como uma única transação
- **Rollback Automático**: Quando é necessário garantir que falhas em qualquer etapa revertam todas as operações

### 10.3. Quando NÃO Utilizar - REGRA FUNDAMENTAL

**SEMPRE que for necessário salvar APENAS 1 AGREGADO, utilize Repository que é mais simples.**

Evite Unit of Work quando:

- **Operações com Um Único Agregado**: Para operações que envolvem apenas um agregado (use Repository diretamente)
- **Apenas Leitura**: Para operações de consulta (use Query Handlers)
- **Operações Independentes**: Quando não há necessidade de atomicidade entre operações
- **CRUD Simples**: Criação, atualização ou remoção de uma única entidade

### 10.4. Implementação

#### Interface Base

```typescript
export interface IUnitOfWork {
  executeTransfer(
    params: TransferParams,
  ): Promise<Either<TransferExecutionError, void>>;
}
```

#### Implementação Concreta

```typescript
export class TransferBetweenAccountsUnitOfWork implements IUnitOfWork {
  private saveAccountRepository: SaveAccountRepository;
  private addTransactionRepository: AddTransactionRepository;

  constructor(private postgresConnectionAdapter: IPostgresConnectionAdapter) {
    this.saveAccountRepository = new SaveAccountRepository(
      postgresConnectionAdapter,
    );
    this.addTransactionRepository = new AddTransactionRepository(
      postgresConnectionAdapter,
    );
  }

  async executeTransfer(
    params: TransferParams,
  ): Promise<Either<TransferExecutionError, void>> {
    let client: IDatabaseClient | undefined;

    try {
      // 1. Obter conexão e iniciar transação
      client = await this.postgresConnectionAdapter.getClient();
      await client.beginTransaction();

      // 2. Executar operações usando a mesma conexão
      const saveFromResult = await this.saveAccountRepository.executeWithClient(
        client,
        params.fromAccount,
      );
      if (saveFromResult.hasError)
        throw new Error('Failed to save source account');

      const saveToResult = await this.saveAccountRepository.executeWithClient(
        client,
        params.toAccount,
      );
      if (saveToResult.hasError)
        throw new Error('Failed to save target account');

      const addDebitResult =
        await this.addTransactionRepository.executeWithClient(
          client,
          params.debitTransaction,
        );
      if (addDebitResult.hasError)
        throw new Error('Failed to add debit transaction');

      const addCreditResult =
        await this.addTransactionRepository.executeWithClient(
          client,
          params.creditTransaction,
        );
      if (addCreditResult.hasError)
        throw new Error('Failed to add credit transaction');

      // 3. Commit da transação
      await client.commitTransaction();
      return Either.success(undefined);
    } catch (error) {
      // 4. Rollback em caso de erro
      if (client) {
        try {
          await client.rollbackTransaction();
        } catch (rollbackError) {
          // Log rollback error but don't mask original error
        }
      }
      return Either.error(new TransferExecutionError(error.message, error));
    }
  }
}
```

### 10.5. Integração com Repositories

Os repositories devem suportar execução com client específico para trabalhar com Unit of Work:

```typescript
export class SaveAccountRepository {
  constructor(private postgresConnectionAdapter: IPostgresConnectionAdapter) {}

  // Método padrão (obtém própria conexão)
  async execute(account: Account): Promise<Either<RepositoryError, void>> {
    const client = await this.postgresConnectionAdapter.getClient();
    return this.executeWithClient(client, account);
  }

  // Método para Unit of Work (usa conexão fornecida)
  async executeWithClient(
    client: IDatabaseClient,
    account: Account,
  ): Promise<Either<RepositoryError, void>> {
    try {
      const accountDto = AccountMapper.domainToDto(account);
      await client.query(UPDATE_ACCOUNT_QUERY, [
        accountDto.name,
        accountDto.accountType,
        accountDto.id,
      ]);
      return Either.success(undefined);
    } catch (error) {
      return Either.error(new RepositoryError('Failed to save account', error));
    }
  }
}
```

### 10.6. Uso em Use Cases

```typescript
export class TransferBetweenAccountsUseCase {
  constructor(
    private unitOfWork: TransferBetweenAccountsUnitOfWork,
    private accountRepository: GetAccountRepository,
  ) {}

  async execute(
    dto: TransferBetweenAccountsDto,
  ): Promise<Either<ApplicationError, void>> {
    // 1. Buscar contas
    const fromAccount = await this.accountRepository.execute(dto.fromAccountId);
    const toAccount = await this.accountRepository.execute(dto.toAccountId);

    // 2. Aplicar regras de negócio
    fromAccount.debit(dto.amount);
    toAccount.credit(dto.amount);

    // 3. Criar transações
    const debitTransaction = Transaction.createDebit(/* ... */);
    const creditTransaction = Transaction.createCredit(/* ... */);

    // 4. Executar com Unit of Work
    const result = await this.unitOfWork.executeTransfer({
      fromAccount,
      toAccount,
      debitTransaction,
      creditTransaction,
    });

    return result;
  }
}
```

### 10.7. Vantagens

- **Atomicidade**: Garante que todas as operações sejam executadas ou nenhuma
- **Consistência**: Mantém o estado consistente mesmo em operações complexas
- **Isolamento**: Usa transações de banco para garantir isolamento
- **Rollback Automático**: Falhas em qualquer etapa revertem toda a operação
- **Reutilização**: Unit of Works podem ser reutilizados em diferentes Use Cases

### 10.8. Organização no Projeto

```
/src/infrastructure/database/pg/unit-of-works/
├── transfer-between-accounts/
│   ├── TransferBetweenAccountsUnitOfWork.ts
│   └── TransferBetweenAccountsUnitOfWork.spec.ts
└── bulk-transaction-import/
    ├── BulkTransactionImportUnitOfWork.ts
    └── BulkTransactionImportUnitOfWork.spec.ts
```

### 10.9. Testes

Unit of Works devem ter cobertura completa de testes, incluindo:

- **Cenários de Sucesso**: Verificação de execução completa
- **Cenários de Falha**: Simulação de falhas em cada etapa
- **Rollback**: Verificação de rollback automático
- **Ordem de Execução**: Validação da sequência correta das operações

```typescript
describe('TransferBetweenAccountsUnitOfWork', () => {
  it('should execute transfer successfully', async () => {
    // Arrange
    mockSaveAccountRepository.executeWithClient.mockResolvedValue(
      Either.success(undefined),
    );
    mockAddTransactionRepository.executeWithClient.mockResolvedValue(
      Either.success(undefined),
    );

    // Act
    const result = await unitOfWork.executeTransfer(transferParams);

    // Assert
    expect(result.hasError).toBe(false);
    expect(mockClient.commitTransaction).toHaveBeenCalled();
  });

  it('should rollback when repository fails', async () => {
    // Arrange
    mockSaveAccountRepository.executeWithClient.mockResolvedValueOnce(
      Either.error(new RepositoryError('Database error')),
    );

    // Act
    const result = await unitOfWork.executeTransfer(transferParams);

    // Assert
    expect(result.hasError).toBe(true);
    expect(mockClient.rollbackTransaction).toHaveBeenCalled();
  });
});
```

## 11. Padrões de Nomenclatura

- Classes: PascalCase (ex: `CriarUsuarioUseCase`, `UsuarioRepository`)
- Arquivos: PascalCase (ex: `CriarUsuarioUseCase.ts`, `UsuarioRepository.ts`)
- Métodos: camelCase (ex: `criarUsuario`, `buscarPorId`, `handle`)
- Pastas: kebab-case (ex: `usecases`, `queries`, `infra`, `unit-of-works`)
- Interfaces: prefixo `I` (ex: `IUsuarioRepository`)
- Unit of Work: sufixo `UnitOfWork` (ex: `TransferBetweenAccountsUnitOfWork`, `BulkTransactionImportUnitOfWork`)

## 12. Tratamento de Erros

O tratamento de erros será realizado utilizando o padrão `Either`, evitando o uso de `throw/try/catch` exceto em situações explicitamente necessárias (ex: falhas inesperadas). Os métodos retornarão objetos do tipo `Either<Erro, Sucesso>`, facilitando o controle de fluxo e a previsibilidade dos resultados.

## 13. Padrão de Imports e Path Alias

Para manter a organização e a clareza do projeto, adotaremos o seguinte padrão para imports:

- **Path Alias:** Devem ser utilizados apenas para importar arquivos entre diferentes camadas (por exemplo, importar algo da camada `domain` para a camada `application`).
- **Imports Relativos:** Devem ser utilizados para importar arquivos dentro da mesma camada (por exemplo, entre arquivos dentro de `usecases`, ou entre arquivos dentro de `aggregates`).

Este padrão visa facilitar a navegação, evitar ciclos de dependência e reforçar a separação entre as camadas da arquitetura.

## 14. Padrão de Ordenação de Métodos em Classes

Para manter a legibilidade e padronização do código, todas as classes devem seguir a seguinte ordem de declaração de métodos:

1. Métodos públicos (incluindo getters/setters)
2. Métodos estáticos
3. Métodos privados

Este padrão deve ser seguido em todas as classes do domínio, value objects, entidades, use cases, etc.

## 15. Organização dos Testes

Os testes devem ser organizados seguindo a mesma estrutura do código de produção, mantendo a proximidade com o código testado:

- **Testes Unitários:** Devem ser colocados na mesma pasta do arquivo testado, com o sufixo `.spec.ts`

  - Exemplo: `src/domain/aggregates/budget/Budget.ts` → `src/domain/aggregates/budget/Budget.spec.ts`
  - Exemplo: `src/domain/shared/value-objects/Money.ts` → `src/domain/shared/value-objects/Money.spec.ts`

- **Testes de Integração:** Devem ser colocados em uma pasta `__tests__` dentro do módulo testado

  - Exemplo: `src/application/usecases/__tests__/CreateBudgetUseCase.spec.ts`

- **Testes E2E:** Devem ser colocados em uma pasta `__tests__` na raiz do projeto
  - Exemplo: `src/__tests__/e2e/budget.spec.ts`

Esta organização visa:

- Manter os testes próximos ao código testado
- Facilitar a manutenção e localização dos testes
- Seguir o princípio de coesão e acoplamento
- Manter a consistência com a arquitetura do projeto

---

**Este documento deve ser atualizado conforme a arquitetura evoluir. Todo o código do projeto será escrito em Inglês.**

## 16. Padrão de Endpoints para Mutations (Decisão de API Command-Style)

### 16.1. Motivação

Adotamos um modelo de domínio rico (DDD) com agregados, invariantes e regras explícitas em Use Cases. A tentativa de expressar estas operações via REST puro (verbs + resources canônicos) resultaria em:

- Ambiguidade ou sobrecarga de verbos HTTP para operações específicas (ex: `mark-transaction-late`, `cancel-scheduled-transaction`, `transfer-between-envelopes`).
- Necessidade de múltiplos endpoints PATCH/PUT semanticamente distintos sobre o mesmo recurso.
- Maior risco de "anemic domain" ao tentar forçar operações complexas dentro de CRUD genérico.

Para preservar a clareza de intenção e alinhar com o modelo Command (próximo de CQRS), adotamos um estilo orientado a comandos para mutações.

### 16.2. Padrão Definido

- **Todos os endpoints de mutação usam HTTP POST.**
- **Formato da rota:** `/<aggregate|context>/<action-name>`
  - Exemplos:
    - `POST /budget/create-budget`
    - `POST /transaction/mark-transaction-late`
    - `POST /credit-card-bill/pay-credit-card-bill`
    - `POST /envelope/transfer-between-envelopes`
- O nome da ação reflete diretamente o caso de uso (classe do UseCase) com kebab-case.
- Request Body segue o DTO do Use Case. Response segue o `UseCaseResponse` encapsulado pelo `DefaultResponseBuilder`.

### 16.3. Escopo

Esta convenção aplica-se exclusivamente a operações de **mutação** (commands). Consultas (queries) poderão futuramente adotar um padrão distinto (ex: GET com filtros ou um endpoint `/query` específico) mantendo a separação CQRS.

### 16.4. Benefícios

| Aspecto                     | Benefício                                                               |
| --------------------------- | ----------------------------------------------------------------------- |
| Clareza semântica           | Cada endpoint comunica explicitamente a intenção do caso de uso         |
| Evolução                    | Facilita adicionar novas operações sem quebrar contratos REST genéricos |
| Alinhamento DDD             | Mantém o ubiquitous language entre domínio e interface                  |
| Simplicidade de Autorização | Policies podem mapear 1:1 para ações                                    |
| Consistência de Erros       | `Either` + `DefaultResponseBuilder` padronizados                        |

### 16.5. Trade-offs / Consequências

- Menos aderente a expectativas REST puras / ferramentas automáticas de geração.
- Pode exigir documentação mais explícita (OpenAPI, Swagger já adaptado).
- Aumento potencial de número de endpoints (um por ação) — mitigado por agrupamento por contexto.

### 16.6. Convenções de Nome

- `create-`, `update-`, `delete-` para CRUD direto.
- Verbos de negócio específicos (`mark-`, `pay-`, `reopen-`, `transfer-between-`, `add-amount-`, `remove-amount-`).
- Kebab-case sempre; evitar abreviações obscuras.

### 16.7. Idempotência

- Operações naturalmente idempotentes (ex: `reopen-credit-card-bill` dentro da janela válida) devem continuar seguras a reenvio — a lógica de domínio garante consistência.
- Para comandos não idempotentes (ex: `pay-credit-card-bill`) podem ser futuramente suportados headers como `Idempotency-Key` se necessário.

### 16.8. Versionamento Futuro

- Caso surja necessidade: prefixo opcional `/v1/` manteve-se adiado até primeira ruptura.
- Evoluções breaking criam novo action name OU novo namespace (`/v2/transaction/...`).

### 16.9. Autorização

- Autorização é aplicada por serviço (`IBudgetAuthorizationService`) no Use Case; camada HTTP não contém lógica de permissão.
- A consistência do verbo único (POST) reduz matriz de permissão ao par (contexto, ação).

### 16.10. Referência

- Decisão formalizada na ADR: `0008-padrao-endpoints-mutations-post-comando.md`.

---

> Esta seção será revisitada quando introduzirmos query endpoints especializados ou se adotarmos GraphQL / gRPC para leitura.

## 17. Fluxo de Autenticação SPA (Firebase Authentication)

### 17.1. Decisão

Adotaremos **Firebase Authentication** como provedor de identidade com fluxo **redirect-based** para SPAs. O backend permanecerá totalmente **stateless** em relação à sessão do usuário, recebendo apenas o **Bearer ID Token** no header `Authorization` em cada requisição autenticada.

### 17.2. Motivação

1. **Simplicidade**: Firebase Auth simplifica integração e gerenciamento de usuários.
2. **Redução de complexidade**: Sem necessidade de gerenciar fluxos OAuth/OIDC complexos.
3. **Múltiplos provedores**: Suporte nativo a Google, email/senha e outros provedores.
4. **SDK robusto**: Bibliotecas maduras para Angular e Node.js.
5. **Escalabilidade**: Infraestrutura gerenciada pelo Google.

### 17.3. Fluxo Resumido

1. **Frontend**: Usuário faz login via Firebase Auth SDK (Google OAuth redirect).
2. **Frontend**: Firebase retorna ID Token JWT após autenticação bem-sucedida.
3. **Frontend**: ID Token armazenado apenas em memória (não `localStorage`).
4. **Backend**: Em cada requisição, valida ID Token via Firebase Admin SDK.
5. **Backend**: Extrai `uid` do token validado para identificar usuário.
6. **Endpoint `/me`**: Retorna dados do usuário ou anônimo se token ausente.

### 17.4. Não teremos inicialmente

- Sessão HTTP server-side (cookies de sessão, redis, etc.).
- Endpoints `/auth/login`, `/auth/callback`, `/auth/logout` no backend.
- Armazenamento de refresh token no backend.
- Múltiplos provedores (apenas Google inicialmente).

### 17.5. Configuração Firebase

**Frontend:**
- Firebase SDK v10+ com modular imports
- Configuração via environment variables
- `browserSessionPersistence` para evitar persistência local
- `onIdTokenChanged` listener para token updates

**Backend:**
- Firebase Admin SDK para validação de tokens
- Service Account key via environment variables
- Validação automática de issuer, audience, signature

### 17.6. Logout

O logout consiste em:
1. Frontend chama `firebase.auth().signOut()`
2. Frontend limpa token da memória
3. Backend não precisa invalidar nada (stateless)
4. Tokens expiram naturalmente (TTL configurável no Firebase)

### 17.7. Token Management

**Renovação Automática:**
- Firebase SDK renova tokens automaticamente
- `onIdTokenChanged` listener atualiza token em memória
- Refresh tokens gerenciados pelo SDK (não expostos ao app)

**Armazenamento:**
- **ID Token**: Apenas em memória no frontend
- **Refresh Token**: Gerenciado automaticamente pelo Firebase SDK
- **Fallback**: Re-login via redirect se token expirado

### 17.8. Requisitos de Segurança no Backend

**Validação via Firebase Admin SDK:**
- Signature verification automática
- Issuer (`https://securetoken.google.com/PROJECT_ID`)
- Audience (Firebase Project ID)
- Expiration (`exp`) e Not Before (`nbf`)
- UID extraction via `decodedToken.uid`

**Segurança Adicional:**
- CORS restrito a domínios conhecidos
- Rate limiting para endpoints críticos
- Métricas de falhas de autenticação

### 17.9. Implementação Backend

```typescript
// Firebase Admin SDK setup
import { initializeApp, cert } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

const adminApp = initializeApp({
  credential: cert({
    projectId: process.env.FIREBASE_PROJECT_ID,
    privateKey: process.env.FIREBASE_PRIVATE_KEY,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL
  })
});

// Token validation middleware
export async function verifyFirebaseToken(token: string): Promise<string> {
  try {
    const decodedToken = await getAuth(adminApp).verifyIdToken(token);
    return decodedToken.uid; // userId para o sistema
  } catch (error) {
    throw new UnauthorizedError('Invalid Firebase token');
  }
}
```

### 17.10. Formato de Requisições Autenticadas

Header obrigatório: `Authorization: Bearer <firebase_id_token>`.

**Responses de Erro:**
- Token ausente/malformado → `401 { code: 'AUTH_MISSING' }`
- Token inválido/expirado → `401 { code: 'AUTH_INVALID' }`
- Token válido mas sem permissão → `403 { code: 'FORBIDDEN' }`

### 17.11. Configuração de Ambiente

**Frontend:**
```typescript
// firebase.config.ts
export const firebaseConfig = {
  apiKey: process.env['FIREBASE_API_KEY'],
  authDomain: `${process.env['FIREBASE_PROJECT_ID']}.firebaseapp.com`,
  projectId: process.env['FIREBASE_PROJECT_ID'],
  appId: process.env['FIREBASE_APP_ID']
};
```

**Backend:**
```bash
FIREBASE_PROJECT_ID=orcasonhos-prod
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n..."
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxx@orcasonhos-prod.iam.gserviceaccount.com
```

### 17.12. Evolução Futura

| Necessidade | Implementação | Notas |
|-------------|---------------|-------|
| **Múltiplos provedores** | Habilitar email/senha, Facebook, etc. | Via console Firebase |
| **Custom claims** | Firebase Admin SDK para roles/permissions | Para autorização granular |
| **Session cookies** | `createSessionCookie()` para maior segurança | Se precisar de persistência |
| **Multi-tenant** | Firebase Auth multi-tenancy | Para orçamentos isolados |

### 17.13. Referências

- [Firebase Auth Documentation](https://firebase.google.com/docs/auth)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
- [Angular Fire](https://github.com/angular/angularfire)

### 17.14. Status

Implementação ativa. Firebase simplifica autenticação mantendo backend stateless e seguro.

## 18. Domain Services Pattern

### 18.1. Conceito

**Domain Services** são serviços que encapsulam operações de domínio que não pertencem naturalmente a uma única entidade. Eles coordenam operações complexas que envolvem múltiplas entidades, aplicam regras de negócio específicas e criam objetos derivados necessários para completar uma operação de domínio.

### 18.2. Quando Utilizar Domain Services

Domain Services devem ser utilizados quando:

#### ✅ Operações Complexas Entre Entidades
- **Coordenação de múltiplas entidades**: Quando uma operação envolve regras que abrangem mais de uma entidade
- **Validações cruzadas**: Quando é necessário validar relações entre diferentes agregados
- **Criação de objetos derivados**: Quando a operação gera múltiplas entidades relacionadas

#### ✅ Lógica de Domínio que não Pertence a uma Entidade
- **Regras de negócio específicas**: Operações que têm regras próprias mas não são responsabilidade de uma única entidade
- **Cálculos complexos**: Algoritmos que precisam de dados de múltiplas fontes
- **Transformações especializadas**: Conversões ou mapeamentos específicos do domínio

### 18.3. Exemplos Práticos da Aplicação

#### 18.3.1. PayCreditCardBillDomainService

**Localização**: `src/domain/aggregates/credit-card-bill/services/PayCreditCardBillDomainService.ts:15`

```typescript
export class PayCreditCardBillDomainService {
  createPaymentOperation(
    bill: CreditCardBill,
    account: Account,
    budgetId: string,
    amount: number,
    paidBy: string,
    paidAt: Date = new Date(),
    paymentCategoryId: string,
  ): Either<DomainError, { debitTransaction: Transaction }> {
    // 1. Validações cruzadas entre entidades
    const validationResult = this.canPayBill(bill, account, budgetId, amount);
    
    // 2. Criação de entidade derivada (Transaction)
    const debitTransaction = Transaction.create({
      accountId: account.id,
      categoryId: paymentCategoryIdVO.value!.id,
      budgetId: account.budgetId!,
      amount: amount,
      type: TransactionTypeEnum.EXPENSE,
      transactionDate: paidAt,
      description: `Pagamento fatura cartão - ${bill.id}`,
    });

    // 3. Aplicação de regra específica na entidade
    const billMarkResult = bill.markAsPaid();

    return Either.success({ debitTransaction: debitTransactionResult.data! });
  }
}
```

**Por que é um Domain Service:**
- Coordena operações entre `CreditCardBill`, `Account` e cria `Transaction`
- Aplica regras de negócio específicas para pagamento de faturas
- Não pertence naturalmente a nenhuma das entidades individualmente

#### 18.3.2. TransferBetweenAccountsDomainService

**Localização**: `src/domain/aggregates/account/services/TransferBetweenAccountsDomainService.ts:11`

```typescript
export class TransferBetweenAccountsDomainService {
  createTransferOperation(
    fromAccount: Account,
    toAccount: Account,
    amount: number,
    transferCategoryId: string,
  ): Either<DomainError, {
    debitTransaction: Transaction;
    creditTransaction: Transaction;
  }> {
    // 1. Validações entre múltiplas contas
    const validationResult = this.canTransfer(fromAccount, toAccount, amount);
    
    // 2. Criação de transações relacionadas
    const debitTransaction = Transaction.create({
      // Débito da conta origem
    });
    
    const creditTransaction = Transaction.create({
      // Crédito da conta destino
    });

    return Either.success({
      debitTransaction: debitTransactionResult.data!,
      creditTransaction: creditTransactionResult.data!,
    });
  }
}
```

**Por que é um Domain Service:**
- Coordena operações entre duas `Account` entities
- Cria duas `Transaction` entities relacionadas atomicamente
- Implementa regras específicas de transferência que não pertencem a uma única conta

### 18.4. Quando NÃO Utilizar Domain Services

#### ❌ Operações Simples de uma Entidade
```typescript
// ❌ EVITAR - Operação simples que deveria estar na entidade
export class UpdateAccountNameDomainService {
  updateName(account: Account, newName: string) {
    account.updateName(newName); // Deveria ser account.updateName() diretamente
  }
}
```

#### ❌ Lógica de Aplicação
```typescript
// ❌ EVITAR - Lógica de orquestração que deveria estar no Use Case
export class CreateAccountDomainService {
  createAccount(dto: CreateAccountDto) {
    // Buscar dados
    // Validar autorização
    // Criar account
    // Salvar no repositório
    // ^ Estas são responsabilidades do Use Case, não do Domain Service
  }
}
```

#### ❌ Acesso a Infraestrutura
```typescript
// ❌ EVITAR - Domain Service não deve acessar repositórios diretamente
export class TransferDomainService {
  constructor(private accountRepository: IAccountRepository) {} // ❌ Violação da camada
  
  transfer(fromId: string, toId: string) {
    const fromAccount = await this.accountRepository.getById(fromId); // ❌ Infra no Domain
  }
}
```

### 18.5. Padrões de Implementação

#### 18.5.1. Estrutura Padrão
```typescript
export class [Operation]DomainService {
  // Método principal público
  create[Operation]Operation(
    // Entidades já hidratadas
    // Parâmetros primitivos necessários
  ): Either<DomainError, ResultType> {
    // 1. Validações cruzadas
    const validation = this.can[Operation](...);
    if (validation.hasError) return validation;

    // 2. Aplicar regras de negócio
    // 3. Criar entidades derivadas se necessário
    // 4. Aplicar mudanças nas entidades existentes

    return Either.success(result);
  }

  // Métodos de validação privados
  private can[Operation](...): Either<DomainError, void> {
    // Lógica de validação
  }
}
```

#### 18.5.2. Retorno Consistente
- **Sempre usar `Either<DomainError, T>`** para tratamento de erros
- **Retornar objetos criados** que serão usados pelo Use Case
- **Não persistir dados** - isso é responsabilidade do Use Case + Repository/UnitOfWork

#### 18.5.3. Validações
- **Método privado `can[Operation]`** para validações específicas
- **Validar invariantes** entre entidades
- **Retornar erros de domínio específicos** quando violações ocorrerem

### 18.6. Integração com Use Cases

Domain Services são **chamados pelos Use Cases**, nunca o contrário:

```typescript
export class PayCreditCardBillUseCase {
  constructor(
    private payCreditCardBillDomainService: PayCreditCardBillDomainService,
    private getBillRepository: IGetCreditCardBillRepository,
    private getAccountRepository: IGetAccountRepository,
    private addTransactionRepository: IAddTransactionRepository,
    private saveBillRepository: ISaveCreditCardBillRepository,
  ) {}

  async execute(dto: PayCreditCardBillDto): Promise<Either<ApplicationError, void>> {
    // 1. Use Case busca entidades (responsabilidade de orquestração)
    const bill = await this.getBillRepository.execute(dto.billId);
    const account = await this.getAccountRepository.execute(dto.accountId);

    // 2. Use Case chama Domain Service (responsabilidade de regras de negócio)
    const operationResult = this.payCreditCardBillDomainService.createPaymentOperation(
      bill.data!,
      account.data!,
      dto.budgetId,
      dto.amount,
      dto.paidBy,
      dto.paidAt,
      dto.paymentCategoryId,
    );

    if (operationResult.hasError) {
      return Either.errors(operationResult.errors);
    }

    // 3. Use Case persiste resultado (responsabilidade de infraestrutura)
    await this.addTransactionRepository.execute(operationResult.data!.debitTransaction);
    await this.saveBillRepository.execute(bill.data!);

    return Either.success(undefined);
  }
}
```

### 18.7. Organização no Projeto

```
/src/domain/aggregates/[aggregate-name]/services/
├── [Operation]DomainService.ts
└── [Operation]DomainService.spec.ts
```

**Exemplos:**
- `src/domain/aggregates/credit-card-bill/services/PayCreditCardBillDomainService.ts`
- `src/domain/aggregates/account/services/TransferBetweenAccountsDomainService.ts`

### 18.8. Testes

Domain Services devem ter cobertura completa incluindo:

- **Cenários de sucesso** com diferentes combinações de entidades
- **Cenários de falha** para cada validação implementada
- **Casos limite** e edge cases das regras de negócio
- **Isolamento** através de mocks das entidades quando necessário

```typescript
describe('PayCreditCardBillDomainService', () => {
  it('should create payment operation successfully', () => {
    // Arrange: Preparar entidades válidas
    const bill = CreditCardBill.create(validBillData);
    const account = Account.create(validAccountData);

    // Act: Executar operação
    const result = domainService.createPaymentOperation(
      bill, account, budgetId, amount, paidBy, paidAt, categoryId
    );

    // Assert: Verificar resultado e efeitos colaterais
    expect(result.hasError).toBe(false);
    expect(result.data!.debitTransaction).toBeDefined();
    expect(bill.status).toBe(BillStatusEnum.PAID);
  });

  it('should fail when bill is already paid', () => {
    // Arrange: Bill já paga
    const bill = CreditCardBill.create(paidBillData);

    // Act & Assert
    const result = domainService.createPaymentOperation(/* ... */);
    expect(result.hasError).toBe(true);
  });
});
```

### 18.9. Princípios e Boas Práticas

#### ✅ Faça
- **Mantenha puro**: Sem efeitos colaterais de I/O ou persistência
- **Foque no domínio**: Apenas regras de negócio e coordenação de entidades
- **Use Either**: Para tratamento consistente de erros
- **Nomeação clara**: `[Operation]DomainService` expressa a intenção
- **Validações explícitas**: Métodos privados para cada tipo de validação

#### ❌ Evite
- **Acesso à infraestrutura**: Repositories, APIs externas, banco de dados
- **Lógica de aplicação**: Orquestração de Use Cases ou workflows
- **Criação excessiva**: Nem toda operação precisa de um Domain Service
- **Estados**: Domain Services devem ser stateless
- **Dependências circulares**: Entre Domain Services ou com entidades

### 18.10. Vantagens

- **Separação clara** de responsabilidades entre entidades, domain services e use cases
- **Reutilização** de lógica complexa entre diferentes Use Cases
- **Testabilidade** isolada das regras de negócio
- **Expressividade** do modelo de domínio
- **Manutenibilidade** através de responsabilidades bem definidas

Esta seção completa a documentação dos padrões de Domain Services na aplicação OrçaSonhos, fornecendo diretrizes claras sobre quando e como utilizá-los efetivamente.
