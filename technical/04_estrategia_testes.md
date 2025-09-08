# Estratégia de Testes - OrcaSonhos

## Visão Geral

Esta estratégia define as práticas, ferramentas e processos de teste para garantir qualidade, confiabilidade e manutenibilidade da aplicação OrcaSonhos.

## Objetivos

- **Cobertura mínima**: 80% do código base
- **Cobertura crítica**: 100% para lógica de domínio
- **Confiabilidade**: Detectar regressões antes da produção
- **Velocidade**: Feedback rápido durante desenvolvimento
- **Manutenibilidade**: Testes fáceis de entender e manter

## Tipos de Testes

### 1. Testes Unitários

**Escopo**: Componentes, serviços, funções isoladas

**Ferramentas**:
- **Frontend**: Karma + Jasmine
- **Backend**: Jest

**Estratégia**:
- Testar lógica de negócio isoladamente
- Mockar dependências externas
- Focar em casos edge e validações
- 100% cobertura para classes de domínio

**Estrutura de arquivos**:
```
src/
├── domain/
│   ├── user.entity.ts
│   └── user.entity.spec.ts
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

## Estratégia de Mocks

### Frontend
```typescript
// MSW para APIs
import { setupServer } from 'msw/node';

const server = setupServer(
  rest.get('/api/users', (req, res, ctx) => {
    return res(ctx.json({ users: [] }));
  })
);
```

### Backend
```typescript
// Mocks de banco de dados
const mockUserRepository = {
  findById: jest.fn(),
  save: jest.fn(),
};
```

### Autenticação
```typescript
// Auth desabilitada para testes iniciais
const mockAuthService = {
  isAuthenticated: () => true,
  getCurrentUser: () => ({ id: 'test-user' }),
};
```

## Estrutura de Dados de Teste

### Factories/Builders
```typescript
// Domain factories
class UserFactory {
  static create(overrides = {}) {
    return {
      id: 'user-123',
      email: 'test@example.com',
      ...overrides,
    };
  }
}
```

### Fixtures
```typescript
// Dados estáticos para testes
export const MOCK_USERS = [
  { id: '1', name: 'User 1' },
  { id: '2', name: 'User 2' },
];
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

### DOs
✅ Testar comportamentos, não implementação  
✅ Usar nomes descritivos para testes  
✅ Manter testes simples e focados  
✅ Limpar estado entre testes  
✅ Usar TypeScript em todos os testes  

### DON'Ts
❌ Testar detalhes de implementação  
❌ Testes dependentes entre si  
❌ Hard-coding de delays em E2E  
❌ Testes muito complexos ou longos  
❌ Ignorar testes que falham ocasionalmente  

## Ferramentas e Configuração

### Ambiente Local
```bash
# Rodar testes unitários
npm run test

# Rodar com cobertura
npm run test:coverage

# Rodar E2E
npm run test:e2e
```

### Debugging
- **VS Code**: Launch configs para debugging
- **Playwright**: Interface visual para E2E
- **Chrome DevTools**: Para testes unitários

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

- **Desenvolvedores**: Escrever testes unitários para novas funcionalidades
- **Tech Lead**: Revisar estratégia e cobertura
- **DevOps**: Manter pipeline de testes funcionando
- **QA**: Definir cenários E2E críticos

---

*Esta estratégia será evoluída conforme o projeto cresce e novas necessidades surgem.*