---
name: test-firecrawl
description: "Teste la connexion avec l'API Firecrawl."
---

# Test de connexion Firecrawl

Cette skill vérifie que ta clé API est bien configurée et que Hermes peut interagir avec Firecrawl.

## Utilisation
Appelle simplement cette skill pour lancer un test de scraping sur `https://example.com`.

```python
import os
import requests
from hermes_tools import terminal

def run_test():
    api_key = os.getenv("FIRECRAWL_API_KEY")
    if not api_key:
        return "Erreur: FIRECRAWL_API_KEY non trouvée dans l'environnement. Ajoute-la dans ~/.hermes/.env"
    
    url = "https://api.firecrawl.dev/v1/scrape"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    data = {"url": "https://example.com"}
    
    # Utilisation de requests au lieu de curl pour un meilleur retour d'erreur
    try:
        response = requests.post(url, headers=headers, json=data)
        if response.status_code == 200:
            return "Succès ! Connexion établie avec Firecrawl."
        else:
            return f"Erreur {response.status_code}: {response.text}"
    except Exception as e:
        return f"Exception: {str(e)}"

print(run_test())
```
