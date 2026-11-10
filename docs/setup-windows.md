# Preparação no Windows

## Detectado em 9 de novembro de 2026

- .NET SDK 10.0.403 instalado durante o bootstrap.
- Flutter 3.41.4 / Dart 3.11.1 disponíveis.
- Git 2.56 disponível.
- PostgreSQL, Docker e `cloudflared` ainda não estavam disponíveis no PATH.
- `api.crowrvo.com.br` não resolvia no DNS público; nenhuma publicação foi feita.

## Backend

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

## App

```powershell
cd apps/vms_finance_app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter run -d windows
```

## Cloudflare

O arquivo `infra/cloudflared.example.yml` é apenas referência. Não execute o túnel antes de:

1. confirmar o DNS de `api.crowrvo.com.br`;
2. concluir autenticação e autorização;
3. validar HTTPS externamente;
4. configurar credenciais fora do repositório.

