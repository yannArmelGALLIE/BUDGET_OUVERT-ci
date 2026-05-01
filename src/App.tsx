import { useState, useRef, useEffect } from 'react';
import { Search, SlidersHorizontal, User, ChevronDown, TrendingUp, TrendingDown, X } from 'lucide-react';

const communes = [
  'Abidjan – Commune d\'Abobo',
  'Abidjan – Commune d\'Adjamé',
  'Abidjan – Commune de Cocody',
  'Abidjan – Commune de Plateau',
  'Abidjan – Commune de Port-Bouët',
  'Abidjan – Commune de Treichville',
  'Abidjan – Commune de Yopougon',
];

const sectors = [
  { name: 'Voirie & Travaux', amount: '712 Million Fcfa', color: '#1a3a1a', pct: 89 },
  { name: 'Education', amount: '584 Million Fcfa', color: '#2d6a2d', pct: 73 },
  { name: 'Santé', amount: '375 Million Fcfa', color: '#7b2d8b', pct: 47 },
  { name: 'Social et Culture', amount: '87 Million Fcfa', color: '#e07b20', pct: 11 },
];

const revenueSlices = [
  { label: 'Taxes locales', pct: 40, color: '#1a3a1a' },
  { label: 'Subv. Etat', pct: 22, color: '#3d7a3d' },
  { label: 'Marchés', pct: 12, color: '#2d2d5e' },
  { label: 'Autre', pct: 11, color: '#b0b0b0' },
];

const transactions = [
  {
    id: 1,
    title: 'Taxe foncière',
    date: '23 avril 2026',
    time: '09h42',
    dept: 'Dir. Financière',
    amount: '+4 500 000 FCFA',
    positive: true,
    type: 'recette',
  },
  {
    id: 2,
    title: 'Réhabilitation voirie',
    date: '23 avril 2025',
    time: '09h42',
    dept: 'Service Technique',
    amount: '-5 400 000 FCFA',
    positive: false,
    type: 'depense',
  },
  {
    id: 3,
    title: 'Subvention État – Trimestre 1 / 2026',
    date: '20 avril 2026',
    time: '10h05',
    dept: 'Dir. Financière',
    amount: '+12 000 000 FCFA',
    positive: true,
    type: 'recette',
  },
  {
    id: 4,
    title: 'Salaires agents communaux – Avril',
    date: '15 avril 2026',
    time: '08h30',
    dept: 'RH Commune',
    amount: '-3 200 000 FCFA',
    positive: false,
    type: 'depense',
  },
  {
    id: 5,
    title: 'Patente commerciale',
    date: '14 avril 2026',
    time: '11h22',
    dept: 'Régie Communale',
    amount: '+1 850 000 FCFA',
    positive: true,
    type: 'recette',
  },
];

function DonutChart() {
  const total = revenueSlices.reduce((s, r) => s + r.pct, 0);
  const r = 52;
  const cx = 70;
  const cy = 70;
  const circumference = 2 * Math.PI * r;
  let cumulative = 0;

  return (
    <svg width="140" height="140" viewBox="0 0 140 140">
      {revenueSlices.map((slice) => {
        const offset = circumference * (1 - cumulative / total);
        const dash = (slice.pct / total) * circumference;
        const gap = circumference - dash;
        const el = (
          <circle
            key={slice.label}
            cx={cx}
            cy={cy}
            r={r}
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
    </svg>
  );
}

type Filter = 'tous' | 'recette' | 'depense';

export default function App() {
  const [filter, setFilter] = useState<Filter>('tous');
  const [search, setSearch] = useState('');
  const [showDateModal, setShowDateModal] = useState(false);
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [selectedCommune, setSelectedCommune] = useState(communes[0]);
  const [showCommuneMenu, setShowCommuneMenu] = useState(false);
  const communeMenuRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (communeMenuRef.current && !communeMenuRef.current.contains(e.target as Node)) {
        setShowCommuneMenu(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const parseDate = (dateStr: string): Date | null => {
    if (!dateStr) return null;
    const parts = dateStr.split(' ');
    const dayMap: { [key: string]: number } = {
      janvier: 1, février: 2, mars: 3, avril: 4, mai: 5, juin: 6,
      juillet: 7, août: 8, septembre: 9, octobre: 10, novembre: 11, décembre: 12,
    };
    if (parts.length === 3) {
      const day = parseInt(parts[0]);
      const month = dayMap[parts[1].toLowerCase()];
      const year = parseInt(parts[2]);
      if (month) return new Date(year, month - 1, day);
    }
    return null;
  };

  const filtered = transactions.filter((t) => {
    const matchFilter = filter === 'tous' || t.type === filter;
    const matchSearch =
      search === '' ||
      t.title.toLowerCase().includes(search.toLowerCase()) ||
      t.dept.toLowerCase().includes(search.toLowerCase());

    let matchDate = true;
    if (dateFrom || dateTo) {
      const tDate = parseDate(t.date);
      const fromDate = dateFrom ? new Date(dateFrom) : null;
      const toDate = dateTo ? new Date(dateTo) : null;

      if (fromDate && tDate && tDate < fromDate) matchDate = false;
      if (toDate && tDate && tDate > toDate) matchDate = false;
    }

    return matchFilter && matchSearch && matchDate;
  });

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
            <div className="absolute right-0 mt-2 bg-white border border-gray-200 rounded-lg shadow-lg z-10 min-w-64">
              {communes.map((commune) => (
                <button
                  key={commune}
                  onClick={() => {
                    setSelectedCommune(commune);
                    setShowCommuneMenu(false);
                  }}
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
      </header>

      <main className="flex-1 overflow-auto px-6 py-6 space-y-5">
        {/* KPI Cards */}
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
          <div className="bg-white rounded-xl p-4 border border-gray-100 shadow-sm">
            <div className="text-xs text-gray-500 mb-1">Budget Voté 2026</div>
            <div className="text-xl font-bold text-gray-900">4,2 Milliard</div>
            <div className="text-xs text-gray-400 mt-1">FCFA – Exercice annuel</div>
          </div>
          <div className="bg-white rounded-xl p-4 border border-gray-100 shadow-sm">
            <div className="text-xs text-gray-500 mb-1">Recette Encaissées</div>
            <div className="text-xl font-bold text-emerald-600">+2,56 Milliard</div>
            <div className="text-xs text-gray-400 mt-1">61 % de l'objectif</div>
          </div>
          <div className="bg-white rounded-xl p-4 border border-gray-100 shadow-sm">
            <div className="text-xs text-gray-500 mb-1">Dépense Effectuées</div>
            <div className="text-xl font-bold text-red-500">−1,97 Milliard</div>
            <div className="text-xs text-gray-400 mt-1">47 % du budget ouvert</div>
          </div>
          <div className="bg-white rounded-xl p-4 border border-gray-100 shadow-sm">
            <div className="text-xs text-gray-500 mb-1">Solde Disponible</div>
            <div className="text-xl font-bold text-gray-900">590 Million</div>
          </div>
        </div>

        {/* Charts row */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          {/* Dépense par secteur */}
          <div className="bg-white rounded-xl p-5 border border-gray-100 shadow-sm">
            <div className="flex justify-between items-center mb-4">
              <span className="font-semibold text-gray-900 text-sm">Dépense par secteur</span>
              <span className="text-xs text-gray-400">Cumul 2026</span>
            </div>
            <div className="space-y-3">
              {sectors.map((s) => (
                <div key={s.name}>
                  <div className="flex justify-between text-xs mb-1">
                    <span className="text-gray-700">{s.name}</span>
                    <span className="text-gray-500">{s.amount}</span>
                  </div>
                  <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
                    <div
                      className="h-full rounded-full transition-all"
                      style={{ width: `${s.pct}%`, backgroundColor: s.color }}
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Sources de recettes */}
          <div className="bg-white rounded-xl p-5 border border-gray-100 shadow-sm">
            <div className="flex justify-between items-center mb-4">
              <span className="font-semibold text-gray-900 text-sm">Sources de recettes</span>
              <span className="text-xs text-gray-400">Répartition</span>
            </div>
            <div className="flex items-center gap-4">
              <DonutChart />
              <div className="space-y-2 flex-1">
                {revenueSlices.map((s) => (
                  <div key={s.label} className="flex items-center gap-2 text-xs">
                    <span
                      className="w-2.5 h-2.5 rounded-full flex-shrink-0"
                      style={{ backgroundColor: s.color }}
                    />
                    <span className="text-gray-700 flex-1">{s.label}</span>
                    <span className="font-medium text-gray-900">{s.pct} %</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* Transaction register */}
        <div>
          <div className="flex justify-between items-baseline mb-3">
            <span className="font-semibold text-gray-900">Régistre public des transactions</span>
            <span className="text-xs text-gray-400">
              1 248 enregistrements · Dernière mise à jour il y a 3 min
            </span>
          </div>

          {/* Search + filters */}
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

          {/* Transactions list */}
          <div className="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
            {filtered.map((tx, idx) => (
              <div
                key={tx.id}
                className={`flex items-center gap-4 px-5 py-4 ${
                  idx < filtered.length - 1 ? 'border-b border-gray-100' : ''
                } hover:bg-gray-50 transition-colors cursor-pointer`}
              >
                <div
                  className={`w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0 ${
                    tx.positive ? 'bg-emerald-50' : 'bg-red-50'
                  }`}
                >
                  {tx.positive ? (
                    <TrendingUp size={18} className="text-emerald-600" />
                  ) : (
                    <TrendingDown size={18} className="text-red-500" />
                  )}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="font-medium text-gray-900 text-sm">{tx.title}</div>
                  <div className="text-xs text-gray-400 mt-0.5">
                    {tx.date} · {tx.time} · {tx.dept}
                  </div>
                </div>
                <div
                  className={`text-sm font-semibold flex-shrink-0 ${
                    tx.positive ? 'text-emerald-600' : 'text-red-500'
                  }`}
                >
                  {tx.amount}
                </div>
              </div>
            ))}
            {filtered.length === 0 && (
              <div className="py-10 text-center text-sm text-gray-400">Aucune transaction trouvée</div>
            )}
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="bg-gray-900 text-gray-400 text-center text-sm py-5 flex-shrink-0">
        tableau de bord public citoyen © 2026
      </footer>

      {/* Date filter modal */}
      {showDateModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl shadow-lg max-w-sm w-full mx-4">
            <div className="flex items-center justify-between p-5 border-b border-gray-100">
              <h2 className="font-semibold text-gray-900">Filtrer par date</h2>
              <button
                onClick={() => setShowDateModal(false)}
                className="text-gray-400 hover:text-gray-600 transition-colors"
              >
                <X size={18} />
              </button>
            </div>

            <div className="p-5 space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  À partir du
                </label>
                <input
                  type="date"
                  value={dateFrom}
                  onChange={(e) => setDateFrom(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-gray-900"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Jusqu'au
                </label>
                <input
                  type="date"
                  value={dateTo}
                  onChange={(e) => setDateTo(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-gray-900"
                />
              </div>
            </div>

            <div className="flex gap-2 p-5 border-t border-gray-100">
              <button
                onClick={() => {
                  setDateFrom('');
                  setDateTo('');
                }}
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
