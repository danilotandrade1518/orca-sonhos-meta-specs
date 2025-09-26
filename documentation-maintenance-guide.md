# 📘 Documentation Maintenance Guide - OrçaSonhos

---
**Metadados Estruturados para IA/RAG:**
```yaml
document_type: "maintenance_guide"
domain: "documentation_governance"
audience: ["ai_systems", "developers", "technical_writers", "product_managers"]
complexity: "advanced"
tags: ["maintenance", "governance", "ai_instructions", "documentation_standards"]
related_docs: ["domain-ontology.md", "domain-glossary.md", "schemas/entities.yaml"]
ai_context: "Comprehensive guide for AI systems to maintain OrçaSonhos documentation"
update_frequency: "on_structural_changes"
last_updated: "2025-01-24"
```
---

## 🎯 Propósito do Guia

Este documento serve como **manual de instruções semânticas** para sistemas de IA e humanos manterem a documentação OrçaSonhos de forma consistente, estruturada e otimizada para RAG.

### **Filosofia de Manutenção:**
- **Consistência semântica** acima de tudo
- **Propagação inteligente** de mudanças
- **Qualidade incremental** contínua
- **Otimização para IA/RAG** em cada atualização

---

## 🗺️ Anatomia da Documentação OrçaSonhos

### **Estrutura Hierárquica:**
```
OrçaSonhos Meta-Specs/
├── 📋 index.md                          # Portal principal
├── 🧠 domain-ontology.md                # Taxonomia formal
├── 📚 domain-glossary.md                # Terminologia central
├── 📊 schemas/entities.yaml             # Schemas estruturados
├── 📘 documentation-maintenance-guide.md # Este documento
├── business/                            # Conhecimento de negócio
│   ├── product-vision/                  # Visão e conceitos
│   └── customer-profile/                # Personas e perfis
├── technical/                          # Documentação técnica
│   ├── frontend-architecture/          # Arquitetura frontend
│   ├── backend-architecture/           # Arquitetura backend
│   └── code-standards/                 # Padrões e convenções
└── adr/                               # Architecture Decision Records
```

### **Tipos de Documentos:**

#### **🏢 Business Documents**
- **Propósito**: Conceitos de negócio, casos de uso, personas
- **Audiência**: Product managers, business analysts, stakeholders
- **Padrão**: Linguagem acessível, exemplos práticos, foco no "por quê"

#### **⚙️ Technical Documents**
- **Propósito**: Arquitetura, padrões, implementação
- **Audiência**: Desenvolvedores, arquitetos, tech leads
- **Padrão**: Precisão técnica, diagramas, código de exemplo

#### **📋 ADRs (Architecture Decision Records)**
- **Propósito**: Registro histórico de decisões arquiteturais
- **Audiência**: Arquitetos, tech leads, futuros mantenedores
- **Padrão**: Contexto → Decisão → Consequências

#### **🔗 Semantic Documents**
- **Propósito**: Ontologia, glossários, schemas
- **Audiência**: IA systems, desenvolvedores, analistas
- **Padrão**: Estrutura formal, metadados ricos, relações explícitas

---

## 🔄 Matriz de Propagação Semântica

### **🆕 Nova Funcionalidade de Negócio**

**Gatilho**: Implementação de nova feature ou caso de uso

**Propagação Obrigatória:**
1. **✅ Core Concepts** → Adicionar conceito se introduz nova abstração
2. **✅ Use Cases** → Incluir novo caso de uso ou atualizar existente
3. **✅ MVP Scope** → Avaliar impacto no escopo do MVP
4. **✅ Domain Glossary** → Adicionar novos termos se aplicável
5. **✅ Personas** → Verificar se afeta jornadas das personas existentes

**Propagação Condicional:**
- **Domain Ontology** → Se nova entidade ou relação de domínio
- **Entity Schemas** → Se nova entidade ou mudança estrutural
- **Architecture Docs** → Se mudança arquitetural significativa

**Template de Análise:**
```markdown
## Análise de Impacto - Nova Funcionalidade

**Feature**: [Nome da funcionalidade]
**Descrição**: [O que faz]

### Conceitos Novos Introduzidos:
- [ ] [Conceito] → Adicionar ao Glossário + Ontologia
- [ ] [Termo] → Definir no Glossário

### Documentos para Atualizar:
- [ ] core-concepts.md → [Específico que seção]
- [ ] use-cases.md → [Qual caso de uso]
- [ ] mvp-scope.md → [Se afeta escopo]
- [ ] personas.md → [Se afeta jornada]

### Validações:
- [ ] Terminologia consistente em todos os docs
- [ ] Referências cruzadas atualizadas
- [ ] Metadados incluindo novas tags
```

### **🏗️ Decisão Arquitetural**

**Gatilho**: Mudança significativa na arquitetura, stack ou padrões

**Propagação Obrigatória:**
1. **✅ Novo ADR** → Documentar decisão seguindo template
2. **✅ Architecture Overview** → Atualizar visão geral se aplicável
3. **✅ Stack Tecnológico** → Atualizar se nova tecnologia/ferramenta

**Propagação Condicional:**
- **Entity Schemas** → Se mudança afeta estrutura de dados
- **Code Standards** → Se estabelece novos padrões
- **Testing Strategy** → Se afeta estratégia de testes
- **Domain Model** → Se mudança conceitual no domínio

**Template ADR:**
```markdown
# ADR XXXX - [Título da Decisão]

## Status
Proposed | Accepted | Deprecated | Superseded

## Context
[Situação que motivou a decisão]

## Decision
[Decisão tomada]

## Consequences
### Positivas
- [Benefício 1]
- [Benefício 2]

### Negativas / Riscos Aceitos
- [Risco 1]
- [Risco 2]

## Alternativas Consideradas
- [Alternativa rejeitada e por quê]

## Implementation Guidelines
[Como implementar/operacionalizar]
```

### **🔄 Evolução de Conceito Existente**

**Gatilho**: Refinamento, extensão ou correção de conceito de domínio

**Propagação Obrigatória:**
1. **✅ Domain Glossary** → Atualizar definição e sinônimos
2. **✅ Domain Ontology** → Revisar relações e taxonomia
3. **✅ Core Concepts** → Sincronizar definição conceitual

**Propagação Condicional:**
- **Entity Schemas** → Se conceito é entidade ou value object
- **Use Cases** → Se mudança afeta casos de uso existentes
- **Code Standards** → Se evolução afeta padrões de implementação

**Checklist de Evolução:**
```markdown
## Evolução de Conceito: [Nome do Conceito]

### Antes → Depois:
**Definição antiga**: [Definição anterior]
**Definição nova**: [Definição refinada]

### Impactos Identificados:
- [ ] Glossário → Atualizar definição e exemplos
- [ ] Ontologia → Revisar relações e hierarquia
- [ ] Schemas → Sincronizar se entidade técnica
- [ ] Core Concepts → Alinhar definição conceitual
- [ ] Use Cases → Verificar se casos de uso fazem sentido
- [ ] Todos os docs que referenciam → Validar consistência

### Validação de Consistência:
- [ ] Buscar todas as referências ao conceito
- [ ] Verificar se sinônimos ainda são válidos
- [ ] Confirmar que exemplos refletem nova definição
- [ ] Atualizar metadados dos documentos afetados
```

### **➕ Novo Agregado/Entidade de Domínio**

**Gatilho**: Identificação de nova entidade ou agregado no DDD

**Propagação Obrigatória:**
1. **✅ Domain Ontology** → Adicionar à taxonomia com relações
2. **✅ Entity Schemas** → Criar schema completo da entidade
3. **✅ Domain Glossary** → Definir termo e conceitos relacionados
4. **✅ Domain Model** → Atualizar modelo de domínio técnico

**Propagação Condicional:**
- **Use Cases** → Se entidade participa de casos de uso principais
- **Core Concepts** → Se entidade é conceito central para usuários
- **API Patterns** → Se entidade exposta via API

**Template Novo Agregado:**
```yaml
# Schema da Nova Entidade
NewEntity:
  type: "aggregate_root" | "entity" | "value_object"
  description: "[Descrição clara do propósito]"

  properties:
    id: { type: "string", format: "uuid" }
    # ... outras propriedades

  relationships:
    belongs_to: ["RelatedEntity"]
    has_many: ["ChildEntity"]

  business_rules:
    - rule: "rule_name"
      description: "[Descrição da regra]"
      validation: "[Como validar]"
```

---

## 📋 Checklist de Qualidade Semântica

### **Para Toda Atualização de Documentação:**

#### **🏷️ Metadados e Estrutura:**
- [ ] **Metadados YAML** completos e válidos
- [ ] **Tags semânticas** apropriadas para o conteúdo
- [ ] **Audience** corretamente identificada
- [ ] **Complexity level** adequado
- [ ] **Related docs** listados e válidos
- [ ] **Last updated** atualizado

#### **📖 Conteúdo e Consistência:**
- [ ] **Terminologia** alinhada com Domain Glossary
- [ ] **Conceitos** referenciados existem na Domain Ontology
- [ ] **Links internos** funcionando e atualizados
- [ ] **Exemplos práticos** relevantes e atuais
- [ ] **Referências cruzadas** bidirecionais quando aplicável

#### **🤖 Otimização para IA/RAG:**
- [ ] **Contexto semântico** claro para sistemas de IA
- [ ] **Estrutura hierárquica** bem definida
- [ ] **Sinônimos e variações** de termos incluídos
- [ ] **Relacionamentos** explícitos entre conceitos
- [ ] **Padrões de consulta** contemplados

---

## 🎨 Templates e Padrões

### **Template Business Document:**
```markdown
# [Título do Documento]

---
**Metadados Estruturados para IA/RAG:**
```yaml
document_type: "business_[concept|case|analysis]"
domain: "business_domain"
audience: ["product_managers", "business_analysts", "stakeholders"]
complexity: "beginner|intermediate|advanced"
tags: ["tag1", "tag2", "tag3"]
related_docs: ["doc1.md", "doc2.md"]
ai_context: "Brief description for AI systems"
personas_affected: ["persona1", "persona2"] # se aplicável
last_updated: "YYYY-MM-DD"
```
---

## [Seção Principal]

### [Subseção com Conceitos]
[Conteúdo usando terminologia do Domain Glossary]

### [Exemplos Práticos]
[Exemplos contextualizados para personas]

---

**Ver também:**
- [Link para conceitos relacionados](link.md)
- [Referência à ontologia](domain-ontology.md#conceito)
```

### **Template Technical Document:**
```markdown
# [Título Técnico]

---
**Metadados Estruturados para IA/RAG:**
```yaml
document_type: "technical_[architecture|standards|patterns]"
domain: "technical_domain"
audience: ["developers", "architects", "tech_leads"]
complexity: "intermediate|advanced"
tags: ["technical", "implementation", "patterns"]
related_docs: ["related-tech-doc.md"]
ai_context: "Technical context for AI systems"
technologies: ["tech1", "tech2"] # se aplicável
patterns: ["pattern1", "pattern2"] # se aplicável
last_updated: "YYYY-MM-DD"
```
---

## [Visão Geral Técnica]

### [Implementação]
```typescript
// Código de exemplo seguindo Code Standards
```

### [Padrões e Convenções]
[Referência aos code-standards estabelecidos]

---

**Implementação relacionada:**
- [Schema relacionado](../schemas/entities.yaml#Entity)
- [Padrão de código](../code-standards/pattern.md)
```

---

## 🔧 Scripts de Validação Minimalistas

### **validate-metadata.sh**
```bash
#!/bin/bash
# Valida metadados YAML em documentos .md

echo "🔍 Validating YAML metadata in documentation..."

errors=0
for file in $(find . -name "*.md" -not -path "./node_modules/*"); do
    # Check if file has YAML metadata
    if grep -q "^```yaml" "$file"; then
        # Extract YAML block and validate
        sed -n '/^```yaml/,/^```/p' "$file" | sed '1d;$d' > temp_yaml.yml

        if ! yaml-validator temp_yaml.yml >/dev/null 2>&1; then
            echo "❌ Invalid YAML in: $file"
            errors=$((errors + 1))
        fi

        # Check required fields
        if ! grep -q "document_type:" temp_yaml.yml; then
            echo "⚠️  Missing 'document_type' in: $file"
        fi

        if ! grep -q "last_updated:" temp_yaml.yml; then
            echo "⚠️  Missing 'last_updated' in: $file"
        fi

        rm -f temp_yaml.yml
    fi
done

echo "✅ Validation complete. Found $errors errors."
exit $errors
```

### **check-cross-references.sh**
```bash
#!/bin/bash
# Verifica links internos quebrados

echo "🔗 Checking internal cross-references..."

broken_links=0
for file in $(find . -name "*.md"); do
    # Find markdown links to other files
    grep -oE '\[.*\]\([^)]+\.md[^)]*\)' "$file" | while read -r link; do
        # Extract the file path from the link
        path=$(echo "$link" | sed 's/.*](\([^)]*\)).*/\1/' | sed 's/#.*//')

        # Convert relative path to absolute
        dir=$(dirname "$file")
        full_path="$dir/$path"

        if [[ ! -f "$full_path" ]]; then
            echo "❌ Broken link in $file: $path"
            broken_links=$((broken_links + 1))
        fi
    done
done

echo "✅ Cross-reference check complete."
```

### **update-timestamps.sh**
```bash
#!/bin/bash
# Atualiza last_updated em arquivos modificados

echo "📅 Updating timestamps for modified files..."

# Get files modified in the last day
for file in $(find . -name "*.md" -mtime -1); do
    if grep -q "last_updated:" "$file"; then
        # Update existing timestamp
        today=$(date +%Y-%m-%d)
        sed -i "s/last_updated: .*/last_updated: \"$today\"/" "$file"
        echo "⏰ Updated timestamp in: $file"
    fi
done

echo "✅ Timestamp update complete."
```

---

## 🎯 Cenários de Manutenção Comuns

### **🚀 "Implementei uma nova funcionalidade"**

**Pergunta de contexto**: A funcionalidade introduz novos conceitos de domínio?

**Se SIM - Conceitos Novos:**
1. **Adicionar ao Domain Glossary** → Definição, sinônimos, exemplos
2. **Incluir na Domain Ontology** → Taxonomia, relações, metadados
3. **Atualizar Core Concepts** → Se conceito central para usuários
4. **Revisar Entity Schemas** → Se nova entidade ou mudança estrutural
5. **Incluir em Use Cases** → Caso de uso específico ou atualização
6. **Considerar Personas** → Impacto nas jornadas das personas

**Se NÃO - Funcionalidade Incremental:**
1. **Atualizar Use Cases** → Incluir nova funcionalidade em caso existente
2. **Revisar MVP Scope** → Confirmar se está no escopo atual
3. **Verificar impacto em Personas** → Melhorias em jornadas existentes

### **📐 "Tomei uma decisão arquitetural importante"**

**Ação obrigatória**: Criar novo ADR seguindo template

**Propagação automática**:
1. **Criar ADR** → Contexto, decisão, consequências, alternativas
2. **Atualizar Overview de Arquitetura** → Se mudança estrutural significativa
3. **Revisar Stack Tecnológico** → Se nova ferramenta ou tecnologia
4. **Considerar Code Standards** → Se estabelece novos padrões
5. **Avaliar impacto em Schemas** → Se mudança afeta estrutura de dados
6. **Atualizar Testing Strategy** → Se afeta abordagem de testes

### **✏️ "Preciso refinar um conceito existente"**

**Fluxo de refinamento**:
1. **Começar pelo Domain Glossary** → Refinar definição principal
2. **Sincronizar Domain Ontology** → Ajustar relações se necessário
3. **Atualizar Core Concepts** → Alinhar definição conceitual
4. **Revisar Entity Schemas** → Se conceito é entidade técnica
5. **Verificar todos os documentos** → Buscar referências e atualizar
6. **Validar Use Cases** → Confirmar que ainda fazem sentido

### **🆕 "Identifiquei um novo agregado de domínio"**

**Processo estruturado**:
1. **Definir no Domain Glossary** → Nome, definição, sinônimos
2. **Adicionar à Domain Ontology** → Taxonomia, relações, hierarquia
3. **Criar Entity Schema** → Propriedades, relacionamentos, regras
4. **Atualizar Domain Model** → Modelo técnico de domínio
5. **Considerar Use Cases** → Casos de uso que envolvem a entidade
6. **Avaliar API Patterns** → Se entidade exposta via API

---

## 🔍 Validação de Consistência Semântica

### **Checklist de Consistência Global:**

#### **🔗 Alinhamento Ontologia ↔ Glossário:**
- [ ] Todo conceito da ontologia tem definição no glossário
- [ ] Todo termo do glossário está mapeado na ontologia
- [ ] Sinônimos são consistentes entre ambos
- [ ] Relações na ontologia refletem definições do glossário

#### **📊 Alinhamento Schemas ↔ Domínio:**
- [ ] Entidades nos schemas existem na ontologia
- [ ] Propriedades técnicas refletem conceitos de negócio
- [ ] Business rules nos schemas alinham com Core Concepts
- [ ] Relacionamentos técnicos espelham relações semânticas

#### **📋 Consistência Terminológica:**
- [ ] Mesma terminologia em docs business vs technical
- [ ] Sinônimos utilizados de forma consistente
- [ ] Conceitos técnicos mapeados para conceitos de negócio
- [ ] Glossário reflete o vocabulário real dos documentos

### **Processo de Auditoria Semântica:**

**1. Auditoria Mensal:**
```bash
# Executar scripts de validação
./scripts/validate-metadata.sh
./scripts/check-cross-references.sh
./scripts/verify-structure.sh

# Checklist manual de consistência
- Revisar alinhamento ontologia-glossário
- Validar referências cruzadas principais
- Verificar metadados de documentos recentes
```

**2. Auditoria por Mudança Significativa:**
- Sempre que novo conceito é introduzido
- Após decisões arquiteturais importantes
- Quando refatoração afeta múltiplos documentos

---

## 🎓 Boas Práticas para IA

### **Durante Criação de Conteúdo:**
1. **Sempre consultar Domain Glossary** antes de usar terminologia
2. **Verificar Domain Ontology** para relações entre conceitos
3. **Incluir metadados YAML** seguindo padrões estabelecidos
4. **Adicionar referências cruzadas** bidirecionais quando aplicável
5. **Usar examples contextualizados** para personas do projeto

### **Durante Atualização de Conteúdo:**
1. **Identificar tipo de mudança** (funcionalidade, conceito, decisão)
2. **Aplicar matriz de propagação** correspondente
3. **Validar consistência terminológica** em todos os docs afetados
4. **Atualizar metadados** com novas tags e relacionamentos
5. **Verificar impacto em cases de uso** e personas

### **Durante Validação:**
1. **Executar checklist de qualidade semântica** completo
2. **Verificar scripts de validação** não reportam erros
3. **Confirmar alinhamento** ontologia-glossário-schemas
4. **Testar navegação** via referências cruzadas
5. **Validar otimização** para sistemas RAG

---

## 📈 Evolução Contínua do Guia

Este guia é um **documento vivo** que deve evoluir com o projeto:

### **Sinais de que o guia precisa ser atualizado:**
- Novos tipos de documentos sendo criados
- Padrões de mudança não cobertos pelos cenários atuais
- Scripts de validação identificando problemas recorrentes não contemplados
- Feedback de que instruções estão ambíguas ou incompletas

### **Como atualizar este guia:**
1. **Identificar novo padrão** ou necessidade
2. **Documentar cenário** na seção apropriada
3. **Atualizar matriz de propagação** se necessário
4. **Adicionar ao checklist** de qualidade
5. **Testar com exemplos reais** do projeto
6. **Atualizar metadados** deste documento

---

## 🔗 Referências e Recursos

### **Documentos Fundamentais:**
- **[Domain Ontology](./domain-ontology.md)** - Taxonomia e relações formais
- **[Domain Glossary](./domain-glossary.md)** - Terminologia centralizada
- **[Entity Schemas](./schemas/entities.yaml)** - Estruturas técnicas
- **[Core Concepts](./business/product-vision/core-concepts.md)** - Conceitos centrais

### **Templates de Referência:**
- **[Business Document Template](./templates/business-document.template.md)**
- **[Technical Document Template](./templates/technical-document.template.md)**
- **[ADR Template](./templates/adr-template.md)**
- **[Schema Template](./templates/schema-template.yaml)**

### **Scripts de Validação:**
- **[Validate Metadata](./scripts/validation/validate-metadata.sh)**
- **[Check Cross References](./scripts/validation/check-cross-references.sh)**
- **[Update Timestamps](./scripts/validation/update-timestamps.sh)**

---

## 🤖 Instruções Específicas para IA

### **Prioridades de Consulta:**
1. **Domain Glossary** → Para definições e terminologia
2. **Domain Ontology** → Para relações e contexto semântico
3. **Este Guia** → Para processos e padrões de manutenção
4. **Entity Schemas** → Para estruturas técnicas
5. **Templates** → Para formato e estrutura de documentos

### **Princípios de Decisão:**
- **Quando em dúvida sobre terminologia** → Consultar glossário
- **Quando mudança afeta múltiplos docs** → Aplicar matriz de propagação
- **Quando criar novo conteúdo** → Usar templates apropriados
- **Quando validar qualidade** → Seguir checklist completo
- **Quando evoluir conceitos** → Manter consistência semântica

### **Qualidade sobre Velocidade:**
É melhor fazer uma atualização completa e consistente do que uma atualização rápida que gera inconsistências. A documentação é a fonte de verdade para o projeto e sistemas de IA.

**Lembrete final**: Toda atualização deve deixar a documentação **mais consistente, mais útil e mais otimizada para IA/RAG** do que estava antes.