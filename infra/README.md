# Infraestrutura local

## PostgreSQL

### Windows portátil (ambiente validado)

O ambiente local validado usa os binários oficiais do PostgreSQL 17.11
extraídos em `%LOCALAPPDATA%\VmsFinance\postgresql-17.11-portable`. Ele não
registra serviço, não altera o `PATH` global e escuta somente em
`127.0.0.1:5432`.

Extração única dos binários oficiais, com hash validado pelo `winget`:

```powershell
$download = Join-Path $env:LOCALAPPDATA 'VmsFinance\downloads'
New-Item -ItemType Directory -Force -Path $download | Out-Null
winget download --exact --id PostgreSQL.PostgreSQL.17 --version 17.11-5 `
  --download-directory $download --accept-source-agreements `
  --accept-package-agreements --disable-interactivity
$installer = Get-ChildItem $download -Filter 'PostgreSQL 17*.exe' |
  Select-Object -First 1 -ExpandProperty FullName
$target = Join-Path $env:LOCALAPPDATA 'VmsFinance\postgresql-17.11-portable'
Start-Process $installer -WindowStyle Hidden -Wait -ArgumentList @(
  '--mode', 'unattended', '--unattendedmodeui', 'none',
  '--extract-only', 'yes', '--enable-components', 'server,commandlinetools',
  '--install_runtimes', '0', '--prefix', $target
)
```

A extração pode levar alguns minutos. Confirme que o processo terminou antes
de executar o gerenciador local.

O script abaixo gera uma senha aleatória, guarda-a cifrada com DPAPI no perfil
do usuário (fora do Git), inicializa o cluster com SCRAM e gerencia o processo:

```powershell
.\infra\local-postgres.ps1 -Action Start
.\infra\local-postgres.ps1 -Action Migrate
.\infra\local-postgres.ps1 -Action Status
```

Backup e restauração de desenvolvimento podem ser verificados sem tocar no
banco principal. O teste cria e remove somente `vms_finance_restore_check`:

```powershell
$backup = .\infra\local-postgres.ps1 -Action Backup
.\infra\local-postgres.ps1 -Action VerifyRestore -BackupPath $backup
```

Para encerrar sem apagar dados:

```powershell
.\infra\local-postgres.ps1 -Action Stop
```

### Docker (alternativa)

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
