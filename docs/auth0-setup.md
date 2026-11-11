# Ativação do Auth0

A integração está pronta para receber identificadores públicos, mas nenhum tenant,
client ID, domínio ou token real é versionado. A API não deve ser publicada para
realizar esta validação.

## Ação mínima no Auth0

1. Criar ou selecionar um tenant Auth0.
2. Criar uma API e guardar o **Identifier** escolhido como audience. Manter RS256.
3. Criar uma **Native Application**, manter OIDC Conformant habilitado e permitir
   Authorization Code com PKCE e refresh token. Não criar client secret para o app
   nativo.
4. Habilitar rotação de refresh tokens e o uso de `offline_access` para a API.
5. Copiar somente estes valores públicos para um arquivo `auth0.local.ps1`, que é
   ignorado pelo Git:

```powershell
$env:VMS_AUTH0_DOMAIN='<dominio-exato-do-tenant-sem-https>'
$env:VMS_AUTH0_CLIENT_ID='<client-id-da-native-application>'
$env:VMS_AUTH0_AUDIENCE='<identifier-exato-da-api>'
$env:VMS_AUTH0_SCHEME='<scheme-android-escolhido>'
$env:VMS_AUTH0_WINDOWS_CALLBACK_URL='<scheme-windows>://callback'

$env:Authentication__Authority="https://$($env:VMS_AUTH0_DOMAIN)/"
$env:Authentication__Audience=$env:VMS_AUTH0_AUDIENCE
```

O domínio deve ser um hostname, a authority deve terminar em `/` e a audience deve
ser uma URI HTTPS. Os validadores do app e da API recusam valores ambíguos ou
inseguros.

## URLs permitidas

Substitua as partes entre `<...>` pelos valores públicos acima e cadastre as URLs
exatas tanto em **Allowed Callback URLs** quanto em **Allowed Logout URLs**:

- Android:
  `<scheme-android>://<dominio-do-tenant>/android/br.com.crowrvo.vms_finance_app/callback`
- iOS:
  `br.com.crowrvo.vmsFinanceApp://<dominio-do-tenant>/ios/br.com.crowrvo.vmsFinanceApp/callback`
- Windows: o valor exato de `VMS_AUTH0_WINDOWS_CALLBACK_URL`.

Android usa o scheme fornecido também em `VMS_AUTH0_SCHEME` no ambiente do Gradle.
O iOS usa o bundle identifier registrado no `Info.plist`. Universal Links ficam
adiados até existir Apple Team e domínio associado; o custom scheme continua
protegido por PKCE. O Windows usa callback direto e não depende de servidor ou
túnel.

## Executar localmente

Carregue o arquivo local e inicie a API somente em loopback:

```powershell
. .\auth0.local.ps1
dotnet run --project src/backend/VmsFinance.Api --urls https://127.0.0.1:7080
```

Em outra sessão, carregue o mesmo arquivo e passe os valores públicos ao Flutter:

```powershell
. .\auth0.local.ps1
cd apps\vms_finance_app
flutter run -d windows `
  --dart-define=VMS_API_BASE_URL=https://127.0.0.1:7080 `
  --dart-define=VMS_AUTH0_DOMAIN=$env:VMS_AUTH0_DOMAIN `
  --dart-define=VMS_AUTH0_CLIENT_ID=$env:VMS_AUTH0_CLIENT_ID `
  --dart-define=VMS_AUTH0_AUDIENCE=$env:VMS_AUTH0_AUDIENCE `
  --dart-define=VMS_AUTH0_WINDOWS_CALLBACK_URL=$env:VMS_AUTH0_WINDOWS_CALLBACK_URL
```

Para Android, troque o device e inclua
`--dart-define=VMS_AUTH0_SCHEME=$env:VMS_AUTH0_SCHEME`. Para iOS, os três valores
domain/client ID/audience bastam com o callback de bundle identifier já configurado.

O certificado HTTPS local precisa ser confiável no dispositivo. Não reduza a
validação TLS para contornar certificados.

## Windows

O SDK oficial requer Visual Studio 2022+, C++17 e `vcpkg`. A instalação local já
validada fica em `%LOCALAPPDATA%\VmsFinance\vcpkg`; antes de compilar:

```powershell
$env:VCPKG_ROOT="$env:LOCALAPPDATA\VmsFinance\vcpkg"
$env:CMAKE_TOOLCHAIN_FILE="$env:VCPKG_ROOT\scripts\buildsystems\vcpkg.cmake"
```

O callback é incorporado ao runner a partir da variável de ambiente durante o
build; use o mesmo valor no `--dart-define`. O scheme deve ser registrado por usuário para apontar ao executável
instalado. Faça isso somente depois de definir o callback real e o caminho final do
executável; não registre o artefato temporário de `build\`. O runner aceita apenas o
prefixo compilado a partir de `VMS_AUTH0_WINDOWS_CALLBACK_URL`, usa uma instância única e um
named pipe restrito ao usuário atual.

## Armazenamento e renovação

- Android/iOS usam o Credentials Manager do SDK Auth0, com Keystore/Keychain e
  renovação automática antes do vencimento.
- Windows guarda access/refresh token e expiração somente via
  `flutter_secure_storage` e troca o refresh token diretamente no endpoint HTTPS do
  tenant. Refresh token rotacionado substitui o anterior.
- Logout encerra a sessão Universal Login e limpa o armazenamento local.
- O backend valida assinatura, issuer, audience, expiração e claim `sub`, com clock
  skew de um minuto.

## Plataformas pendentes

Linux desktop está formalmente adiado: o SDK Auth0 Flutter atual não oferece essa
plataforma. Não será criado fluxo próprio de senha. Android precisa de um Android SDK
para a compilação final, e iOS precisa de Xcode/macOS para build e validação no
simulador/dispositivo.
