// src/contexts/BlockchainContext.tsx
// Connecté au backend Railway — https://budgetouvert-ci-production.up.railway.app
// Format de réponse API réel pris en compte

import {
  createContext,
  useState,
  useEffect,
  useCallback,
  ReactNode,
} from "react";

const API_BASE        = "https://budgetouvert-ci-production.up.railway.app/api/budget";
const DEFAULT_COMMUNE  = "Commune Cocody";
const DEFAULT_RECORDER = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";

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
  error?:  string;
}

export interface BlockchainContextType {
  account:             string | null;
  isConnected:         boolean;
  chainId:             number | null;
  mode:                "real" | "local";
  connectWallet:       () => Promise<void>;
  transactions:        Transaction[];
  balance:             number;
  totalRecettes:       number;
  totalDepenses:       number;
  loading:             boolean;
  txPending:           boolean;
  error:               string | null;
  lastTxHash:          string | null;
  recordExpense:       (payload: TxPayload) => Promise<TxResult>;
  recordRevenue:       (payload: TxPayload) => Promise<TxResult>;
  refreshTransactions: () => void;
  commune:             string;
}

// Format brut retourné par le backend
interface RawTransaction {
  id:          number;
  communeName: string;
  txType:      "REVENUE" | "EXPENSE";
  category:    string;
  amount:      string;
  timestamp:   string;
  description: string;
  recorder:    string;
  hash?:       string;
}

// Convertir la réponse brute en Transaction utilisable par les dashboards
function parseRawTx(raw: RawTransaction): Transaction {
  return {
    id:          raw.id,
    commune:     raw.communeName,
    type:        raw.txType === "REVENUE" ? "recette" : "dépense",
    category:    raw.category,
    amount:      Number(raw.amount),
    date:        new Date(raw.timestamp).toLocaleDateString("fr-FR"),
    timestamp:   Math.floor(new Date(raw.timestamp).getTime() / 1000),
    description: raw.description,
    recorder:    raw.recorder,
    hash:        raw.hash ?? null,
  };
}

export const BlockchainContext = createContext<BlockchainContextType | null>(null);

export function BlockchainProvider({ children }: { children: ReactNode }) {
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [loading,      setLoading]      = useState(false);
  const [txPending,    setTxPending]    = useState(false);
  const [error,        setError]        = useState<string | null>(null);
  const [lastTxHash,   setLastTxHash]   = useState<string | null>(null);
  const [mode,         setMode]         = useState<"real" | "local">("local");
  const [account,      setAccount]      = useState<string | null>(null);
  const [isConnected,  setIsConnected]  = useState(false);
  const [chainId,      setChainId]      = useState<number | null>(null);

  // Charger les transactions — backend retourne un tableau direct []
  const loadTransactions = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch(
        `${API_BASE}/transactions/${encodeURIComponent(DEFAULT_COMMUNE)}`
      );
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const rawList: RawTransaction[] = await res.json();
      setTransactions(rawList.map(parseRawTx));
      setMode("real");
    } catch (e: any) {
      console.warn("Backend inaccessible:", e.message);
      setMode("local");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { loadTransactions(); }, [loadTransactions]);

  // Polling toutes les 10 secondes
  useEffect(() => {
    const interval = setInterval(loadTransactions, 10_000);
    return () => clearInterval(interval);
  }, [loadTransactions]);

  const connectWallet = useCallback(async () => {
    if (!(window as any).ethereum) { setError("MetaMask non détecté"); return; }
    try {
      const accounts = await (window as any).ethereum.request({ method: "eth_requestAccounts" }) as string[];
      const chainHex = await (window as any).ethereum.request({ method: "eth_chainId" }) as string;
      setAccount(accounts[0] ?? null);
      setChainId(parseInt(chainHex, 16));
      setIsConnected(true);
    } catch { setError("Connexion MetaMask échouée"); }
  }, []);

  const recordRevenue = useCallback(async ({ commune, category, amount, description }: TxPayload): Promise<TxResult> => {
    setError(null);
    if (mode === "local") {
      const fake: Transaction = {
        id: transactions.length + 1, commune: commune ?? DEFAULT_COMMUNE,
        type: "recette", category, amount: Math.round(amount),
        date: new Date().toLocaleDateString("fr-FR"),
        timestamp: Math.floor(Date.now() / 1000), description,
        recorder: "0xSimulation...",
        hash: "0x" + Math.random().toString(16).slice(2, 18) + "...local",
      };
      setTransactions(prev => [fake, ...prev]);
      return { success: true, hash: fake.hash! };
    }
    setTxPending(true);
    try {
      const res = await fetch(`${API_BASE}/revenue`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          commune: commune ?? DEFAULT_COMMUNE,
          category,
          amount: String(Math.round(amount)),
          description,
          recorder: account ?? DEFAULT_RECORDER,
        }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || `HTTP ${res.status}`);
      setLastTxHash(data.hash ?? null);
      await loadTransactions();
      return { success: true, hash: data.hash };
    } catch (e: any) {
      const msg = e.message ?? "Erreur enregistrement";
      setError(msg);
      return { success: false, error: msg };
    } finally { setTxPending(false); }
  }, [mode, transactions, account, loadTransactions]);

  const recordExpense = useCallback(async ({ commune, category, amount, description }: TxPayload): Promise<TxResult> => {
    setError(null);
    if (mode === "local") {
      const fake: Transaction = {
        id: transactions.length + 1, commune: commune ?? DEFAULT_COMMUNE,
        type: "dépense", category, amount: Math.round(amount),
        date: new Date().toLocaleDateString("fr-FR"),
        timestamp: Math.floor(Date.now() / 1000), description,
        recorder: "0xSimulation...",
        hash: "0x" + Math.random().toString(16).slice(2, 18) + "...local",
      };
      setTransactions(prev => [fake, ...prev]);
      return { success: true, hash: fake.hash! };
    }
    setTxPending(true);
    try {
      const res = await fetch(`${API_BASE}/expense`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          commune: commune ?? DEFAULT_COMMUNE,
          category,
          amount: String(Math.round(amount)),
          description,
          recorder: account ?? DEFAULT_RECORDER,
        }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || `HTTP ${res.status}`);
      setLastTxHash(data.hash ?? null);
      await loadTransactions();
      return { success: true, hash: data.hash };
    } catch (e: any) {
      const msg = e.message ?? "Erreur enregistrement";
      setError(msg);
      return { success: false, error: msg };
    } finally { setTxPending(false); }
  }, [mode, transactions, account, loadTransactions]);

  const totalRecettes = transactions.filter(t => t.type === "recette").reduce((s, t) => s + t.amount, 0);
  const totalDepenses = transactions.filter(t => t.type === "dépense").reduce((s, t) => s + t.amount, 0);
  const balance       = totalRecettes - totalDepenses;

  return (
    <BlockchainContext.Provider value={{
      account, isConnected, chainId, mode, connectWallet,
      transactions, balance, totalRecettes, totalDepenses,
      loading, txPending, error, lastTxHash,
      recordExpense, recordRevenue,
      refreshTransactions: loadTransactions,
      commune: DEFAULT_COMMUNE,
    }}>
      {children}
    </BlockchainContext.Provider>
  );
}