# ADR-0013: Adoção de Feature-Based Architecture no Frontend

---

**Metadados Estruturados para IA/RAG:**

````yaml
document_type: "architecture_decision_record"
domain: "frontend_architecture"
audience: ["architects", "tech_leads", "frontend_developers", "product_managers"]
complexity: "high"
tags: ["adr", "architecture_decision", "frontend", "feature_based", "angular", "scalability"]
related_docs: ["0012-adocao-dto-first-architecture-frontend.md", "technical/frontend-architecture/overview.md"]
ai_context: "Architecture decision record for migrating frontend from DTO-First to Feature-Based Architecture while maintaining DTO-First principles"
decision_status: "accepted"
decision_date: "2025-01-24"
decision_impact: "high"
technologies_affected: ["angular", "typescript", "rxjs", "angular_material"]
last_updated: "2025-01-24"
---

## Status

**Accepted**

- **Status**: Aceito
- **Data da Decisão**: 2025-01-24
- **Responsável pela Decisão**: Equipe de Arquitetura
- **Stakeholders Consultados**: Tech Lead, Frontend Developers, Product Owner

---

## Contexto

### **Situação Atual:**
O frontend do OrçaSonhos atualmente segue uma **DTO-First Architecture** (conforme ADR-0012), organizada por camadas técnicas:

- **Estrutura por Camadas**: `/components`, `/services`, `/dtos`, `/models`
- **DTOs como Cidadãos de Primeira Classe**: Contratos diretos com API
- **Angular Signals**: Gerenciamento de estado reativo
- **Angular Material**: Design System base
- **Clean Architecture**: Separação clara de responsabilidades

### **Problema/Oportunidade:**
Com o crescimento do projeto, a organização por camadas técnicas está criando desafios:

1. **Dispersão de Funcionalidades**: Componentes relacionados espalhados por diferentes pastas
2. **Dificuldade de Navegação**: Desenvolvedores precisam navegar entre múltiplas pastas para uma feature
3. **Acoplamento Indireto**: Features compartilham componentes sem clareza de dependências
4. **Escalabilidade Limitada**: Estrutura não escala bem com aumento de funcionalidades
5. **Manutenção Complexa**: Mudanças em features impactam múltiplas camadas

### **Fatores de Influência:**
- **Técnicos**: Necessidade de melhor organização para equipes maiores, lazy loading eficiente
- **Negócio**: Crescimento rápido de funcionalidades, necessidade de desenvolvimento paralelo
- **Equipe**: Múltiplos desenvolvedores trabalhando em features diferentes
- **Externos**: Preparação para Design System isolado, integração com micro-frontends futuros

### **Requisitos e Constraints:**
```yaml
requirements:
  functional:
    - "Manter princípios DTO-First Architecture"
    - "Suporte a lazy loading de features"
    - "Isolamento de funcionalidades de negócio"
    - "Design System isolado e reutilizável"

  non_functional:
    - performance: "Lazy loading sem impacto na performance inicial"
    - scalability: "Estrutura que escala com crescimento da equipe"
    - maintainability: "Facilidade de manutenção e navegação"
    - modularity: "Features independentes e testáveis"

constraints:
  technical:
    - "Manter Angular Signals para estado"
    - "Preservar Angular Material como base"
    - "Manter compatibilidade com DTO-First"
    - "Suporte a TypeScript strict mode"

  business:
    - "Migração sem interrupção do desenvolvimento"
    - "Preparação para Design System futuro"
    - "Alinhamento com arquitetura backend"

  regulatory:
    - "Manter padrões de acessibilidade existentes"
````

---

## Decisão

### **Decisão Tomada:**

Adotar **Feature-Based Architecture** no frontend, organizando o código por funcionalidades de negócio, mantendo os princípios fundamentais da DTO-First Architecture.

### **Justificativa:**

A Feature-Based Architecture resolve os problemas de escalabilidade e manutenibilidade da organização por camadas, permitindo:

1. **Desenvolvimento Paralelo**: Features independentes podem ser desenvolvidas simultaneamente
2. **Navegação Intuitiva**: Tudo relacionado a uma feature fica em um local
3. **Lazy Loading Eficiente**: Carregamento sob demanda por funcionalidade
4. **Manutenção Simplificada**: Mudanças isoladas por feature
5. **Preparação para Micro-Frontends**: Estrutura compatível com arquitetura futura

### **Arquitetura Resultante:**

```
Antes (DTO-First por Camadas):
┌─────────────────────────────────────┐
│              /src/app               │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐│
│  │/components│/services│/dtos     ││
│  │         │ │         │ │         ││
│  └─────────┘ └─────────┘ └─────────┘│
└─────────────────────────────────────┘

Depois (Feature-Based):
┌─────────────────────────────────────┐
│              /src/app               │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐│
│  │/features│/shared   │/core      ││
│  │         │ │         │ │         ││
│  │┌───────┐│ │┌───────┐│ │┌───────┐││
│  ││budgets││ ││ui-comp││ ││services│││
│  ││transac││ ││theme  ││ ││guards  │││
│  ││goals  ││ ││utils  ││ ││interc  │││
│  │└───────┘│ │└───────┘│ │└───────┘││
│  └─────────┘ └─────────┘ └─────────┘│
└─────────────────────────────────────┘
```

---

## Alternativas Consideradas

### **Alternativa 1: Manter DTO-First por Camadas**

**Descrição**: Continuar com organização atual por camadas técnicas

**Prós**:

- Sem necessidade de migração
- Estrutura já estabelecida
- Princípios DTO-First mantidos

**Contras**:

- Dificuldade de navegação com crescimento
- Desenvolvimento paralelo limitado
- Manutenção complexa
- Não escala com equipe maior

**Por que foi rejeitada**: Não resolve os problemas de escalabilidade e manutenibilidade identificados

### **Alternativa 2: Micro-Frontends Completo**

**Descrição**: Implementar arquitetura de micro-frontends desde o início

**Prós**:

- Máxima independência entre features
- Escalabilidade total
- Tecnologias independentes por feature

**Contras**:

- Complexidade excessiva para projeto atual
- Overhead de infraestrutura
- Dificuldade de compartilhamento de código
- Não alinhado com stack atual

**Por que foi rejeitada**: Complexidade desnecessária para o estágio atual do projeto

### **Alternativa 3: Feature-Based com Domain Models**

**Descrição**: Combinar Feature-Based com reintrodução de Domain Models

**Prós**:

- Isolamento completo de regras de negócio
- Features totalmente independentes
- Flexibilidade máxima

**Contras**:

- Contradiz ADR-0012 (DTO-First)
- Complexidade desnecessária
- Duplicação de lógica com backend
- Overhead de manutenção

**Por que foi rejeitada**: Contradiz a decisão já estabelecida de DTO-First Architecture

### **Opção "Não Fazer Nada"**

**Descrição**: Manter estrutura atual e resolver problemas conforme surgem

**Por que foi rejeitada**: Problemas de escalabilidade já são evidentes e vão piorar com crescimento

---

## Consequências

### **Consequências Positivas:**

#### **Técnicas:**

- **Performance**: Lazy loading eficiente por feature, redução do bundle inicial
- **Manutenibilidade**: Código organizado por funcionalidade, fácil localização
- **Escalabilidade**: Estrutura que cresce com o projeto e equipe
- **Flexibilidade**: Features independentes, desenvolvimento paralelo

#### **De Negócio:**

- **Time-to-Market**: Desenvolvimento paralelo de features acelera entregas
- **Custos**: Redução de tempo de navegação e manutenção
- **Qualidade**: Isolamento de features reduz bugs cruzados
- **Capacidade da Equipe**: Múltiplos desenvolvedores podem trabalhar simultaneamente

### **Consequências Negativas / Riscos Aceitos:**

#### **Riscos Técnicos:**

- **Complexidade**: Estrutura inicial mais complexa que organização por camadas
- **Dependências**: Necessidade de definir regras claras entre features
- **Débito Técnico**: Migração requer refatoração de código existente
- **Learning Curve**: Equipe precisa aprender nova organização

#### **Riscos de Negócio:**

- **Custos**: Tempo de migração e treinamento da equipe
- **Prazos**: Migração pode impactar desenvolvimento de novas features
- **Recursos**: Necessidade de planejamento cuidadoso da migração

### **Mitigações de Risco:**

```yaml
risk_mitigations:
  - risk: "Complexidade da migração"
    mitigation: "Migração gradual, feature por feature"
    owner: "Tech Lead"

  - risk: "Dependências entre features"
    mitigation: "Regras claras de dependência e shared components"
    owner: "Arquitetos"

  - risk: "Learning curve da equipe"
    mitigation: "Documentação detalhada e treinamento"
    owner: "Tech Lead"

  - risk: "Impacto no desenvolvimento"
    mitigation: "Migração em paralelo com desenvolvimento"
    owner: "Product Owner"
```

---

## Plano de Implementação

### **Fases de Implementação:**

#### **Fase 1: Criação do ADR e Documentação Base (Semana 1)**

**Objetivos**:

- Documentar decisão arquitetural
- Atualizar documentação técnica existente
- Criar novos documentos específicos para Feature-Based

**Entregas**:

- [x] ADR-0013 (este documento)
- [ ] Atualizar `technical/frontend-architecture/overview.md`
- [ ] Atualizar `technical/frontend-architecture/directory-structure.md`
- [ ] Atualizar `technical/frontend-architecture/layer-responsibilities.md`
- [ ] Atualizar `technical/frontend-architecture/dependency-rules.md`
- [ ] Atualizar `technical/frontend-architecture/data-flow.md`
- [ ] Atualizar `technical/frontend-architecture/index.md`
- [ ] Criar `technical/frontend-architecture/feature-organization.md`
- [ ] Criar `technical/frontend-architecture/design-system-integration.md`
- [ ] Criar `technical/frontend-architecture/state-management.md`

**Critérios de Sucesso**:

- Documentação completa e consistente
- Princípios DTO-First mantidos
- Estrutura Feature-Based bem definida

#### **Fase 2: Atualização da Estratégia de Testes (Semana 2)**

**Objetivos**:

- Adaptar estratégia de testes para Feature-Based
- Manter padrões DDD/Clean Architecture
- Definir padrões de teste por feature

**Entregas**:

- [ ] Atualizar `technical/04_estrategia_testes.md`
- [ ] Atualizar `technical/frontend-architecture/testing-strategy.md`
- [ ] Criar `technical/frontend-architecture/feature-testing-patterns.md`

#### **Fase 3: Atualização dos Padrões de Código (Semana 3)**

**Objetivos**:

- Adaptar padrões de código para Feature-Based
- Manter padrões existentes de Angular Signals
- Definir convenções específicas para features

**Entregas**:

- [ ] Atualizar `technical/code-standards/angular-modern-patterns.md`
- [ ] Atualizar `technical/code-standards/architectural-patterns.md`
- [ ] Atualizar `technical/code-standards/naming-conventions.md`
- [ ] Atualizar `technical/code-standards/import-patterns.md`
- [ ] Criar `technical/code-standards/feature-patterns.md`
- [ ] Criar `technical/code-standards/design-system-patterns.md`

#### **Fase 4: Atualização da Stack Tecnológica (Semana 4)**

**Objetivos**:

- Atualizar documentação da stack para Feature-Based
- Manter tecnologias existentes
- Adicionar ferramentas específicas para features

**Entregas**:

- [ ] Atualizar `technical/03_stack_tecnologico.md`
- [ ] Atualizar configurações para Feature-Based

#### **Fase 5: Documentação de Implementação (Semana 5)**

**Objetivos**:

- Criar guias práticos de implementação
- Documentar processo de migração
- Fornecer exemplos concretos

**Entregas**:

- [ ] Criar `technical/frontend-architecture/implementation-guide.md`
- [ ] Criar `technical/frontend-architecture/migration-guide.md`
- [ ] Criar `technical/frontend-architecture/feature-examples.md`
- [ ] Atualizar índices de documentação

### **Dependências Críticas:**

- **Documentação Base** → Necessária para implementação consistente
- **Padrões de Código** → Essenciais para desenvolvimento padronizado
- **Estratégia de Testes** → Crítica para qualidade do código

### **Recursos Necessários:**

```yaml
resources:
  team:
    - role: "Tech Lead"
      effort: "40 horas"
      timeline: "5 semanas"

    - role: "Frontend Developers"
      effort: "20 horas"
      timeline: "Revisão e validação"

  infrastructure:
    - resource: "Documentação atualizada"
      justification: "Base para implementação consistente"

  external:
    - service: "Nenhum"
      cost: "R$ 0"
```

---

## Métricas e Monitoramento

### **Métricas de Sucesso:**

| Métrica                         | Baseline       | Target          | Como Medir                  |
| ------------------------------- | -------------- | --------------- | --------------------------- |
| Tempo de navegação para feature | 5+ pastas      | 1 pasta         | Tempo para localizar código |
| Dependências entre features     | Não controlado | < 3 por feature | Análise de imports          |
| Bundle size inicial             | 100%           | 60%             | Análise de bundle           |
| Tempo de build                  | Baseline       | < 10% aumento   | Medição de build time       |

### **Indicadores de Alerta:**

- **Aumento de Dependências** → > 5 dependências por feature → Revisar arquitetura
- **Bundle Size** → Aumento > 20% → Otimizar lazy loading
- **Tempo de Build** → Aumento > 30% → Revisar configurações

### **Plano de Rollback:**

**Gatilhos para Rollback**:

- Aumento significativo de complexidade sem benefícios
- Impacto negativo na performance
- Resistência da equipe após período de adaptação

**Processo de Rollback**:

1. Reverter para estrutura por camadas
2. Manter princípios DTO-First
3. Documentar lições aprendidas
4. Revisar abordagem arquitetural

---

## Documentação Impactada

### **Documentos que Precisam ser Atualizados:**

- **[Frontend Architecture Overview](../technical/frontend-architecture/overview.md)** → Migração para Feature-Based
- **[Directory Structure](../technical/frontend-architecture/directory-structure.md)** → Nova estrutura de pastas
- **[Layer Responsibilities](../technical/frontend-architecture/layer-responsibilities.md)** → Adicionar responsabilidades de features
- **[Code Standards](../technical/code-standards/)** → Novos padrões para features
- **[Testing Strategy](../technical/04_estrategia_testes.md)** → Estratégia adaptada para features

### **Novos Documentos a Criar:**

- [x] **ADR-0013** → Decisão arquitetural
- [ ] **Feature Organization** → Padrões de organização por features
- [ ] **Design System Integration** → Integração com features
- [ ] **State Management** → Estratégia de estado por feature
- [ ] **Implementation Guide** → Guia prático de implementação
- [ ] **Migration Guide** → Processo de migração

---

## Referências e Pesquisa

### **Pesquisa Realizada:**

- **[Feature-Based Architecture Patterns](https://martinfowler.com/articles/frontend-architecture.html)** - Padrões de organização frontend
- **[Angular Feature Modules](https://angular.dev/guide/feature-modules)** - Documentação oficial Angular
- **[Micro-Frontends Architecture](https://martinfowler.com/articles/micro-frontends.html)** - Preparação para evolução futura

### **Consultorias e Validações:**

- **Equipe Frontend** - Validação de necessidades práticas
- **Tech Lead** - Validação técnica e arquitetural
- **Product Owner** - Validação de impacto no negócio

### **ADRs Relacionados:**

- **[ADR-0012](./0012-adocao-dto-first-architecture-frontend.md)** - Base DTO-First mantida
- **[ADR-0008](./0008-padrao-endpoints-mutations-post-comando.md)** - Padrões de API mantidos

---

## Revisão e Evolução

### **Critérios para Revisão:**

- **Temporal**: Revisar em 3 meses após implementação
- **Por Evento**: Quando equipe atingir 10+ desenvolvedores
- **Por Métrica**: Se tempo de navegação não melhorar em 50%

### **Possíveis Evoluções Futuras:**

```yaml
future_evolutions:
  short_term: # 6-12 meses
    - scenario: "Crescimento para 10+ desenvolvedores"
      impact: "Pode necessitar micro-frontends"
      action: "Avaliar migração para micro-frontends"

  long_term: # 1-2 anos
    - scenario: "Design System maduro"
      impact: "Features mais independentes"
      action: "Considerar extração de features como packages"
```

### **Sinais de que ADR Precisa ser Revisado:**

- Resistência da equipe após período de adaptação
- Aumento significativo de complexidade
- Necessidade de micro-frontends
- Mudança na estratégia de Design System

---

## Aprovações

### **Stakeholders que Aprovaram:**

- **Equipe de Arquitetura** (Arquitetos) - 2025-01-24
- **Tech Lead** (Tech Lead) - 2025-01-24
- **Product Owner** (Product Owner) - 2025-01-24

### **Processo de Aprovação:**

1. **2025-01-20** - Proposta inicial apresentada
2. **2025-01-22** - Feedback coletado e análise refinada
3. **2025-01-23** - Alternativas validadas com equipe técnica
4. **2025-01-24** - Decisão final aprovada

---

## Histórico de Mudanças

| Data       | Versão | Mudança         | Responsável           |
| ---------- | ------ | --------------- | --------------------- |
| 2025-01-24 | 1.0    | Criação inicial | Equipe de Arquitetura |

---

**Notas para Manutenção deste ADR:**

- Revisar métricas mensalmente durante implementação
- Atualizar seção de consequências com resultados reais
- Documentar lições aprendidas na implementação
- Considerar criação de ADR superseding se decisão mudar significativamente
