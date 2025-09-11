# MVP Scope - Escopo do MVP

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

## 🏗️ Arquitetura MVP

### Core Features (Fase 1)
**Objetivo**: Usuário consegue criar meta e controlar gastos básicos
- Autenticação Firebase
- CRUD de orçamentos
- CRUD de transações básicas
- Sistema de categorias preset
- Dashboard simples

### Collaboration Features (Fase 2)
**Objetivo**: Famílias conseguem compartilhar orçamentos
- Compartilhamento de orçamentos
- Múltiplos usuários por orçamento
- Sincronização em tempo real

### Advanced Features (Fase 3)
**Objetivo**: Planejamento financeiro completo
- Sistema de metas SMART
- Transações futuras/agendadas
- Controle de envelopes
- Gestão de cartões de crédito
- Onboarding completo

---

## 📚 Termos importantes para a IA Assistente

| Termo | Significado |
|-------|-------------|
| **Orçamento** | Espaço virtual com categorias, transações, metas e envelopes. Pode ser compartilhado ou individual. |
| **Categoria** | Tipo de gasto/receita (ex: alimentação, transporte, investimento). Organiza as transações. |
| **Meta** | Objetivo financeiro (ex: comprar carro, fazer intercâmbio), com valor-alvo e prazo. |
| **Envelope** | Limite de gastos por categoria dentro de um orçamento mensal. |
| **Transação** | Registro de entrada ou saída de dinheiro. Pode ter data passada, presente ou futura. Deve sempre ter um valor, data, categoria e orçamento. |
| **Transação Agendada** | Transação com data futura que ainda não foi efetivada. Útil para planejamento. |
| **Transação Realizada** | Transação que já aconteceu e impacta o saldo atual. Pode ter qualquer data. |
| **Transação Atrasada** | Transação com data passada que ainda não foi concluída/paga. |
| **Conta** | Local físico onde o dinheiro está armazenado (conta bancária, carteira, etc.). Pode ter saldo negativo. |
| **Cartão de Crédito** | Meio de pagamento com controle de limite e fatura. Não é tratado como conta bancária. |
| **Fatura** | Conjunto de despesas em um cartão com data de fechamento e vencimento. |
| **Pagamento de fatura** | Despesa pontual que representa a quitação da fatura do cartão. |
| **Dashboard** | Tela com resumo financeiro de um orçamento ou da visão geral do usuário. |
| **Usuário** | Pessoa que acessa a plataforma. Pode ter acesso a múltiplos orçamentos e metas. |

---

## 🔐 Visão de Confiança

### Segurança MVP
- Todos os dados são privados por padrão
- Usuários têm controle sobre quem acessa seus orçamentos
- Toda transação é auditável com histórico de alterações
- Autenticação Firebase para segurança
- Dados criptografados em trânsito e repouso

### Privacidade MVP
- Dados pessoais mínimos coletados
- LGPD compliance desde o primeiro dia
- Opção de exclusão completa de dados
- Transparência sobre uso de informações

---

## 🎯 Critérios de Sucesso do MVP

### Métricas de Produto
- **Cadastro**: > 1.000 usuários em 3 meses
- **Engajamento**: > 60% retorno em 7 dias
- **Retenção**: > 40% usuários ativos em 30 dias
- **Feature adoption**: > 80% criam primeira meta

### Métricas de Negócio
- **Time to value**: < 7 minutos do cadastro à primeira transação
- **Compartilhamento**: > 30% dos orçamentos são compartilhados
- **Metas ativas**: > 70% dos usuários têm meta ativa
- **NPS**: > 50 (categoria promotores)

### Métricas Técnicas
- **Performance**: < 3s carregamento inicial
- **Disponibilidade**: > 99% uptime
- **Bugs críticos**: 0 em produção
- **Mobile responsiveness**: 100% funcional

---

## 🚦 Gate Criteria para Pós-MVP

### Critérios de Validação
- [ ] Product-market fit demonstrado (NPS > 50)
- [ ] Tração orgânica (> 30% crescimento MoM)
- [ ] Uso consistente de features core (> 80% adoption)
- [ ] Feedback qualitativo positivo de famílias

### Critérios de Infraestrutura  
- [ ] Escalabilidade validada (> 10k usuários)
- [ ] Performance mantida sob carga
- [ ] Sistema de monitoramento robusto
- [ ] Processos de deploy automatizados

---

## ✅ Resumo do MVP

OrçaSonhos MVP não é apenas um app de finanças — é um **organizador de vida financeira com propósito.**  
Permite que cada usuário, sozinho ou em família, **controle seus gastos, visualize seu futuro e alcance seus sonhos** com planejamento realista.

**Diferencial único do MVP:** Transformar sonhos em metas alcançáveis através de uma experiência simples, visual e colaborativa, focada no mercado brasileiro.

**Próxima fase:** Com MVP validado, expandir para funcionalidades avançadas de engajamento e integração bancária.

---

**Tópicos relacionados:**
- **[Use Cases](./use-cases.md)** - Casos de uso prioritários
- **[Core Concepts](./core-concepts.md)** - Conceitos centrais do sistema