// src/contexts/BlockchainContext.tsx
import { createContext, useState, useEffect, useCallback, useRef, ReactNode } from "react";

// ── Types ─────────────────────────────────────────────────────────────────────

export interface Transaction {
  id:          number;
  commune:     string;
  type:        "recette" | "dépense";
  category:    string;
  amount:      number;
  date:        string;
  timestamp:   number;
  description: string;
  recorder:    string;
  hash:        string | null;
}

export interface TxPayload {
  commune?:    string;
  category:    string;
  amount:      number;
  description: string;
}

export interface TxResult {
  success: boolean;
  hash?:   string;
}

export interface BlockchainContextType {
  account:              string | null;
  isConnected:          boolean;
  chainId:              number | null;
  mode:                 "real" | "local";
  connectWallet:        () => Promise<void>;
  transactions:         Transaction[];
  balance:              number;
  totalRecettes:        number;
  totalDepenses:        number;
  loading:              boolean;
  txPending:            boolean;
  error:                string | null;
  lastTxHash:           string | null;
  recordExpense:        (payload: TxPayload) => Promise<TxResult>;
  recordRevenue:        (payload: TxPayload) => Promise<TxResult>;
  refreshTransactions:  () => void;
  commune:              string;
}

// ── Déclaration de window.ethereum pour TypeScript ────────────────────────────
declare global {
  interface Window {
    ethereum?: {
      request:  (args: { method: string; params?: unknown[] }) => Promise<unknown>;
      on:       (event: string, handler: (args: unknown) => void) => void;
      off?:     (event: string, handler: (args: unknown) => void) => void;
    };
  }
}

// ── ABI minimal ───────────────────────────────────────────────────────────────
const ABI = [
  { inputs:[{name:"commune",type:"string"},{name:"category",type:"string"},{name:"amount",type:"uint256"},{name:"description",type:"string"}], name:"recordRevenue",  outputs:[], stateMutability:"nonpayable", type:"function" },
  { inputs:[{name:"commune",type:"string"},{name:"category",type:"string"},{name:"amount",type:"uint256"},{name:"description",type:"string"}], name:"recordExpense",  outputs:[], stateMutability:"nonpayable", type:"function" },
  { inputs:[{name:"commune",type:"string"}], name:"getTransactions", outputs:[{components:[{name:"id",type:"uint256"},{name:"commune",type:"string"},{name:"txType",type:"uint8"},{name:"category",type:"string"},{name:"amount",type:"uint256"},{name:"timestamp",type:"uint256"},{name:"description",type:"string"},{name:"recorder",type:"address"}],type:"tuple[]"}], stateMutability:"view", type:"function" },
  { inputs:[{name:"commune",type:"string"}], name:"getBalance",      outputs:[{name:"",type:"int256"}],  stateMutability:"view", type:"function" },
  { anonymous:false, inputs:[{indexed:true,name:"id",type:"uint256"},{indexed:true,name:"commune",type:"string"},{indexed:false,name:"txType",type:"uint8"},{indexed:false,name:"category",type:"string"},{indexed:false,name:"amount",type:"uint256"},{indexed:false,name:"timestamp",type:"uint256"},{indexed:false,name:"description",type:"string"},{indexed:false,name:"recorder",type:"address"}], name:"TransactionRecorded", type:"event" },
];

// ── Config ────────────────────────────────────────────────────────────────────
// ⚠️ Remplacer par l'adresse réelle après déploiement sur Amoy
export const CONTRACT_ADDRESS = "0x0000000000000000000000000000000000000000";
const DEFAULT_COMMUNE = "Commune Cocody";

// ── Context ───────────────────────────────────────────────────────────────────
export const BlockchainContext = createContext<BlockchainContextType | null>(null);

// ── Conversion blockchain → objet JS ─────────────────────────────────────────
function parseTx(tx: Record<string, unknown>, index: number): Transaction {
  return {
    id:          Number(tx.id ?? index + 1),
    commune:     String(tx.commune ?? ""),
    type:        Number(tx.txType) === 0 ? "recette" : "dépense",
    category:    String(tx.category ?? ""),
    amount:      Number(tx.amount ?? 0),
    date:        new Date(Number(tx.timestamp ?? 0) * 1000).toLocaleDateString("fr-FR"),
    timestamp:   Number(tx.timestamp ?? 0),
    description: String(tx.description ?? ""),
    recorder:    String(tx.recorder ?? ""),
    hash:        (tx.hash as string) ?? null,
  };
}

// ── Provider ──────────────────────────────────────────────────────────────────
export function BlockchainProvider({ children }: { children: ReactNode }) {
  const [account,      setAccount]      = useState<string | null>(null);
  const [isConnected,  setIsConnected]  = useState(false);
  const [chainId,      setChainId]      = useState<number | null>(null);
  const [mode,         setMode]         = useState<"real" | "local">("local");
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [loading,      setLoading]      = useState(false);
  const [txPending,    setTxPending]    = useState(false);
  const [error,        setError]        = useState<string | null>(null);
  const [lastTxHash,   setLastTxHash]   = useState<string | null>(null);

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const contractRef = useRef<any>(null);

  // ── Connexion MetaMask ──────────────────────────────────────────────────────
  const connectWallet = useCallback(async () => {
    if (!window.ethereum) {
      setError("MetaMask non détecté — mode simulation activé");
      return;
    }
    try {
      setLoading(true);
      setError(null);
      const { ethers } = await import("ethers");
      const accounts   = await window.ethereum.request({ method: "eth_requestAccounts" }) as string[];
      const provider   = new ethers.BrowserProvider(window.ethereum as never);
      const signer     = await provider.getSigner();
      const network    = await provider.getNetwork();

      contractRef.current = new ethers.Contract(CONTRACT_ADDRESS, ABI, signer);

      setAccount(accounts[0]);
      setChainId(Number(network.chainId));
      setIsConnected(true);
      setMode("real");

      window.ethereum.on("accountsChanged", (accs: unknown) => {
        const list = accs as string[];
        setAccount(list[0] ?? null);
        if (!list[0]) { setIsConnected(false); setMode("local"); }
      });

      await loadFromChain();
    } catch {
      setError("Connexion MetaMask échouée — mode simulation activé");
    } finally {
      setLoading(false);
    }
  }, []); // eslint-disable-line

  // ── Lire depuis la blockchain ───────────────────────────────────────────────
  const loadFromChain = useCallback(async () => {
    if (!contractRef.current) return;
    try {
      setLoading(true);
      const raw = await contractRef.current.getTransactions(DEFAULT_COMMUNE) as Record<string, unknown>[];
      setTransactions(raw.map((tx, i) => parseTx(tx, i)));
    } catch (e) {
      console.warn("Lecture blockchain:", e);
      setError("Impossible de lire la blockchain");
    } finally {
      setLoading(false);
    }
  }, []);

  // ── Écoute événements temps réel ───────────────────────────────────────────
  useEffect(() => {
    if (mode !== "real" || !contractRef.current) return;
    const c = contractRef.current;

    const handler = (
      id: unknown, commune: unknown, txType: unknown,
      category: unknown, amount: unknown, timestamp: unknown,
      description: unknown, recorder: unknown,
      event: { transactionHash: string }
    ) => {
      const newTx = parseTx({ id, commune, txType, category, amount, timestamp, description, recorder }, 0);
      newTx.hash = event.transactionHash;
      setTransactions(prev => prev.find(t => t.id === Number(id)) ? prev : [newTx, ...prev]);
    };

    c.on("TransactionRecorded", handler);
    return () => c.off("TransactionRecorded", handler);
  }, [mode]);

  // ── Enregistrer dépense ─────────────────────────────────────────────────────
  const recordExpense = useCallback(async ({ commune, category, amount, description }: TxPayload): Promise<TxResult> => {
    setError(null);

    if (mode === "real" && contractRef.current) {
      try {
        setTxPending(true);
        const tx = await contractRef.current.recordExpense(commune ?? DEFAULT_COMMUNE, category, Math.round(amount), description);
        setLastTxHash(tx.hash);
        await tx.wait();
        return { success: true, hash: tx.hash };
      } catch (e: unknown) {
        const err = e as { reason?: string; message?: string };
        setError(err.reason ?? err.message ?? "Transaction échouée");
        return { success: false };
      } finally {
        setTxPending(false);
      }
    }

    // Mode local (simulation)
    const hash = "0x" + Math.random().toString(16).slice(2, 18) + "...local";
    const newTx: Transaction = {
      id: transactions.length + 1,
      commune: commune ?? DEFAULT_COMMUNE,
      type: "dépense", category, amount: Math.round(amount),
      date: new Date().toLocaleDateString("fr-FR"),
      timestamp: Math.floor(Date.now() / 1000),
      description, recorder: "0xSimulation...", hash,
    };
    setTransactions(prev => [newTx, ...prev]);
    return { success: true, hash };
  }, [mode, transactions]);

  // ── Enregistrer recette ─────────────────────────────────────────────────────
  const recordRevenue = useCallback(async ({ commune, category, amount, description }: TxPayload): Promise<TxResult> => {
    setError(null);

    if (mode === "real" && contractRef.current) {
      try {
        setTxPending(true);
        const tx = await contractRef.current.recordRevenue(commune ?? DEFAULT_COMMUNE, category, Math.round(amount), description);
        setLastTxHash(tx.hash);
        await tx.wait();
        return { success: true, hash: tx.hash };
      } catch (e: unknown) {
        const err = e as { reason?: string; message?: string };
        setError(err.reason ?? err.message ?? "Transaction échouée");
        return { success: false };
      } finally {
        setTxPending(false);
      }
    }

    const hash = "0x" + Math.random().toString(16).slice(2, 18) + "...local";
    const newTx: Transaction = {
      id: transactions.length + 1,
      commune: commune ?? DEFAULT_COMMUNE,
      type: "recette", category, amount: Math.round(amount),
      date: new Date().toLocaleDateString("fr-FR"),
      timestamp: Math.floor(Date.now() / 1000),
      description, recorder: "0xSimulation...", hash,
    };
    setTransactions(prev => [newTx, ...prev]);
    return { success: true, hash };
  }, [mode, transactions]);

  // ── Calculs dérivés ─────────────────────────────────────────────────────────
  const totalRecettes = transactions.filter(t => t.type === "recette").reduce((s, t) => s + t.amount, 0);
  const totalDepenses = transactions.filter(t => t.type === "dépense").reduce((s, t) => s + t.amount, 0);
  const balance       = totalRecettes - totalDepenses;

  return (
    <BlockchainContext.Provider value={{
      account, isConnected, chainId, mode, connectWallet,
      transactions, balance, totalRecettes, totalDepenses,
      loading, txPending, error, lastTxHash,
      recordExpense, recordRevenue,
      refreshTransactions: loadFromChain,
      commune: DEFAULT_COMMUNE,
    }}>
      {children}
    </BlockchainContext.Provider>
  );
}