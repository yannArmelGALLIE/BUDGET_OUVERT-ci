require('dotenv').config();
const express = require('express');
const cors    = require('cors');
const budgetRoutes = require('./src/routes/budget.route');

const app = express();
app.use(cors());
app.use(express.json());

app.use('/api/budget', budgetRoutes);

app.get('/', (_, res) => res.send('🇨🇮 BudgetOuvert CI — API opérationnelle'));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`✅ Serveur sur http://localhost:${PORT}`));