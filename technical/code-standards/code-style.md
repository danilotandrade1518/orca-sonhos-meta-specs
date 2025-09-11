# Code Style - Formatação e Estilo

## 🎨 Formatação e Estilo

### Prettier e ESLint

**Obrigatório**: Usar Prettier + ESLint com configuração padrão do projeto.

```json
// .prettierrc
{
  "printWidth": 100,
  "tabWidth": 2,
  "useTabs": false,
  "semi": true,
  "singleQuote": true,
  "quoteProps": "as-needed",
  "trailingComma": "es5",
  "bracketSpacing": true,
  "arrowParens": "avoid"
}
```

### Tamanho de Linha e Indentação

```typescript
// ✅ Max 100 caracteres por linha
const result = await this.transactionUseCase.execute(
  transactionDto,
  userId
);

// ✅ 2 espaços de indentação
if (condition) {
  doSomething();
  if (anotherCondition) {
    doAnotherThing();
  }
}

// ❌ Linha muito longa
const result = await this.transactionUseCase.execute(transactionDto, userId, budgetId, accountId, categoryId);

// ❌ Indentação incorreta (4 espaços)
if (condition) {
    doSomething();
}
```

### Quebras de Linha

```typescript
// ✅ Parâmetros em linha quando cabem (até 100 caracteres)
public createTransaction(dto: CreateTransactionDto, userId: string): Promise<Either<Error, Transaction>> {
  // implementation
}

// ✅ Quebrar quando não cabem
public transferBetweenAccounts(
  fromAccountId: string,
  toAccountId: string,
  amount: Money,
  budgetId: string,
  userId: string
): Promise<Either<ApplicationError, void>> {
  // implementation
}

// ✅ Objetos e arrays longos
const config = {
  apiUrl: 'https://api.orcasonhos.com',
  timeout: 5000,
  retries: 3,
  headers: {
    'Content-Type': 'application/json',
    'X-API-Version': '1.0'
  }
};

// ✅ Imports longos
import {
  CreateTransactionUseCase,
  UpdateTransactionUseCase,
  DeleteTransactionUseCase,
  FindTransactionByIdUseCase
} from '@application/use-cases';
```

### Espaçamento e Organização

```typescript
// ✅ Espaçamento entre blocos lógicos
export class TransactionService {
  // Propriedades
  private readonly repository: ITransactionRepository;
  private readonly logger: ILogger;

  // Construtor
  constructor(repository: ITransactionRepository, logger: ILogger) {
    this.repository = repository;
    this.logger = logger;
  }

  // Métodos públicos
  public async createTransaction(dto: CreateTransactionDto): Promise<Either<Error, Transaction>> {
    const validation = this.validateDto(dto);
    if (validation.isLeft()) {
      return Either.left(validation.value);
    }

    const transaction = Transaction.create(validation.value);
    return this.repository.execute(transaction);
  }

  // Métodos privados
  private validateDto(dto: CreateTransactionDto): Either<ValidationError, CreateTransactionDto> {
    // validation logic
  }
}
```

### Chaves e Pontuação

```typescript
// ✅ Chaves no mesmo linha (K&R style)
if (condition) {
  doSomething();
} else {
  doSomethingElse();
}

// ✅ Ponto e vírgula obrigatório
const amount = Money.fromCents(1000);
const transaction = Transaction.create(dto);

// ✅ Vírgulas trailing em objetos/arrays multilinhas
const config = {
  apiUrl: '/api',
  timeout: 5000,
  retries: 3, // ← vírgula trailing
};

const items = [
  'item1',
  'item2',
  'item3', // ← vírgula trailing
];
```

### Aspas e Strings

```typescript
// ✅ Single quotes para strings simples
const message = 'Transaction created successfully';
const selector = 'os-transaction-form';

// ✅ Template literals para interpolação
const errorMessage = `Failed to create transaction with ID: ${transactionId}`;
const query = `
  SELECT * FROM transactions 
  WHERE account_id = $1 
  AND created_at > $2
`;

// ✅ Double quotes apenas para HTML attributes (Angular)
@Component({
  selector: 'os-transaction-form',
  template: `
    <input 
      type="text" 
      class="form-control" 
      [value]="amount()"
    />
  `
})
```

### Organização de Arquivos

```typescript
// ✅ Ordem de exports
// 1. Types e interfaces primeiro
export interface ITransactionRepository {
  execute(transaction: Transaction): Promise<Either<Error, void>>;
}

export type TransactionStatus = 'pending' | 'completed' | 'cancelled';

// 2. Classes principais
export class CreateTransactionUseCase {
  // implementation
}

// 3. Default export por último (se necessário)
export default CreateTransactionUseCase;
```

### Convenções de Arquivo

```bash
# ✅ Nomes de arquivos consistentes
CreateTransactionUseCase.ts          # Backend classes
TransactionRepository.ts             # Backend classes
create-transaction.page.ts           # Angular pages
transaction-list.component.ts        # Angular components
budget-overview.widget.ts            # Angular widgets

# ✅ Extensões apropriadas
.ts        # TypeScript
.spec.ts   # Testes
.dto.ts    # DTOs
.types.ts  # Type definitions
.const.ts  # Constants
```

## 🔧 Configuração de Ferramentas

### ESLint Configuration

```javascript
// eslint.config.js
module.exports = {
  extends: [
    '@angular-eslint/recommended',
    '@typescript-eslint/recommended',
    'prettier'
  ],
  rules: {
    '@typescript-eslint/no-explicit-any': 'error',
    '@typescript-eslint/explicit-function-return-type': 'error',
    'prefer-const': 'error',
    'no-var': 'error',
    'no-console': 'warn'
  }
};
```

### TypeScript Configuration

```json
// tsconfig.json (strict configuration)
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "noImplicitReturns": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "exactOptionalPropertyTypes": true
  }
}
```

### VS Code Settings

```json
// .vscode/settings.json
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true,
    "source.organizeImports": true
  },
  "typescript.preferences.organizeImports": true,
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  }
}
```

---

**Próximos tópicos:**
- **[Comments Guidelines](./comments-guidelines.md)** - Quando NÃO comentar
- **[Angular Modern Patterns](./angular-modern-patterns.md)** - Padrões Angular modernos