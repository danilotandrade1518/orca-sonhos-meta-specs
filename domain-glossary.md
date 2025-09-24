# 📚 Domain Glossary - Glossário de Domínio OrçaSonhos

---
**Metadados Estruturados para IA/RAG:**
```yaml
document_type: "domain_glossary"
domain: "financial_management"
audience: ["developers", "product_managers", "business_analysts", "qa_testers", "ai_systems"]
complexity: "reference"
tags: ["glossary", "terminology", "domain_terms", "definitions", "semantic_reference"]
related_docs: ["domain-ontology.md", "core-concepts.md", "schemas/entities.yaml"]
ai_context: "Comprehensive terminology reference for OrçaSonhos domain understanding"
term_count: 45
languages: ["pt-BR", "en-US"]
last_updated: "2025-01-24"
```
---

## 🎯 Propósito

Este glossário centraliza todas as definições de termos utilizados no domínio OrçaSonhos, servindo como fonte única de verdade para comunicação entre equipe, documentação e sistemas de IA.

---

## 📋 Termos Principais (Core Terms)

### **Account / Conta** {#account}
**Definição**: Local físico onde o dinheiro está armazenado antes de ser gasto ou após ser recebido.
**Sinônimos**: Conta bancária, carteira, meio de armazenamento
**Tipos**: Conta corrente, poupança, carteira física, carteira digital, conta investimento
**Relacionamentos**: Pertence a um Budget, registra Transactions
**Exemplo**: "Conta Corrente Itaú", "Carteira Física", "Nubank"
**Schema**: Ver [Account schema](./schemas/entities.yaml#Account)

### **Budget / Orçamento** {#budget}
**Definição**: Container virtual que agrupa transações, metas e categorias com propósito comum.
**Sinônimos**: Plano financeiro, orçamento
**Tipos**: Pessoal (personal), compartilhado (shared), familiar (family), empresarial (business)
**Relacionamentos**: Contém Transactions, Goals, Categories; pertence a User(s)
**Exemplo**: "Casa" (compartilhado), "Viagem Europa" (pessoal)
**Regras**: Deve ter pelo menos um participante; pessoal = apenas 1 participante
**Schema**: Ver [Budget schema](./schemas/entities.yaml#Budget)

### **Category / Categoria** {#category}
**Definição**: Classificação temática para organizar transações e facilitar análise financeira.
**Sinônimos**: Tipo de gasto, classificação
**Base**: Modelo 50-30-20 (Necessidades 50%, Estilo de vida 30%, Prioridades financeiras 20%)
**Exemplos**: Alimentação, Transporte, Lazer, Investimento, Moradia
**Relacionamentos**: Classifica Transactions, pertence a Budget
**Customização**: Usuários podem criar categorias personalizadas

### **Envelope / Envelope** {#envelope}
**Definição**: Limite de gastos definido para uma categoria específica dentro de um período (geralmente mensal).
**Sinônimos**: Orçamento por categoria, limite de categoria
**Propósito**: Controlar gastos e evitar estouros em categorias específicas
**Relacionamentos**: Vinculado a Category e Budget
**Exemplo**: R$ 800/mês para categoria "Alimentação"

### **Goal / Meta** {#goal}
**Definição**: Objetivo financeiro específico com valor-alvo e prazo definido, seguindo metodologia SMART.
**Sinônimos**: Objetivo, sonho, meta financeira
**Metodologia**: SMART (Specific, Measurable, Achievable, Relevant, Time-bound)
**Componentes**: Nome, valor-alvo, prazo, valor atual, categoria temática
**Estados**: Ativa, concluída, pausada, cancelada
**Exemplo**: "Viagem Europa - R$ 8.000 em 12 meses"
**Schema**: Ver [Goal schema](./schemas/entities.yaml#Goal)

### **Money / Dinheiro** {#money}
**Definição**: Value object que representa quantias monetárias usando centavos para evitar problemas de ponto flutuante.
**Formato**: Inteiro representando centavos (1500 = R$ 15,00)
**Moeda padrão**: BRL (Real brasileiro)
**Operações**: Soma, subtração, comparação, formatação para display
**Invariantes**: Operações apenas entre mesma moeda
**Schema**: Ver [Money schema](./schemas/entities.yaml#Money)

### **Transaction / Transação** {#transaction}
**Definição**: Registro de entrada ou saída de dinheiro com data, valor, categoria e descrição.
**Sinônimos**: Lançamento, movimentação financeira
**Tipos**: Receita (income), despesa (expense), transferência (transfer)
**Estados**: Agendada, realizada, atrasada, cancelada
**Temporalidade**: Pode ter data passada, presente ou futura
**Exemplo**: "Supermercado Extra - R$ 85,50 em 2025-01-20"
**Schema**: Ver [Transaction schema](./schemas/entities.yaml#Transaction)

### **User / Usuário** {#user}
**Definição**: Pessoa física que acessa e utiliza a plataforma OrçaSonhos.
**Relacionamentos**: Possui Budgets, participa de Budgets compartilhados, cria Transactions
**Autenticação**: Firebase Authentication
**Permissões**: Acesso total aos budgets que participa
**Contextos**: Pode ter múltiplos budgets (pessoal, familiar, profissional)

---

## 💳 Termos de Cartão de Crédito

### **Credit Card / Cartão de Crédito** {#credit-card}
**Definição**: Meio de pagamento com limite pré-aprovado que gera faturas mensais.
**Relacionamentos**: É um tipo de Account, gera Bills
**Características**: Tem limite, data de fechamento, vencimento
**Exemplo**: "Cartão Nubank - Limite R$ 5.000"

### **Credit Card Bill / Fatura do Cartão** {#credit-card-bill}
**Definição**: Conjunto de despesas em um cartão com período específico, data de fechamento e vencimento.
**Sinônimos**: Fatura
**Estados**: Aberta (OPEN), fechada (CLOSED), paga (PAID), vencida (OVERDUE)
**Componentes**: Valor total, data fechamento, data vencimento, transações vinculadas
**Exemplo**: "Fatura Janeiro/2025 - R$ 1.200,00 - Vence em 15/02/2025"

### **Bill Payment / Pagamento de Fatura** {#bill-payment}
**Definição**: Transação específica que representa o pagamento/quitação de uma fatura de cartão.
**Categoria**: Geralmente "Pagamento de Fatura" ou equivalente
**Origem**: Conta bancária ou dinheiro
**Destino**: Cartão de crédito (quitação de fatura)

---

## ⏰ Termos Temporais

### **Scheduled Transaction / Transação Agendada** {#scheduled-transaction}
**Definição**: Transação com data futura que ainda não foi efetivada.
**Impacto**: Não afeta saldo atual, apenas projeções futuras
**Uso**: Planejamento de receitas e despesas futuras
**Exemplos**: Salário do próximo mês, conta de luz do próximo mês

### **Completed Transaction / Transação Realizada** {#completed-transaction}
**Definição**: Transação que já aconteceu e impacta o saldo atual.
**Características**: Pode ter qualquer data (passada, presente)
**Impacto**: Afeta imediatamente o saldo da conta associada

### **Overdue Transaction / Transação Atrasada** {#overdue-transaction}
**Definição**: Transação com data passada que ainda não foi concluída/paga.
**Status**: Sistema identifica automaticamente com base na data
**Impacto**: Não afeta saldo atual até ser marcada como realizada
**Exemplo**: Conta de dezembro que ainda não foi paga

### **Recurring Transaction / Transação Recorrente** {#recurring-transaction}
**Definição**: Transação que se repete automaticamente em intervalos regulares.
**Padrões**: Mensal, semanal, anual, customizado
**Exemplos**: Salário mensal, conta de internet, aluguel
**Gestão**: Sistema pode gerar automaticamente as próximas ocorrências

---

## 🎯 Termos de Metas e Planejamento

### **SMART Goal / Meta SMART** {#smart-goal}
**Definição**: Meta que segue metodologia SMART para garantir objetivos realistas.
**Critérios**:
- **S**pecific (Específica): Nome claro e finalidade definida
- **M**easurable (Mensurável): Valor e progresso quantificáveis
- **A**chievable (Atingível): Realista baseada na renda disponível
- **R**elevant (Relevante): Vinculada a orçamento e categorizada
- **T**ime-bound (Temporal): Data limite definida

### **Goal Category / Categoria de Meta** {#goal-category}
**Definição**: Classificação temática de metas para organização e análise.
**Tipos**: Casa, viagem, educação, emergência, veículo, saúde, negócio, outros
**Propósito**: Facilitar priorização e relatórios por tipo de objetivo

### **Goal Progress / Progresso da Meta** {#goal-progress}
**Definição**: Porcentagem de conclusão baseada no valor atual vs valor-alvo.
**Cálculo**: (valor_atual / valor_alvo) × 100
**Visualização**: Barras de progresso, percentuais, valores absolutos

### **Monthly Contribution / Contribuição Mensal** {#monthly-contribution}
**Definição**: Valor sugerido ou definido para aportar mensalmente em uma meta.
**Cálculo automático**: (valor_restante / meses_restantes)
**Flexibilidade**: Pode ser ajustado pelo usuário conforme capacidade

---

## 👥 Termos de Colaboração

### **Shared Budget / Orçamento Compartilhado** {#shared-budget}
**Definição**: Orçamento que pode ser acessado e gerenciado por múltiplos usuários.
**Acesso**: Todos participantes têm acesso total (sem níveis de permissão)
**Gestão**: Qualquer participante pode adicionar/remover outros usuários
**Exemplos**: Orçamento familiar "Casa", orçamento de casal

### **Budget Participant / Participante do Orçamento** {#budget-participant}
**Definição**: Usuário com acesso a um orçamento específico.
**Permissões**: Acesso total para criar/editar transações, metas, categorias
**Adição**: Processo direto sem necessidade de convite/aprovação
**Remoção**: Possível por qualquer participante (exceto remover o criador)

### **Budget Owner / Proprietário do Orçamento** {#budget-owner}
**Definição**: Usuário que criou o orçamento e tem privilégios especiais.
**Privilégios**: Não pode ser removido do orçamento, responsável final
**Responsabilidades**: Pode arquivar/desativar o orçamento
**Herança**: Pode transferir propriedade para outro participante

---

## 📊 Termos de Análise e Relatórios

### **Balance / Saldo** {#balance}
**Definição**: Valor disponível em uma conta em momento específico.
**Tipos**: Saldo atual, saldo projetado, saldo disponível (incluindo limite)
**Cálculo**: Receitas - despesas realizadas
**Pode ser negativo**: Para contas com limite de crédito

### **Cash Flow / Fluxo de Caixa** {#cash-flow}
**Definição**: Projeção de entradas e saídas de dinheiro ao longo do tempo.
**Componentes**: Transações realizadas + transações agendadas
**Períodos**: Semanal, mensal, anual
**Uso**: Planejamento financeiro e identificação de déficits futuros

### **Expense Category Analysis / Análise por Categoria de Despesa** {#expense-category-analysis}
**Definição**: Relatório que mostra distribuição de gastos por categoria.
**Visualizações**: Gráficos pizza, barras, tabelas
**Períodos**: Mensal, trimestral, anual
**Comparações**: Atual vs anterior, orçado vs realizado

### **Goal Timeline / Cronograma de Metas** {#goal-timeline}
**Definição**: Projeção de quando cada meta será atingida baseada nos aportes atuais.
**Fatores**: Contribuição mensal, valor restante, data-alvo
**Alertas**: Meta atrasada, no prazo, adiantada
**Ajustes**: Sugestões de aporte para cumprir prazo

---

## ⚙️ Termos Técnicos

### **Aggregate Root / Raiz de Agregado** {#aggregate-root}
**Definição**: Entidade principal que serve como ponto de entrada para um agregado no DDD.
**Exemplos**: Budget, Transaction, Goal, Account
**Características**: Têm identidade própria, controlam invariantes do agregado
**Persistência**: Salvos e carregados como unidade

### **Value Object / Objeto de Valor** {#value-object}
**Definição**: Objeto imutável definido pelos seus atributos, sem identidade própria.
**Exemplos**: Money, DatePeriod, Address
**Características**: Imutáveis, comparados por valor, sem ID
**Uso**: Representar conceitos que são descrições/medidas

### **Domain Service / Serviço de Domínio** {#domain-service}
**Definição**: Serviço que encapsula lógica de negócio que não pertence a uma entidade específica.
**Uso**: Operações que envolvem múltiplas entidades
**Exemplos**: Cálculo de metas, validação de regras complexas

### **Repository Pattern / Padrão Repository** {#repository-pattern}
**Definição**: Abstração para acesso a dados, isolando a camada de domínio da persistência.
**Operações**: Add, Save, Get, Find, Delete
**Benefício**: Testabilidade, flexibilidade de implementação

---

## 🔄 Estados e Status

### **Transaction Status / Status da Transação** {#transaction-status}
- **Scheduled**: Agendada para data futura
- **Completed**: Realizada e impactando saldo
- **Overdue**: Data passada mas não concluída
- **Cancelled**: Cancelada pelo usuário

### **Goal Status / Status da Meta** {#goal-status}
- **Active**: Meta ativa sendo trabalhada
- **Completed**: Meta atingida com sucesso
- **Paused**: Temporariamente pausada
- **Cancelled**: Cancelada pelo usuário

### **Budget Status / Status do Orçamento** {#budget-status}
- **Active**: Orçamento ativo em uso
- **Inactive**: Temporariamente inativo
- **Archived**: Arquivado para consulta histórica

### **Credit Card Bill Status / Status da Fatura** {#bill-status}
- **OPEN**: Fatura aberta recebendo lançamentos
- **CLOSED**: Fatura fechada aguardando pagamento
- **PAID**: Fatura quitada
- **OVERDUE**: Fatura vencida não paga

---

## 🏷️ Tags e Categorias Semânticas

### **Complexity Tags / Tags de Complexidade**
- **beginner**: Conceitos básicos para iniciantes
- **intermediate**: Conceitos de nível médio
- **advanced**: Conceitos avançados e especializados

### **Context Tags / Tags de Contexto**
- **financial_planning**: Planejamento financeiro
- **transaction_management**: Gestão de transações
- **collaboration**: Funcionalidades colaborativas
- **temporal**: Aspectos temporais (agendamento, recorrência)
- **analytics**: Relatórios e análises

### **Persona Tags / Tags por Persona**
- **ana_familiar**: Ana - organizadora familiar
- **carlos_young**: Carlos - jovem planejador
- **roberto_maria**: Casal experiente
- **julia_entrepreneur**: Júlia - empreendedora

---

## 🔗 Referências Cruzadas

### Documentos Relacionados
- **[Domain Ontology](./domain-ontology.md)** - Taxonomia formal e relações semânticas
- **[Core Concepts](./business/product-vision/core-concepts.md)** - Conceitos centrais detalhados
- **[Entity Schemas](./schemas/entities.yaml)** - Schemas estruturados das entidades
- **[Use Cases](./business/product-vision/use-cases.md)** - Casos de uso práticos
- **[MVP Scope](./business/product-vision/mvp-scope.md)** - Escopo e definições do MVP

### ADRs Relacionados
- **[ADR-0004](./adr/0004-escolha-postgresql-como-banco-de-dados.md)** - Decisões de persistência
- **[ADR-0008](./adr/0008-padrao-endpoints-mutations-post-comando.md)** - Padrões de API
- **[ADR-0011](./adr/0011-postergacao-offline-first-mvp.md)** - Estratégia offline

---

## 🤖 Instruções para IA/RAG

### Como usar este glossário:

1. **Consulta de definições**: Use os IDs únicos (#account, #budget, etc.) para referência precisa
2. **Validação de terminologia**: Sempre use os termos conforme definidos aqui
3. **Contexto semântico**: Os relacionamentos ajudam a entender conexões entre conceitos
4. **Exemplos práticos**: Use os exemplos para ilustrar conceitos aos usuários
5. **Navegação**: Use as referências cruzadas para explorar tópicos relacionados

### Prioridades de consulta:
1. Termos principais (Core Terms) para conceitos fundamentais
2. Estados e status para validar transições
3. Termos técnicos para implementação
4. Tags semânticas para categorização e busca

### Notas importantes:
- Sempre prefira a terminologia em português nos contextos de negócio
- Use termos em inglês apenas em contextos técnicos/código
- Mantenha consistência com as definições estabelecidas
- Consulte schemas para detalhes de implementação