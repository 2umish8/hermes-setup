# Caddyfile Mowtif — Configuration Complète

Emplacement : `/etc/caddy/Caddyfile`
Serveur : Caddy v2.6.2
SSL : Let's Encrypt automatique

## Structure Générale

```
{
    admin off                                    # ← PAS de reload API, restart nécessaire
}

(mowtif_auth) {
    # Basic Auth via cookie "mowtif_auth"
    # Compte : hermes / bcrypt hash
    # Affiche /login.html personnalisé si 401
}

# --- Portail & Apps ---
dev.mowtif.com, portal.dev.mowtif.com → file_server (static HTML)
marketing.dev.mowtif.com → reverse_proxy localhost:3000
latram.dev.mowtif.com → reverse_proxy localhost:5173
spiritually.dev.mowtif.com → reverse_proxy localhost:5174
weekly.dev.mowtif.com → reverse_proxy localhost:5175
milann.dev.mowtif.com → reverse_proxy localhost:5176
dooeet.dev.mowtif.com → reverse_proxy localhost:5177
mira.dev.mowtif.com → reverse_proxy localhost:5178
writer.dev.mowtif.com → reverse_proxy localhost:5179
boarduo.dev.mowtif.com → reverse_proxy localhost:5180
api.dev.mowtif.com → reverse_proxy https://supabase.co
hermes.dev.mowtif.com → reverse_proxy localhost:3333   # ← ajouté juin 2026
code.dev.mowtif.com → reverse_proxy localhost:8080     # ← ajouté juin 2026
```

## Bloc Auth (snippet importé)

```caddy
(mowtif_auth) {
    route {
        @auth_cookie header_regexp auth_cookie_regex Cookie mowtif_auth=(?P<credentials>[^;]+)
        request_header @auth_cookie Authorization "Basic {re.auth_cookie_regex.credentials}"

        basicauth * {
            hermes $2a$14$UIHD9vFiDyaPo5iQwTWCVOmBJEikHQY24pcGodfSfc3dxeOReWuea
        }
    }

    handle_errors {
        @401 expression {err.status_code} == 401
        handle @401 {
            header -WWW-Authenticate
            root * /home/hermes/projects/Mowtif/apps/portal
            rewrite * /login.html
            file_server
        }
    }
}
```

## Ports / Services Backend

| Port | Service | Statut |
|------|---------|--------|
| 3333 | Hermes Dashboard (FastAPI) | ✅ 200 |
| 8080 | code-server (VS Code Web) | ✅ 302 → /login |
| 3000 | Next.js (Mowtif Marketing) | ⚠️ 500 (env vars Supabase) |
| 5173..5180 | Vite dev servers (apps) | ✅ variés |

## Notes

- Les sous-domaines `.mowtif.local` et `.nip.io` (Tailscale) sont aussi dans le même bloc pour l'accès local.
- Les apps qui importent `mowtif_auth` ont une Basic Auth superposée.
- `hermes.dev.mowtif.com` et `code.dev.mowtif.com` sont **sans auth** pour l'instant.
- Pour ajouter l'auth sur un de ces blocs : ajouter `import mowtif_auth` dans le bloc.
