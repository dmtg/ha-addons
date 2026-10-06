# Documentação

Crie na Cloudflare um API Token com:
- Zone > DNS > Edit
- Limitado à zona xavelha.top

Depois introduza o token na configuração do App.

Os três domínios podem ser alterados no campo `ip4_domains`.
A expressão `proxied` permite definir quais os domínios que usam o proxy Cloudflare.
