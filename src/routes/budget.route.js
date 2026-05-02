const express = require('express');
const router  = express.Router();
const ctrl    = require('../controllers/budget.controller');

// ── Écriture (comme les fonctions external du contrat) ────────────────────────
router.post('/revenue',  ctrl.recordRevenue);   // recordRevenue()
router.post('/expense',  ctrl.recordExpense);   // recordExpense()

// ── Lecture (comme les fonctions view du contrat) ─────────────────────────────
router.get('/transactions/:commune', ctrl.getTransactions);      // getTransactions()
router.get('/count/:commune',        ctrl.getTransactionCount);  // getTransactionCount()
router.get('/balance/:commune',      ctrl.getBalance);           // getBalance()
router.get('/total',                 ctrl.getTotalTransactions); // getTotalTransactions()
router.get('/communes',              ctrl.getAllCommunes);        // liste toutes les communes

module.exports = router;