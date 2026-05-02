// src/lib/useBlockchain.ts
import { useContext } from "react";
import { BlockchainContext } from "../contexts/BlockchainContext";
import type { BlockchainContextType } from "../contexts/BlockchainContext";

export function useBlockchain(): BlockchainContextType {
  const ctx = useContext(BlockchainContext);
  if (!ctx) throw new Error("useBlockchain doit être utilisé dans un BlockchainProvider");
  return ctx;
}