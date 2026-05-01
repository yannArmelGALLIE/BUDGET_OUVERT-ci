# BudgetOuvert — Smart Contract

> Projet CI-01 | MIABE Hackathon 2026  
> Gouvernance locale & Transparence budgétaire sur Polygon

---

## Présentation

BudgetOuvert est un registre budgétaire communal infalsifiable basé sur la blockchain Polygon. Chaque dépense enregistrée par un agent communal est permanente, publique et vérifiable par n'importe quel citoyen en temps réel.

Ce dépôt contient uniquement la couche smart contract du projet.

---

## Architecture du projet

```
BudgetOuvert/
├── smart-contract/         ← ce dépôt
│   ├── BudgetOuvert.sol    ← le contrat principal
│   ├── README.md           ← ce fichier
│   └── ABI/
│       └── BudgetOuvert.json  ← généré après déploiement
│
└── app/                    ← dépôt frontend (coéquipiers)
```

---

## Stack technique

| Composant | Outil |
|---|---|
| Langage smart contract | Solidity ^0.8.0 |
| Éditeur & déploiement | Remix IDE |
| Réseau blockchain | Polygon Mumbai (testnet) |
| Wallet | MetaMask |
| Contrôle des accès | OpenZeppelin AccessControl |

---

## Ce que fait le smart contract

- Permettre à un agent communal autorisé d'enregistrer une dépense
- Rendre toutes les dépenses lisibles publiquement
- Émettre un événement à chaque nouvelle dépense (pour la mise à jour temps réel du frontend)
- Empêcher toute modification ou suppression d'un enregistrement existant

---

## Déploiement — étape par étape

### 1. Configurer MetaMask sur Polygon Mumbai

Ajouter le réseau manuellement dans MetaMask :

| Paramètre | Valeur |
|---|---|
| Nom du réseau | Polygon Mumbai |
| URL RPC | https://rpc-mumbai.maticvigil.com |
| Chain ID | 80001 |
| Symbole | MATIC |
| Explorateur | https://mumbai.polygonscan.com |

### 2. Obtenir des MATIC de test (gratuit)

Aller sur le faucet officiel et coller ton adresse MetaMask :

```
https://faucet.polygon.technology
```

Tu reçois des MATIC fictifs pour payer les gas fees des transactions de test.

### 3. Ouvrir Remix IDE

```
https://remix.ethereum.org
```

Créer un nouveau fichier : `BudgetOuvert.sol`  
Coller le code du smart contract.

### 4. Compiler le contrat

Dans Remix → onglet **Solidity Compiler**  
- Version : `0.8.20`  
- Cliquer **Compile BudgetOuvert.sol**

### 5. Déployer le contrat

Dans Remix → onglet **Deploy & Run Transactions**  
- Environment : **Injected Provider - MetaMask**  
- MetaMask s'ouvre automatiquement sur Polygon Mumbai  
- Cliquer **Deploy**  
- Confirmer la transaction dans MetaMask

### 6. Récupérer l'adresse et l'ABI

Après déploiement, Remix affiche :
- **L'adresse du contrat** → à donner au coéquipier frontend
- **L'ABI** → onglet Compiler → bouton ABI → copier → sauvegarder dans `ABI/BudgetOuvert.json`

---

## Ce que le frontend reçoit

Le coéquipier frontend a besoin de deux éléments pour connecter l'app au contrat :

```
1. Adresse du contrat déployé
   Exemple : 0x742d35Cc6634C0532925a3b8D4C9...

2. ABI du contrat (fichier ABI/BudgetOuvert.json)
   C'est le mode d'emploi du contrat pour ethers.js
```

---

## Événement émis à chaque dépense

Quand un agent enregistre une dépense, le contrat émet :

```solidity
event DepenseEnregistree(
    string categorie,
    uint256 montant,
    string description,
    uint256 timestamp
);
```

Le frontend écoute cet événement pour mettre à jour le dashboard citoyen en temps réel — c'est la base de la démo live Phase 2.

---

## Vérifier le contrat en ligne

Une fois déployé, n'importe qui peut consulter toutes les transactions sur :

```
https://mumbai.polygonscan.com/address/[ADRESSE_DU_CONTRAT]
```

---

## Branches

| Branche | Rôle |
|---|---|
| `main` | version stable déployée |
| `smart-contract` | développement du contrat |

---

## Liens utiles

- [Remix IDE](https://remix.ethereum.org)
- [Polygon Faucet](https://faucet.polygon.technology)
- [Mumbai Polygonscan](https://mumbai.polygonscan.com)
- [OpenZeppelin AccessControl](https://docs.openzeppelin.com/contracts/4.x/access-control)
- [Documentation Solidity](https://docs.soliditylang.org)
- [MIABE Hackathon 2026](https://www.miabehackathon.com)

---

*MIABE Hackathon 2026 — Projet CI-01 BudgetOuvert — ODD 11 · ODD 16 · ODD 17*