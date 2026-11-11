# ADR 0001 — Auth0 como provedor de identidade

- Status: aceito para implementação
- Data: 2026-11-10

## Contexto

O VMS Finance precisa autenticar um aplicativo Flutter em Android, iOS e desktop contra uma Minimal API .NET, usando Authorization Code com PKCE. A autorização financeira por família não deve depender de claims administradas no provedor: ela continua sendo validada no PostgreSQL a cada operação.

Foram comparados Auth0, ZITADEL Cloud e Microsoft Entra External ID usando documentação oficial. Auth0 apresenta o caminho mais direto para Flutter e `JwtBearer` no ASP.NET Core. O plano gratuito e seus limites devem ser revistos antes da criação do tenant, pois preços podem mudar.

## Decisão

- Usar Auth0 como provedor OIDC.
- Registrar o app como Native Application e a API com audience estável `https://api.crowrvo.com.br`.
- Usar Authorization Code + PKCE e scopes `openid profile email offline_access`.
- Usar o claim `sub` como identificador externo imutável do usuário.
- Consultar membership/role no banco para toda operação por `householdId`; não colocar `household_id` no token.
- Guardar tokens somente no armazenamento seguro do sistema. No Windows, manter nossa abstração baseada em `flutter_secure_storage`.
- Não configurar `auth.crowrvo.com.br`, DNS ou credenciais até o tenant existir e os registros exatos serem fornecidos pelo Auth0.
- Não publicar a API antes de validar autenticação, autorização e HTTPS.

## Plataformas

O SDK Flutter do Auth0 cobre Android, iOS, macOS, Windows e web. Linux desktop foi
formalmente adiado porque o SDK atual não oferece essa plataforma. Antes de uma
distribuição Linux, será avaliado um cliente OIDC genérico com navegador do sistema
e redirect loopback. Essa lacuna não altera os gates de segurança nem autoriza uma
implementação própria de login por senha.

## Configuração esperada

A API recebe somente configuração externa, sem segredos versionados:

```text
Authentication__Authority=https://TENANT_REGION.auth0.com/
Authentication__Audience=https://api.crowrvo.com.br
```

As fórmulas de callback, configuração externa e ação mínima do tenant estão em
`docs/auth0-setup.md`. Os valores reais só serão preenchidos quando o tenant e a
Native Application existirem.

## Referências verificadas em 2026-11-10

- [Auth0 — preços](https://auth0.com/pricing)
- [Auth0 Flutter SDK](https://github.com/auth0/auth0-flutter)
- [Auth0 — ASP.NET Core Web API](https://developer.auth0.com/resources/get-started/api/aspnet-core)
- [ZITADEL — Flutter com PKCE](https://zitadel.com/docs/examples/login/flutter)
- [Microsoft Entra External ID](https://learn.microsoft.com/entra/external-id/customers/overview-solutions-customers)

## Consequências

A implementação pode avançar com interfaces e validação JWT sem criar tenant ou expor serviço. A ativação real dependerá de uma conta Auth0 e dos identificadores públicos do tenant/app; esses valores serão solicitados somente quando o fluxo local estiver pronto para validação.
