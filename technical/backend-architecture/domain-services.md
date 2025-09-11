# Domain Services Pattern

## Conceito

**Domain Services** são serviços que encapsulam operações de domínio que não pertencem naturalmente a uma única entidade. Eles coordenam operações complexas que envolvem múltiplas entidades, aplicam regras de negócio específicas e criam objetos derivados necessários para completar uma operação de domínio.

## Quando Utilizar Domain Services

### ✅ Use Domain Services quando:

#### Operações Complexas Entre Entidades
- **Coordenação de múltiplas entidades**: Quando uma operação envolve regras que abrangem mais de uma entidade
- **Validações cruzadas**: Quando é necessário validar relações entre diferentes agregados  
- **Criação de objetos derivados**: Quando a operação gera múltiplas entidades relacionadas

#### Lógica de Domínio que não Pertence a uma Entidade
- **Regras de negócio específicas**: Operações que têm regras próprias mas não são responsabilidade de uma única entidade
- **Cálculos complexos**: Algoritmos que precisam de dados de múltiplas fontes
- **Transformações especializadas**: Conversões ou mapeamentos específicos do domínio

## Exemplos Práticos da Aplicação

### PayCreditCardBillDomainService

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
    if (validationResult.hasError) {
      return validationResult;
    }
    
    // 2. Criação de entidade derivada (Transaction)
    const debitTransaction = Transaction.create({
      accountId: account.id,
      categoryId: paymentCategoryId,
      budgetId: budgetId,
      amount: amount,
      type: TransactionTypeEnum.EXPENSE,
      transactionDate: paidAt,
      description: `Pagamento fatura cartão - ${bill.id}`,
    });

    // 3. Aplicação de regra específica na entidade
    const billMarkResult = bill.markAsPaid();
    if (billMarkResult.hasError) {
      return Either.error(billMarkResult.errors);
    }

    return Either.success({ debitTransaction: debitTransaction });
  }

  private canPayBill(
    bill: CreditCardBill,
    account: Account, 
    budgetId: string,
    amount: number
  ): Either<DomainError, void> {
    // Validações específicas para pagamento de fatura
    if (bill.budgetId !== budgetId) {
      return Either.error(new DomainError('Bill does not belong to budget'));
    }
    
    if (account.budgetId !== budgetId) {
      return Either.error(new DomainError('Account does not belong to budget'));
    }
    
    if (bill.status === BillStatusEnum.PAID) {
      return Either.error(new DomainError('Bill is already paid'));
    }
    
    if (account.availableBalance < amount) {
      return Either.error(new DomainError('Insufficient account balance'));
    }
    
    return Either.success(undefined);
  }
}
```

**Por que é um Domain Service:**
- Coordena operações entre `CreditCardBill`, `Account` e cria `Transaction`
- Aplica regras de negócio específicas para pagamento de faturas
- Não pertence naturalmente a nenhuma das entidades individualmente

### TransferBetweenAccountsDomainService

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
    if (validationResult.hasError) {
      return validationResult;
    }
    
    // 2. Aplicar regras de domínio nas entidades
    fromAccount.debit(amount);
    toAccount.credit(amount);
    
    // 3. Criação de transações relacionadas
    const debitTransaction = Transaction.create({
      accountId: fromAccount.id,
      categoryId: transferCategoryId,
      budgetId: fromAccount.budgetId,
      amount: amount,
      type: TransactionTypeEnum.EXPENSE,
      description: `Transfer to ${toAccount.name}`,
    });
    
    const creditTransaction = Transaction.create({
      accountId: toAccount.id,
      categoryId: transferCategoryId,
      budgetId: toAccount.budgetId,
      amount: amount,
      type: TransactionTypeEnum.INCOME,
      description: `Transfer from ${fromAccount.name}`,
    });

    return Either.success({
      debitTransaction: debitTransaction,
      creditTransaction: creditTransaction,
    });
  }

  private canTransfer(
    fromAccount: Account,
    toAccount: Account,
    amount: number
  ): Either<DomainError, void> {
    if (fromAccount.budgetId !== toAccount.budgetId) {
      return Either.error(new DomainError('Accounts must be in the same budget'));
    }
    
    if (fromAccount.id === toAccount.id) {
      return Either.error(new DomainError('Cannot transfer to the same account'));
    }
    
    if (amount <= 0) {
      return Either.error(new DomainError('Transfer amount must be positive'));
    }
    
    if (fromAccount.availableBalance < amount) {
      return Either.error(new DomainError('Insufficient balance for transfer'));
    }
    
    return Either.success(undefined);
  }
}
```

**Por que é um Domain Service:**
- Coordena operações entre duas `Account` entities
- Cria duas `Transaction` entities relacionadas atomicamente
- Implementa regras específicas de transferência que não pertencem a uma única conta

## Quando NÃO Utilizar Domain Services

### ❌ Operações Simples de uma Entidade
```typescript
// ❌ EVITAR - Operação simples que deveria estar na entidade
export class UpdateAccountNameDomainService {
  updateName(account: Account, newName: string) {
    account.updateName(newName); // Deveria ser account.updateName() diretamente
  }
}
```

### ❌ Lógica de Aplicação
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

### ❌ Acesso a Infraestrutura
```typescript
// ❌ EVITAR - Domain Service não deve acessar repositórios diretamente
export class TransferDomainService {
  constructor(private accountRepository: IAccountRepository) {} // ❌ Violação da camada
  
  transfer(fromId: string, toId: string) {
    const fromAccount = await this.accountRepository.getById(fromId); // ❌ Infra no Domain
  }
}
```

## Padrões de Implementação

### Estrutura Padrão
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

### Retorno Consistente
- **Sempre usar `Either<DomainError, T>`** para tratamento de erros
- **Retornar objetos criados** que serão usados pelo Use Case
- **Não persistir dados** - isso é responsabilidade do Use Case + Repository/UnitOfWork

### Validações
- **Método privado `can[Operation]`** para validações específicas
- **Validar invariantes** entre entidades
- **Retornar erros de domínio específicos** quando violações ocorrerem

## Integração com Use Cases

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
    const billResult = await this.getBillRepository.execute(dto.billId);
    const accountResult = await this.getAccountRepository.execute(dto.accountId);

    if (billResult.hasError || accountResult.hasError) {
      return Either.error(new ApplicationError('Failed to fetch entities'));
    }

    // 2. Use Case chama Domain Service (responsabilidade de regras de negócio)
    const operationResult = this.payCreditCardBillDomainService.createPaymentOperation(
      billResult.data!,
      accountResult.data!,
      dto.budgetId,
      dto.amount,
      dto.paidBy,
      dto.paidAt,
      dto.paymentCategoryId,
    );

    if (operationResult.hasError) {
      return Either.error(new ApplicationError(operationResult.errors));
    }

    // 3. Use Case persiste resultado (responsabilidade de infraestrutura)
    await this.addTransactionRepository.execute(operationResult.data!.debitTransaction);
    await this.saveBillRepository.execute(billResult.data!);

    return Either.success(undefined);
  }
}
```

## Organização no Projeto

```
/src/domain/aggregates/[aggregate-name]/services/
├── [Operation]DomainService.ts
└── [Operation]DomainService.spec.ts
```

**Exemplos:**
- `src/domain/aggregates/credit-card-bill/services/PayCreditCardBillDomainService.ts`
- `src/domain/aggregates/account/services/TransferBetweenAccountsDomainService.ts`

## Testes

Domain Services devem ter cobertura completa incluindo:

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
    expect(result.errors[0].message).toContain('already paid');
  });

  it('should fail when insufficient balance', () => {
    // Test edge cases and validation rules
  });
});
```

**Tipos de Teste:**
- **Cenários de sucesso** com diferentes combinações de entidades
- **Cenários de falha** para cada validação implementada
- **Casos limite** e edge cases das regras de negócio
- **Isolamento** através de mocks das entidades quando necessário

## Princípios e Boas Práticas

### ✅ Faça
- **Mantenha puro**: Sem efeitos colaterais de I/O ou persistência
- **Foque no domínio**: Apenas regras de negócio e coordenação de entidades
- **Use Either**: Para tratamento consistente de erros
- **Nomeação clara**: `[Operation]DomainService` expressa a intenção
- **Validações explícitas**: Métodos privados para cada tipo de validação

### ❌ Evite
- **Acesso à infraestrutura**: Repositories, APIs externas, banco de dados
- **Lógica de aplicação**: Orquestração de Use Cases ou workflows
- **Criação excessiva**: Nem toda operação precisa de um Domain Service
- **Estados**: Domain Services devem ser stateless
- **Dependências circulares**: Entre Domain Services ou com entidades

## Vantagens

- **Separação clara** de responsabilidades entre entidades, domain services e use cases
- **Reutilização** de lógica complexa entre diferentes Use Cases
- **Testabilidade** isolada das regras de negócio
- **Expressividade** do modelo de domínio
- **Manutenibilidade** através de responsabilidades bem definidas

---

**Ver também:**
- [Domain Model](./domain-model.md) - Agregados e entidades coordenados pelos Domain Services
- [Unit of Work](./unit-of-work.md) - Persistência atômica dos resultados dos Domain Services
- [Layer Responsibilities](./layer-responsibilities.md) - Contexto das responsabilidades