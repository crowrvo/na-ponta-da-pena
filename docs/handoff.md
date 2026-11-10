# Handoff — VMS Finance

Atualizado em: 2026-11-10 (America/Sao_Paulo)

## Objetivo atual

Organizar as demandas do VMS Finance no GitHub Project e continuar a implementação do repositório `crowrvo/na-ponta-da-pena` com segurança.

## Estado confirmado

- Repositório local: `C:\Projetos\na-ponta-a-pena`.
- GitHub Project: `VMS Finance` (`https://github.com/users/crowrvo/projects/2`).
- Issues `#1` a `#7` foram adicionadas ao Project com status inicial `Todo`.
- A visualização original em tabela permanece como `View 1`.
- Uma segunda visualização foi criada como `View 2`, mas ainda precisa ser convertida para Board e renomeada para `Kanban`.
- GitHub CLI `2.103.3` foi instalado; o usuário informou que concluiu o login.
- Login do GitHub CLI foi validado para a conta `crowrvo`.
- O token atual possui `gist`, `read:org`, `repo` e `workflow`, mas a API de Projects recusou a consulta por ausência de `read:project`/`project`.
- O escopo `project` foi autorizado e a API GraphQL confirmou o Project `PVT_kwHOA1vrVc4Bq7nZ`, com exatamente 7 Issues.
- A API confirmou duas visualizações: `View 1` e `View 2`, ambas em formato de tabela.
- A mutação foi concluída: a visualização 1 agora é `Backlog` (`TABLE_LAYOUT`) e a visualização 2 é `Kanban` (`BOARD_LAYOUT`).
- A API confirmou que o Project já está vinculado ao repositório `crowrvo/na-ponta-da-pena` e contém exatamente as Issues `#1` a `#7`.
- O campo `Sprint` foi criado como seleção única com `Sprint 0`, `Sprint 1` e `Sprint 2`.
- Todas as sete Issues foram classificadas no campo `Sprint` conforme seus títulos.
- Validação final: 7 itens, todos com status `Todo`; Issues `#1`, `#2` e `#6` na Sprint 0; `#3`, `#4` e `#5` na Sprint 1; `#7` na Sprint 2.
- Automação do Codex `continuar-vms-finance-pelo-handoff` está ativa a cada 5 horas.

## Próxima ação

1. Continuar a implementação técnica pelo backlog, iniciando pelas demandas da Sprint 0.
2. Antes de cada nova etapa relevante, atualizar este handoff com a demanda escolhida e o estado do repositório.
3. Manter a Issue `#7` bloqueada até HTTPS e autenticação estarem implementados e validados.

## Restrições permanentes

- Não publicar a API antes de HTTPS e autenticação estarem implementados e validados.
- Não assumir que DNS ou Cloudflare estão ativos sem verificação.
- Não registrar senhas, tokens, códigos de autenticação ou outros segredos neste arquivo.
- Ao atingir aproximadamente 90% do orçamento disponível da tarefa, atualizar este handoff e encerrar a execução atual de forma segura; a automação recorrente fará a retomada.
