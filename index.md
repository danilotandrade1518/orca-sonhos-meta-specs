# 📋 OrçaSonhos - Documentação do Projeto

Central de documentação para o projeto OrçaSonhos, uma plataforma de gestão financeira focada em transformar sonhos em metas alcançáveis.

## 🗂️ Estrutura da Documentação

### [`business/`](./business/index.md) 
**Documentação de Negócio**
- Visão de produto, perfil de clientes e funcionalidades core
- Conceitos centrais: orçamentos, transações, metas, categorias
- Personas, casos de uso e análise competitiva

### [`technical/`](./technical/index.md)
**Documentação Técnica** 
- Arquitetura backend (Clean Architecture + DDD) e frontend (Angular em camadas)
- Stack tecnológico, estratégia de testes e padrões de código
- Configurações offline-first, mobile-first e autenticação Firebase

### [`adr/`](./adr/index.md)
**Architecture Decision Records**
- Registro histórico de todas as decisões arquiteturais do projeto
- Stack de backend, banco de dados, infraestrutura e padrões de API
- Evolução das escolhas técnicas com contexto e justificativas

## 🚀 Para Começar

### Novos Desenvolvedores
1. Leia [`business/01_visao_produto.md`](./business/01_visao_produto.md) para entender o domínio
2. Consulte [`technical/03_stack_tecnologico.md`](./technical/03_stack_tecnologico.md) para setup
3. Revise [`technical/05_padroes_codigo.md`](./technical/05_padroes_codigo.md) para convenções

### Product Managers  
1. Explore [`business/02_perfil_cliente.md`](./business/02_perfil_cliente.md) para personas
2. Veja [`business/03_funcionalidades_core.md`](./business/03_funcionalidades_core.md) para roadmap

### Arquitetos/Tech Leads
1. [`technical/backend-architecture/index.md`](./technical/backend-architecture/index.md) - Backend architecture
2. [`technical/02_visao-arquitetural-frontend.md`](./technical/02_visao-arquitetural-frontend.md) - Frontend architecture
3. [`adr/index.md`](./adr/index.md) - Decisões arquiteturais e evolução técnica

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
**Última atualização:** 2025-09-08  
**Status:** Documentação base para desenvolvimento MVP