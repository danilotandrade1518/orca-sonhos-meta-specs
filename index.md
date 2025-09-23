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