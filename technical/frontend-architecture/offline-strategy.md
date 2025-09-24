# Offline-First e Sincronização

> ⚠️ **Status Atual**: **POSTERGADO PARA PÓS-MVP**
> Esta funcionalidade foi temporariamente adiada para focar no lançamento do MVP.
> Ver: [ADR 0011 - Postergação Offline-First](../../adr/0011-postergacao-offline-first-mvp.md)
>
> **Estratégia MVP**: Online-first com HttpClient direto e cache HTTP básico
> **Retomada**: Após validação do product-market fit e > 1.000 usuários ativos

## Objetivos da Strategy

- **Funcionamento essencial** do app sem conexão de internet
- **Experiência consistente** com atualização transparente quando rede voltar
- **Baixo acoplamento**: Lógica de sync isolada da UI
- **Ports dedicados** na camada Application para abstração

## Arquitetura de Persistência

### Armazenamento Local (IndexedDB + Dexie)

**Biblioteca Utilizada:** [Dexie](https://dexie.org/) - wrapper TypeScript para IndexedDB que simplifica operações e melhora a experiência de desenvolvimento.

**Por que Dexie?**
- Abstração simples e intuitiva sobre IndexedDB
- TypeScript nativo com tipagem forte
- Suporte a queries avançadas (where, orderBy, filter)
- Manejo automático de transações e conexões
- Hooks para observabilidade e debugging
- Suporte a migrações de schema

#### Schema e Configuração

```typescript
// infra/storage/dexie-database.ts
import Dexie, { Table } from 'dexie';

export interface Budget {
  id: string;
  name: string;
  userId: string;
  createdAt: Date;
  updatedAt: Date;
  syncStatus: 'synced' | 'pending' | 'failed';
}

export interface Account {
  id: string;
  budgetId: string;
  name: string;
  balance: number;
  updatedAt: Date;
  syncStatus: 'synced' | 'pending' | 'failed';
}

export interface Transaction {
  id: string;
  accountId: string;
  amount: number;
  description: string;
  category: string;
  date: Date;
  createdAt: Date;
  syncStatus: 'synced' | 'pending' | 'failed';
}

export interface Goal {
  id: string;
  budgetId: string;
  title: string;
  targetAmount: number;
  currentAmount: number;
  targetDate: Date;
  updatedAt: Date;
  syncStatus: 'synced' | 'pending' | 'failed';
}

export interface CachedQuery<T = unknown> {
  queryKey: string;
  data: T;
  cachedAt: Date;
  expiresAt: Date;
  etag?: string;
}

export interface QueuedCommand {
  id: string;
  type: string;
  payload: Record<string, unknown>;
  idempotencyKey: string;
  entityId?: string;
  createdAt: Date;
  attempts: number;
  status: 'pending' | 'processing' | 'failed' | 'completed';
}

export class OrçaSonhosDatabase extends Dexie {
  budgets!: Table<Budget>;
  accounts!: Table<Account>;
  transactions!: Table<Transaction>;
  goals!: Table<Goal>;
  queryCache!: Table<CachedQuery>;
  commandsQueue!: Table<QueuedCommand>;

  constructor() {
    super('OrçaSonhosDB');

    this.version(1).stores({
      budgets: 'id, userId, syncStatus, updatedAt',
      accounts: 'id, budgetId, syncStatus, updatedAt',
      transactions: 'id, accountId, syncStatus, date, createdAt',
      goals: 'id, budgetId, syncStatus, targetDate, updatedAt',
      queryCache: 'queryKey, expiresAt',
      commandsQueue: 'id, status, createdAt, attempts'
    });

    // Hooks para auditoria e debugging
    this.budgets.hook('creating', (primKey, obj, trans) => {
      obj.createdAt = new Date();
      obj.updatedAt = new Date();
      obj.syncStatus = 'pending';
    });

    this.budgets.hook('updating', (modifications, primKey, obj, trans) => {
      modifications.updatedAt = new Date();
      modifications.syncStatus = 'pending';
    });
  }
}

export const db = new OrçaSonhosDatabase();
```

#### Adapter Implementation com Dexie

```typescript
// infra/storage/local-store.adapter.ts
export interface ILocalStorePort {
  // Entities storage
  getEntity<T>(storeName: string, id: string): Promise<T | null>;
  setEntity<T>(storeName: string, id: string, entity: T): Promise<void>;
  deleteEntity(storeName: string, id: string): Promise<void>;
  getAllEntities<T>(storeName: string): Promise<T[]>;

  // Query cache
  getCachedQuery<T>(queryKey: string): Promise<CachedQuery<T> | null>;
  setCachedQuery<T>(queryKey: string, data: T, ttl?: number): Promise<void>;

  // Commands queue
  enqueueCommand(command: QueuedCommand): Promise<void>;
  dequeueCommand(id: string): Promise<void>;
  getPendingCommands(): Promise<QueuedCommand[]>;
}

@Injectable({ providedIn: 'root' })
export class DexieAdapter implements ILocalStorePort {
  constructor(private db: OrçaSonhosDatabase = db) {}

  async getEntity<T>(storeName: string, id: string): Promise<T | null> {
    const table = this.getTable(storeName);
    const entity = await table.get(id);
    return (entity as T) || null;
  }

  async setEntity<T>(storeName: string, id: string, entity: T): Promise<void> {
    const table = this.getTable(storeName);
    await table.put({ ...entity, id });
  }

  async deleteEntity(storeName: string, id: string): Promise<void> {
    const table = this.getTable(storeName);
    await table.delete(id);
  }

  async getAllEntities<T>(storeName: string): Promise<T[]> {
    const table = this.getTable(storeName);
    return table.toArray() as Promise<T[]>;
  }

  async getCachedQuery<T>(queryKey: string): Promise<CachedQuery<T> | null> {
    const cached = await this.db.queryCache.get(queryKey);

    if (!cached) return null;

    // Verificar se expirou
    if (cached.expiresAt < new Date()) {
      await this.db.queryCache.delete(queryKey);
      return null;
    }

    return cached as CachedQuery<T>;
  }

  async setCachedQuery<T>(
    queryKey: string,
    data: T,
    ttl: number = 5 * 60 * 1000
  ): Promise<void> {
    const cachedQuery: CachedQuery<T> = {
      queryKey,
      data,
      cachedAt: new Date(),
      expiresAt: new Date(Date.now() + ttl)
    };

    await this.db.queryCache.put(cachedQuery);
  }

  async enqueueCommand(command: QueuedCommand): Promise<void> {
    await this.db.commandsQueue.add(command);
  }

  async dequeueCommand(id: string): Promise<void> {
    await this.db.commandsQueue.delete(id);
  }

  async getPendingCommands(): Promise<QueuedCommand[]> {
    return this.db.commandsQueue
      .where('status')
      .equals('pending')
      .orderBy('createdAt')
      .toArray();
  }

  private getTable(storeName: string) {
    switch (storeName) {
      case 'budgets': return this.db.budgets;
      case 'accounts': return this.db.accounts;
      case 'transactions': return this.db.transactions;
      case 'goals': return this.db.goals;
      default: throw new Error(`Unknown store: ${storeName}`);
    }
  }
}
```

#### Queries Avançadas com Dexie

```typescript
// infra/repositories/TransactionRepository.ts
@Injectable({ providedIn: 'root' })
export class LocalTransactionRepository {
  constructor(private db: OrçaSonhosDatabase = db) {}

  async getTransactionsByAccount(
    accountId: string,
    limit?: number
  ): Promise<Transaction[]> {
    let query = this.db.transactions
      .where('accountId')
      .equals(accountId)
      .orderBy('date')
      .reverse();

    if (limit) {
      query = query.limit(limit);
    }

    return query.toArray();
  }

  async getTransactionsByDateRange(
    accountId: string,
    startDate: Date,
    endDate: Date
  ): Promise<Transaction[]> {
    return this.db.transactions
      .where('accountId')
      .equals(accountId)
      .and(transaction =>
        transaction.date >= startDate &&
        transaction.date <= endDate
      )
      .orderBy('date')
      .toArray();
  }

  async getTransactionsByCategory(
    budgetId: string,
    category: string
  ): Promise<Transaction[]> {
    // Join-like query usando Dexie
    const accounts = await this.db.accounts
      .where('budgetId')
      .equals(budgetId)
      .toArray();

    const accountIds = accounts.map(acc => acc.id);

    return this.db.transactions
      .where('accountId')
      .anyOf(accountIds)
      .and(transaction => transaction.category === category)
      .orderBy('date')
      .reverse()
      .toArray();
  }

  async getPendingSyncTransactions(): Promise<Transaction[]> {
    return this.db.transactions
      .where('syncStatus')
      .equals('pending')
      .orderBy('createdAt')
      .toArray();
  }
}
```

### Estruturas de Dados

#### Cached Query
```typescript
// models/cache/CachedQuery.ts
export interface CachedQuery<T> {
  readonly data: T;
  readonly cachedAt: Date;
  readonly expiresAt: Date;
  readonly queryKey: string;
  readonly etag?: string; // Para validação com servidor
}

export class CachedQuery<T> {
  constructor(
    private readonly _data: T,
    private readonly _queryKey: string,
    private readonly _ttl: number = 5 * 60 * 1000 // 5 minutes default
  ) {}

  static create<T>(data: T, queryKey: string, ttl?: number): CachedQuery<T> {
    return new CachedQuery(data, queryKey, ttl);
  }

  get data(): T { return this._data; }
  get queryKey(): string { return this._queryKey; }
  get cachedAt(): Date { return new Date(Date.now()); }
  get expiresAt(): Date { return new Date(Date.now() + this._ttl); }
  
  isExpired(): boolean {
    return Date.now() > this.expiresAt.getTime();
  }
}
```

#### Queued Command
```typescript
// models/sync/QueuedCommand.ts
export interface QueuedCommand {
  readonly id: string;
  readonly type: string; // 'CREATE_TRANSACTION', 'UPDATE_BUDGET', etc.
  readonly payload: Record<string, unknown>;
  readonly idempotencyKey: string;
  readonly entityId?: string;
  readonly entityVersion?: number;
  readonly createdAt: Date;
  readonly attempts: number;
  readonly lastAttemptAt?: Date;
  readonly status: 'pending' | 'processing' | 'failed' | 'completed';
}

export class QueuedCommand {
  constructor(
    private readonly _id: string,
    private readonly _type: string,
    private readonly _payload: Record<string, unknown>,
    private readonly _idempotencyKey: string,
    private readonly _entityId?: string
  ) {}

  static create(params: {
    type: string;
    payload: Record<string, unknown>;
    entityId?: string;
  }): QueuedCommand {
    return new QueuedCommand(
      generateId(),
      params.type,
      params.payload,
      generateIdempotencyKey(),
      params.entityId
    );
  }

  get id(): string { return this._id; }
  get type(): string { return this._type; }
  get payload(): Record<string, unknown> { return this._payload; }
  get idempotencyKey(): string { return this._idempotencyKey; }
}
```

## Strategy de Queries (Leitura)

### Stale-While-Revalidate Pattern

```typescript
// application/queries/base-cached-query.handler.ts
export abstract class BaseCachedQueryHandler<TQuery, TResult> {
  constructor(
    protected localStore: ILocalStorePort,
    protected remoteService: IRemoteServicePort,
    protected networkService: INetworkStatusPort
  ) {}

  async handle(query: TQuery): Promise<Either<QueryError, TResult>> {
    const queryKey = this.buildQueryKey(query);
    
    // 1. Buscar dados do cache local (stale)
    const cachedResult = await this.getCachedData(queryKey);
    
    // 2. Se tem cache válido, retornar imediatamente
    if (cachedResult && !cachedResult.isExpired()) {
      // Disparar revalidação em background
      this.revalidateInBackground(query, queryKey);
      return Either.success(cachedResult.data);
    }
    
    // 3. Se está offline e tem cache (mesmo expirado)
    if (!this.networkService.isOnline() && cachedResult) {
      return Either.success(cachedResult.data);
    }
    
    // 4. Tentar buscar dados frescos
    return this.fetchFreshData(query, queryKey);
  }

  private async getCachedData(queryKey: string): Promise<CachedQuery<TResult> | null> {
    return this.localStore.getCachedQuery<TResult>(queryKey);
  }

  private async fetchFreshData(
    query: TQuery, 
    queryKey: string
  ): Promise<Either<QueryError, TResult>> {
    try {
      const remoteResult = await this.fetchFromRemote(query);
      
      if (remoteResult.hasError) {
        // Se falhou e tem cache antigo, usar cache
        const staleCache = await this.getCachedData(queryKey);
        if (staleCache) {
          return Either.success(staleCache.data);
        }
        return remoteResult;
      }

      // Cache dados frescos
      await this.cacheData(queryKey, remoteResult.data!);
      
      return remoteResult;
    } catch (error) {
      return Either.error(new QueryError('Failed to fetch data'));
    }
  }

  private revalidateInBackground(query: TQuery, queryKey: string): void {
    // Não aguardar resultado - executar em background
    setTimeout(async () => {
      try {
        const freshResult = await this.fetchFromRemote(query);
        if (!freshResult.hasError) {
          await this.cacheData(queryKey, freshResult.data!);
          // Notificar UI de dados atualizados (opcional)
          this.notifyDataUpdated(queryKey, freshResult.data!);
        }
      } catch (error) {
        // Falha silenciosa em background revalidation
        console.warn('Background revalidation failed:', error);
      }
    }, 0);
  }

  protected abstract buildQueryKey(query: TQuery): string;
  protected abstract fetchFromRemote(query: TQuery): Promise<Either<QueryError, TResult>>;
  protected abstract notifyDataUpdated(queryKey: string, data: TResult): void;
}
```

### Implementação Concreta

```typescript
// application/queries/GetBudgetSummaryQueryHandler.ts
export class GetBudgetSummaryQueryHandler extends BaseCachedQueryHandler<
  GetBudgetSummaryQuery,
  BudgetSummaryDto
> {
  constructor(
    localStore: ILocalStorePort,
    private budgetService: IBudgetServicePort,
    networkService: INetworkStatusPort
  ) {
    super(localStore, budgetService, networkService);
  }

  protected buildQueryKey(query: GetBudgetSummaryQuery): string {
    return `budget_summary:${query.budgetId}:${query.period}`;
  }

  protected async fetchFromRemote(
    query: GetBudgetSummaryQuery
  ): Promise<Either<QueryError, BudgetSummaryDto>> {
    return this.budgetService.getBudgetSummary(query.budgetId, query.period);
  }

  protected notifyDataUpdated(queryKey: string, data: BudgetSummaryDto): void {
    // Usar EventBus para notificar componentes interessados
    this.eventBus.emit('query_updated', { queryKey, data });
  }
}
```

## Strategy de Commands (Escrita)

### Fluxo Otimista

```typescript
// application/services/OfflineCommandService.ts
@Injectable({ providedIn: 'root' })
export class OfflineCommandService {
  constructor(
    private localStore: ILocalStorePort,
    private networkService: INetworkStatusPort,
    private syncService: ISyncService
  ) {}

  async executeCommand<T>(
    command: Command<T>,
    optimisticUpdate?: (entity: T) => void
  ): Promise<Either<CommandError, void>> {
    // 1. Validar comando localmente
    const validation = await this.validateCommand(command);
    if (validation.hasError) {
      return validation;
    }

    // 2. Enfileirar comando para sincronização
    const queuedCommand = QueuedCommand.create({
      type: command.type,
      payload: command.payload,
      entityId: command.entityId
    });

    await this.localStore.enqueueCommand(queuedCommand);

    // 3. Aplicar atualização otimista (se fornecida)
    if (optimisticUpdate) {
      try {
        await this.applyOptimisticUpdate(command, optimisticUpdate);
      } catch (error) {
        // Reverter enfileiramento se falha otimista
        await this.localStore.dequeueCommand(queuedCommand.id);
        return Either.error(new CommandError('Failed to apply optimistic update'));
      }
    }

    // 4. Tentar processar imediatamente se online
    if (this.networkService.isOnline()) {
      // Não aguardar - processar em background
      this.syncService.processQueue();
    }

    return Either.success(undefined);
  }

  private async validateCommand<T>(command: Command<T>): Promise<Either<CommandError, void>> {
    // Validações que podem ser feitas offline
    // Ex.: campos obrigatórios, tipos, ranges básicos
    return Either.success(undefined);
  }

  private async applyOptimisticUpdate<T>(
    command: Command<T>,
    optimisticUpdate: (entity: T) => void
  ): Promise<void> {
    // Buscar entity atual do cache
    const entity = await this.getEntityFromCache(command.entityId!, command.entityType);
    
    if (entity) {
      // Aplicar update otimista
      optimisticUpdate(entity);
      
      // Salvar no cache local com flag de "pendente sync"
      await this.saveEntityToCache(entity, command.entityType, true);
    }
  }
}
```

### Sync Service

```typescript
// application/services/SyncService.ts
@Injectable({ providedIn: 'root' })
export class SyncService {
  private processingQueue = false;

  constructor(
    private localStore: ILocalStorePort,
    private commandAdapter: ICommandServicePort,
    private networkService: INetworkStatusPort
  ) {
    // Processar fila quando rede voltar
    this.networkService.onOnline(() => this.processQueue());
  }

  async processQueue(): Promise<void> {
    if (this.processingQueue) return;
    
    this.processingQueue = true;
    
    try {
      const pendingCommands = await this.localStore.getPendingCommands();
      
      for (const command of pendingCommands) {
        await this.processCommand(command);
      }
    } finally {
      this.processingQueue = false;
    }
  }

  private async processCommand(command: QueuedCommand): Promise<void> {
    try {
      // Tentar executar comando no servidor
      const result = await this.commandAdapter.executeCommand({
        type: command.type,
        payload: command.payload,
        idempotencyKey: command.idempotencyKey
      });

      if (result.hasError) {
        await this.handleCommandFailure(command, result.error);
      } else {
        await this.handleCommandSuccess(command, result.data);
      }
    } catch (error) {
      await this.handleCommandFailure(command, error);
    }
  }

  private async handleCommandSuccess(
    command: QueuedCommand,
    serverResponse: unknown
  ): Promise<void> {
    // Remover da fila
    await this.localStore.dequeueCommand(command.id);
    
    // Reconciliar estado local com resposta do servidor
    await this.reconcileEntity(command, serverResponse);
  }

  private async handleCommandFailure(
    command: QueuedCommand,
    error: unknown
  ): Promise<void> {
    if (this.isRetryableError(error)) {
      // Agendar retry com backoff exponencial
      await this.scheduleRetry(command);
    } else {
      // Falha definitiva - remover da fila e reverter otimista
      await this.handleDefinitiveFailure(command);
    }
  }

  private isRetryableError(error: unknown): boolean {
    // Network errors, 5xx, rate limits
    if (error instanceof NetworkError) return true;
    if (error instanceof ServerError && error.status >= 500) return true;
    if (error instanceof RateLimitError) return true;
    
    // 409 Conflict - necessário resolução manual
    if (error instanceof ConflictError) return false;
    
    // 4xx client errors - não tentar novamente
    return false;
  }
}
```

## Resolução de Conflitos

### Estratégia: Last-Write-Wins (LWW)

**Abordagem Escolhida:** Last-Write-Wins baseado em timestamp `updatedAt`

**Justificativa para MVP:**
- Simplicidade de implementação e manutenção
- Comportamento previsível para usuários finais
- Adequado para dados financeiros pessoais (baixa concorrência)
- Menor complexidade de UI para resolução manual
- Facilita debugging e auditoria

**Como Funciona:**
1. Toda entidade possui campo `updatedAt` com timestamp preciso
2. Em caso de conflito, a versão com `updatedAt` mais recente prevalece
3. Dados "perdedores" são mantidos em log de auditoria para recuperação
4. Interface opcional para revisão de conflitos em casos críticos

### Strategy para Conflitos 409/412

```typescript
// application/services/ConflictResolutionService.ts
export interface ConflictResolution<T> {
  readonly strategy: 'server_wins' | 'client_wins' | 'merge' | 'manual';
  readonly resolvedEntity?: T;
  readonly requiresUserInput?: boolean;
}

@Injectable({ providedIn: 'root' })
export class ConflictResolutionService {
  async resolveConflict<T>(
    localEntity: T,
    serverEntity: T,
    conflictType: ConflictType
  ): Promise<ConflictResolution<T>> {
    
    switch (conflictType) {
      case 'VERSION_CONFLICT':
        return this.resolveVersionConflict(localEntity, serverEntity);
        
      case 'CONCURRENT_MODIFICATION':
        return this.resolveConcurrentModification(localEntity, serverEntity);
        
      case 'DELETED_ENTITY':
        return this.resolveDeletedEntity(localEntity, serverEntity);
        
      default:
        return {
          strategy: 'manual',
          requiresUserInput: true
        };
    }
  }

  private resolveVersionConflict<T>(
    localEntity: T,
    serverEntity: T
  ): ConflictResolution<T> {
    // Para MVP: last-write-wins autorizado pelo servidor
    return {
      strategy: 'server_wins',
      resolvedEntity: serverEntity
    };
  }

  private resolveConcurrentModification<T>(
    localEntity: T & { updatedAt: Date },
    serverEntity: T & { updatedAt: Date }
  ): ConflictResolution<T> {
    // Last-Write-Wins: Comparar timestamps - mais recente ganha
    const localTime = localEntity.updatedAt.getTime();
    const serverTime = serverEntity.updatedAt.getTime();

    if (localTime > serverTime) {
      // Log da entidade "perdedora" para auditoria
      this.auditService.logConflictResolution({
        winnerSource: 'client',
        winnerEntity: localEntity,
        loserEntity: serverEntity,
        conflictType: 'concurrent_modification',
        resolvedAt: new Date()
      });

      return {
        strategy: 'client_wins',
        resolvedEntity: localEntity
      };
    } else if (serverTime > localTime) {
      // Log da entidade "perdedora" para auditoria
      this.auditService.logConflictResolution({
        winnerSource: 'server',
        winnerEntity: serverEntity,
        loserEntity: localEntity,
        conflictType: 'concurrent_modification',
        resolvedAt: new Date()
      });

      return {
        strategy: 'server_wins',
        resolvedEntity: serverEntity
      };
    } else {
      // Timestamps idênticos - preferir servidor (tie-breaker)
      return {
        strategy: 'server_wins',
        resolvedEntity: serverEntity
      };
    }
  }
}
```

### UI para Resolução Manual

```typescript
// app/components/conflict-resolution-dialog.component.ts
@Component({
  selector: 'app-conflict-resolution',
  template: `
    <os-modal [isOpen]="isOpen()" (onClose)="cancel()">
      <os-modal-header>
        <h2>Conflito Detectado</h2>
        <p>Os dados foram modificados enquanto você estava offline.</p>
      </os-modal-header>
      
      <os-modal-content>
        <div class="conflict-comparison">
          <div class="local-version">
            <h3>Sua Versão</h3>
            <pre>{{ localData() | json }}</pre>
          </div>
          
          <div class="server-version">
            <h3>Versão do Servidor</h3>
            <pre>{{ serverData() | json }}</pre>
          </div>
        </div>
      </os-modal-content>
      
      <os-modal-actions>
        <os-button variant="secondary" (onClick)="useServerVersion()">
          Usar Versão do Servidor
        </os-button>
        <os-button variant="primary" (onClick)="useLocalVersion()">
          Manter Minhas Alterações
        </os-button>
        <os-button variant="tertiary" (onClick)="showMergeEditor()">
          Mesclar Manualmente
        </os-button>
      </os-modal-actions>
    </os-modal>
  `
})
export class ConflictResolutionDialogComponent {
  isOpen = input.required<boolean>();
  localData = input.required<unknown>();
  serverData = input.required<unknown>();
  
  onResolution = output<ConflictResolution<unknown>>();
  onCancel = output<void>();
}
```

## Service Worker e PWA

### Background Sync

```typescript
// public/sw.js - Service Worker
self.addEventListener('sync', event => {
  if (event.tag === 'command-sync') {
    event.waitUntil(processCommandQueue());
  }
});

async function processCommandQueue() {
  // Buscar comandos pendentes do IndexedDB
  const commands = await getQueuedCommands();
  
  for (const command of commands) {
    try {
      const response = await fetch('/api' + command.endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${await getStoredToken()}`
        },
        body: JSON.stringify(command.payload)
      });
      
      if (response.ok) {
        await removeFromQueue(command.id);
      } else {
        await incrementRetryCount(command.id);
      }
    } catch (error) {
      await incrementRetryCount(command.id);
    }
  }
}
```

### Cache Strategy

```typescript
// Cache strategy para diferentes tipos de requests
self.addEventListener('fetch', event => {
  const { request } = event;
  
  if (request.url.includes('/api/')) {
    if (request.method === 'GET') {
      // Queries: stale-while-revalidate
      event.respondWith(staleWhileRevalidate(request));
    } else {
      // Commands: não cachear, usar fila offline
      event.respondWith(handleCommand(request));
    }
  } else {
    // Assets estáticos: cache-first
    event.respondWith(cacheFirst(request));
  }
});
```

## Edge Cases e Observabilidade

### Telemetria

```typescript
// application/services/OfflineMetricsService.ts
@Injectable({ providedIn: 'root' })
export class OfflineMetricsService {
  async recordSyncMetrics(): Promise<void> {
    const metrics = {
      queueSize: await this.getQueueSize(),
      failedCommands: await this.getFailedCommandsCount(),
      averageSyncTime: await this.calculateAverageSyncTime(),
      conflictRate: await this.calculateConflictRate(),
      cacheHitRate: await this.calculateCacheHitRate()
    };
    
    // Enviar para analytics (quando online)
    this.analyticsService.track('offline_metrics', metrics);
  }

  async getQueueSize(): Promise<number> {
    const commands = await this.localStore.getPendingCommands();
    return commands.length;
  }
}
```

### Cleanup e Migração

```typescript
// application/services/DataMaintenanceService.ts
@Injectable({ providedIn: 'root' })
export class DataMaintenanceService {
  async performMaintenance(): Promise<void> {
    // Limpar cache expirado
    await this.cleanExpiredCache();
    
    // Remover comandos órfãos
    await this.cleanOrphanedCommands();
    
    // Migrar schema se necessário
    await this.migrateDataSchema();
  }

  private async cleanExpiredCache(): Promise<void> {
    const allCached = await this.localStore.getAllCachedQueries();
    const expired = allCached.filter(cached => cached.isExpired());
    
    for (const expiredCache of expired) {
      await this.localStore.deleteCachedQuery(expiredCache.queryKey);
    }
  }
}
```

---

**Ver também:**
- [Authentication](./authentication.md) - Como autenticação funciona offline
- [Backend Integration](./backend-integration.md) - Integração com APIs para sync
- [Performance](./performance.md) - Otimizações para apps offline-first