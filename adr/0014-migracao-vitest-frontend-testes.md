# ADR-0014: Migração para Vitest como Ferramenta de Testes do Frontend

---

**Status:** Aceito  
**Data:** 2025-01-24  
**Decisores:** Equipe de Desenvolvimento Frontend  
**Consultados:** Tech Lead, DevOps

---

## Contexto

Atualmente, o projeto OrçaSonhos utiliza **Karma + Jasmine** como ferramenta principal para testes unitários do frontend Angular. Esta combinação tem sido amplamente utilizada no ecossistema Angular, mas apresenta algumas limitações em relação a performance, configuração e experiência de desenvolvimento.

### Problemas Identificados com Karma + Jasmine

1. **Performance**: Karma é relativamente lento para execução de testes, especialmente em projetos grandes
2. **Configuração Complexa**: Requer configuração adicional para coverage, watch mode e integração com ferramentas modernas
3. **Dependências**: Karma depende de browsers para execução, aumentando complexidade em ambientes CI/CD
4. **Developer Experience**: Interface de desenvolvimento menos intuitiva comparada a ferramentas modernas
5. **Manutenção**: Karma tem menor atividade de desenvolvimento comparado a ferramentas mais modernas

### Alternativas Consideradas

1. **Jest**: Framework popular, mas requer configuração adicional para Angular
2. **Vitest**: Ferramenta moderna, rápida, com excelente suporte a TypeScript e Vite
3. **Manter Karma + Jasmine**: Status quo, mas com limitações identificadas

## Decisão

**Migrar para Vitest** como ferramenta principal de testes unitários do frontend.

### Justificativa

1. **Performance Superior**: Vitest é significativamente mais rápido que Karma, especialmente em watch mode
2. **Integração Nativa**: Excelente integração com Vite (build tool moderno) e TypeScript
3. **Developer Experience**: Interface moderna, hot reload de testes, melhor debugging
4. **Configuração Simplificada**: Menos configuração necessária comparado a Karma
5. **Ecosistema Moderno**: Ativa comunidade, desenvolvimento ativo, compatibilidade com ferramentas modernas
6. **CI/CD Friendly**: Execução mais eficiente em ambientes de integração contínua
7. **Compatibilidade Angular**: Suporte oficial e bem documentado para Angular

## Consequências

### Positivas

✅ **Performance**: Execução de testes 2-3x mais rápida  
✅ **Developer Experience**: Melhor interface e debugging  
✅ **Configuração**: Setup mais simples e manutenível  
✅ **Integração**: Melhor integração com Vite e TypeScript  
✅ **CI/CD**: Execução mais eficiente em pipelines  
✅ **Modernidade**: Alinhamento com ferramentas modernas do ecossistema

### Negativas

❌ **Migração**: Esforço inicial para migrar testes existentes  
❌ **Aprendizado**: Curva de aprendizado para a equipe  
❌ **Dependências**: Mudança nas dependências do projeto  
❌ **Configuração**: Necessidade de reconfigurar coverage e scripts

### Riscos e Mitigações

| Risco                                    | Probabilidade | Impacto | Mitigação                                        |
| ---------------------------------------- | ------------- | ------- | ------------------------------------------------ |
| Problemas de compatibilidade com Angular | Baixa         | Médio   | Testes extensivos em ambiente de desenvolvimento |
| Resistência da equipe à mudança          | Média         | Baixo   | Treinamento e documentação adequada              |
| Regressão em testes existentes           | Baixa         | Alto    | Migração gradual e validação cuidadosa           |
| Configuração complexa inicial            | Média         | Baixo   | Documentação detalhada e suporte da equipe       |

## Implementação

### Fase 1: Setup e Configuração (1-2 dias)

1. **Instalação do Vitest**

   ```bash
   npm install --save-dev vitest @vitest/ui
   npm install --save-dev @angular-builders/vite
   ```

2. **Configuração do vite.config.ts**

   ```typescript
   import { defineConfig } from "vite";
   import angular from "@analogjs/vite-plugin-angular";

   export default defineConfig({
     plugins: [angular()],
     test: {
       globals: true,
       environment: "jsdom",
       setupFiles: ["src/test-setup.ts"],
       include: ["src/**/*.{test,spec}.{js,mjs,cjs,ts,mts,cts,jsx,tsx}"],
       coverage: {
         provider: "v8",
         reporter: ["text", "json", "html"],
         exclude: ["node_modules/", "src/test-setup.ts", "src/**/*.d.ts"],
       },
     },
   });
   ```

3. **Atualização do angular.json**
   ```json
   {
     "projects": {
       "orca-sonhos": {
         "architect": {
           "test": {
             "builder": "@angular-builders/vite:test",
             "options": {
               "configFile": "vite.config.ts"
             }
           }
         }
       }
     }
   }
   ```

### Fase 2: Migração de Testes (3-5 dias)

1. **Atualização de Imports**

   - Substituir imports do Jasmine por Vitest
   - Atualizar matchers e utilitários

2. **Migração de Configurações**

   - Converter configurações de Karma para Vitest
   - Atualizar setup files

3. **Validação de Testes**
   - Executar suite completa de testes
   - Corrigir testes quebrados
   - Validar coverage

### Fase 3: Documentação e Treinamento (1-2 dias)

1. **Atualização da Documentação**

   - Estratégia de testes
   - Padrões de teste
   - Guias de configuração

2. **Treinamento da Equipe**
   - Sessão de treinamento
   - Documentação de migração
   - Exemplos práticos

### Fase 4: Limpeza (1 dia)

1. **Remoção de Dependências**

   - Remover Karma e Jasmine
   - Limpar configurações antigas

2. **Atualização de Scripts**
   - Atualizar package.json
   - Atualizar CI/CD

## Configuração Detalhada

### vitest.config.ts

```typescript
import { defineConfig } from "vitest/config";
import angular from "@analogjs/vite-plugin-angular";

export default defineConfig({
  plugins: [angular()],
  test: {
    globals: true,
    environment: "jsdom",
    setupFiles: ["src/test-setup.ts"],
    include: ["src/**/*.{test,spec}.{js,mjs,cjs,ts,mts,cts,jsx,tsx}"],
    exclude: [
      "node_modules/",
      "dist/",
      "cypress/",
      "playwright/",
      "src/test-setup.ts",
    ],
    coverage: {
      provider: "v8",
      reporter: ["text", "json", "html"],
      reportsDirectory: "./coverage",
      exclude: [
        "node_modules/",
        "src/test-setup.ts",
        "src/**/*.d.ts",
        "src/**/*.config.ts",
        "src/**/*.interface.ts",
        "src/**/*.type.ts",
        "src/**/*.enum.ts",
        "src/**/*.constant.ts",
        "src/**/*.mock.ts",
        "src/**/*.stub.ts",
        "src/**/*.spec.ts",
        "src/**/*.test.ts",
      ],
      thresholds: {
        global: {
          branches: 80,
          functions: 80,
          lines: 80,
          statements: 80,
        },
        "./src/domain/": {
          branches: 100,
          functions: 100,
          lines: 100,
          statements: 100,
        },
        "./src/application/": {
          branches: 85,
          functions: 85,
          lines: 85,
          statements: 85,
        },
      },
    },
  },
});
```

### src/test-setup.ts

```typescript
import "zone.js/testing";
import { getTestBed } from "@angular/core/testing";
import {
  BrowserDynamicTestingModule,
  platformBrowserDynamicTesting,
} from "@angular/platform-browser-dynamic/testing";

// Setup Angular testing environment
getTestBed().initTestEnvironment(
  BrowserDynamicTestingModule,
  platformBrowserDynamicTesting()
);

// Global test utilities
declare global {
  namespace Vi {
    interface JestAssertion<T = any> {
      toBeRight(): T;
      toBeLeft(): T;
      toBeRightWith(expected: any): T;
      toBeLeftWith(expected: any): T;
    }
  }
}

// Custom matchers for Either pattern
expect.extend({
  toBeRight(received: any) {
    const pass = received.isRight();
    return {
      message: () =>
        `expected Either to be Right, but was Left: ${received.value}`,
      pass,
    };
  },

  toBeLeft(received: any) {
    const pass = received.isLeft();
    return {
      message: () =>
        `expected Either to be Left, but was Right: ${received.value}`,
      pass,
    };
  },

  toBeRightWith(received: any, expected: any) {
    if (!received.isRight()) {
      return {
        message: () =>
          `expected Either to be Right, but was Left: ${received.value}`,
        pass: false,
      };
    }

    const pass = this.equals(received.value, expected);
    return {
      message: () =>
        `expected Right value to be ${this.utils.printExpected(
          expected
        )}, but received ${this.utils.printReceived(received.value)}`,
      pass,
    };
  },

  toBeLeftWith(received: any, expected: any) {
    if (!received.isLeft()) {
      return {
        message: () =>
          `expected Either to be Left, but was Right: ${received.value}`,
        pass: false,
      };
    }

    const pass =
      received.value instanceof expected ||
      this.equals(received.value, expected);
    return {
      message: () =>
        `expected Left value to be ${this.utils.printExpected(
          expected
        )}, but received ${this.utils.printReceived(received.value)}`,
      pass,
    };
  },
});
```

### package.json Scripts

```json
{
  "scripts": {
    "test": "vitest",
    "test:watch": "vitest --watch",
    "test:ui": "vitest --ui",
    "test:coverage": "vitest --coverage",
    "test:run": "vitest run",
    "test:ci": "vitest run --coverage --reporter=verbose",
    "test:features": "vitest run --include='**/features/**/*.spec.ts'",
    "test:shared": "vitest run --include='**/shared/**/*.spec.ts'",
    "test:dtos": "vitest run --include='**/dtos/**/*.spec.ts'",
    "test:state": "vitest run --include='**/state/**/*.spec.ts'",
    "test:budgets": "vitest run --include='**/features/budgets/**/*.spec.ts'",
    "test:transactions": "vitest run --include='**/features/transactions/**/*.spec.ts'",
    "test:goals": "vitest run --include='**/features/goals/**/*.spec.ts'"
  }
}
```

## Migração de Testes

### Antes (Karma + Jasmine)

```typescript
// budget.service.spec.ts
import { TestBed } from "@angular/core/testing";
import { HttpClient } from "@angular/common/http";
import { of, throwError } from "rxjs";

import { BudgetService } from "./budget.service";

describe("BudgetService", () => {
  let service: BudgetService;
  let httpClient: jasmine.SpyObj<HttpClient>;

  beforeEach(() => {
    const httpClientSpy = jasmine.createSpyObj("HttpClient", ["get", "post"]);

    TestBed.configureTestingModule({
      providers: [
        BudgetService,
        { provide: HttpClient, useValue: httpClientSpy },
      ],
    });

    service = TestBed.inject(BudgetService);
    httpClient = TestBed.inject(HttpClient) as jasmine.SpyObj<HttpClient>;
  });

  it("should be created", () => {
    expect(service).toBeTruthy();
  });

  it("should fetch budgets", () => {
    const mockBudgets = [{ id: "1", name: "Budget 1" }];
    httpClient.get.and.returnValue(of(mockBudgets));

    service.getBudgets().subscribe((budgets) => {
      expect(budgets).toEqual(mockBudgets);
    });

    expect(httpClient.get).toHaveBeenCalledWith("/api/budgets");
  });
});
```

### Depois (Vitest)

```typescript
// budget.service.spec.ts
import { TestBed } from "@angular/core/testing";
import { HttpClient } from "@angular/common/http";
import { of, throwError } from "rxjs";
import { describe, it, expect, beforeEach, vi } from "vitest";

import { BudgetService } from "./budget.service";

describe("BudgetService", () => {
  let service: BudgetService;
  let httpClient: any;

  beforeEach(() => {
    httpClient = {
      get: vi.fn(),
      post: vi.fn(),
    };

    TestBed.configureTestingModule({
      providers: [BudgetService, { provide: HttpClient, useValue: httpClient }],
    });

    service = TestBed.inject(BudgetService);
  });

  it("should be created", () => {
    expect(service).toBeTruthy();
  });

  it("should fetch budgets", () => {
    const mockBudgets = [{ id: "1", name: "Budget 1" }];
    httpClient.get.mockReturnValue(of(mockBudgets));

    service.getBudgets().subscribe((budgets) => {
      expect(budgets).toEqual(mockBudgets);
    });

    expect(httpClient.get).toHaveBeenCalledWith("/api/budgets");
  });
});
```

## Monitoramento e Métricas

### KPIs de Sucesso

1. **Performance**: Redução de 50% no tempo de execução de testes
2. **Coverage**: Manutenção de cobertura atual (80%+)
3. **Developer Experience**: Feedback positivo da equipe
4. **CI/CD**: Redução de 30% no tempo de pipeline

### Métricas de Acompanhamento

- Tempo de execução de testes (unit, watch, ci)
- Cobertura de código por camada
- Taxa de sucesso de testes
- Tempo de feedback em desenvolvimento
- Satisfação da equipe (survey)

## Reversão

Em caso de problemas críticos, a reversão pode ser feita:

1. **Backup**: Manter configurações do Karma em branch separada
2. **Rollback**: Reverter para versão anterior do package.json
3. **Testes**: Executar suite completa para validar funcionamento
4. **Documentação**: Atualizar documentação com lições aprendidas

## Conclusão

A migração para Vitest representa um avanço significativo na experiência de desenvolvimento e performance dos testes do frontend. Apesar do esforço inicial de migração, os benefícios a longo prazo justificam a mudança, alinhando o projeto com as melhores práticas modernas do ecossistema JavaScript/TypeScript.

A implementação será feita de forma gradual e cuidadosa, com validação extensiva para garantir que não haja regressão na qualidade dos testes existentes.

---

**Aprovado por:**

- Tech Lead: [Nome] - [Data]
- DevOps: [Nome] - [Data]
- Desenvolvedor Frontend: [Nome] - [Data]
