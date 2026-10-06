# Cloudflare DDNS

Crie na Cloudflare um API Token com:

- Zone → DNS → Edit
- Limitado à zona `xavelha.top`

Depois introduza o token na configuração do App.

Os domínios podem ser alterados no campo `ip4_domains`.

O campo `proxied` usa a expressão do projeto Cloudflare DDNS:
`is(micro.xavelha.top) || is(canico.xavelha.top)`

Assim:
- `app.xavelha.top` fica DNS Only
- `micro.xavelha.top` fica Proxied
- `canico.xavelha.top` fica Proxied
