// src/abi/BudgetRegistry.abi.ts
// ABI du smart contract BudgetRegistry déployé sur Polygon Amoy
// Copie exacte des fonctions et events du contrat Solidity

export const BUDGET_REGISTRY_ABI = [
  // ── Fonctions d'écriture (nécessitent MetaMask + rôle COMMUNE_ADMIN) ──────
  {
    inputs: [
      { name: "commune",     type: "string"  },
      { name: "category",    type: "string"  },
      { name: "amount",      type: "uint256" },
      { name: "description", type: "string"  },
    ],
    name: "recordRevenue",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      { name: "commune",     type: "string"  },
      { name: "category",    type: "string"  },
      { name: "amount",      type: "uint256" },
      { name: "description", type: "string"  },
    ],
    name: "recordExpense",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },

  // ── Fonctions de lecture (gratuites, sans MetaMask) ───────────────────────
  {
    inputs: [{ name: "commune", type: "string" }],
    name: "getTransactions",
    outputs: [
      {
        components: [
          { name: "id",          type: "uint256" },
          { name: "commune",     type: "string"  },
          { name: "txType",      type: "uint8"   },
          { name: "category",    type: "string"  },
          { name: "amount",      type: "uint256" },
          { name: "timestamp",   type: "uint256" },
          { name: "description", type: "string"  },
          { name: "recorder",    type: "address" },
        ],
        type: "tuple[]",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ name: "commune", type: "string" }],
    name: "getBalance",
    outputs: [{ name: "", type: "int256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ name: "commune", type: "string" }],
    name: "getTransactionCount",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "getTotalTransactions",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },

  // ── Event écouté en temps réel ────────────────────────────────────────────
  {
    anonymous: false,
    inputs: [
      { indexed: true,  name: "id",          type: "uint256" },
      { indexed: true,  name: "commune",     type: "string"  },
      { indexed: false, name: "txType",      type: "uint8"   },
      { indexed: false, name: "category",    type: "string"  },
      { indexed: false, name: "amount",      type: "uint256" },
      { indexed: false, name: "timestamp",   type: "uint256" },
      { indexed: false, name: "description", type: "string"  },
      { indexed: false, name: "recorder",    type: "address" },
    ],
    name: "TransactionRecorded",
    type: "event",
  },
] as const;

// Adresse du contrat déployé sur Polygon Amoy
// ⚠️ Remplace par l'adresse copiée depuis Remix
export const CONTRACT_ADDRESS = import.meta.env.VITE_CONTRACT_ADDRESS as string;

// RPC public Polygon Amoy (lecture seule, sans MetaMask)
export const AMOY_RPC = "https://rpc-amoy.polygon.technology";