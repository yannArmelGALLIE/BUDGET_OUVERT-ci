const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// ── Utilitaire : sérialiser BigInt pour JSON ──────────────────────────────────
const serialize = (obj) => JSON.parse(JSON.stringify(obj, (_, v) =>
  typeof v === 'bigint' ? v.toString() : v
));

// ── recordRevenue — Enregistrer une recette ───────────────────────────────────
exports.recordRevenue = async (req, res) => {
  const { commune, category, amount, description, recorder } = req.body;

  if (!commune || !category || !amount || !description || !recorder)
    return res.status(400).json({ error: "Tous les champs sont requis" });

  if (BigInt(amount) <= 0n)
    return res.status(400).json({ error: "montant doit etre superieur a 0" });

  try {
    // 1. Enregistrer la transaction (comme _saveTransaction)
    const tx = await prisma.transaction.create({
      data: {
        communeName: commune,
        txType: 'REVENUE',
        category,
        amount: BigInt(amount),
        description,
        recorder,
      }
    });

    // 2. Mettre à jour le solde (comme communeBalance[commune] += amount)
    await prisma.commune.upsert({
      where: { name: commune },
      create: {
        id: `commune-${Date.now()}`,
        name: commune,
        region: "Non définie",
        budgetTotal: BigInt(amount),
        budgetConsomme: 0n,
        tauxExecution: 0,
      },
      update: {
        budgetTotal: { increment: BigInt(amount) },
      }
    });

    // 3. Mettre à jour le taux d'exécution
    await updateTauxExecution(commune);

    res.status(201).json({
      message: "✅ Recette enregistrée",
      transaction: serialize(tx),
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ── recordExpense — Enregistrer une dépense ───────────────────────────────────
exports.recordExpense = async (req, res) => {
  const { commune, category, amount, description, recorder } = req.body;

  if (!commune || !category || !amount || !description || !recorder)
    return res.status(400).json({ error: "Tous les champs sont requis" });

  if (BigInt(amount) <= 0n)
    return res.status(400).json({ error: "montant doit etre superieur a 0" });

  try {
    // 1. Enregistrer la transaction
    const tx = await prisma.transaction.create({
      data: {
        communeName: commune,
        txType: 'EXPENSE',
        category,
        amount: BigInt(amount),
        description,
        recorder,
      }
    });

    // 2. Mettre à jour le solde (comme communeBalance[commune] -= amount)
    await prisma.commune.upsert({
      where: { name: commune },
      create: {
        id: `commune-${Date.now()}`,
        name: commune,
        region: "Non définie",
        budgetTotal: 0n,
        budgetConsomme: BigInt(amount),
        tauxExecution: 0,
      },
      update: {
        budgetConsomme: { increment: BigInt(amount) },
      }
    });

    // 3. Mettre à jour le taux d'exécution
    await updateTauxExecution(commune);

    res.status(201).json({
      message: "✅ Dépense enregistrée",
      transaction: serialize(tx),
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ── getTransactions — Lire les transactions d'une commune ─────────────────────
exports.getTransactions = async (req, res) => {
  const { commune } = req.params;
  try {
    const txs = await prisma.transaction.findMany({
      where: { communeName: decodeURIComponent(commune) },
      orderBy: { timestamp: 'desc' },
    });
    res.json(serialize(txs));
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ── getTransactionCount — Nombre de transactions ──────────────────────────────
exports.getTransactionCount = async (req, res) => {
  const { commune } = req.params;
  try {
    const count = await prisma.transaction.count({
      where: { communeName: decodeURIComponent(commune) },
    });
    res.json({ commune, count });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ── getBalance — Solde d'une commune ─────────────────────────────────────────
exports.getBalance = async (req, res) => {
  const { commune } = req.params;
  try {
    const data = await prisma.commune.findUnique({
      where: { name: decodeURIComponent(commune) },
    });

    if (!data) return res.json({ commune, balance: "0" });

    const balance = data.budgetTotal - data.budgetConsomme;
    res.json({
      commune,
      balance: balance.toString(),
      budgetTotal: data.budgetTotal.toString(),
      budgetConsomme: data.budgetConsomme.toString(),
      tauxExecution: data.tauxExecution,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ── getTotalTransactions — Compteur global ────────────────────────────────────
exports.getTotalTransactions = async (req, res) => {
  try {
    const count = await prisma.transaction.count();
    res.json({ totalTransactions: count });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ── getAllCommunes — Liste toutes les communes ─────────────────────────────────
exports.getAllCommunes = async (req, res) => {
  try {
    const communes = await prisma.commune.findMany({
      orderBy: { name: 'asc' },
    });
    res.json(serialize(communes));
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ── Utilitaire interne : recalcule le taux d'exécution ────────────────────────
async function updateTauxExecution(communeName) {
  const commune = await prisma.commune.findUnique({ where: { name: communeName } });
  if (!commune || commune.budgetTotal === 0n) return;

  const taux = Number(commune.budgetConsomme * 100n / commune.budgetTotal);
  await prisma.commune.update({
    where: { name: communeName },
    data: { tauxExecution: taux },
  });
}