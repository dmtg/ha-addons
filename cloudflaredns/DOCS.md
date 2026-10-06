# Cloudflare DDNS

Crie na Cloudflare um API Token com:

- Zone → DNS → Edit
- Limitado à zona `xxxxxx`

Depois introduza o token na configuração do App.

Os domínios podem ser alterados no campo `ip4_domains`.

O campo `proxied` usa a expressão do projeto Cloudflare DDNS:
`is(xxxxxxx) || is(xxxxxxx)`

