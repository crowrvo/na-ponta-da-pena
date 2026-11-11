# Preparação no Windows

## Detectado em 9 de novembro de 2026

- .NET SDK 10.0.403 instalado durante o bootstrap.
- Flutter 3.41.4 / Dart 3.11.1 disponíveis.
- Git 2.56 disponível.
- PostgreSQL, Docker e `cloudflared` ainda não estavam disponíveis no PATH.
- `api.crowrvo.com.br` não resolvia no DNS público; nenhuma publicação foi feita.

## Backend

O PostgreSQL portátil validado fica fora do repositório e não registra serviço.
Consulte `infra/README.md` para extrair os binários oficiais uma vez. Depois:

```powershell
.\infra\local-postgres.ps1 -Action Start
.\infra\local-postgres.ps1 -Action Migrate
```

```powershell
dotnet restore VmsFinance.slnx
dotnet tool restore
dotnet test VmsFinance.slnx
dotnet run --project src/backend/VmsFinance.Api --urls http://127.0.0.1:5080
```

Em desenvolvimento, defina a conexão sem gravar senha no Git:

```powershell
$env:ConnectionStrings__VmsFinance='Host=127.0.0.1;Port=5432;Database=vms_finance;Username=vms_finance;Password=...'
dotnet tool run dotnet-ef database update --project src/backend/VmsFinance.Infrastructure --startup-project src/backend/VmsFinance.Api
```

A migração inicial está versionada. O comando de atualização deve ser executado somente depois que o PostgreSQL local estiver disponível e a variável de conexão acima estiver definida.

Para validar JWT localmente, use os identificadores públicos do tenant quando ele existir. Não versione esses valores:

```powershell
$env:Authentication__Authority='https://TENANT_REGION.auth0.com/'
$env:Authentication__Audience='https://api.crowrvo.com.br'
```

O procedimento completo para Native Application, callbacks, Flutter e renovação
está em [auth0-setup.md](auth0-setup.md). Os valores reais devem ficar em
`auth0.local.ps1`, ignorado pelo Git.

Enquanto o tenant não existir, o harness local exige ambiente `Development`,
flag explícita, token fornecido fora do Git e identificador de usuário local:

```powershell
$env:DevelopmentAuthentication__Enabled='true'
$env:DevelopmentAuthentication__Token='<token-aleatorio-da-sessao>'
$env:DevelopmentAuthentication__UserId='local-developer'
dotnet run --project src/backend/VmsFinance.Api --urls http://127.0.0.1:5080
```

A API recusa essa flag fora de `Development`. O token local nunca substitui o
fluxo Auth0 em release ou em origens remotas.

## App

```powershell
cd apps/vms_finance_app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter run -d windows `
  --dart-define=VMS_API_BASE_URL=http://127.0.0.1:5080 `
  --dart-define=VMS_DEVELOPMENT_ACCESS_TOKEN=<mesmo-token-da-sessao>
```

Sem os identificadores Auth0, o fluxo local acima continua usando exclusivamente o
harness de desenvolvimento. Com Auth0 configurado, use os `--dart-define` descritos
em `auth0-setup.md`; o login passa a usar Authorization Code + PKCE.

O app aceita HTTP somente para `localhost`/`127.0.0.1` em builds de desenvolvimento. Qualquer API remota exige uma origem HTTPS sem path, query, fragmento ou credenciais. Sem `VMS_API_BASE_URL`, a sincronização permanece explicitamente desativada.

## Cloudflare

O arquivo `infra/cloudflared.example.yml` é apenas referência. Não execute o túnel antes de:

1. confirmar o DNS de `api.crowrvo.com.br`;
2. concluir autenticação e autorização;
3. validar HTTPS externamente;
4. configurar credenciais fora do repositório.

