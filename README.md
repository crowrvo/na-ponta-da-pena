# VMS Finance

Aplicativo financeiro familiar, multiplataforma e offline-first.

## Estado atual

- API em .NET 10 com arquitetura em camadas.
- Persistência preparada para PostgreSQL via Entity Framework Core/Npgsql.
- App Flutter para Android, iOS, Windows, macOS e Linux.
- SQLite local com fila de sincronização (outbox).
- Inicialização de produção bloqueada sem banco e configuração de autenticação.
- CI para compilar e testar backend e app.
- Nenhuma API publicada e nenhum túnel configurado automaticamente.

## Estrutura

```text
apps/vms_finance_app/       aplicativo Flutter
src/backend/                API, aplicação, domínio e infraestrutura
tests/backend/              testes do backend
infra/                      PostgreSQL e exemplo de Cloudflare Tunnel
docs/                       arquitetura, backlog e operação
```

## Primeiros passos

Consulte [docs/setup-windows.md](docs/setup-windows.md). Para decisões arquiteturais e próximos incrementos, veja [docs/architecture.md](docs/architecture.md) e [docs/backlog.md](docs/backlog.md).

> Segurança: não publique a API até autenticação, HTTPS e regras do Cloudflare estarem validadas. `api.crowrvo.com.br` não é considerado ativo por este projeto.

