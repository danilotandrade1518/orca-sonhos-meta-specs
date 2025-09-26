# Core Concepts - Conceitos Centrais

---

**Metadados Estruturados para IA/RAG:**

```yaml
document_type: "business_concepts"
domain: "personal_finance"
audience: ["developers", "product_managers", "business_analysts"]
complexity: "intermediate"
tags:
  ["core_concepts", "domain_model", "business_rules", "financial_management"]
related_docs: ["domain-ontology.md", "use-cases.md", "mvp-scope.md"]
ai_context: "Central domain concepts for OrçaSonhos financial management platform"
last_updated: "2025-01-24"
```

---

## 🧭 Conceitos Fundamentais

### 💡 Orçamento (Budget)

- Representa um agrupamento de finanças com um objetivo ou perfil comum.
- Pode ser **compartilhado** (ex: "Casa") ou **pessoal** (ex: "Viagem solo").
- O usuário pode alternar entre diferentes orçamentos.
- Cada orçamento tem:
  - Categorias próprias (ou herdadas de presets)
  - Transações
  - Metas vinculadas
  - Saldo e controle por envelope

**Exemplos Práticos por Persona:**

- **Ana**: "Orçamento Casa" (compartilhado) - R$ 8.000/mês para despesas familiares
- **Carlos**: "Orçamento Pessoal" - R$ 4.500/mês para gastos individuais e metas
- **Roberto & Maria**: "Orçamento Família" + "Orçamento Aposentadoria" - múltiplos contextos
- **Júlia**: "Orçamento PF" + "Orçamento PJ" - separação pessoal/profissional

#### 👥 Compartilhamento Simplificado

- **Orçamentos compartilhados** permitem colaboração entre usuários.
- **Adição direta**: Qualquer participante pode adicionar outros usuários ao orçamento sem necessidade de convites ou aprovações.
- **Acesso total**: Todo usuário adicionado tem acesso completo ao orçamento (sem níveis de permissão).
- **Remoção**: Participantes podem ser removidos do orçamento (exceto o criador).

### 💸 Transações (Receitas e Despesas)

- São os lançamentos manuais ou importados que alimentam o sistema.
- Associadas a uma **categoria**, um **orçamento** e uma **data**.
- **Flexibilidade temporal**: O sistema permite transações com **data passada, presente ou futura** para máximo controle financeiro.
- Tipos:
  - Receita (entrada)
  - Despesa (saída)
  - Transferência (entre orçamentos)
- Status:
  - **Agendada**: Transação futura que ainda não foi efetivada
  - **Realizada**: Transação que já aconteceu e impacta o saldo atual
  - **Atrasada**: Transação com data passada que ainda não foi concluída
  - **Cancelada**: Transação agendada que foi cancelada
- **Controle de pagamento**: Ao cadastrar, o usuário define se a transação já foi paga/recebida ou se ainda está pendente.
- Cada transação possui uma **forma de pagamento**, que pode incluir cartões de crédito.

#### 💡 Impacto no Saldo:

- **Transações Realizadas**: Afetam imediatamente o saldo atual, independente da data
- **Transações Agendadas**: Não afetam o saldo atual, apenas aparecem nas projeções
- **Transações Atrasadas**: Não afetam o saldo atual, mas são identificadas pelo sistema como pendentes

### 🗂️ Categorias

- Organizam os lançamentos para permitir análise.
- Baseadas no modelo 50-30-20:
  - **50%**: Necessidades (moradia, alimentação, transporte)
  - **30%**: Estilo de vida (lazer, assinaturas)
  - **20%**: Prioridades financeiras (reserva, investimento, dívidas)
- Usuários podem criar suas próprias categorias conforme necessidade.

### 🎯 Metas (Objetivos Financeiros)

- São o coração do OrçaSonhos: **transformar sonhos em planos de ação financeiros.**
- Cada meta é vinculada a um orçamento.
- Parâmetros:
  - Nome
  - Valor total necessário
  - Valor acumulado
  - Prazo desejado
  - Aportes manuais

**Exemplos Práticos por Persona:**

- **Ana**: "Casa Própria - R$ 200.000 em 5 anos" (R$ 3.333/mês)
- **Carlos**: "Intercâmbio Europa - R$ 25.000 em 2 anos" (R$ 1.042/mês)
- **Roberto & Maria**: "Faculdade dos Filhos - R$ 300.000 em 10 anos" (R$ 2.500/mês)
- **Júlia**: "Equipamentos do Negócio - R$ 15.000 em 6 meses" (R$ 2.500/mês)

#### 🎯 Metodologia SMART para Metas

As metas no OrçaSonhos seguem a metodologia **SMART** para garantir objetivos realistas e alcançáveis:

**S - Específica (Specific)**

- Nome claro da meta (ex: "Viagem para Europa", não "Viajar")
- Descrição detalhada do objetivo
- Finalidade bem definida

**M - Mensurável (Measurable)**

- Valor total necessário definido
- Progresso percentual visual
- Histórico de aportes e evolução
- Métricas claras de acompanhamento

**A - Atingível (Achievable)**

- Sistema sugere valor mensal baseado na renda/gastos disponíveis
- Alerta se meta está muito ambiciosa para o prazo definido
- Sugestão de ajustes realistas no valor ou prazo

**R - Relevante (Relevant)**

- Vinculada a um orçamento específico
- Categorizada por tipo (casa, educação, lazer, emergência, etc.)
- Permite priorização entre múltiplas metas
- Alinhada com objetivos pessoais/familiares

**T - Temporal (Time-bound)**

- Data limite claramente definida
- Cálculo automático de aportes necessários por mês
- Alertas de progresso (atrasado, no prazo, adiantado)
- Visualização de timeline para conclusão

### 💰 Envelopes (Orçamento Mensal por Categoria)

- Definem limites de gastos por categoria.
- Ajudam o usuário a **controlar o que pode gastar** em cada área.
- Funcionam como subcontas dentro de um orçamento.

### 🏦 Contas (Accounts)

- Representam **onde o dinheiro está fisicamente armazenado** antes de ser gasto ou após ser recebido.
- **Dimensão complementar** aos orçamentos: orçamentos definem "para que uso", contas definem "onde está".
- Cada conta mantém seu **saldo próprio** e histórico de movimentações.
- Tipos de conta:
  - **Conta Corrente**: Conta bancária para movimentações do dia a dia
  - **Conta Poupança**: Conta bancária para reservas e economias
  - **Carteira Física**: Dinheiro em espécie que o usuário carrega
  - **Carteira Digital**: Saldo em apps como PIX, PayPal, cartões pré-pagos
  - **Conta Investimento**: Recursos aplicados em investimentos líquidos
  - **Outros**: Tipos personalizados conforme necessidade

#### Como funciona na prática:

- **Toda transação** deve indicar de qual conta o dinheiro saiu/entrou
- **Transferências** podem mover dinheiro entre contas (ex: saque no caixa)
- **Reconciliação**: Saldos das contas devem bater com extratos reais
- **Controle total**: Usuário sabe exatamente onde cada centavo está guardado

### 💳 Gestão de Cartões de Crédito

O OrçaSonhos permite **gerenciar cartões de crédito de forma integrada ao controle de despesas**, seguindo o modelo:

#### Como funciona:

- Ao lançar uma **despesa**, o usuário seleciona a **forma de pagamento** como sendo um cartão (ex: "Cartão Nubank").
- O gasto é tratado como uma despesa comum, com sua **categoria normal** (ex: mercado, transporte), e entra no orçamento e relatórios normalmente.
- Existe uma **área específica** para cada cartão, que mostra:
  - Limite total e limite disponível
  - Fatura atual (total acumulado da fatura aberta)
  - Data de fechamento e vencimento
  - Listagem das transações dessa fatura
- O pagamento da fatura é **registrado como uma nova transação**, com categoria "Pagamento de Fatura" e origem em uma conta bancária ou orçamento.

#### Benefícios:

- Mantém a consistência nos relatórios por categoria
- Permite controle real de limite e fatura
- Não fragmenta a experiência de lançamento
- Permite visão clara da fatura e pagamento

### 💳 Fatura de Cartão (CreditCardBill)

- Agregado que representa uma fatura específica de um cartão de crédito.
- Cada fatura tem:
  - Data de fechamento e vencimento
  - Valor total da fatura
  - Status (OPEN, CLOSED, PAID, OVERDUE) - Enum type-safe
  - Listagem de transações vinculadas
  - Referência ao cartão de crédito
- Permite visualização consolidada de gastos por fatura
- Facilita controle de pagamentos e histórico de faturas

---

**Próximos tópicos:**

- **[Use Cases](./use-cases.md)** - Casos de uso prioritários
- **[MVP Scope](./mvp-scope.md)** - Escopo do MVP
