# 📋 OrçaSonhos - Documentação do Projeto

Central de documentação para o projeto OrçaSonhos, uma plataforma de gestão financeira focada em transformar sonhos em metas alcançáveis.

## 🗂️ Estrutura da Documentação

### [`business/`](./business/index.md) 
**Documentação de Negócio**
- **[`product-vision/`](./business/product-vision/)** - Visão de produto e conceitos fundamentais
- **[`customer-profile/`](./business/customer-profile/)** - Personas, perfis de clientes e análise de mercado
- **[Funcionalidades Core](./business/03_funcionalidades_core.md)** - Features principais e roadmap

### [`technical/`](./technical/index.md)
**Documentação Técnica** 
- **[`backend-architecture/`](./technical/backend-architecture/)** - Clean Architecture + DDD, serviços e padrões
- **[`frontend-architecture/`](./technical/frontend-architecture/)** - Angular em camadas, UI system e estratégias
- **[`code-standards/`](./technical/code-standards/)** - Padrões de código, convenções e boas práticas
- **[Stack Tecnológico](./technical/03_stack_tecnologico.md)** - Ferramentas e tecnologias utilizadas
- **[Estratégia de Testes](./technical/04_estrategia_testes.md)** - Testes unitários, integração e E2E

### [`adr/`](./adr/index.md)
**Architecture Decision Records**
- Registro histórico de todas as decisões arquiteturais do projeto
- Stack de backend, banco de dados, infraestrutura e padrões de API
- Evolução das escolhas técnicas com contexto e justificativas

## 🧠 Documentação Semântica para IA/RAG

### Recursos Otimizados para IA
- **[Domain Ontology](./domain-ontology.md)** - Taxonomia formal e relações semânticas
- **[Domain Glossary](./domain-glossary.md)** - Glossário completo com 45+ termos definidos
- **[Entity Schemas](./schemas/entities.yaml)** - Schemas estruturados das entidades principais

### Metadados Estruturados
Todos os documentos principais agora incluem metadados YAML para otimizar:
- Contexto semântico para sistemas de IA
- Tags estruturadas para busca e categorização
- Referências cruzadas entre documentos
- Audiência-alvo e complexidade dos conteúdos

## 🔧 Manutenção da Documentação

### Sistema Híbrido de Manutenção
A documentação OrçaSonhos utiliza uma abordagem híbrida combinando orientações inteligentes para IA (80%) com scripts de validação automatizada (20%):

#### **📘 Guias para IA e Humanos**
- **[Documentation Maintenance Guide](./documentation-maintenance-guide.md)** - Guia completo de manutenção
- **[Propagation Matrix](./maintenance/propagation-matrix.md)** - Matriz de propagação semântica
- **[Templates](./templates/)** - Templates padronizados para diferentes tipos de documentos

#### **🔍 Scripts de Validação Automatizada**
```bash
# Validar metadados YAML
./scripts/validation/validate-metadata.sh

# Verificar links internos
./scripts/validation/check-cross-references.sh

# Atualizar timestamps
./scripts/validation/update-timestamps.sh [--dry-run] [--force]

# Verificar estrutura de diretórios
./scripts/validation/verify-structure.sh
```

#### **📋 Templates Disponíveis**
- **[Business Document](./templates/business-document.template.md)** - Para conceitos e análises de negócio
- **[Technical Document](./templates/technical-document.template.md)** - Para documentação técnica e arquitetura
- **[ADR Template](./templates/adr-template.md)** - Para Architecture Decision Records
- **[Schema Template](./templates/schema-template.yaml)** - Para schemas de entidades

### **Fluxo de Manutenção Recomendado**

1. **Para Mudanças Rotineiras**: Consultar o [Maintenance Guide](./documentation-maintenance-guide.md)
2. **Para Validações**: Executar scripts de validação periodicamente
3. **Para Novos Documentos**: Usar templates apropriados
4. **Para Consistência**: Seguir a [Propagation Matrix](./maintenance/propagation-matrix.md)

## 📦 Repositórios do Projeto

- **Frontend**: [orca-sonhos-front](https://github.com/danilotandrade1518/orca-sonhos-front)
- **Backend**: [orca-sonhos-back](https://github.com/danilotandrade1518/orca-sonhos-back)

## 🚀 Para Começar

### Novos Desenvolvedores
1. Explore [`business/product-vision/`](./business/product-vision/) para entender o domínio
2. Consulte [`technical/03_stack_tecnologico.md`](./technical/03_stack_tecnologico.md) para setup
3. Revise [`technical/code-standards/`](./technical/code-standards/) para convenções e padrões

### Product Managers  
1. Veja [`business/customer-profile/`](./business/customer-profile/) para personas e perfis
2. Consulte [`business/03_funcionalidades_core.md`](./business/03_funcionalidades_core.md) para roadmap
3. Explore [`business/product-vision/`](./business/product-vision/) para conceitos de produto

### Arquitetos/Tech Leads
1. [`technical/backend-architecture/`](./technical/backend-architecture/) - Arquitetura backend completa
2. [`technical/frontend-architecture/`](./technical/frontend-architecture/) - Arquitetura frontend detalhada
3. [`adr/index.md`](./adr/index.md) - Decisões arquiteturais e evolução técnica
4. [`technical/04_estrategia_testes.md`](./technical/04_estrategia_testes.md) - Estratégia de testes

## 🎯 Conceitos-Chave do OrçaSonhos

- **Múltiplos Orçamentos**: Flexibilidade para diferentes contextos financeiros
- **Metas SMART**: Transformação de sonhos em objetivos alcançáveis  
- **Compartilhamento Familiar**: Colaboração financeira simplificada
- **Offline-First**: Funciona sem conexão com sincronização automática
- **Mobile-First**: Interface otimizada para dispositivos móveis

## 🔄 Manutenção da Documentação

Esta documentação deve ser atualizada sempre que houver:
- Mudanças nos requisitos de negócio ou arquitetura
- Novas funcionalidades implementadas
- Alterações no stack tecnológico
- Refinamentos nos padrões de código

---

**Projeto:** OrçaSonhos  
**Última atualização:** 2025-09-11  
**Status:** Documentação base para desenvolvimento MVP