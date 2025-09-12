# Estratégia de Testes - OrcaSonhos

## Visão Geral

Esta estratégia define as práticas, ferramentas e processos de teste para garantir qualidade, confiabilidade e manutenibilidade da aplicação OrcaSonhos, com foco especial nos padrões DDD e Clean Architecture implementados no backend.

## Objetivos

- **Cobertura mínima**: 80% do código base
- **Cobertura crítica**: 100% para agregados e use cases de domínio
- **Confiabilidade**: Detectar regressões antes da produção
- **Velocidade**: Feedback rápido durante desenvolvimento
- **Manutenibilidade**: Testes fáceis de entender e manter
- **Arquitetura**: Validar integridade dos padrões DDD/Clean Architecture

## Tipos de Testes

### 1. Testes Unitários

**Escopo**: Agregados, Value Objects, Use Cases, Domain Services isolados

**Ferramentas**:
- **Frontend**: Karma + Jasmine
- **Backend**: Jest com TypeScript

**Estratégia**:
- Testar invariantes de domínio nos agregados
- Validar comportamentos de use cases
- Mockar repositórios e dependências externas
- Testar padrão Either para tratamento de erros
- 100% cobertura para camada de domínio

**Estrutura de arquivos**:
```
src/
├── domain/
│   ├── aggregates/
│   │   ├── account/
│   │   │   ├── account.ts
│   │   │   └── account.spec.ts
│   ├── shared/
│   │   ├── value-objects/
│   │   │   ├── money-vo.ts
│   │   │   └── money-vo.spec.ts
├── application/
│   ├── use-cases/
│   │   ├── create-account/
│   │   │   ├── create-account.use-case.ts
│   │   │   └── create-account.use-case.spec.ts
├── components/
│   ├── user-profile/
│   │   ├── user-profile.component.ts
│   │   └── user-profile.component.spec.ts
```

### 2. Testes End-to-End (E2E)

**Escopo**: Fluxos completos de usuário

**Ferramenta**: Playwright

**Estratégia**:
- Cenários críticos de negócio
- Fluxos principais de usuário
- Validação de integração frontend/backend
- Testes cross-browser principais

**Cenários prioritários**:
- Cadastro e autenticação de usuário
- Navegação principal da aplicação
- Fluxos de criação/edição de dados
- Funcionalidades PWA/offline

## Configuração Offline/PWA

### Service Worker e Cache
```typescript
// Testes específicos para PWA
describe('PWA Functionality', () => {
  it('should cache critical resources', async () => {
    // Simular offline
    await page.setOfflineMode(true);
    // Verificar funcionamento básico
  });
});
```

### Sincronização de Dados
```typescript
// Testes de sincronização IndexedDB
describe('Offline Sync', () => {
  it('should sync data when connection restored', async () => {
    // Simular dados offline
    // Restaurar conexão
    // Verificar sincronização
  });
});
```

## Padrões de Teste por Camada

### 1. Testes de Agregados (Domain)

**Estrutura**:
```typescript
describe('Account Aggregate', () => {
  describe('constructor validations', () => {
    it('should create valid account', () => {
      // Arrange
      const accountData = { name: 'Conta Corrente', type: AccountType.CHECKING };
      
      // Act
      const result = Account.create(accountData);
      
      // Assert
      expect(result.isRight()).toBe(true);
      const account = result.value as Account;
      expect(account.name.value).toBe('Conta Corrente');
    });

    it('should fail with invalid name', () => {
      // Arrange
      const accountData = { name: '', type: AccountType.CHECKING };
      
      // Act
      const result = Account.create(accountData);
      
      // Assert
      expect(result.isLeft()).toBe(true);
      expect(result.value).toBeInstanceOf(ValidationError);
    });
  });

  describe('business rules', () => {
    it('should debit successfully with sufficient balance', () => {
      // Arrange
      const account = AccountFactory.createWithBalance(100);
      const debitAmount = MoneyVo.create(50).value as MoneyVo;
      
      // Act
      const result = account.debit(debitAmount);
      
      // Assert
      expect(result.isRight()).toBe(true);
      expect(account.balance.value).toBe(50);
    });

    it('should fail debit with insufficient balance', () => {
      // Arrange
      const account = AccountFactory.createWithBalance(30);
      const debitAmount = MoneyVo.create(50).value as MoneyVo;
      
      // Act
      const result = account.debit(debitAmount);
      
      // Assert
      expect(result.isLeft()).toBe(true);
      expect(result.value).toBeInstanceOf(InsufficientBalanceError);
    });
  });
});
```

### 2. Testes de Use Cases (Application)

**Estrutura**:
```typescript
describe('CreateAccountUseCase', () => {
  let useCase: CreateAccountUseCase;
  let mockAccountRepo: jest.Mocked<IAccountRepository>;
  let mockBudgetRepo: jest.Mocked<IBudgetRepository>;

  beforeEach(() => {
    mockAccountRepo = createMockAccountRepository();
    mockBudgetRepo = createMockBudgetRepository();
    useCase = new CreateAccountUseCase(mockAccountRepo, mockBudgetRepo);
  });

  describe('execute', () => {
    it('should create account successfully', async () => {
      // Arrange
      const request = CreateAccountRequestFactory.create();
      mockAccountRepo.save.mockResolvedValue(right(undefined));
      
      // Act
      const result = await useCase.execute(request);
      
      // Assert
      expect(result.isRight()).toBe(true);
      expect(mockAccountRepo.save).toHaveBeenCalledTimes(1);
      const savedAccount = mockAccountRepo.save.mock.calls[0][0];
      expect(savedAccount.name.value).toBe(request.name);
    });

    it('should fail when repository throws error', async () => {
      // Arrange
      const request = CreateAccountRequestFactory.create();
      mockAccountRepo.save.mockResolvedValue(left(new RepositoryError()));
      
      // Act
      const result = await useCase.execute(request);
      
      // Assert
      expect(result.isLeft()).toBe(true);
      expect(result.value).toBeInstanceOf(RepositoryError);
    });
  });
});
```

### 3. Testes de Value Objects

**Estrutura**:
```typescript
describe('MoneyVo', () => {
  describe('create', () => {
    it('should create valid money value', () => {
      // Act
      const result = MoneyVo.create(100.50);
      
      // Assert
      expect(result.isRight()).toBe(true);
      const money = result.value as MoneyVo;
      expect(money.value).toBe(100.50);
    });

    it('should fail with negative value', () => {
      // Act
      const result = MoneyVo.create(-10);
      
      // Assert
      expect(result.isLeft()).toBe(true);
      expect(result.value).toBeInstanceOf(InvalidMoneyError);
    });
  });

  describe('operations', () => {
    it('should add money values correctly', () => {
      // Arrange
      const money1 = MoneyVo.create(100).value as MoneyVo;
      const money2 = MoneyVo.create(50).value as MoneyVo;
      
      // Act
      const result = money1.add(money2);
      
      // Assert
      expect(result.isRight()).toBe(true);
      const sum = result.value as MoneyVo;
      expect(sum.value).toBe(150);
    });
  });
});
```

## Estratégia de Mocks e Factories

### Repository Mocks
```typescript
// Mock para repositórios seguindo interface
export const createMockAccountRepository = (): jest.Mocked<IAccountRepository> => ({
  findById: jest.fn(),
  findByBudgetId: jest.fn(),
  save: jest.fn(),
  delete: jest.fn(),
  existsByName: jest.fn(),
});

// Helper para setup padrão
export const setupMockAccountRepository = (scenarios: Partial<IAccountRepository> = {}) => {
  const mock = createMockAccountRepository();
  
  // Defaults que funcionam na maioria dos casos
  mock.save.mockResolvedValue(right(undefined));
  mock.findById.mockResolvedValue(right(null));
  mock.existsByName.mockResolvedValue(right(false));
  
  // Override com cenários específicos
  Object.assign(mock, scenarios);
  
  return mock;
};
```

### Factories para Entidades e VOs
```typescript
// Factory para agregados de domínio
export class AccountFactory {
  static create(overrides: Partial<CreateAccountDTO> = {}): Account {
    const defaultData: CreateAccountDTO = {
      name: 'Conta Teste',
      type: AccountType.CHECKING,
      initialBalance: 0,
      budgetId: 'budget-123',
    };

    const accountData = { ...defaultData, ...overrides };
    const result = Account.create(accountData);
    
    if (result.isLeft()) {
      throw new Error(`Failed to create Account: ${result.value.message}`);
    }
    
    return result.value;
  }

  static createWithBalance(balance: number): Account {
    return AccountFactory.create({ initialBalance: balance });
  }

  static createSavingsAccount(): Account {
    return AccountFactory.create({ 
      name: 'Conta Poupança',
      type: AccountType.SAVINGS 
    });
  }
}

// Factory para requests de use case
export class CreateAccountRequestFactory {
  static create(overrides: Partial<CreateAccountRequest> = {}): CreateAccountRequest {
    return {
      name: 'Nova Conta',
      type: 'CHECKING',
      initialBalance: 0,
      budgetId: 'budget-123',
      userId: 'user-123',
      ...overrides,
    };
  }
}
```

### Domain Services Mock
```typescript
// Mock para services de domínio
export const createMockAccountDomainService = (): jest.Mocked<IAccountDomainService> => ({
  validateAccountCreation: jest.fn(),
  calculateTotalBalance: jest.fn(),
  canDeleteAccount: jest.fn(),
});
```

### Frontend Mocks
```typescript
// MSW para APIs
import { setupServer } from 'msw/node';

const server = setupServer(
  rest.get('/api/accounts', (req, res, ctx) => {
    return res(ctx.json({ accounts: [] }));
  }),
  rest.post('/api/accounts', (req, res, ctx) => {
    return res(ctx.status(201), ctx.json({ id: 'account-123' }));
  })
);
```

## Organização e Convenções

### Nomenclatura
- **Unitários**: `*.spec.ts`
- **E2E**: `*.e2e.ts`
- **Helpers**: `test-utils/`

### Estrutura de describe/it
```typescript
describe('UserService', () => {
  describe('createUser', () => {
    it('should create user with valid data', () => {
      // Arrange, Act, Assert
    });

    it('should throw error with invalid email', () => {
      // Test error cases
    });
  });
});
```

### Padrão AAA (Arrange, Act, Assert)
```typescript
it('should calculate user age correctly', () => {
  // Arrange
  const birthDate = new Date('1990-01-01');
  const user = UserFactory.create({ birthDate });

  // Act
  const age = user.getAge();

  // Assert
  expect(age).toBe(34);
});
```

## Execução e Pipeline

### Scripts NPM

**Backend**:
```json
{
  "test": "jest",
  "test:watch": "jest --watch",
  "test:coverage": "jest --coverage",
  "test:domain": "jest --testPathPattern=domain",
  "test:application": "jest --testPathPattern=application",
  "test:integration": "jest --testPathPattern=integration"
}
```

**Frontend**:
```json
{
  "test": "ng test",
  "test:watch": "ng test --watch",
  "test:coverage": "ng test --code-coverage",
  "test:e2e": "playwright test",
  "test:e2e:ui": "playwright test --ui"
}
```

### CI/CD Integration
- **Pull Request**: Testes unitários obrigatórios
- **Main branch**: Suite completa (unit + e2e)
- **Deploy**: Smoke tests em staging

## Relatórios e Métricas

### Cobertura
- Relatórios HTML gerados automaticamente
- Falha no CI se cobertura < 80%
- Domínio deve manter 100%

### Performance E2E
- Timeout padrão: 30s por teste
- Paralelização quando possível
- Retry em casos de flaky tests

## Boas Práticas

### DOs - Arquitetura DDD
✅ Testar invariantes de domínio nos agregados  
✅ Validar padrão Either em todos os retornos  
✅ Usar factories para criar objetos de domínio  
✅ Mockar repositórios seguindo suas interfaces  
✅ Testar comportamentos, não implementação  
✅ Usar nomes descritivos para testes (Given/When/Then)  
✅ Manter testes simples e focados em um aspecto  
✅ Limpar estado entre testes  
✅ Usar TypeScript com strict mode em todos os testes  
✅ Testar cenários de erro além dos casos felizes  

### DON'Ts - Arquitetura DDD
❌ Testar detalhes de implementação interna dos agregados  
❌ Quebrar encapsulamento de agregados nos testes  
❌ Testes dependentes entre si ou com ordem específica  
❌ Hard-coding de delays em E2E  
❌ Testes muito complexos ou longos  
❌ Ignorar testes que falham ocasionalmente (flaky tests)  
❌ Usar mocks que não seguem as interfaces de domínio  
❌ Testar múltiplas responsabilidades no mesmo teste  
❌ Pular validação do padrão Either nos retornos  

## Ferramentas e Configuração

### Ambiente Local

**Backend**:
```bash
# Rodar todos os testes
npm run test

# Rodar com watch mode
npm run test:watch

# Rodar com cobertura
npm run test:coverage

# Rodar apenas testes de domínio
npm run test:domain

# Rodar apenas testes de aplicação
npm run test:application
```

**Frontend**:
```bash
# Rodar testes unitários
npm run test

# Rodar com cobertura
npm run test:coverage

# Rodar E2E
npm run test:e2e
```

### Configuração Jest (Backend)

**jest.config.js**:
```javascript
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src'],
  testMatch: ['**/*.spec.ts'],
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.d.ts',
    '!src/shared/observability/**',
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80,
    },
    './src/domain/': {
      branches: 100,
      functions: 100,
      lines: 100,
      statements: 100,
    },
  },
  moduleNameMapping: {
    '^@domain/(.*)$': '<rootDir>/src/domain/$1',
    '^@application/(.*)$': '<rootDir>/src/application/$1',
    '^@infrastructure/(.*)$': '<rootDir>/src/infrastructure/$1',
    '^@http/(.*)$': '<rootDir>/src/interface/http/$1',
    '^@shared/(.*)$': '<rootDir>/src/shared/$1',
  },
  setupFilesAfterEnv: ['<rootDir>/src/shared/test/setup.ts'],
};
```

**setup.ts**:
```typescript
// Helper para Either pattern em testes
declare global {
  namespace jest {
    interface Matchers<R> {
      toBeRight(): R;
      toBeLeft(): R;
      toBeRightWith(expected: any): R;
      toBeLeftWith(expected: any): R;
    }
  }
}

expect.extend({
  toBeRight(received) {
    const pass = received.isRight();
    return {
      message: () => `expected Either to be Right, but was Left: ${received.value}`,
      pass,
    };
  },

  toBeLeft(received) {
    const pass = received.isLeft();
    return {
      message: () => `expected Either to be Left, but was Right: ${received.value}`,
      pass,
    };
  },

  toBeRightWith(received, expected) {
    if (!received.isRight()) {
      return {
        message: () => `expected Either to be Right, but was Left: ${received.value}`,
        pass: false,
      };
    }
    
    const pass = this.equals(received.value, expected);
    return {
      message: () => `expected Right value to be ${this.utils.printExpected(expected)}, but received ${this.utils.printReceived(received.value)}`,
      pass,
    };
  },

  toBeLeftWith(received, expected) {
    if (!received.isLeft()) {
      return {
        message: () => `expected Either to be Left, but was Right: ${received.value}`,
        pass: false,
      };
    }
    
    const pass = received.value instanceof expected || this.equals(received.value, expected);
    return {
      message: () => `expected Left value to be ${this.utils.printExpected(expected)}, but received ${this.utils.printReceived(received.value)}`,
      pass,
    };
  },
});
```

### Debugging
- **VS Code**: Launch configs para debugging Jest
- **Jest**: `--verbose` para output detalhado
- **Playwright**: Interface visual para E2E
- **Chrome DevTools**: Para testes unitários frontend

## Roadmap Futuro

### Fase 2
- Testes de integração específicos
- Testes de performance/carga
- Testes de acessibilidade automatizados
- Visual regression tests

### Fase 3
- Dados de teste gerenciados
- Ambiente de testes dedicado
- Testes com autenticação real
- Monitoramento de qualidade avançado

## Responsabilidades

### Desenvolvedores Backend
- **Domínio**: Escrever testes unitários para agregados, value objects e domain services
- **Aplicação**: Implementar testes de use cases com mocks de repositórios
- **Arquitetura**: Garantir que testes seguem padrões DDD/Clean Architecture
- **Either Pattern**: Validar tratamento de erros em todos os retornos

### Desenvolvedores Frontend  
- **Componentes**: Testes unitários de comportamento e integração
- **Serviços**: Mock de APIs e validação de estados
- **E2E**: Colaborar na definição de cenários críticos

### Tech Lead
- **Estratégia**: Revisar e evoluir padrões de teste
- **Cobertura**: Monitorar métricas de qualidade
- **Arquitetura**: Validar aderência aos padrões estabelecidos
- **Code Review**: Garantir qualidade dos testes em PRs

### DevOps
- **Pipeline**: Manter execução automatizada funcionando
- **Ambiente**: Configurar ambientes de teste isolados
- **Métricas**: Coletar e reportar dados de qualidade
- **Performance**: Otimizar tempo de execução dos testes

---

*Esta estratégia será evoluída conforme o projeto cresce e novas necessidades surgem.*