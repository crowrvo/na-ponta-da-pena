# Handoff — VMS Finance

Atualizado em: 2026-11-10 (America/Sao_Paulo)

## Objetivo atual

Concluir o VMS Finance de ponta a ponta, incluindo arquitetura, organização, funcionalidades, testes, CI e documentação. O aplicativo Flutter deve usar Cubit; o backend .NET 10 deve usar Minimal API. PostgreSQL será o banco principal e SQLite sustentará a operação offline-first.

## Estado confirmado

- Repositório local: `C:\Projetos\na-ponta-a-pena`.
- GitHub Project: `VMS Finance` (`https://github.com/users/crowrvo/projects/2`).
- Issues `#1` a `#7` foram adicionadas ao Project com status inicial `Todo`.
- GitHub CLI `2.103.3` foi instalado; o usuário informou que concluiu o login.
- Login do GitHub CLI foi validado para a conta `crowrvo`.
- O token do GitHub CLI possui o escopo `project` necessário para administrar o Project pela API.
- O escopo `project` foi autorizado e a API GraphQL confirmou o Project `PVT_kwHOA1vrVc4Bq7nZ`, com exatamente 7 Issues.
- A API confirmou duas visualizações: `View 1` e `View 2`, ambas em formato de tabela.
- A mutação foi concluída: a visualização 1 agora é `Backlog` (`TABLE_LAYOUT`) e a visualização 2 é `Kanban` (`BOARD_LAYOUT`).
- A API confirmou que o Project já está vinculado ao repositório `crowrvo/na-ponta-da-pena` e contém exatamente as Issues `#1` a `#7`.
- O campo `Sprint` foi criado como seleção única com `Sprint 0`, `Sprint 1` e `Sprint 2`.
- Todas as sete Issues foram classificadas no campo `Sprint` conforme seus títulos.
- Validação final: 7 itens, todos com status `Todo`; Issues `#1`, `#2` e `#6` na Sprint 0; `#3`, `#4` e `#5` na Sprint 1; `#7` na Sprint 2.
- Automação do Codex `continuar-vms-finance-pelo-handoff` está ativa a cada 5 horas.
- Objetivo persistente criado: concluir o VMS Finance com Flutter/Cubit e .NET 10 Minimal API.
- Ferramentas confirmadas: .NET SDK `10.0.403` e Flutter `3.41.4`/Dart `3.11.1`.
- Trabalho paralelo iniciado em três frentes: backend/domínio/testes; Flutter/Cubit/offline-first; infraestrutura/CI/documentação.
- Issues `#1`, `#2`, `#3`, `#5` e `#6` foram movidas para `In Progress`; `#4` e `#7` permanecem em `Todo`.
- Retomada automática: os agentes paralelos encerraram; o agente de backend atingiu o limite de uso, mas deixou alterações parciais em Domain/Application. Flutter e infraestrutura também deixaram alterações não commitadas.
- O worktree contém apenas alterações das frentes autorizadas e deste handoff; nenhuma publicação foi feita.
- Integração concluída nesta retomada: domínio de famílias e lançamentos, serviços de aplicação, repositório EF Core/PostgreSQL e endpoints protegidos em Minimal API.
- Flutter agora possui domínio de lançamentos, repositório offline-first e Cubit para resumo/cadastro; o erro de importação do Drift foi corrigido.
- Qualidade validada: `dotnet test` aprovado; `flutter analyze` sem alertas; `flutter test` aprovado; `git diff --check` aprovado.
- Docker não está instalado/disponível neste Windows, portanto `docker compose config` não pôde ser executado localmente. Nenhum serviço foi publicado.

## Próxima ação

1. Completar o GitHub Project com os campos de priorização e área.
2. Adicionar testes unitários para `FinanceService`, isolamento entre famílias e idempotência.
3. Criar e validar a primeira migração EF Core quando PostgreSQL/Docker estiver disponível.
4. Implementar o contrato de sincronização entre outbox Flutter e Minimal API.
5. Atualizar Issues e Project conforme os resultados; manter a Issue `#7` bloqueada até HTTPS e autenticação estarem implementados e validados.

## Restrições permanentes

- Não publicar a API antes de HTTPS e autenticação estarem implementados e validados.
- Não assumir que DNS ou Cloudflare estão ativos sem verificação.
- Não registrar senhas, tokens, códigos de autenticação ou outros segredos neste arquivo.
- Ao atingir aproximadamente 90% do orçamento disponível da tarefa, atualizar este handoff e encerrar a execução atual de forma segura; a automação recorrente fará a retomada.
