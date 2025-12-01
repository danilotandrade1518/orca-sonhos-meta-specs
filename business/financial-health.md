#! Saúde Financeira - OrçaSonhos

---

**Metadados Estruturados para IA/RAG:**
```yaml
document_type: "business_concept"
domain: "personal_finance"
audience: ["product_managers", "business_analysts", "stakeholders", "developers"]
complexity: "intermediate"
tags:
  [
    "financial_health",
    "indicators",
    "dashboard",
    "personal_finance",
    "risk_management",
  ]
related_docs:
  [
    "product-vision/core-concepts.md",
    "product-vision/mvp-scope.md",
    "03_funcionalidades_core.md",
    "../domain-glossary.md",
  ]
ai_context: "Concept and indicator definitions for measuring a user's financial health in OrçaSonhos, including formulas and interpretation ranges to support dashboards and recommendations"
personas_affected: ["ana_familiar", "carlos_young", "roberto_maria", "julia_entrepreneur"]
use_cases_covered: ["dashboard_overview", "financial_health_insights"]
last_updated: "2025-12-01"
```
---

## 🎯 Propósito e Definição

**Saúde financeira**, no contexto do OrçaSonhos, é o grau em que a situação financeira de uma pessoa ou família é:

- **Sustentável no curto prazo** (fluxo de caixa positivo ou equilibrado).
- **Protegida contra imprevistos** (reserva de emergência adequada).
- **Alinhada com objetivos de longo prazo** (metas SMART on-track).
- **Equilibrada em termos de uso de crédito e orçamento** (gastos dentro de limites saudáveis).

Na prática, é a resposta para a pergunta:

> **“Estamos conseguindo viver hoje, proteger o amanhã e ainda avançar nos nossos sonhos, sem depender perigosamente de dívida?”**

Este documento define os **indicadores mínimos** que alimentam componentes como o `FinancialHealthIndicatorComponent` no dashboard.

### **Contexto no Projeto OrçaSonhos**

- Relaciona-se diretamente à feature **📊 Dashboard Centrado em Progresso** descrita em `03_funcionalidades_core.md`.
- Usa os conceitos de:
  - **Orçamento (Budget)**, **Transações**, **Metas**, **Contas** e **Envelopes** (ver `product-vision/core-concepts.md`).
  - Termos formais de **Fluxo de Caixa**, **Goal Progress** e **Monthly Contribution** (ver `domain-glossary.md`).
- Serve como base conceitual para:
  - Dashboards que mostram **“Indicadores de saúde financeira”**.
  - Lógica de insights e alertas proativos (ex.: “sua reserva está abaixo de 3 meses de despesas”).

---

## 📋 Indicadores de Saúde Financeira

Os indicadores abaixo representam uma **visão mínima** que o OrçaSonhos deve considerar para avaliar a saúde financeira de um orçamento/usuário.

Eles podem ser exibidos individualmente (cards) ou combinados em um **score agregado** em componentes como `FinancialHealthIndicatorComponent`.

### 1. Uso de Orçamento e Envelopes

**Pergunta que responde:** _“Estou gastando dentro do que planejei?”_

- **Indicador principal:** `% do orçamento usado no período atual`.
- **Base conceitual:**
  - `BudgetResponseDto` e cálculo de `usagePercentage` em `core-concepts.md`.
  - Conceito de **Envelope** como limite por categoria (modelo 50-30-20).

**Fórmula (por orçamento):**

- \( usage\_percentage = (currentUsageInCents / limitInCents) \times 100 \)

**Interpretação sugerida:**

- `0–80%` → **Verde**: uso saudável dentro do planejado.
- `80–100%` → **Amarelo**: atenção, perto do limite.
- `> 100%` → **Vermelho**: ultrapassou o orçamento definido.

> Observação: o mesmo raciocínio pode ser aplicado por envelope/categoria para análises mais detalhadas.

---

### 2. Relação Receitas vs Despesas (Fluxo de Caixa)

**Pergunta que responde:** _“Gasto menos do que ganho?”_

- **Indicador principal:** `Índice receitas vs despesas no período`.
- **Base conceitual:**
  - Termo **Cash Flow / Fluxo de Caixa** no `domain-glossary.md`.
  - Boas práticas de finanças pessoais: gastar sistematicamente menos do que se ganha.

**Fórmulas (mensal, usando transações realizadas):**

- \( total\_receitas = \sum transações\_realizadas\_do\_tipo\_Receita \)
- \( total\_despesas = \sum transações\_realizadas\_do\_tipo\_Despesa \)
- \( fluxo\_relativo = (total\_receitas / \max(total\_despesas, 1)) \times 100 \)

**Interpretação sugerida:**

- `fluxo_relativo > 110%` → **Verde**: superávit confortável (sobra mensal consistente).
- `fluxo_relativo entre 100–110%` → **Verde/Amarelo**: superávit leve.
- `fluxo_relativo ≈ 100%` → **Amarelo**: equilíbrio; pouca margem para imprevistos.
- `fluxo_relativo < 100%` → **Vermelho**: déficit; despesas maiores que receitas.

Opcionalmente, o dashboard pode mostrar também o **valor absoluto** de sobra/falta:

- \( saldo\_mensal = total\_receitas - total\_despesas \)

---

### 3. Progresso das Metas (Metas On-Track)

**Pergunta que responde:** _“Estou avançando nos meus objetivos no prazo?”_

- **Indicador principal:** `% de metas on-track`.
- **Base conceitual:**
  - **Metas SMART** e `Goal Progress` / `Goal Timeline` no `domain-glossary.md`.
  - Alertas de progresso: atrasado, no prazo, adiantado.

**Definições operacionais sugeridas:**

- `goal_progress = (valor_atual / valor_alvo) × 100`
- `contribuição_mensal_ideal = valor_restante / meses_restantes`
- Uma meta é considerada **on-track** se:
  - Progresso atual ≥ progresso esperado para a data, **ou**
  - Contribuição média recente ≥ contribuição mensal ideal calculada.

**Indicador agregado:**

- \( metas\_on\_track\_percent = (qtd\_metas\_on\_track / max(qtd\_metas\_ativas, 1)) \times 100 \)

**Interpretação sugerida:**

- `≥ 75%` das metas ativas on-track → **Verde**.
- `entre 50–75%` → **Amarelo**.
- `< 50%` → **Vermelho**.

---

### 4. Nível de Reserva de Emergência

**Pergunta que responde:** _“Por quantos meses eu consigo me sustentar se algo der errado?”_

- **Indicador principal:** `Meses cobertos pela reserva de emergência`.
- **Base conceitual:**
  - Personas e exemplos de metas de **“Reserva de Emergência”** (`personas.md`, `persona-examples.md`).
  - Boas práticas de educação financeira: reserva de **3 a 6 meses** de despesas.

**Fórmulas sugeridas:**

- \( despesa\_mensal\_media = média(despesas\_mensais\_dos\_últimos\_N\_meses) \)
- \( meses\_cobertos = reserva\_atual / max(despesa\_mensal\_media, 1) \)
  - Onde `reserva_atual` pode ser:
    - Saldo em contas/envelopes marcados como “emergência”, **ou**
    - Valor atual acumulado em metas do tipo “reserva de emergência”.

**Interpretação sugerida:**

- `< 3 meses` → **Vermelho**: muito vulnerável a imprevistos.
- `3–6 meses` → **Amarelo/Verde**: zona recomendada.
- `> 6 meses` → **Verde**: reserva confortável.

---

### 5. (Opcional) Distribuição 50-30-20 Real vs Ideal

**Pergunta que responde:** _“Minhas escolhas de consumo estão equilibradas entre necessidades, estilo de vida e prioridades financeiras?”_

- **Indicador principal:** `Desvio em relação ao modelo 50-30-20`.
- **Base conceitual:**
  - Modelo de categorias 50-30-20 definido em `product-vision/core-concepts.md`:
    - 50% Necessidades
    - 30% Estilo de vida
    - 20% Prioridades financeiras

**Fórmulas sugeridas (mensal):**

- \( pct\_necessidades = despesas\_necessidades / total\_despesas \times 100 \)
- \( pct\_estilo\_vida = despesas\_estilo\_vida / total\_despesas \times 100 \)
- \( pct\_prioridades = despesas\_prioridades / total\_despesas \times 100 \)

Pode-se definir um **índice de aderência** simples:

- \( aderencia\_50\_30\_20 = 100 - (|pct\_necessidades - 50| + |pct\_estilo\_vida - 30| + |pct\_prioridades - 20|) / 3 \)
  - (quanto menor o desvio médio, maior a aderência).

Este indicador é opcional, mas útil para **educação financeira** e recomendações.

---

## 📊 Score Agregado de Saúde Financeira (Opcional)

O OrçaSonhos **não precisa** expor um score único para o usuário final, mas, para IA/RAG e motores de recomendação, pode ser útil modelar um **score interno** de 0 a 100 combinando os indicadores acima.

### Exemplo de combinação (sugestão)

```yaml
financial_health_score:
  weights:
    budget_usage: 0.25      # Uso de orçamento/envelopes
    cash_flow: 0.25         # Receitas vs despesas
    goals_on_track: 0.25    # Metas on-track
    emergency_reserve: 0.25 # Meses de reserva
  scale: 0-100
```

Cada indicador é normalizado para 0–100 conforme as faixas definidas acima e então combinado pelos pesos.

### Faixas de classificação sugeridas

- `0–39` → **Crítico**: risco alto de endividamento ou colapso de fluxo de caixa.
- `40–59` → **Vulnerável**: situação instável; pequenos choques causam problemas.
- `60–79` → **Saudável**: base organizada, ainda com espaço para melhoria.
- `80–100` → **Muito saudável**: finanças robustas e bem alinhadas às metas.

> Importante: o score agregado é uma **abstração interna**; UX pode optar por mostrar apenas os indicadores individuais ou um resumo qualitativo (ex.: “Saúde financeira: saudável”).

---

## 🔗 Relacionamentos e Impactos

### Impacto nas Personas

| Persona            | Impacto                                                | Benefício principal                               |
|--------------------|--------------------------------------------------------|---------------------------------------------------|
| Ana (Familiar)     | Entende rapidamente se o orçamento da casa está estável| Segurança para a família e tomada de decisão em casal |
| Carlos (Jovem)     | Visualiza se consegue sustentar aportes para intercâmbio| Disciplina para construir primeira grande meta   |
| Roberto & Maria    | Monitoram múltiplos orçamentos e metas longas          | Planejamento de longo prazo com menos incerteza  |
| Júlia (Empreendedora) | Equilibra PF e PJ olhando risco de caixa e reservas | Proteção do negócio e da vida pessoal            |

### Casos de Uso Relacionados

- **Dashboard Principal**: Mostrar os principais indicadores de saúde financeira logo na entrada.
- **Insights Inteligentes**: Gerar alertas do tipo:
  - “Sua reserva está abaixo de 3 meses de despesas.”
  - “Suas despesas superam suas receitas há 3 meses seguidos.”
  - “Mais da metade das suas metas estão atrasadas.”

---

## 📊 Indicadores de Sucesso (do Produto)

```yaml
metrics:
  primary:
    - name: "users_with_health_indicators_visible"
      description: "Percentual de usuários que visualizam indicadores de saúde financeira no dashboard"
      target: ">= 80% dos usuários ativos mensais"
      frequency: "mensal"

    - name: "improvement_in_health_over_time"
      description: "Percentual de usuários que melhoram pelo menos 1 faixa de saúde financeira em 6 meses"
      target: ">= 30% dos usuários com uso recorrente"
      frequency: "trimestral"

  secondary:
    - name: "goals_on_track_increase"
      description: "Variação no percentual de metas on-track após uso recorrente do produto"
      target: "tendência positiva ao longo de 12 meses"
```

---

## 📝 Notas para Manutenção

### Quando Atualizar Este Documento

- Mudanças nas regras de cálculo de qualquer indicador de saúde financeira.
- Ajustes nas faixas de classificação (ex.: redefinição do que é “saudável” para reserva).
- Introdução de novos indicadores relevantes no dashboard.

### Documentos Impactados por Mudanças Aqui

- `business/03_funcionalidades_core.md` — descrição do **Dashboard Centrado em Progresso**.
- `business/product-vision/core-concepts.md` — se novos conceitos forem introduzidos.
- `domain-glossary.md` — se surgirem novos termos ou variações de definição.
- Documentação técnica de frontend relacionada a dashboard e componentes de indicadores.

### Checklist de Atualização

- [ ] Validar terminologia com `domain-glossary.md`.
- [ ] Verificar alinhamento com `domain-ontology.md`.
- [ ] Atualizar referências cruzadas em `index.md` e documentos de visão de produto.
- [ ] Revisar exemplos para todas as personas principais.
- [ ] Atualizar metadados (tags, `last_updated`).

---

**Histórico de Mudanças:**
- `2025-12-01` - Criação inicial do conceito de Saúde Financeira e definição de indicadores mínimos.


