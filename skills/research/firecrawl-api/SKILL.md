---
name: firecrawl-api
description: "Utilise l'API Firecrawl pour scraper des pages web."
---

# Firecrawl API Client

Cette skill permet d'utiliser l'API Firecrawl pour extraire du contenu web proprement.

## Prérequis
1. Obtenir une clé API sur https://firecrawl.dev/
2. Ajouter `FIRECRAWL_API_KEY` dans `~/.hermes/.env`

## Utilisation
Utilise la fonction `scrape_url(url)` ci-dessous pour extraire le contenu.

```python
import os
import requests
import json
from hermes_tools import terminal

def scrape_url(url: str):
    api_key = os.getenv("FIRECRAWL_API_KEY")
    if not api_key:
        return "Erreur: FIRECRAWL_API_KEY manquante."
    
    # Appel via curl pour rester simple et sans dépendance python supplémentaire
    cmd = f"curl -s https://api.firecrawl.dev/v1/scrape -H 'Authorization: Bearer {api_key}' -H 'Content-Type: application/json' -d '{{\"url\": \"{url}\"}}'"
    result = terminal(cmd)
    return result['output']
```
