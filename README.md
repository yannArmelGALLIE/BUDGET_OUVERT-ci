# 🌐 BudgetOuvert CI — Documentation API Backend

> API REST de communication entre le frontend et le smart contract BudgetRegistry sur Hardhat Local

---

## Prérequis

Avant d'utiliser l'API, s'assurer que :

```bash
# Terminal 1 — Blockchain locale
npx hardhat node

# Terminal 2 — Déployer le contrat
npx hardhat run scripts/deploy.js --network localhost

# Terminal 3 — Lancer le serveur API
npm run dev   # ou node server.js
```

---

## Base URL

```
http://localhost:3000/api/budget
```

---

## Endpoints

---

### 1. Enregistrer une recette

```
POST http://localhost:3000/api/budget/revenue
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
POST http://localhost:3000/api/budget/expense
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
GET http://localhost:3000/api/budget/transactions/Commune Cocody
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
GET http://localhost:3000/api/budget/balance/Commune Cocody
```

**Réponse (200)**
```json
{
  "commune": "Commune Cocody",
  "balance": 38000000,
  "currency": "FCFA"
}
```

> Solde = Total recettes − Total dépenses
> Un solde négatif indique un déficit

---

### 5. Nombre de transactions

```
GET http://localhost:3000/api/budget/count/Commune Cocody
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
GET http://localhost:3000/api/budget/total
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
GET http://localhost:3000/api/budget/communes
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
| 500  | Erreur serveur / nœud Hardhat non disponible       |

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
  "error":   "Impossible de contacter le nœud Hardhat — vérifiez que npx hardhat node tourne"
}
```

---

## Tester avec Postman

1. Ouvrir Postman
2. Importer les requêtes ci-dessus
3. Sélectionner `Body → raw → JSON`
4. Lancer les requêtes dans l'ordre :
   - D'abord `POST /revenue` pour créer une recette
   - Puis `POST /expense` pour créer une dépense
   - Ensuite `GET /transactions/Commune Cocody` pour vérifier

---

## Variables d'environnement

Créer un fichier `.env` à la racine du serveur :

```env
# Adresse du contrat déployé
CONTRACT_ADDRESS=0x5FbDB2315678afecb367f032d93F642f64180aa3

# RPC du nœud Hardhat local
RPC_URL=http://127.0.0.1:8545

# Chain ID Hardhat
CHAIN_ID=31337

# Clé privée du wallet déployeur (Account #0 Hardhat)
# ⚠️ Ne jamais committer ce fichier
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Port du serveur
PORT=3000
```

---

## Architecture de communication

```
Frontend React (port 5173)
        │
        │ fetch() / axios
        ▼
Serveur Express (port 3000)   ← CE FICHIER DOCUMENTE CETTE COUCHE
        │
        │ ethers.js
        ▼
BudgetRegistry.sol
        │
        │ JSON-RPC
        ▼
Nœud Hardhat (port 8545)
```

---

## Wallet autorisé (COMMUNE_ADMIN)

Le wallet qui peut enregistrer des transactions est le **Account #0 de Hardhat** :

> Ce rôle a été accordé automatiquement lors du déploiement via `scripts/deploy.js`

---

*BudgetOuvert CI — MIABE Hackathon 2026 | CI-01 | feat/smart-contract*