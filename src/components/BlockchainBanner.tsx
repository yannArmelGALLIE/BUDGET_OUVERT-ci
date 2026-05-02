// src/components/BlockchainBanner.tsx
import { useBlockchain } from "../lib/useBlockchain";

const SHORT = (addr: string) => `${addr.slice(0, 6)}...${addr.slice(-4)}`;

export function BlockchainBanner() {
  const {
    mode, account, isConnected, chainId,
    connectWallet, txPending, error, lastTxHash, loading,
  } = useBlockchain();

  const isAmoy = chainId === 80002;

  return (
    <div style={{
      background: mode === "real" ? "#0f172a" : "#1c1917",
      padding: "8px 24px",
      display: "flex",
      alignItems: "center",
      gap: 16,
      fontSize: 12,
      borderBottom: `2px solid ${mode === "real" ? "#10b981" : "#f97316"}`,
      flexWrap: "wrap" as const,
    }}>
      {/* Mode indicator */}
      <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
        <div style={{
          width: 8, height: 8, borderRadius: "50%",
          background: mode === "real" ? "#10b981" : "#f97316",
          boxShadow: `0 0 6px ${mode === "real" ? "#10b981" : "#f97316"}`,
        }} />
        <span style={{ color: mode === "real" ? "#10b981" : "#f97316", fontWeight: 700 }}>
          {mode === "real" ? "⛓ BLOCKCHAIN RÉELLE" : "⚡ MODE SIMULATION"}
        </span>
      </div>

      {/* Network */}
      {mode === "real" && (
        <span style={{
          color: isAmoy ? "#6ee7b7" : "#fbbf24",
          background: "#ffffff10",
          padding: "2px 8px",
          borderRadius: 20,
        }}>
          {isAmoy ? "Polygon Amoy ✓" : `Réseau inconnu (${chainId})`}
        </span>
      )}

      {/* Account */}
      {isConnected && account && (
        <span style={{ color: "#94a3b8", fontFamily: "monospace" }}>
          {SHORT(account)}
        </span>
      )}

      {/* Pending tx */}
      {txPending && (
        <span style={{ color: "#fbbf24", display: "flex", alignItems: "center", gap: 6 }}>
          <span style={{
            display: "inline-block",
            width: 10, height: 10,
            border: "2px solid #fbbf24",
            borderTopColor: "transparent",
            borderRadius: "50%",
            animation: "spin 0.7s linear infinite",
          }} />
          Enregistrement sur blockchain...
        </span>
      )}

      {/* Last tx hash */}
      {lastTxHash && !txPending && (
        <a
          href={`https://amoy.polygonscan.com/tx/${lastTxHash}`}
          target="_blank"
          rel="noopener noreferrer"
          style={{ color: "#10b981", textDecoration: "none", fontFamily: "monospace", fontSize: 11 }}
        >
          ✓ {lastTxHash.slice(0, 10)}... →
        </a>
      )}

      {/* Error */}
      {error && (
        <span style={{ color: "#f87171", marginLeft: "auto" }}>⚠ {error}</span>
      )}

      {/* Connect button */}
      {!isConnected && (
        <button
          onClick={connectWallet}
          disabled={loading}
          style={{
            marginLeft: "auto",
            padding: "4px 14px",
            background: "#10b981",
            color: "white",
            border: "none",
            borderRadius: 20,
            cursor: loading ? "wait" : "pointer",
            fontWeight: 700,
            fontSize: 11,
          }}
        >
          {loading ? "Connexion..." : "🦊 Connecter MetaMask"}
        </button>
      )}

      {/* Simulation label */}
      {mode === "local" && (
        <span style={{ color: "#78716c", fontSize: 11, marginLeft: isConnected ? 0 : 4 }}>
          (connecter MetaMask pour la vraie blockchain)
        </span>
      )}
    </div>
  );
}