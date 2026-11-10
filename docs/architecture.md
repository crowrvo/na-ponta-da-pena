# Arquitetura inicial

## Princípios

1. O app grava primeiro no SQLite local.
2. Cada alteração local cria um item na outbox com identificador idempotente.
3. A sincronização envia lotes autenticados quando houver conectividade.
4. O PostgreSQL é a fonte compartilhada entre membros da família.
5. Conflitos usam versão do registro e `updated_at`; regras financeiras nunca dependem apenas do relógio do dispositivo.

## Limites

- **Domain**: entidades e invariantes financeiras sem dependência de infraestrutura.
- **Application**: casos de uso, contratos e autorização por família.
- **Infrastructure**: EF Core, PostgreSQL, autenticação externa e sincronização.
- **API**: composição HTTP; endpoints financeiros ficam desabilitados até a autenticação estar pronta.
- **Flutter**: UI, SQLite, outbox e cliente de sincronização.

## Segurança antes da publicação

- provedor OIDC/OAuth 2.1 definido;
- tokens guardados em armazenamento seguro do sistema;
- autorização por `household_id` testada em todos os casos de uso;
- Cloudflare Tunnel com HTTPS público e regra 404 padrão;
- segredos somente em variáveis/secret stores;
- backup e restauração do PostgreSQL testados;
- logs sem valores, descrições ou tokens financeiros.

