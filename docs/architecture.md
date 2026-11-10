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

## Contrato de sincronização de lançamentos

O app envia lotes autenticados de 1 a 100 operações para
`POST /api/households/{householdId}/sync/entries`:

```json
{
  "operations": [
    {
      "id": "00000000-0000-0000-0000-000000000001",
      "direction": "expense",
      "amountInCents": 2599,
      "description": "Internet",
      "occurredOn": "2026-11-10",
      "idempotencyKey": "outbox-operation-id"
    }
  ]
}
```

A resposta contém `results` com `id`, `idempotencyKey`, `created` e `version` para cada operação. O mesmo lote pode ser reenviado: operações idênticas retornam `created: false`. Uma chave reutilizada com dados diferentes retorna HTTP 409 e nenhuma nova operação do lote é persistida.

O app dispara a sincronização por Cubit ao recuperar conectividade ou por ação manual. A origem da API vem exclusivamente de `VMS_API_BASE_URL`; origens remotas precisam usar HTTPS. Lançamentos ainda sem uma família remota válida permanecem locais e não são enviados.

## Convites e membership

Somente owners criam, listam ou revogam convites. O token de convite possui 256 bits de entropia, é devolvido uma única vez e somente seu hash SHA-256 é persistido. Convites expiram, são de uso único e usam controle otimista de concorrência. A listagem administrativa contém apenas metadados e status, nunca token, hash ou identificadores dos usuários.

Um member pode sair da família; um owner precisa transferir a responsabilidade ou excluir a família antes de sair. Owners podem remover members, mas não outros owners.

## Segurança antes da publicação

- provedor OIDC/OAuth 2.1 definido;
- tokens guardados em armazenamento seguro do sistema;
- autorização por `household_id` testada em todos os casos de uso;
- Cloudflare Tunnel com HTTPS público e regra 404 padrão;
- segredos somente em variáveis/secret stores;
- backup e restauração do PostgreSQL testados;
- logs sem valores, descrições ou tokens financeiros.

