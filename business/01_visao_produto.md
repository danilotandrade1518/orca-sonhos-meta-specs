# 📘 Visão de Produto - OrçaSonhos

## 🎯 Propósito da Ferramenta

O **OrçaSonhos** é uma plataforma de gestão financeira voltada para pessoas físicas (indivíduos e famílias) que desejam **tomar o controle das suas finanças** e **transformar sonhos em metas alcançáveis**.  
A proposta é unir **simplicidade, clareza e efetividade**, permitindo desde o controle básico de gastos até o planejamento de metas complexas com envolvimento familiar.

**Focado inicialmente no mercado brasileiro**, o OrçaSonhos é uma ferramenta de gestão financeira familiar simples, prática e com foco em metas reais.

---

## 🧱 Princípios do Produto

- **Descomplicado por padrão:** Sem jargões financeiros ou telas complexas.
- **Multi-orçamento:** Usuário pode criar orçamentos distintos (ex: orçamento pessoal, familiar, metas específicas).
- **Foco em metas:** Tudo gira em torno de ajudar o usuário a atingir seus objetivos.
- **Controle visual:** O usuário precisa ver claramente para onde vai seu dinheiro.
- **Compartilhável:** Casais e famílias podem cooperar em orçamentos comuns através de adição direta de usuários.
- **Evolutivo:** Começa simples e pode crescer com o usuário.

---

## 🧭 Conceitos Centrais

### 💡 Orçamento (Budget)

- Representa um agrupamento de finanças com um objetivo ou perfil comum.
- Pode ser **compartilhado** (ex: "Casa") ou **pessoal** (ex: "Viagem solo").
- O usuário pode alternar entre diferentes orçamentos.
- Cada orçamento tem:
  - Categorias próprias (ou herdadas de presets)
  - Transações
  - Metas vinculadas
  - Saldo e controle por envelope

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
  - Referência ao cartão de crédito
- **Regras de negócio**:
  - Data de fechamento deve ser anterior à data de vencimento
  - Fatura em atraso quando passou do vencimento e não foi paga
  - Pode ser marcada como paga, alterando o status e registrando data do pagamento
  - Calcula automaticamente dias restantes até o vencimento
  - Status controlado por enum para garantir type-safety

---

## 🏆 Análise Competitiva

### Principais Concorrentes

| Concorrente | Pontos Fortes | Pontos Fracos |
|-------------|---------------|---------------|
| **Mobills** | Líder no Brasil, funcionalidades completas | Interface complexa, foco em controle vs. objetivos |
| **GuiaBolso/Serasa** | Gratuito, integração bancária | Monetizado por dados, pouco foco em metas |
| **Organizze** | Interface clean, experiência premium | Preço alto, funcionalidades limitadas no gratuito |
| **Toshl** | Gamificação interessante | Interface infantil, pouco contexto brasileiro |
| **Expense Manager** | Muito simples de usar | Funcionalidades limitadas, sem foco em metas |

### Posicionamento Diferenciado do OrçaSonhos

#### 🎯 **Foco em Metas e Sonhos**
- Competidores focam em **controle de gastos**
- OrçaSonhos foca em **realizar objetivos** e transformar sonhos em realidade
- Interface centrada em **progresso visual** das metas
- Metodologia SMART integrada ao produto

#### 🔄 **Simplicidade com Múltiplos Orçamentos**
- Competidores ou são muito simples (1 orçamento) ou muito complexos
- OrçaSonhos equilibra: **simples para iniciantes, poderoso para usuários avançados**
- Evolução natural conforme usuário ganha experiência

#### 👥 **Compartilhamento Familiar Verdadeiro**
- Concorrentes têm compartilhamento limitado ou processos burocráticos
- OrçaSonhos: **adição direta de usuários, acesso total, sem complicações**
- Foco real em gestão financeira familiar colaborativa

#### 🇧🇷 **Contexto Brasileiro**
- Desenvolvido pensando especificamente no mercado brasileiro
- Categorias e casos de uso alinhados com a realidade nacional
- Linguagem e abordagem adaptadas ao público brasileiro

---

## 🚀 Estratégia de Onboarding

O processo de entrada no OrçaSonhos é desenhado para **gerar valor imediato** e **reduzir a barreira de entrada**:

### Passo 1: Bem-vindo Motivacional (30 segundos)
- **Mensagem**: "Transforme seus sonhos em realidade"
- Explicação visual do conceito: sonhos → metas → ações → conquistas
- Exemplo animado de uma meta sendo alcançada
- Call-to-action: "Começar agora"

### Passo 2: Primeira Meta (2 minutos)
- **Pergunta motivacional**: "Qual seu maior sonho hoje?"
- Sugestões visuais com ícones:
  - 🏠 Casa própria
  - 🚗 Carro novo
  - ✈️ Viagem dos sonhos
  - 🎓 Curso/Educação
  - 💍 Casamento
  - 👶 Filhos
- Cadastro simplificado: Nome + Valor aproximado + "Quando quer conseguir?"

### Passo 3: Primeiro Orçamento (1 minuto)
- Criação automática do orçamento principal
- Nome pré-preenchido: "Meu Orçamento Principal"
- Vinculação automática da meta criada ao orçamento
- Explicação: "Aqui você vai controlar suas finanças para alcançar suas metas"

### Passo 4: Categorias Básicas (1 minuto)
- Preset automático baseado no modelo 50-30-20
- Usuário pode aceitar as sugestões ou personalizar
- Explicação visual simples de cada tipo:
  - 💰 **Necessidades**: Contas essenciais para viver
  - 🎉 **Estilo de vida**: Diversão e qualidade de vida  
  - 🎯 **Prioridades financeiras**: Reservas e investimentos

### Passo 5: Primeira Transação Guiada (2 minutos)
- Tutorial interativo passo-a-passo
- Exemplo prático e comum: "Café da manhã - R$ 15,00"
- Mostra escolha de categoria, data, forma de pagamento
- **Impacto imediato**: mostra como a transação aparece nos relatórios
- Motivação: "Viu como é simples? Cada lançamento te aproxima das suas metas!"

### Passo 6: Dashboard Tour (1 minuto)
- Apresentação das áreas principais:
  - Progresso da primeira meta criada
  - Saldo atual do orçamento
  - Gastos por categoria (com a primeira transação)
  - Botões principais para próximas ações
- **Mensagem final**: "Sua jornada financeira começa aqui! 🚀"
- Call-to-action: "Cadastrar mais transações"

### Objetivos do Onboarding:
- ✅ Usuário cria primeira meta em menos de 3 minutos
- ✅ Entende o conceito de orçamentos e categorias
- ✅ Faz primeira transação com confiança
- ✅ Vê valor imediato na ferramenta
- ✅ Tem motivação para continuar usando

---

## 📊 Relatórios e Painéis

- Painel de controle por orçamento:
  - Saldo atual
  - Evolução das metas
  - Gastos por categoria
  - Status dos envelopes
- Visão consolidada (para quem participa de múltiplos orçamentos)
- Fatura atual de cada cartão, com detalhamento
- Progresso das metas SMART

---

## 🧩 Casos de Uso Prioritários

### 👥 Gestão Familiar

- Criar um orçamento compartilhado com parceiro(a)
- Adicionar parceiro(a) diretamente ao orçamento (sem convites)
- Definir metas comuns (ex: reforma da casa)
- Controlar contas da casa, supermercado, etc.
- Ambos participantes têm acesso total para lançar transações e gerenciar o orçamento

### 👤 Gestão Individual

- Orçamento pessoal separado (ex: hobbies, presentes, cursos)
- Meta pessoal (ex: comprar um notebook)
- Controle de gastos pessoais sem impactar o casal

### 🔁 Planejamento Contínuo

- Revisar gastos semanais/mensais
- Ajustar envelopes e metas
- Realocar valores entre orçamentos
- Acompanhar faturas de cartão e programar quitação
- **Agendar transações futuras**: Lançar salários, contas fixas e gastos programados
- **Projetar fluxo de caixa**: Visualizar entradas e saídas futuras para melhor planejamento

### 📅 Transações Futuras - Casos de Uso

- **Receitas recorrentes**: Agendar salário do próximo mês
- **Despesas fixas**: Contas de luz, água, internet com vencimento futuro
- **Planejamento de gastos**: Aniversários, viagens, compras planejadas
- **Parcelas e financiamentos**: Controlar prestações futuras
- **Gestão de metas**: Calcular quando objetivos serão atingidos com aportes manuais

### 📅 Transações Passadas - Casos de Uso

- **Lançamento retroativo**: Cadastrar gastos esquecidos com data correta
- **Conciliação bancária**: Registrar transações já realizadas no banco
- **Controle de pendências**: Marcar contas vencidas que ainda não foram pagas
- **Histórico completo**: Manter registro fiel da movimentação financeira
- **Identificação de atrasos**: Sistema identifica automaticamente transações em atraso

---

## 🎯 Escopo do MVP

### Funcionalidades Incluídas no MVP:
- ✅ Todos os conceitos centrais descritos neste documento
- ✅ Criação e gestão de orçamentos (pessoais e compartilhados)
- ✅ Sistema completo de transações (passadas, presentes e futuras)
- ✅ Gestão de metas com metodologia SMART
- ✅ Controle de categorias e envelopes
- ✅ Gestão de contas e cartões de crédito
- ✅ Relatórios e painéis básicos
- ✅ Sistema de onboarding completo
- ✅ Compartilhamento familiar simplificado

### Funcionalidades Pós-MVP:
- 📱 Notificações push e por email
- 🎮 Gamificação e elementos de engajamento
- 📚 Conteúdo educativo financeiro
- 📊 Relatórios avançados e personalizáveis
- 🔗 Integrações bancárias (Open Banking)
- 💰 Modelo de monetização definido

---

## 📚 Termos importantes para a IA Assistente

| Termo                   | Significado                                                                                                                                 |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| **Orçamento**           | Espaço virtual com categorias, transações, metas e envelopes. Pode ser compartilhado ou individual.                                         |
| **Categoria**           | Tipo de gasto/receita (ex: alimentação, transporte, investimento). Organiza as transações.                                                  |
| **Meta**                | Objetivo financeiro (ex: comprar carro, fazer intercâmbio), com valor-alvo e prazo.                                                         |
| **Envelope**            | Limite de gastos por categoria dentro de um orçamento mensal.                                                                               |
| **Transação**           | Registro de entrada ou saída de dinheiro. Pode ter data passada, presente ou futura. Deve sempre ter um valor, data, categoria e orçamento. |
| **Transação Agendada**  | Transação com data futura que ainda não foi efetivada. Útil para planejamento.                                                              |
| **Transação Realizada** | Transação que já aconteceu e impacta o saldo atual. Pode ter qualquer data.                                                                 |
| **Transação Atrasada**  | Transação com data passada que ainda não foi concluída/paga.                                                                                |
| **Conta**               | Local físico onde o dinheiro está armazenado (conta bancária, carteira, etc.). Pode ter saldo negativo.                                     |
| **Cartão de Crédito**   | Meio de pagamento com controle de limite e fatura. Não é tratado como conta bancária.                                                       |
| **Fatura**              | Conjunto de despesas em um cartão com data de fechamento e vencimento.                                                                      |
| **Pagamento de fatura** | Despesa pontual que representa a quitação da fatura do cartão.                                                                              |
| **Dashboard**           | Tela com resumo financeiro de um orçamento ou da visão geral do usuário.                                                                    |
| **Usuário**             | Pessoa que acessa a plataforma. Pode ter acesso a múltiplos orçamentos e metas.                                                             |

---

## 🔐 Visão de Confiança

- Todos os dados são privados por padrão.
- Usuários têm controle sobre quem acessa seus orçamentos.
- Toda transação é auditável com histórico de alterações.

---

## ✅ Resumo

OrçaSonhos não é apenas um app de finanças — é um **organizador de vida financeira com propósito.**  
Permite que cada usuário, sozinho ou em família, **controle seus gastos, visualize seu futuro e alcance seus sonhos** com planejamento realista.

**Diferencial único:** Transformar sonhos em metas alcançáveis através de uma experiência simples, visual e colaborativa, focada no mercado brasileiro.