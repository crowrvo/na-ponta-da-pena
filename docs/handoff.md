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
- Retomada automática de 2026-11-10 13:41 (America/Sao_Paulo): repositório confirmado limpo no commit `3bccd37`; em andamento a cobertura unitária de `FinanceService` para autorização por família, idempotência e totais mensais.
- Cobertura unitária adicionada: isolamento entre famílias, retry idempotente, conflito de chave, totais mensais e autorização exclusiva do owner. `dotnet test` passou com 6 testes.
- GitHub Project completado com os campos `Priority` e `Area`; as 7 Issues foram classificadas e a Issue `#7` permanece `Todo`, P2 e bloqueada pelos gates de segurança.
- Ferramenta local `dotnet-ef` 10.0.4 versionada e migração `InitialCreate` gerada. A modelagem ganhou chave estrangeira de lançamentos para famílias e limite de 100 caracteres para a chave idempotente.
- A migração foi validada por compilação/model generation, mas não aplicada: não há PostgreSQL ativo em `localhost:5432`. Nenhuma API ou túnel foi publicado.
- Retomada automática de 2026-11-10 18:41 (America/Sao_Paulo): repositório confirmado limpo no commit `e9c7e0a`; GitHub Project íntegro com 7 Issues. Em andamento a Issue `#4`, dividida entre contrato batch autenticado na Minimal API e consumidor da outbox no Flutter.
- Contrato de sincronização implementado: `POST /api/households/{householdId}/sync/entries`, lote de 1 a 100 operações, enum textual camelCase, `DateOnly` em `yyyy-MM-dd`, isolamento por família e resultado por chave idempotente.
- O backend faz preflight do lote antes de persistir, aceita retry idêntico sem duplicar e rejeita conflito com HTTP 409 sem gravar itens novos. O endpoint exige autenticação; teste HTTP confirma 401 sem token.
- O Flutter agora agrupa a outbox por família, usa token por abstração de armazenamento seguro, envia lotes, confirma SQLite em transação, aplica backoff exponencial e trata conflito/payload inválido sem perder o lançamento local.
- Robustez validada: 401/403 não entram em retry, respostas parciais/extras/duplicadas são recusadas antes do ack, erros persistidos são códigos genéricos e um guard evita sincronizações concorrentes.
- Validação desta retomada: `dotnet test` com 12 testes; `flutter analyze` limpo; `flutter test` com 10 testes; nenhuma publicação externa.

## Próxima ação

1. Integrar o disparo do `FinanceSyncService` ao Cubit/conectividade e expor estados de sincronização na interface, sem iniciar o túnel.
2. Completar convites/entrada/revogação de membros e documentar a escolha do provedor OIDC; só então conectar o login real ao `AccessTokenProvider`.
3. Adicionar testes de persistência PostgreSQL assim que uma instância local estiver disponível e aplicar a migração `InitialCreate`.
4. Atualizar Issues e Project conforme os resultados; manter a Issue `#7` bloqueada até HTTPS e autenticação estarem implementados e validados.

## Restrições permanentes

- Não publicar a API antes de HTTPS e autenticação estarem implementados e validados.
- Não assumir que DNS ou Cloudflare estão ativos sem verificação.
- Não registrar senhas, tokens, códigos de autenticação ou outros segredos neste arquivo.
- Ao atingir aproximadamente 90% do orçamento disponível da tarefa, atualizar este handoff e encerrar a execução atual de forma segura; a automação recorrente fará a retomada.
