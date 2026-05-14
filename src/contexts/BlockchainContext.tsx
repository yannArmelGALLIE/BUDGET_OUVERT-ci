// src/contexts/BlockchainContext.tsx
// ─────────────────────────────────────────────────────────────────────────────
// Connexion DIRECTE au smart contract BudgetRegistry sur Polygon Amoy
// ✅ Lecture  : ethers.js → contract.getTransactions() — sans backend
// ✅ Écriture : MetaMask  → contract.recordRevenue/Expense() — sans backend
// ✅ Temps réel : écoute l'event TransactionRecorded + polling 15s
// ─────────────────────────────────────────────────────────────────────────────

import {
  createContext, useState, useEffect,
  useCallback, useRef, ReactNode,
} from "react";
import { ethers } from "ethers";
import { BUDGET_REGISTRY_ABI, CONTRACT_ADDRESS, AMOY_RPC } from "../abi/BudgetRegistry.abi";

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

// ── Constantes ────────────────────────────────────────────────────────────────

const DEFAULT_COMMUNE = "Commune Cocody";
const AMOY_CHAIN_ID   = 80002;

// ── Utilitaire : convertit une transaction brute du contrat ──────────────────

function parseContractTx(raw: any, txHash?: string): Transaction {
  return {
    id:          Number(raw.id),
    commune:     raw.commune,
    type:        Number(raw.txType) === 0 ? "recette" : "dépense",
    category:    raw.category,
    amount:      Number(raw.amount),
    date:        new Date(Number(raw.timestamp) * 1000).toLocaleDateString("fr-FR"),
    timestamp:   Number(raw.timestamp),
    description: raw.description,
    recorder:    raw.recorder,
    hash:        txHash ?? null,
  };
}

// ── Contract en lecture seule (sans MetaMask, gratuit) ───────────────────────

function getReadContract() {
  const provider = new ethers.JsonRpcProvider(AMOY_RPC);
  return new ethers.Contract(CONTRACT_ADDRESS, BUDGET_REGISTRY_ABI, provider);
}

// ── Contract en écriture (MetaMask requis) ───────────────────────────────────

async function getWriteContract() {
  const eth = (window as any).ethereum;
  if (!eth) throw new Error("MetaMask non détecté");
  const provider = new ethers.BrowserProvider(eth);
  const signer   = await provider.getSigner();
  return new ethers.Contract(CONTRACT_ADDRESS, BUDGET_REGISTRY_ABI, signer);
}

// ── Context ───────────────────────────────────────────────────────────────────

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

  // Map id_onchain → hash tx Polygon pour les afficher dans la table
  const knownHashes = useRef<Map<number, string>>(new Map());

  // ── Lire les transactions directement depuis le contrat ──────────────────────
  const loadTransactions = useCallback(async () => {
    if (!CONTRACT_ADDRESS) return;
    setLoading(true);
    setError(null);
    try {
      const contract = getReadContract();
      const rawList  = await contract.getTransactions(DEFAULT_COMMUNE);

      const parsed: Transaction[] = Array.from(rawList).map((raw: any) =>
        parseContractTx(raw, knownHashes.current.get(Number(raw.id)))
      );

      // Plus récent en premier
      parsed.sort((a, b) => b.timestamp - a.timestamp);
      setTransactions(parsed);
      setMode("real");
    } catch (e: any) {
      console.warn("Lecture blockchain échouée:", e.message);
      setMode("local");
    } finally {
      setLoading(false);
    }
  }, []);

  // Chargement initial
  useEffect(() => { loadTransactions(); }, [loadTransactions]);

  // Polling toutes les 15 secondes — met à jour tous les dashboards ouverts
  useEffect(() => {
    const id = setInterval(loadTransactions, 15_000);
    return () => clearInterval(id);
  }, [loadTransactions]);

  // ── Écoute les events en temps réel quand MetaMask est connecté ──────────────
  useEffect(() => {
    if (!isConnected || !CONTRACT_ADDRESS) return;
    let contract: ethers.Contract;
    try {
      const provider = new ethers.BrowserProvider((window as any).ethereum);
      contract = new ethers.Contract(CONTRACT_ADDRESS, BUDGET_REGISTRY_ABI, provider);

      contract.on("TransactionRecorded", (
        id, _commune, _txType, _category, _amount, _timestamp, _description, _recorder, event
      ) => {
        knownHashes.current.set(Number(id), event.log.transactionHash);
        // Recharge 2s après l'event (temps de propagation Polygon)
        setTimeout(loadTransactions, 2000);
      });
    } catch (e) {
      console.warn("Écoute events échouée:", e);
    }
    return () => { contract?.removeAllListeners(); };
  }, [isConnected, loadTransactions]);

  // ── Connecter MetaMask et vérifier le réseau Amoy ───────────────────────────
  const connectWallet = useCallback(async () => {
    const eth = (window as any).ethereum;
    if (!eth) {
      setError("MetaMask non détecté — installe l'extension");
      return;
    }
    try {
      const accounts = await eth.request({ method: "eth_requestAccounts" }) as string[];
      const chainHex = await eth.request({ method: "eth_chainId" }) as string;
      const cid      = parseInt(chainHex, 16);

      // Change automatiquement vers Polygon Amoy si nécessaire
      if (cid !== AMOY_CHAIN_ID) {
        try {
          await eth.request({
            method: "wallet_switchEthereumChain",
            params: [{ chainId: "0x13882" }], // 80002 en hex
          });
        } catch {
          setError("Change le réseau MetaMask vers Polygon Amoy (Chain ID 80002)");
          return;
        }
      }

      setAccount(accounts[0] ?? null);
      setChainId(AMOY_CHAIN_ID);
      setIsConnected(true);
      setError(null);
      await loadTransactions();
    } catch (e: any) {
      setError("Connexion MetaMask échouée : " + (e.message ?? ""));
    }
  }, [loadTransactions]);

  // ── Enregistrer une RECETTE directement sur le contrat ──────────────────────
  const recordRevenue = useCallback(async ({
    commune, category, amount, description,
  }: TxPayload): Promise<TxResult> => {
    setError(null);

    // Mode simulation si contrat non configuré ou pas connecté
    if (!CONTRACT_ADDRESS || !isConnected) {
      const fake: Transaction = {
        id: transactions.length + 1,
        commune: commune ?? DEFAULT_COMMUNE,
        type: "recette", category,
        amount: Math.round(amount),
        date: new Date().toLocaleDateString("fr-FR"),
        timestamp: Math.floor(Date.now() / 1000),
        description,
        recorder: account ?? "0xSimulation",
        hash: "0xlocal_" + Math.random().toString(16).slice(2, 14),
      };
      setTransactions(prev => [fake, ...prev]);
      return { success: true, hash: fake.hash! };
    }

    setTxPending(true);
    try {
      const contract = await getWriteContract();

      // ⚡ Appel direct au smart contract via MetaMask
      const tx = await contract.recordRevenue(
        commune ?? DEFAULT_COMMUNE,
        category,
        BigInt(Math.round(amount)),
        description,
      );

      // Attend la confirmation du bloc (≈ 2s sur Amoy)
      const receipt = await tx.wait(1);
      setLastTxHash(receipt.hash);

      // Recharge — tous les autres dashboards verront la nouvelle tx au prochain polling
      await loadTransactions();
      return { success: true, hash: receipt.hash };
    } catch (e: any) {
      const msg = e.reason ?? e.message ?? "Erreur enregistrement";
      setError(msg);
      return { success: false, error: msg };
    } finally {
      setTxPending(false);
    }
  }, [isConnected, transactions, account, loadTransactions]);

  // ── Enregistrer une DÉPENSE directement sur le contrat ──────────────────────
  const recordExpense = useCallback(async ({
    commune, category, amount, description,
  }: TxPayload): Promise<TxResult> => {
    setError(null);

    if (!CONTRACT_ADDRESS || !isConnected) {
      const fake: Transaction = {
        id: transactions.length + 1,
        commune: commune ?? DEFAULT_COMMUNE,
        type: "dépense", category,
        amount: Math.round(amount),
        date: new Date().toLocaleDateString("fr-FR"),
        timestamp: Math.floor(Date.now() / 1000),
        description,
        recorder: account ?? "0xSimulation",
        hash: "0xlocal_" + Math.random().toString(16).slice(2, 14),
      };
      setTransactions(prev => [fake, ...prev]);
      return { success: true, hash: fake.hash! };
    }

    setTxPending(true);
    try {
      const contract = await getWriteContract();

      const tx = await contract.recordExpense(
        commune ?? DEFAULT_COMMUNE,
        category,
        BigInt(Math.round(amount)),
        description,
      );

      const receipt = await tx.wait(1);
      setLastTxHash(receipt.hash);
      await loadTransactions();
      return { success: true, hash: receipt.hash };
    } catch (e: any) {
      const msg = e.reason ?? e.message ?? "Erreur enregistrement";
      setError(msg);
      return { success: false, error: msg };
    } finally {
      setTxPending(false);
    }
  }, [isConnected, transactions, account, loadTransactions]);

  // ── Calculs ───────────────────────────────────────────────────────────────────
  const totalRecettes = transactions.filter(t => t.type === "recette").reduce((s,t) => s+t.amount, 0);
  const totalDepenses = transactions.filter(t => t.type === "dépense").reduce((s,t) => s+t.amount, 0);
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