import { useState, useRef, useEffect, useCallback } from 'react';
import { Search, SlidersHorizontal, User, ChevronDown, TrendingUp, TrendingDown, X, RefreshCw } from 'lucide-react';

// ── Config Railway ─────────────────────────────────────────────────────────────
const API_BASE = "https://budgetouvert-ci-production.up.railway.app/api/budget";

const communes = [
  'Commune Cocody',
  'Commune Abobo',
  'Commune Adjamé',
  'Commune Yopougon',
  'Commune Marcory',
  'Commune Plateau',
  'Commune Port-Bouët',
  'Commune Treichville',
];

// ── Types ──────────────────────────────────────────────────────────────────────
interface RawTransaction {
  id:          number;
  communeName: string;
  txType:      'REVENUE' | 'EXPENSE';
  category:    string;
  amount:      string;
  timestamp:   string;
  description: string;
  recorder:    string;
  hash?:       string;
}

interface Transaction {
  id:          number;
  title:       string;
  date:        string;
  dept:        string;
  amount:      string;
  positive:    boolean;
  type:        'recette' | 'depense';
  rawAmount:   number;
  hash:        string | null;
  recorder:    string;
}

interface BalanceData {
  balance:        number;
  budgetTotal:    number;
  budgetConsomme: number;
  tauxExecution:  number;
}

// ── Formater les montants en FCFA lisible ──────────────────────────────────────
function formatFCFA(n: number): string {
  if (n >= 1_000_000_000) return (n / 1_000_000_000).toFixed(1) + ' Milliard';
  if (n >= 1_000_000)     return (n / 1_000_000).toFixed(1) + ' Million';
  if (n >= 1_000)         return (n / 1_000).toFixed(0) + ' K';
  return n.toLocaleString('fr-FR');
}

// ── Convertir transaction brute → format affichage ────────────────────────────
function parseRawTx(raw: RawTransaction): Transaction {
  const isRevenue = raw.txType === 'REVENUE';
  const amount    = Number(raw.amount);
  const date      = new Date(raw.timestamp);

  return {
    id:        raw.id,
    title:     raw.description || raw.category,
    date:      date.toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' }),
    dept:      raw.category,
    amount:    `${isRevenue ? '+' : '−'}${formatFCFA(amount)} FCFA`,
    positive:  isRevenue,
    type:      isRevenue ? 'recette' : 'depense',
    rawAmount: amount,
    hash:      raw.hash ?? null,
    recorder:  raw.recorder,
  };
}

// ── Graphique Donut (sources de recettes calculées dynamiquement) ──────────────
const DONUT_COLORS = ['#1a3a1a', '#3d7a3d', '#2d2d5e', '#b0b0b0'];

function DonutChart({ slices }: { slices: { label: string; pct: number; color: string }[] }) {
  const r             = 52;
  const cx            = 70;
  const cy            = 70;
  const circumference = 2 * Math.PI * r;
  const total         = slices.reduce((s, r) => s + r.pct, 0) || 1;
  let cumulative      = 0;

  return (
    <svg width="140" height="140" viewBox="0 0 140 140">
      {slices.map((slice) => {
        const offset = circumference * (1 - cumulative / total);
        const dash   = (slice.pct / total) * circumference;
        const gap    = circumference - dash;
        const el = (
          <circle
            key={slice.label}
            cx={cx} cy={cy} r={r}
            fill="none"
            stroke={slice.color}
            strokeWidth="16"
            strokeDasharray={`${dash} ${gap}`}
            strokeDashoffset={offset}
            transform={`rotate(-90 ${cx} ${cy})`}
          />
        );
        cumulative += slice.pct;
        return el;
      })}
      <circle cx={cx} cy={cy} r={38} fill="white" />
      <text x={cx} y={cy - 4} textAnchor="middle" fontSize="9" fill="#6b7280">Total</text>
      <text x={cx} y={cy + 10} textAnchor="middle" fontSize="10" fontWeight="bold" fill="#111">
        {slices.reduce((s, r) => s + r.pct, 0)}%
      </text>
    </svg>
  );
}

type Filter = 'tous' | 'recette' | 'depense';

// ── Composant principal ────────────────────────────────────────────────────────
export default function CitizenDashboard() {
  const [filter,           setFilter]          = useState<Filter>('tous');
  const [search,           setSearch]          = useState('');
  const [showDateModal,    setShowDateModal]    = useState(false);
  const [dateFrom,         setDateFrom]         = useState('');
  const [dateTo,           setDateTo]           = useState('');
  const [selectedCommune,  setSelectedCommune]  = useState(communes[0]);
  const [showCommuneMenu,  setShowCommuneMenu]  = useState(false);
  const communeMenuRef = useRef<HTMLDivElement>(null);

  // ── État des données depuis Railway ──────────────────────────────────────────
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [balanceData,  setBalanceData]  = useState<BalanceData | null>(null);
  const [loading,      setLoading]      = useState(false);
  const [lastUpdate,   setLastUpdate]   = useState<Date | null>(null);
  const [isConnected,  setIsConnected]  = useState(false);

  // Fermer le menu commune en cliquant ailleurs
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (communeMenuRef.current && !communeMenuRef.current.contains(e.target as Node)) {
        setShowCommuneMenu(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // ── Charger les données depuis Railway ───────────────────────────────────────
  const loadData = useCallback(async (commune: string) => {
    setLoading(true);
    try {
      // Appels parallèles pour aller plus vite
      const [txRes, balRes] = await Promise.all([
        fetch(`${API_BASE}/transactions/${encodeURIComponent(commune)}`),
        fetch(`${API_BASE}/balance/${encodeURIComponent(commune)}`),
      ]);

      if (txRes.ok) {
        const rawList: RawTransaction[] = await txRes.json();
        setTransactions(rawList.map(parseRawTx));
        setIsConnected(true);
      }

      if (balRes.ok) {
        const bal = await balRes.json();
        setBalanceData({
          balance:        Number(bal.balance),
          budgetTotal:    Number(bal.budgetTotal),
          budgetConsomme: Number(bal.budgetConsomme),
          tauxExecution:  Number(bal.tauxExecution),
        });
      }

      setLastUpdate(new Date());
    } catch (e) {
      console.warn('Backend inaccessible:', e);
      setIsConnected(false);
    } finally {
      setLoading(false);
    }
  }, []);

  // Charger au démarrage et quand la commune change
  useEffect(() => {
    loadData(selectedCommune);
  }, [selectedCommune, loadData]);

  // Polling toutes les 15 secondes — mise à jour auto sans recharger la page
  useEffect(() => {
    const interval = setInterval(() => loadData(selectedCommune), 15_000);
    return () => clearInterval(interval);
  }, [selectedCommune, loadData]);

  // ── Calculs dérivés ──────────────────────────────────────────────────────────
  const totalRecettes = transactions
    .filter(t => t.type === 'recette')
    .reduce((s, t) => s + t.rawAmount, 0);

  const totalDepenses = transactions
    .filter(t => t.type === 'depense')
    .reduce((s, t) => s + t.rawAmount, 0);

  const solde = totalRecettes - totalDepenses;

  // Calcul dynamique des secteurs depuis les vraies dépenses
  const secteurMap: Record<string, number> = {};
  transactions
    .filter(t => t.type === 'depense')
    .forEach(t => {
      secteurMap[t.dept] = (secteurMap[t.dept] || 0) + t.rawAmount;
    });

  const sectors = Object.entries(secteurMap)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(([name, amount], i) => ({
      name,
      amount: formatFCFA(amount) + ' FCFA',
      color: ['#1a3a1a', '#2d6a2d', '#7b2d8b', '#e07b20', '#2d2d5e'][i],
      pct: totalDepenses > 0 ? Math.round((amount / totalDepenses) * 100) : 0,
    }));

  // Calcul dynamique des sources de recettes
  const recetteMap: Record<string, number> = {};
  transactions
    .filter(t => t.type === 'recette')
    .forEach(t => {
      recetteMap[t.dept] = (recetteMap[t.dept] || 0) + t.rawAmount;
    });

  const revenueSlices = Object.entries(recetteMap)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 4)
    .map(([label, amount], i) => ({
      label,
      pct: totalRecettes > 0 ? Math.round((amount / totalRecettes) * 100) : 0,
      color: DONUT_COLORS[i],
    }));

  // ── Filtrage des transactions ─────────────────────────────────────────────────
  const filtered = transactions.filter((t) => {
    const matchFilter = filter === 'tous' || t.type === filter;
    const matchSearch =
      search === '' ||
      t.title.toLowerCase().includes(search.toLowerCase()) ||
      t.dept.toLowerCase().includes(search.toLowerCase());

    let matchDate = true;
    if (dateFrom || dateTo) {
      const tDate    = new Date(t.date.split(' ').reverse().join('-'));
      const fromDate = dateFrom ? new Date(dateFrom) : null;
      const toDate   = dateTo   ? new Date(dateTo)   : null;
      if (fromDate && tDate < fromDate) matchDate = false;
      if (toDate   && tDate > toDate)   matchDate = false;
    }
    return matchFilter && matchSearch && matchDate;
  });

  // Temps depuis dernière mise à jour
  const timeSinceUpdate = lastUpdate
    ? Math.floor((Date.now() - lastUpdate.getTime()) / 1000)
    : null;

  const updateLabel = timeSinceUpdate === null
    ? 'Connexion...'
    : timeSinceUpdate < 10
      ? 'À l\'instant'
      : `il y a ${timeSinceUpdate}s`;

  return (
    <div className="h-screen bg-gray-50 font-sans flex flex-col overflow-hidden">

      {/* Header */}
      <header className="bg-white border-b border-gray-200 px-6 py-3 flex items-center justify-between flex-shrink-0">
        <div className="flex items-center gap-3">
          <img src="/image.png" alt="BudgetOuvert" className="w-10 h-10" />
          <div>
            <div className="font-bold text-gray-900 text-base leading-tight">BudgetOuvert</div>
            <div className="text-xs text-gray-500">Tableau de bord public</div>
          </div>
        </div>

        <div className="flex items-center gap-3">
          {/* Indicateur connexion blockchain */}
          <div className="flex items-center gap-1.5">
            <div className={`w-2 h-2 rounded-full ${isConnected ? 'bg-emerald-500' : 'bg-orange-400'}`}
              style={{ boxShadow: isConnected ? '0 0 5px #10b981' : 'none' }} />
            <span className="text-xs text-gray-500">
              {isConnected ? '⛓ Polygon Amoy' : '⚡ Simulation'}
            </span>
          </div>

          {/* Bouton actualiser */}
          <button
            onClick={() => loadData(selectedCommune)}
            disabled={loading}
            className="flex items-center gap-1.5 text-xs text-gray-500 hover:text-gray-800 transition-colors"
          >
            <RefreshCw size={13} className={loading ? 'animate-spin' : ''} />
            {loading ? 'Chargement...' : 'Actualiser'}
          </button>

          {/* Sélecteur de commune */}
          <div className="relative" ref={communeMenuRef}>
            <button
              onClick={() => setShowCommuneMenu(!showCommuneMenu)}
              className="flex items-center gap-2 border border-gray-200 rounded-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 transition-colors"
            >
              <User size={15} className="text-gray-500" />
              <span>{selectedCommune}</span>
              <ChevronDown size={14} className={`text-gray-400 transition-transform ${showCommuneMenu ? 'rotate-180' : ''}`} />
            </button>
            {showCommuneMenu && (
              <div className="absolute right-0 mt-2 bg-white border border-gray-200 rounded-lg shadow-lg z-10 min-w-56">
                {communes.map((commune) => (
                  <button
                    key={commune}
                    onClick={() => { setSelectedCommune(commune); setShowCommuneMenu(false); }}
                    className={`block w-full text-left px-4 py-2 text-sm transition-colors first:rounded-t-lg last:rounded-b-lg ${
                      selectedCommune === commune
                        ? 'bg-gray-100 text-gray-900 font-medium'
                        : 'text-gray-700 hover:bg-gray-50'
                    }`}
                  >
                    {commune}
                  </button>
                ))}
              </div>
            )}
          </div>
        </div>
      </header>

      <main className="flex-1 overflow-auto px-6 py-6 space-y-5">

        {/* KPI Cards — données réelles du backend */}
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
          <div className="bg-white rounded-xl p-4 border border-gray-100 shadow-sm">
            <div className="text-xs text-gray-500 mb-1">Budget Voté 2026</div>
            <div className="text-xl font-bold text-gray-900">
              {balanceData ? formatFCFA(balanceData.budgetTotal) : '—'}
            </div>
            <div className="text-xs text-gray-400 mt-1">FCFA – Exercice annuel</div>
          </div>
          <div className="bg-white rounded-xl p-4 border border-gray-100 shadow-sm">
            <div className="text-xs text-gray-500 mb-1">Recettes Encaissées</div>
            <div className="text-xl font-bold text-emerald-600">
              +{formatFCFA(totalRecettes)}
            </div>
            <div className="text-xs text-gray-400 mt-1">
              {transactions.filter(t => t.type === 'recette').length} transactions
            </div>
          </div>
          <div className="bg-white rounded-xl p-4 border border-gray-100 shadow-sm">
            <div className="text-xs text-gray-500 mb-1">Dépenses Effectuées</div>
            <div className="text-xl font-bold text-red-500">
              −{formatFCFA(totalDepenses)}
            </div>
            <div className="text-xs text-gray-400 mt-1">
              {balanceData ? `${balanceData.tauxExecution}% du budget` : `${transactions.filter(t => t.type === 'depense').length} transactions`}
            </div>
          </div>
          <div className="bg-white rounded-xl p-4 border border-gray-100 shadow-sm">
            <div className="text-xs text-gray-500 mb-1">Solde Disponible</div>
            <div className={`text-xl font-bold ${solde >= 0 ? 'text-gray-900' : 'text-red-500'}`}>
              {solde >= 0 ? '' : '−'}{formatFCFA(Math.abs(solde))}
            </div>
            <div className="text-xs text-gray-400 mt-1">
              {solde >= 0 ? 'Excédent' : 'Déficit'} communal
            </div>
          </div>
        </div>

        {/* Charts row */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">

          {/* Dépenses par catégorie — données réelles */}
          <div className="bg-white rounded-xl p-5 border border-gray-100 shadow-sm">
            <div className="flex justify-between items-center mb-4">
              <span className="font-semibold text-gray-900 text-sm">Dépenses par catégorie</span>
              <span className="text-xs text-gray-400">{selectedCommune}</span>
            </div>
            {sectors.length === 0 ? (
              <div className="text-center text-sm text-gray-400 py-6">
                Aucune dépense enregistrée
              </div>
            ) : (
              <div className="space-y-3">
                {sectors.map((s) => (
                  <div key={s.name}>
                    <div className="flex justify-between text-xs mb-1">
                      <span className="text-gray-700">{s.name}</span>
                      <span className="text-gray-500">{s.amount}</span>
                    </div>
                    <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
                      <div
                        className="h-full rounded-full transition-all duration-500"
                        style={{ width: `${s.pct}%`, backgroundColor: s.color }}
                      />
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Sources de recettes — données réelles */}
          <div className="bg-white rounded-xl p-5 border border-gray-100 shadow-sm">
            <div className="flex justify-between items-center mb-4">
              <span className="font-semibold text-gray-900 text-sm">Sources de recettes</span>
              <span className="text-xs text-gray-400">Répartition</span>
            </div>
            {revenueSlices.length === 0 ? (
              <div className="text-center text-sm text-gray-400 py-6">
                Aucune recette enregistrée
              </div>
            ) : (
              <div className="flex items-center gap-4">
                <DonutChart slices={revenueSlices} />
                <div className="space-y-2 flex-1">
                  {revenueSlices.map((s) => (
                    <div key={s.label} className="flex items-center gap-2 text-xs">
                      <span className="w-2.5 h-2.5 rounded-full flex-shrink-0" style={{ backgroundColor: s.color }} />
                      <span className="text-gray-700 flex-1 truncate">{s.label}</span>
                      <span className="font-medium text-gray-900">{s.pct}%</span>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Registre des transactions */}
        <div>
          <div className="flex justify-between items-baseline mb-3">
            <span className="font-semibold text-gray-900">
              Registre public des transactions
            </span>
            <span className="text-xs text-gray-400">
              {transactions.length} enregistrement{transactions.length > 1 ? 's' : ''} · Mis à jour {updateLabel}
            </span>
          </div>

          {/* Filtres */}
          <div className="flex gap-2 mb-3 flex-wrap">
            <div className="flex-1 min-w-48 flex items-center gap-2 bg-white border border-gray-200 rounded-lg px-3 py-2">
              <Search size={14} className="text-gray-400 flex-shrink-0" />
              <input
                type="text"
                placeholder="Rechercher une transaction, un service"
                className="text-sm text-gray-600 outline-none bg-transparent w-full placeholder-gray-400"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </div>
            <div className="flex gap-1.5 flex-wrap">
              {(['tous', 'recette', 'depense'] as Filter[]).map((f) => (
                <button
                  key={f}
                  onClick={() => setFilter(f)}
                  className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                    filter === f
                      ? 'bg-gray-900 text-white'
                      : 'bg-white border border-gray-200 text-gray-600 hover:bg-gray-50'
                  }`}
                >
                  {f === 'tous' ? 'Tous' : f === 'recette' ? 'Recettes' : 'Dépenses'}
                </button>
              ))}
              <button
                onClick={() => setShowDateModal(true)}
                className={`flex items-center gap-1.5 px-3 py-2 rounded-lg text-sm transition-colors ${
                  dateFrom || dateTo
                    ? 'bg-gray-900 text-white'
                    : 'bg-white border border-gray-200 text-gray-600 hover:bg-gray-50'
                }`}
              >
                <SlidersHorizontal size={14} />
                Filtre (Date)
              </button>
            </div>
          </div>

          {/* Liste des transactions */}
          <div className="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
            {loading && transactions.length === 0 && (
              <div className="py-10 text-center text-sm text-gray-400">
                Chargement des données blockchain...
              </div>
            )}
            {!loading && filtered.length === 0 && (
              <div className="py-10 text-center text-sm text-gray-400">
                Aucune transaction trouvée
              </div>
            )}
            {filtered.map((tx, idx) => (
              <div
                key={tx.id}
                className={`flex items-center gap-4 px-5 py-4 ${
                  idx < filtered.length - 1 ? 'border-b border-gray-100' : ''
                } hover:bg-gray-50 transition-colors`}
              >
                <div className={`w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0 ${
                  tx.positive ? 'bg-emerald-50' : 'bg-red-50'
                }`}>
                  {tx.positive
                    ? <TrendingUp size={18} className="text-emerald-600" />
                    : <TrendingDown size={18} className="text-red-500" />
                  }
                </div>
                <div className="flex-1 min-w-0">
                  <div className="font-medium text-gray-900 text-sm">{tx.title}</div>
                  <div className="text-xs text-gray-400 mt-0.5">
                    {tx.date} · {tx.dept}
                    {tx.hash && (
                      <a
                        href={`https://amoy.polygonscan.com/tx/${tx.hash}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="ml-2 text-emerald-600 hover:underline"
                      >
                        ⛓ voir preuve
                      </a>
                    )}
                  </div>
                </div>
                <div className={`text-sm font-semibold flex-shrink-0 ${tx.positive ? 'text-emerald-600' : 'text-red-500'}`}>
                  {tx.amount}
                </div>
              </div>
            ))}
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="bg-gray-900 text-gray-400 text-center text-sm py-5 flex-shrink-0">
        tableau de bord public citoyen © 2026 · données blockchain immuables sur Polygon Amoy
      </footer>

      {/* Modal filtre date */}
      {showDateModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl shadow-lg max-w-sm w-full mx-4">
            <div className="flex items-center justify-between p-5 border-b border-gray-100">
              <h2 className="font-semibold text-gray-900">Filtrer par date</h2>
              <button onClick={() => setShowDateModal(false)} className="text-gray-400 hover:text-gray-600 transition-colors">
                <X size={18} />
              </button>
            </div>
            <div className="p-5 space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">À partir du</label>
                <input
                  type="date" value={dateFrom}
                  onChange={(e) => setDateFrom(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-gray-900"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Jusqu'au</label>
                <input
                  type="date" value={dateTo}
                  onChange={(e) => setDateTo(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-gray-900"
                />
              </div>
            </div>
            <div className="flex gap-2 p-5 border-t border-gray-100">
              <button
                onClick={() => { setDateFrom(''); setDateTo(''); }}
                className="flex-1 px-4 py-2 border border-gray-200 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-50 transition-colors"
              >
                Réinitialiser
              </button>
              <button
                onClick={() => setShowDateModal(false)}
                className="flex-1 px-4 py-2 bg-gray-900 text-white rounded-lg text-sm font-medium hover:bg-gray-800 transition-colors"
              >
                Appliquer
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}