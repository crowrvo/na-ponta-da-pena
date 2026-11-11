# Handoff — VMS Finance

Atualizado em: 2026-11-11 (America/Sao_Paulo)

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
- Retomada manual de 2026-11-10: repositório limpo no commit `45fc5eb`. Em andamento, em frentes separadas: integração do `FinanceSyncService` com Cubit/conectividade/UI; convites, entrada e revogação de membros no backend; pesquisa oficial para decisão do provedor OIDC. Nenhuma publicação foi autorizada ou iniciada.
- Decisão OIDC registrada em `docs/decisions/0001-authentication-provider.md`: Auth0, Authorization Code + PKCE, audience `https://api.crowrvo.com.br`, membership consultado no PostgreSQL e tokens no armazenamento seguro. Linux desktop ficou como validação pendente; nenhum tenant, DNS ou segredo foi configurado.
- Integração Flutter concluída no worktree: `FinanceSyncCubit`, disparo por conectividade/ação manual, estados na dashboard e configuração exclusiva por `VMS_API_BASE_URL`. Origem remota exige HTTPS; HTTP só é aceito para loopback em desenvolvimento. Operações sem UUID de família ficam `local-only` e nunca chegam à API.
- Gestão de famílias concluída no backend: convite opaco de 256 bits com somente hash persistido, validade/uso único/revogação, listagem de metadados sem segredos, aceite, remoção e saída de members. A migração `AddHouseholdInvitations` foi gerada, mas não aplicada sem PostgreSQL local.
- Validação atual: `dotnet test` com 18 testes e `flutter analyze`/`flutter test` com 18 testes aprovados. Nenhum DNS, tenant, túnel ou serviço externo foi alterado.
- GitHub atualizado após `efe4fb4`: Issues `#1` e `#2` concluídas; Issue `#8` criada para a integração real Auth0/PKCE e mantida em `Todo`; Issue `#9` criada para o fluxo Flutter de famílias e movida para `In Progress`. A publicação continua bloqueada.
- Em andamento: feature Flutter de famílias/seleção ativa e, em paralelo sem sobreposição de arquivos, formulário/lista mensal com `FinanceOverviewCubit`.
- Fluxo Flutter integrado: cache Drift v3 e seleção ativa de famílias, cliente autenticado, fallback offline, `HouseholdCubit` e UI para listar/criar/aceitar convite/abrir família. A dashboard abre a visão financeira somente com UUID ativo válido.
- Visão financeira concluída: isolamento SQLite por família, resumo mensal, navegação entre meses, lista com status de sync, formulário validado de receita/despesa e persistência offline. Teste com banco em arquivo confirma lançamento e outbox após fechar e reabrir.
- Validação integrada: geração Drift reproduzível, `flutter analyze` limpo, 41 testes Flutter e 18 testes .NET aprovados. O CI do commit anterior `efe4fb4` também concluiu com sucesso.
- Entrega publicada no commit `cd87b18`. Issues `#3`, `#4`, `#5` e `#9` foram concluídas e movidas para `Done`. O Project agora tem 9 itens: 7 concluídos, `#6` em andamento e `#7`/`#8` em `Todo`; `#8` e `#7` preservam os bloqueios de autenticação e publicação.
- Branch `main` protegida contra force-push e exclusão, com histórico linear obrigatório. Push direto regular continua permitido para não interromper a automação atual; checks obrigatórios serão ativados quando o fluxo migrar para pull requests.
- CI do commit `eb0522b` aprovado integralmente: backend e app concluíram restore, geração, formatação, build, análise e testes no GitHub Actions.
- Regra operacional solicitada pelo usuário: ao concluir uma tarefa, atualizar este handoff e iniciar a próxima em um novo chat; em retomadas agendadas, também abrir um novo chat. O foco imediato passou a ser um MVP local executável de ponta a ponta. A automação de 5 horas permanece como recuperação quando a execução parar por limite de tokens.
- Retomada de 2026-11-10 para o MVP local: repositório confirmado limpo e alinhado com `origin/main` no commit `6bb73b3`; GitHub CLI autenticado; Project confirmado com 9 itens, sendo 7 em `Done`, Issue `#6` em `In Progress` e Issues `#7`/`#8` em `Todo`. Iniciada a auditoria de uma opção PostgreSQL local pouco intrusiva e do harness de autenticação exclusivo de `Development`; nenhuma instalação, publicação, alteração de DNS ou túnel foi iniciada até este ponto.
- Escolha para o banco local: PostgreSQL 17 oficial em modo `extract-only` sob `%LOCALAPPDATA%\VmsFinance`, sem serviço do Windows, atalhos, alteração global de `PATH` ou bind externo. O cluster usará apenas loopback, SCRAM e credencial local fora do Git. O harness de autenticação foi implementado com ativação explícita apenas em `Development`; o Flutter só considera o token local em build não-release contra loopback. Os 44 testes Flutter passaram; validação .NET segue em andamento.
- PostgreSQL portátil 17.11 operacional em `127.0.0.1:5432`, com cluster e senha cifrada por DPAPI sob `%LOCALAPPDATA%\VmsFinance`. As migrações `InitialCreate` e `AddHouseholdInvitations` foram aplicadas ao banco `vms_finance`; as cinco tabelas esperadas foram confirmadas. Backup em formato custom foi criado e restaurado com sucesso no banco temporário `vms_finance_restore_check`, removido ao final. Nenhuma porta externa, serviço do Windows ou segredo versionado foi criado.
- MVP local validado de ponta a ponta pelo Flutter contra API e PostgreSQL reais: família criada, receita de `750000` centavos e despesa de `12550` centavos sincronizadas, SQLite fechado/reaberto com outbox vazia e itens `synced`, e PostgreSQL confirmado com 2 linhas e saldo `737450`. Validação final: 20 testes .NET; `flutter analyze` limpo; 44 testes Flutter mais 1 E2E local aprovados; backup/restauração repetidos com sucesso. API e PostgreSQL foram encerrados de forma limpa, preservando dados e backups locais.
- Entrega publicada no commit `92ee036`. A Issue `#6` foi fechada e movida para `Done`. A Issue `#10` foi criada para automatizar o E2E no CI e classificada como `Todo`, Sprint 1, P1 e Full-stack. O Project agora tem 10 itens: 7 em `Done`; `#7`, `#8` e `#10` preservados em `Todo`, sem iniciar publicação ou Auth0.
- Retomada de 2026-11-11 para a Issue `#10`: worktree limpo e `main` alinhada com `origin/main` no commit `0118e97`; o CI desse commit foi confirmado como aprovado. A Issue `#10` foi movida para `In Progress`; `#7` e `#8` permanecem em `Todo`. Iniciada exclusivamente a automação do E2E Flutter → Minimal API → PostgreSQL em GitHub Actions, sem tenant Auth0, publicação, túnel ou alteração de DNS.
- Marco da Issue `#10`: o workflow `CI` ganhou o job `local-mvp-e2e`, com PostgreSQL 17 efêmero limitado ao runner/loopback, banco/usuário/senha/token aleatórios por job e mascarados, migrações EF Core, API em `Development` vinculada a `127.0.0.1:5080`, execução de `test/local_mvp_integration_test.dart` e teardown defensivo da API, log temporário e container. Validações locais aprovadas: YAML lint, `git diff --check`, formatação e 20 testes .NET, geração Drift reproduzível, formatação/análise Flutter e 44 testes (com o E2E corretamente ignorado sem habilitação explícita). A execução real do novo job no GitHub Actions ainda será confirmada após o push.
- Primeira execução do novo job no GitHub Actions (`8438612`): PostgreSQL, credenciais, migrações e teardown passaram; o E2E detectou que `launchSettings.json` sobrepunha `ASPNETCORE_URLS` e iniciava a API em `localhost:5072`. O workflow foi corrigido para ignorar o launch profile e passar explicitamente `--urls http://127.0.0.1:5080`; backend e app permaneceram aprovados e nenhum recurso externo foi criado.

## Próxima ação

1. Concluir a Issue `#10`: automatizar o E2E Flutter → API → PostgreSQL em CI com banco efêmero e credenciais exclusivas do job, sem publicar serviços.
2. Depois, conectar Auth0 real ao `AccessTokenProvider` quando os identificadores públicos estiverem disponíveis e validar PKCE em Android, iOS e Windows.
3. Manter a Issue `#7` bloqueada até autenticação real e HTTPS estarem implementados e validados; não iniciar o túnel antes disso.

## Restrições permanentes

- Não publicar a API antes de HTTPS e autenticação estarem implementados e validados.
- Não assumir que DNS ou Cloudflare estão ativos sem verificação.
- Não registrar senhas, tokens, códigos de autenticação ou outros segredos neste arquivo.
- Ao atingir aproximadamente 90% do orçamento disponível da tarefa, atualizar este handoff e encerrar a execução atual de forma segura; a automação recorrente fará a retomada.
