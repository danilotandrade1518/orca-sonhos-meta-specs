# MSW (Mock Service Worker) Configuration

## Objetivo e Strategy

Mock Service Worker intercepta requests HTTP no nível de rede, fornecendo mocks **realistas** tanto para desenvolvimento quanto para testes. Diferente de mocks tradicionais, MSW simula um servidor real.

### Vantagens do MSW

- **Network Level**: Intercepta `fetch` real, não substitui código
- **Realistic**: Simula latência, status codes, headers reais
- **Shared**: Mesmo mock para dev e testes
- **Debugging**: Requests visíveis no DevTools Network tab
- **Offline Development**: Desenvolvimento independente do backend

## Estrutura de Organização

### Organização por Contexto

```
/mocks/
├── browser.ts              # Setup para desenvolvimento (browser)
├── server.ts               # Setup para testes (Node.js)
├── handlers.ts             # Agregação de todos handlers
└── /context/               # Handlers por contexto de negócio
    ├── budgetHandlers.ts   # Budget CRUD + queries  
    ├── transactionHandlers.ts # Transaction management
    ├── accountHandlers.ts  # Account operations
    ├── authHandlers.ts     # Authentication flow
    ├── envelopeHandlers.ts # Envelope/category management
    ├── goalHandlers.ts     # Goals and savings
    └── creditCardHandlers.ts # Credit card management
```

## Setup e Inicialização

### Browser Setup (Desenvolvimento)

```typescript
// mocks/browser.ts
import { setupWorker } from 'msw/browser';
import { handlers } from './handlers';

export const worker = setupWorker(...handlers);

// Start worker conditionally
if (typeof window !== 'undefined') {
  worker.start({
    onUnhandledRequest: 'warn', // Log unhandled requests
    serviceWorker: {
      url: '/mockServiceWorker.js', // Service worker location
      options: {
        scope: '/' // Intercept all requests
      }
    }
  });
}
```

### Node Setup (Testes)

```typescript
// mocks/server.ts  
import { setupServer } from 'msw/node';
import { handlers } from './handlers';

export const server = setupServer(...handlers);

// Global test setup
beforeAll(() => {
  server.listen({
    onUnhandledRequest: 'error' // Stricter in tests
  });
});

afterEach(() => {
  server.resetHandlers(); // Reset after each test
});

afterAll(() => {
  server.close();
});
```

### Main.ts Integration

```typescript
// main.ts
import { bootstrapApplication } from '@angular/platform-browser';
import { AppComponent } from './app/app.component';
import { environment } from './environments/environment';

async function enableMocking() {
  if (!environment.flags.mswEnabled) {
    return;
  }

  const { worker } = await import('./mocks/browser');
  
  return worker.start({
    onUnhandledRequest: 'bypass'
  });
}

enableMocking().then(() => {
  bootstrapApplication(AppComponent, appConfig);
});
```

### Test Setup Integration

```typescript
// test-setup.ts
import './mocks/server'; // Auto-initializes server

// Angular testing setup  
import 'zone.js/testing';
import { getTestBed } from '@angular/core/testing';
import { BrowserDynamicTestingModule, platformBrowserDynamicTesting } from '@angular/platform-browser-dynamic/testing';

getTestBed().initTestEnvironment(
  BrowserDynamicTestingModule,
  platformBrowserDynamicTesting()
);
```

## Handlers por Contexto

### Budget Handlers

```typescript
// mocks/context/budgetHandlers.ts
import { http, HttpResponse, delay } from 'msw';

export const budgetHandlers = [
  // Create Budget - POST /api/budget/create
  http.post('/api/budget/create', async ({ request }) => {
    await delay(200); // Simulate network latency
    
    const body = await request.json();
    
    // Realistic validation
    if (!body.name?.trim()) {
      return HttpResponse.json(
        {
          success: false,
          errors: [{
            code: 'VALIDATION_ERROR',
            message: 'Budget name is required'
          }]
        },
        { status: 400 }
      );
    }
    
    if (body.limit_in_cents <= 0) {
      return HttpResponse.json(
        {
          success: false,
          errors: [{
            code: 'VALIDATION_ERROR', 
            message: 'Budget limit must be positive'
          }]
        },
        { status: 400 }
      );
    }

    // Success response (no content)
    return new HttpResponse(null, { status: 204 });
  }),

  // Update Budget - POST /api/budget/update  
  http.post('/api/budget/update', async ({ request }) => {
    await delay(300);
    
    const body = await request.json();
    
    if (!body.id) {
      return HttpResponse.json(
        { success: false, errors: [{ code: 'MISSING_ID', message: 'Budget ID required' }] },
        { status: 400 }
      );
    }
    
    // Simulate not found
    if (body.id === 'not-found') {
      return HttpResponse.json(
        { success: false, errors: [{ code: 'NOT_FOUND', message: 'Budget not found' }] },
        { status: 404 }
      );
    }
    
    // Simulate authorization error
    if (body.id === 'forbidden') {
      return HttpResponse.json(
        { success: false, errors: [{ code: 'FORBIDDEN', message: 'Access denied' }] },
        { status: 403 }
      );
    }

    return new HttpResponse(null, { status: 204 });
  }),

  // Get Budget - GET /api/budget/:id
  http.get('/api/budget/:id', async ({ params }) => {
    await delay(150);
    
    const { id } = params;
    
    if (id === 'not-found') {
      return HttpResponse.json(
        { success: false, errors: [{ code: 'NOT_FOUND', message: 'Budget not found' }] },
        { status: 404 }
      );
    }

    // Mock budget data
    return HttpResponse.json({
      id: id,
      name: 'Home Budget',
      limit_in_cents: 500000, // R$ 5,000.00
      participants: ['user-123', 'user-456'],
      created_at: '2024-01-15T10:00:00Z',
      updated_at: '2024-01-16T14:30:00Z'
    });
  }),

  // Get Budget Summary - GET /api/budget/:id/summary
  http.get('/api/budget/:id/summary', async ({ params, request }) => {
    await delay(400); // Longer delay for complex query
    
    const url = new URL(request.url);
    const period = url.searchParams.get('period') || 'current_month';
    const { id } = params;

    // Generate realistic data based on period
    const mockData = generateBudgetSummaryData(id as string, period);
    
    return HttpResponse.json(mockData);
  }),

  // Get User Budgets - GET /api/budget/list
  http.get('/api/budget/list', async ({ request }) => {
    await delay(250);
    
    const url = new URL(request.url);
    const userId = url.searchParams.get('userId');
    
    if (!userId) {
      return HttpResponse.json(
        { success: false, errors: [{ code: 'MISSING_USER_ID', message: 'User ID required' }] },
        { status: 400 }
      );
    }

    // Mock user budgets
    return HttpResponse.json({
      budgets: [
        {
          id: 'budget-1',
          name: 'Home Budget',
          limit_in_cents: 500000,
          participant_count: 2,
          is_owner: true,
          created_at: '2024-01-15T10:00:00Z'
        },
        {
          id: 'budget-2',
          name: 'Travel Fund',
          limit_in_cents: 200000,
          participant_count: 1,
          is_owner: true,
          created_at: '2024-02-01T08:00:00Z'
        }
      ]
    });
  })
];

// Helper function to generate realistic summary data
function generateBudgetSummaryData(budgetId: string, period: string) {
  const baseLimit = 500000; // R$ 5,000.00
  const spentPercentage = Math.random() * 0.8 + 0.1; // 10% - 90%
  const totalSpent = Math.round(baseLimit * spentPercentage);
  
  return {
    budget_id: budgetId,
    budget_name: 'Home Budget',
    limit_in_cents: baseLimit,
    total_spent_in_cents: totalSpent,
    remaining_in_cents: baseLimit - totalSpent,
    usage_percentage: Math.round(spentPercentage * 100),
    transaction_count: Math.floor(Math.random() * 50) + 5,
    period: period
  };
}
```

### Transaction Handlers

```typescript
// mocks/context/transactionHandlers.ts
import { http, HttpResponse, delay } from 'msw';

export const transactionHandlers = [
  // Create Transaction - POST /api/transaction/create
  http.post('/api/transaction/create', async ({ request }) => {
    await delay(300);
    
    const body = await request.json();
    
    // Validation
    if (!body.description?.trim()) {
      return HttpResponse.json(
        { success: false, errors: [{ code: 'VALIDATION_ERROR', message: 'Description required' }] },
        { status: 400 }
      );
    }
    
    if (!body.account_id) {
      return HttpResponse.json(
        { success: false, errors: [{ code: 'VALIDATION_ERROR', message: 'Account ID required' }] },
        { status: 400 }
      );
    }
    
    if (body.amount_in_cents === 0) {
      return HttpResponse.json(
        { success: false, errors: [{ code: 'VALIDATION_ERROR', message: 'Amount cannot be zero' }] },
        { status: 400 }
      );
    }

    // Simulate account not found
    if (body.account_id === 'not-found') {
      return HttpResponse.json(
        { success: false, errors: [{ code: 'ACCOUNT_NOT_FOUND', message: 'Account not found' }] },
        { status: 404 }
      );
    }

    return new HttpResponse(null, { status: 204 });
  }),

  // Get Transactions - GET /api/transaction/list
  http.get('/api/transaction/list', async ({ request }) => {
    await delay(200);
    
    const url = new URL(request.url);
    const budgetId = url.searchParams.get('budgetId');
    const limit = parseInt(url.searchParams.get('limit') || '20');
    const offset = parseInt(url.searchParams.get('offset') || '0');
    
    if (!budgetId) {
      return HttpResponse.json(
        { success: false, errors: [{ code: 'MISSING_BUDGET_ID', message: 'Budget ID required' }] },
        { status: 400 }
      );
    }

    // Generate mock transactions
    const transactions = generateMockTransactions(budgetId, limit, offset);
    
    return HttpResponse.json({
      transactions,
      total_count: 150, // Total available
      has_more: offset + limit < 150
    });
  }),

  // Delete Transaction - POST /api/transaction/delete
  http.post('/api/transaction/delete', async ({ request }) => {
    await delay(200);
    
    const body = await request.json();
    
    if (!body.id) {
      return HttpResponse.json(
        { success: false, errors: [{ code: 'MISSING_ID', message: 'Transaction ID required' }] },
        { status: 400 }
      );
    }

    // Simulate not found
    if (body.id === 'not-found') {
      return HttpResponse.json(
        { success: false, errors: [{ code: 'NOT_FOUND', message: 'Transaction not found' }] },
        { status: 404 }
      );
    }

    return new HttpResponse(null, { status: 204 });
  })
];

function generateMockTransactions(budgetId: string, limit: number, offset: number) {
  const transactions = [];
  const categories = ['food', 'transport', 'entertainment', 'utilities', 'healthcare'];
  const descriptions = [
    'Grocery shopping', 'Gas station', 'Netflix subscription', 'Electricity bill',
    'Restaurant dinner', 'Coffee shop', 'Pharmacy', 'Uber ride', 'Online purchase'
  ];

  for (let i = offset; i < offset + limit; i++) {
    const isExpense = Math.random() > 0.3; // 70% expenses, 30% income
    const amount = isExpense 
      ? -(Math.floor(Math.random() * 20000) + 1000) // -R$ 10 to -R$ 200
      : Math.floor(Math.random() * 50000) + 10000;  // R$ 100 to R$ 500

    transactions.push({
      id: `transaction-${i + 1}`,
      account_id: 'account-123',
      budget_id: budgetId,
      amount_in_cents: amount,
      description: descriptions[Math.floor(Math.random() * descriptions.length)],
      transaction_type: isExpense ? 'expense' : 'income',
      category_id: categories[Math.floor(Math.random() * categories.length)],
      transaction_date: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000).toISOString(),
      created_at: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000).toISOString()
    });
  }

  return transactions;
}
```

### Authentication Handlers  

```typescript
// mocks/context/authHandlers.ts
import { http, HttpResponse, delay } from 'msw';

export const authHandlers = [
  // Get Current User - GET /api/user/me
  http.get('/api/user/me', async ({ request }) => {
    await delay(100);
    
    const authHeader = request.headers.get('Authorization');
    
    if (!authHeader?.startsWith('Bearer ')) {
      return HttpResponse.json(
        { success: false, errors: [{ code: 'MISSING_AUTH', message: 'Authorization required' }] },
        { status: 401 }
      );
    }
    
    const token = authHeader.substring(7);
    
    // Simulate invalid token
    if (token === 'invalid-token') {
      return HttpResponse.json(
        { success: false, errors: [{ code: 'INVALID_TOKEN', message: 'Invalid or expired token' }] },
        { status: 401 }
      );
    }
    
    // Mock user data
    return HttpResponse.json({
      uid: 'user-123',
      email: 'user@orcasonhos.com',
      display_name: 'João Silva',
      photo_url: 'https://via.placeholder.com/40',
      email_verified: true,
      is_anonymous: false,
      created_at: '2024-01-01T00:00:00Z'
    });
  })
];
```

## Handlers Aggregation

```typescript
// mocks/handlers.ts
import { budgetHandlers } from './context/budgetHandlers';
import { transactionHandlers } from './context/transactionHandlers';
import { accountHandlers } from './context/accountHandlers';
import { authHandlers } from './context/authHandlers';
import { envelopeHandlers } from './context/envelopeHandlers';
import { goalHandlers } from './context/goalHandlers';
import { creditCardHandlers } from './context/creditCardHandlers';

export const handlers = [
  ...authHandlers,
  ...budgetHandlers,
  ...transactionHandlers, 
  ...accountHandlers,
  ...envelopeHandlers,
  ...goalHandlers,
  ...creditCardHandlers
];
```

## Convenções de Dados

### Base URL Consistency

```typescript
// Todos handlers devem usar '/api' como base
http.post('/api/budget/create', ...)
http.get('/api/transaction/list', ...)
http.post('/api/account/transfer-money', ...)
```

### Money Values (Centavos)

```typescript
// ✅ Sempre usar centavos nos payloads
{
  "amount_in_cents": 12345,  // R$ 123.45
  "limit_in_cents": 500000   // R$ 5,000.00
}

// ❌ Nunca usar decimais  
{
  "amount": 123.45,
  "limit": 5000.00
}
```

### Date Formats (ISO 8601)

```typescript
// ✅ Usar ISO 8601 com timezone
{
  "created_at": "2024-01-15T10:00:00Z",
  "transaction_date": "2024-01-15T00:00:00Z"
}

// ❌ Evitar outros formatos
{
  "created_at": "15/01/2024 10:00:00",
  "date": "2024-01-15"
}
```

### Error Response Format

```typescript
// Padrão de resposta de erro consistente
{
  "success": false,
  "errors": [
    {
      "code": "VALIDATION_ERROR",
      "message": "Field is required",
      "field": "name"  // opcional
    }
  ],
  "timestamp": "2024-01-15T10:00:00Z"
}
```

## Advanced Features

### Dynamic Data Generation

```typescript
// Mock data que varia entre requests
http.get('/api/budget/:id/summary', ({ params }) => {
  // Generate different data each time
  const usage = Math.random() * 100;
  const color = usage > 80 ? 'danger' : usage > 60 ? 'warning' : 'success';
  
  return HttpResponse.json({
    usage_percentage: Math.round(usage),
    status: color,
    // ... other fields
  });
});
```

### Stateful Mocks

```typescript
// Maintain state between requests
const budgetStore = new Map();

http.post('/api/budget/create', async ({ request }) => {
  const body = await request.json();
  const id = `budget-${Date.now()}`;
  
  budgetStore.set(id, {
    id,
    ...body,
    created_at: new Date().toISOString()
  });
  
  return HttpResponse.json({ id });
});

http.get('/api/budget/:id', ({ params }) => {
  const budget = budgetStore.get(params.id);
  
  if (!budget) {
    return HttpResponse.json(
      { error: 'Budget not found' },
      { status: 404 }
    );
  }
  
  return HttpResponse.json(budget);
});
```

### Request/Response Logging

```typescript
// Debug helper for development
if (!environment.production) {
  http.all('/api/*', ({ request }) => {
    console.log(`[MSW] ${request.method} ${request.url}`);
    return passthrough(); // Let other handlers process
  });
}
```

## Environment Configuration

### Feature Flag Integration

```typescript
// environments/environment.ts
export const environment = {
  production: false,
  flags: {
    mswEnabled: true,     // Enable MSW
    authDisabled: false,  // Bypass auth
    offlineMode: false    // Simulate offline
  }
};
```

### Conditional Handler Loading

```typescript
// Load different handlers based on environment
async function getHandlers() {
  const baseHandlers = await import('./handlers');
  
  if (environment.flags.offlineMode) {
    const offlineHandlers = await import('./offline-handlers');
    return [...baseHandlers.handlers, ...offlineHandlers.handlers];
  }
  
  return baseHandlers.handlers;
}
```

## Performance Considerations

### Realistic Delays

```typescript
// Simulate realistic network conditions
await delay(Math.random() * 200 + 100); // 100-300ms random delay

// Different delays for different operations
const delays = {
  create: 300,
  update: 250, 
  delete: 200,
  get: 100,
  list: 150
};
```

### Large Data Sets

```typescript
// Handle large lists with pagination
http.get('/api/transaction/list', ({ request }) => {
  const url = new URL(request.url);
  const limit = Math.min(parseInt(url.searchParams.get('limit') || '20'), 100);
  const offset = parseInt(url.searchParams.get('offset') || '0');
  
  // Generate only requested slice
  const transactions = generateTransactions(offset, limit);
  
  return HttpResponse.json({
    transactions,
    total_count: 5000,  // Total available
    has_more: offset + limit < 5000
  });
});
```

---

**Ver também:**
- [Testing Strategy](./testing-strategy.md) - Como usar MSW nos testes
- [Backend Integration](./backend-integration.md) - Alinhamento dos mocks com APIs reais
- [Environment Configuration](./environment-configuration.md) - Feature flags e configurações