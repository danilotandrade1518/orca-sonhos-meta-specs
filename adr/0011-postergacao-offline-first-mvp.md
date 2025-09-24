# ADR 0011 - Postergação da Estratégia Offline-First para Pós-MVP

## Status

Accepted - 2025-09-24

## Contexto

Durante o desenvolvimento da arquitetura frontend do OrçaSonhos, foi especificada uma estratégia offline-first robusta utilizando IndexedDB com Dexie, fila de comandos para sincronização, resolução de conflitos e Service Workers para PWA.

No entanto, com a proximidade do lançamento do MVP e a necessidade de foco nas funcionalidades core que geram valor imediato para os usuários, surgiu a questão sobre a prioridade da implementação offline-first.

A estratégia offline-first, embora valiosa para a experiência do usuário, adiciona significativa complexidade técnica:
- Configuração e manutenção do IndexedDB/Dexie
- Implementação de filas de comando e sincronização
- Lógica de resolução de conflitos (Last-Write-Wins)
- Configuração de Service Workers
- Testes de cenários offline/online
- Debugging de problemas de sincronização

Para o contexto atual do MVP, onde o foco deve estar na validação do produto e das funcionalidades core (gestão de orçamentos, transações, metas), essa complexidade pode representar um risco desnecessário.

## Decisão

**Adiar a implementação completa da estratégia offline-first para depois do lançamento do MVP.**

Para o MVP, será implementada uma estratégia online-first simplificada:

### Estratégia MVP (Online-First):
- **Armazenamento**: Sem persistência local complexa
- **API Calls**: Diretas com HttpClient do Angular
- **Cache**: Apenas cache de HTTP padrão do browser
- **Feedback de Conectividade**: Indicadores básicos quando offline
- **Experiência Offline**: Mensagens informativas sobre necessidade de conexão

### Mantém no MVP:
- Arquitetura preparada para offline (Ports/Adapters)
- Estrutura de Commands/Queries que facilita migração futura
- UI responsiva e otimizada para mobile
- Service Workers básicos apenas para cache de assets

## Consequências

### Positivas

- **Tempo de Desenvolvimento**: Redução significativa no tempo até o MVP
- **Complexidade**: Stack mais simples para debugging e manutenção inicial
- **Foco**: Concentração nas funcionalidades core de valor
- **Risco**: Menor superfície de falha para o lançamento
- **Iteração**: Permite validar o produto antes de investir em offline

### Negativas / Riscos Aceitos

- **Experiência Mobile**: Usuários precisarão de conexão constante
- **Adoção**: Potencial impacto na adoção em áreas com conectividade ruim
- **Refatoração**: Será necessário refatorar para adicionar offline posteriormente
- **Competitividade**: Diferencial competitivo adiado

### Riscos Mitigados

A arquitetura foi projetada pensando em offline-first, então:
- **Ports/Adapters** já abstraem a camada de dados
- **Commands/Queries** facilitam implementação futura de filas
- **Angular Signals** já preparam para reatividade offline
- **Documentação técnica** preservada como referência

## Critérios para Retomar

A implementação offline-first deve ser retomada quando ocorrer **um ou mais** dos seguintes cenários:

### Critérios de Produto
- **Tração validada**: MVP com > 1.000 usuários ativos mensais
- **Feedback de usuários**: Solicitações frequentes por funcionalidade offline
- **Contexto de uso**: Evidência de uso em locais com conectividade limitada
- **Competição**: Concorrentes lançarem com vantagem offline significativa

### Critérios de Negócio
- **Product-Market Fit**: Comprovado através de métricas de retenção
- **Roadmap validado**: Core features funcionando e bem adotadas
- **Recursos**: Equipe com bandwidth para complexidade adicional
- **ROI**: Evidência que offline aumentará significativamente engajamento

### Critérios Técnicos
- **Estabilidade**: Sistema atual estável com poucos bugs críticos
- **Performance**: Baseline de performance bem estabelecida
- **Monitoramento**: Observabilidade robusta para debugging offline

## Implementação da Migração Futura

Quando retomar, seguir esta ordem de implementação:

### Fase 1: Persistência Local
- Configurar Dexie/IndexedDB conforme documentação existente
- Implementar LocalStoreAdapter mantendo interface dos Ports
- Migrar queries para padrão stale-while-revalidate

### Fase 2: Command Queue
- Implementar fila de comandos offline
- Adicionar sincronização automática quando voltar online
- Sistema básico de retry com backoff

### Fase 3: Resolução de Conflitos
- Implementar estratégia Last-Write-Wins documentada
- UI para resolução manual em casos críticos
- Logging de conflitos para análise

### Fase 4: Service Workers Avançados
- Background sync para fila de comandos
- Cache strategies personalizadas
- Notificações de sincronização

## Alternativas Consideradas

### Offline Limitado
Implementar apenas cache de leitura, sem funcionalidade de escrita offline.
**Rejeitado**: Complexidade ainda significativa sem benefício proporcional.

### Offline Terceirizado
Utilizar soluções como Firebase Offline ou AWS AppSync.
**Rejeitado**: Vendor lock-in e menor controle sobre a experiência.

### Progressive Enhancement
Implementar offline gradualmente feature por feature.
**Rejeitado**: Pode gerar UX inconsistente e bugs difíceis de rastrear.

## Documentação Relacionada

- **Documentação Técnica Preservada**: [`technical/frontend-architecture/offline-strategy.md`](../technical/frontend-architecture/offline-strategy.md)
- **Escopo MVP Atualizado**: [`business/product-vision/mvp-scope.md`](../business/product-vision/mvp-scope.md)
- **Referência para Implementação**: ADR 0009 sobre postergações de observabilidade (padrão similar)

## Conclusão

Esta decisão prioriza **speed-to-market** e **validação de produto** sobre **experiência offline premium**.

A estratégia offline-first permanece como objetivo técnico importante, mas será implementada após validação do product-market fit, quando houver maior segurança sobre ROI e recursos para lidar com a complexidade adicional.

A arquitetura foi desenhada para facilitar esta migração futura, minimizando o impacto da decisão temporária de postergação.