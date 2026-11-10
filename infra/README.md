# Infraestrutura local

## PostgreSQL

1. Copie `.env.example` para `.env`.
2. Troque `POSTGRES_PASSWORD` por uma senha local forte e exclusiva.
3. Inicie apenas o banco:

```powershell
docker compose --env-file infra/.env -f infra/compose.yaml up -d postgres
docker compose --env-file infra/.env -f infra/compose.yaml ps
```

O PostgreSQL é exposto somente em `127.0.0.1`. O volume
`vms_finance_postgres` preserva os dados entre recriações do contêiner.

Para encerrar sem apagar dados:

```powershell
docker compose --env-file infra/.env -f infra/compose.yaml down
```

Não execute `down --volumes` sem um backup verificado.

## Cloudflare Tunnel

`cloudflared.example.yml` é somente um modelo. Não contém credenciais e não
deve ser executado antes que autenticação, autorização por família e HTTPS
público tenham sido validados. O último ingresso sempre responde `404` para
hostnames não declarados.

As credenciais reais do túnel devem permanecer fora do repositório. Antes de
iniciar o serviço, valide a configuração com:

```powershell
cloudflared tunnel --config C:\caminho\seguro\config.yml ingress validate
```
