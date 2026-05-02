# 🏛️ BudgetOuvert CI — Documentation API Backend

> API REST de communication entre le frontend et le smart contract BudgetRegistry
> **Déployé sur Railway** — accessible publiquement

---

## 🌍 URL de Production

```
https://budgetouvert-ci-production.up.railway.app
```

---

## Base URL des endpoints

```
https://budgetouvert-ci-production.up.railway.app/api/budget
```

---

## Endpoints

---

### 1. Enregistrer une recette

```
POST https://budgetouvert-ci-production.up.railway.app/api/budget/revenue
```

**Headers**
```
Content-Type: application/json
```

**Body**
```json
{
  "commune":     "Commune Cocody",
  "category":    "Taxe Foncière",
  "amount":      "50000000",
  "description": "Collecte T1 2026",
  "recorder":    "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
}
```

**Réponse succès (200)**
```json
{
  "success": true,
  "hash":    "0xaeba313f99fcbb25a2a95298d77ccaf5c8798da...",
  "message": "Recette enregistrée sur la blockchain"
}
```

---

### 2. Enregistrer une dépense

```
POST https://budgetouvert-ci-production.up.railway.app/api/budget/expense
```

**Headers**
```
Content-Type: application/json
```

**Body**
```json
{
  "commune":     "Commune Cocody",
  "category":    "Voirie & Travaux",
  "amount":      "12000000",
  "description": "Réhabilitation marché central",
  "recorder":    "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
}
```

**Réponse succès (200)**
```json
{
  "success": true,
  "hash":    "0xca3028883da9009ef5095ace5fe54a2e267c00fd...",
  "message": "Dépense enregistrée sur la blockchain"
}
```

---

### 3. Voir les transactions d'une commune

```
GET https://budgetouvert-ci-production.up.railway.app/api/budget/transactions/Commune Cocody
```

**Réponse (200)**
```json
{
  "commune": "Commune Cocody",
  "count": 2,
  "transactions": [
    {
      "id":          1,
      "commune":     "Commune Cocody",
      "type":        "recette",
      "category":    "Taxe Foncière",
      "amount":      50000000,
      "date":        "02/05/2026",
      "timestamp":   1746172800,
      "description": "Collecte T1 2026",
      "recorder":    "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
      "hash":        "0xaeba313f..."
    },
    {
      "id":          2,
      "commune":     "Commune Cocody",
      "type":        "dépense",
      "category":    "Voirie & Travaux",
      "amount":      12000000,
      "date":        "02/05/2026",
      "timestamp":   1746172900,
      "description": "Réhabilitation marché central",
      "recorder":    "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
      "hash":        "0xca3028..."
    }
  ]
}
```

---

### 4. Voir le solde d'une commune

```
GET https://budgetouvert-ci-production.up.railway.app/api/budget/balance/Commune Cocody
```

**Réponse (200)**
```json
{
  "commune":  "Commune Cocody",
  "balance":  38000000,
  "currency": "FCFA"
}
```

> Solde = Total recettes − Total dépenses
> Un solde négatif indique un déficit

---

### 5. Nombre de transactions

```
GET https://budgetouvert-ci-production.up.railway.app/api/budget/count/Commune Cocody
```

**Réponse (200)**
```json
{
  "commune": "Commune Cocody",
  "count":   2
}
```

---

### 6. Total global (toutes communes)

```
GET https://budgetouvert-ci-production.up.railway.app/api/budget/total
```

**Réponse (200)**
```json
{
  "totalTransactions": 42,
  "message": "Total de toutes les transactions enregistrées sur la blockchain"
}
```

---

### 7. Liste de toutes les communes

```
GET https://budgetouvert-ci-production.up.railway.app/api/budget/communes
```

**Réponse (200)**
```json
{
  "communes": [
    "Commune Cocody",
    "Commune Abobo",
    "Commune Yopougon",
    "Commune Adjamé",
    "Commune Marcory"
  ]
}
```

---

## Codes d'erreur

| Code | Signification                                      |
|------|----------------------------------------------------|
| 200  | Succès                                             |
| 400  | Paramètre manquant ou invalide                     |
| 403  | Wallet non autorisé (rôle COMMUNE_ADMIN manquant)  |
| 500  | Erreur serveur / nœud blockchain non disponible    |

**Exemple d'erreur (403)**
```json
{
  "success": false,
  "error":   "Accès refusé : ce wallet n'a pas le rôle COMMUNE_ADMIN"
}
```

**Exemple d'erreur (500)**
```json
{
  "success": false,
  "error":   "Impossible de contacter le nœud blockchain"
}
```

---

## Tester avec Postman

```
1. Ouvrir Postman
2. Créer une nouvelle requête
3. Coller l'URL Railway ci-dessus
4. Pour les POST : Body → raw → JSON
5. Lancer les requêtes dans l'ordre :
   → POST /revenue  (créer une recette)
   → POST /expense  (créer une dépense)
   → GET  /transactions/Commune Cocody  (vérifier)
   → GET  /balance/Commune Cocody       (voir le solde)
```

---

## Architecture de communication

```
Navigateur / App Mobile
        │
        │ HTTPS
        ▼
https://budgetouvert-ci-production.up.railway.app
(Serveur Express — Railway)
        │
        │ ethers.js + JSON-RPC
        ▼
BudgetRegistry.sol
(Smart contract Polygon Amoy)
        │
        │ Réseau Polygon
        ▼
Blockchain publique — données immuables
```

---

## Wallet autorisé (COMMUNE_ADMIN)

Le wallet qui peut enregistrer des transactions doit avoir le rôle `COMMUNE_ADMIN` accordé lors du déploiement :

```
Adresse : 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
```

---

## Liens utiles

| Ressource | Lien |
|---|---|
| 🌍 API Production | https://budgetouvert-ci-production.up.railway.app |
| 📦 Repository GitHub | https://github.com/yannArmelGALLIE/BUDGET_OUVERT-ci |
| 🔍 Polygonscan Amoy | https://amoy.polygonscan.com |
| 🏆 MIABE Hackathon | https://www.miabehackathon.com |

---

*BudgetOuvert CI — MIABE Hackathon 2026 | CI-01 | ODD 11 · ODD 16 · ODD 17*