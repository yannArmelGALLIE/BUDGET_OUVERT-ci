// src/components/BlockchainBanner.tsx
// Barre de statut — affiche la connexion au backend Railway et à Polygon Amoy

import { useBlockchain } from "../lib/useBlockchain";

const SHORT = (addr: string) => `${addr.slice(0, 6)}...${addr.slice(-4)}`;
const RAILWAY_URL = "https://budgetouvert-ci-production.up.railway.app";
const POLYGONSCAN  = "https://amoy.polygonscan.com";

export function BlockchainBanner() {
  const {
    mode, account, isConnected,
    connectWallet, txPending, error, lastTxHash, loading,
  } = useBlockchain();

  const isReal = mode === "real";

  return (
    <div style={{
      background:    isReal ? "#0f172a" : "#1c1917",
      padding:       "7px 20px",
      display:       "flex",
      alignItems:    "center",
      gap:           14,
      fontSize:      12,
      borderBottom:  `2px solid ${isReal ? "#10b981" : "#f97316"}`,
      flexWrap:      "wrap" as const,
      minHeight:     36,
    }}>

      {/* Indicateur statut principal */}
      <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
        <div style={{
          width:      8,
          height:     8,
          borderRadius: "50%",
          background:  isReal ? "#10b981" : "#f97316",
          boxShadow:  `0 0 6px ${isReal ? "#10b981" : "#f97316"}`,
          animation:  isReal ? "none" : "pulse 1.5s infinite",
        }} />
        <span style={{ color: isReal ? "#10b981" : "#f97316", fontWeight: 700 }}>
          {isReal ? "⛓ BLOCKCHAIN POLYGON AMOY" : "⚡ MODE SIMULATION"}
        </span>
      </div>

      {/* Badge Railway */}
      {isReal && (
        <a
          href={RAILWAY_URL}
          target="_blank"
          rel="noopener noreferrer"
          style={{
            color:        "#6ee7b7",
            background:   "#ffffff10",
            padding:      "2px 9px",
            borderRadius: 20,
            textDecoration: "none",
            fontSize:     11,
          }}
        >
          🚂 Railway API ✓
        </a>
      )}

      {/* Badge Polygonscan */}
      {isReal && (
        <a
          href={POLYGONSCAN}
          target="_blank"
          rel="noopener noreferrer"
          style={{
            color:        "#a78bfa",
            background:   "#ffffff10",
            padding:      "2px 9px",
            borderRadius: 20,
            textDecoration: "none",
            fontSize:     11,
          }}
        >
          🔍 Polygonscan Amoy ↗
        </a>
      )}

      {/* Wallet connecté */}
      {isConnected && account && (
        <span style={{ color: "#94a3b8", fontFamily: "monospace", fontSize: 11 }}>
          🦊 {SHORT(account)}
        </span>
      )}

      {/* Chargement */}
      {loading && !txPending && (
        <span style={{ color: "#94a3b8", fontSize: 11 }}>
          Synchronisation...
        </span>
      )}

      {/* Transaction en cours */}
      {txPending && (
        <span style={{ color: "#fbbf24", display: "flex", alignItems: "center", gap: 6 }}>
          <span style={{
            display:      "inline-block",
            width:        10,
            height:       10,
            border:       "2px solid #fbbf24",
            borderTopColor: "transparent",
            borderRadius: "50%",
            animation:    "spin 0.7s linear infinite",
          }} />
          Enregistrement sur Polygon...
        </span>
      )}

      {/* Hash dernière transaction */}
      {lastTxHash && !txPending && (
        <a
          href={`${POLYGONSCAN}/tx/${lastTxHash}`}
          target="_blank"
          rel="noopener noreferrer"
          style={{
            color:          "#10b981",
            fontFamily:     "monospace",
            fontSize:       11,
            textDecoration: "none",
          }}
        >
          ✓ {lastTxHash.slice(0, 12)}... ↗
        </a>
      )}

      {/* Erreur */}
      {error && (
        <span style={{ color: "#f87171", fontSize: 11 }}>
          ⚠ {error}
        </span>
      )}

      {/* Bouton connecter MetaMask */}
      {!isConnected && (
        <button
          onClick={connectWallet}
          style={{
            marginLeft:   "auto",
            padding:      "4px 14px",
            background:   "#10b981",
            color:        "white",
            border:       "none",
            borderRadius: 20,
            cursor:       "pointer",
            fontWeight:   700,
            fontSize:     11,
          }}
        >
          🦊 Connecter MetaMask
        </button>
      )}

      {/* CSS animations */}
      <style>{`
        @keyframes spin {
          to { transform: rotate(360deg); }
        }
        @keyframes pulse {
          0%, 100% { opacity: 1; }
          50% { opacity: 0.4; }
        }
      `}</style>
    </div>
  );
}