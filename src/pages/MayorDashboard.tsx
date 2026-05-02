import React, { useState } from 'react';
import { LogOut, BarChart3, TrendingUp, Calendar, Search, Filter } from 'lucide-react';

interface MayorDashboardProps {
  onLogout: () => void;
}

interface Transaction {
  id: string;
  date: string;
  description: string;
  category: string;
  amount: number;
  type: 'recette' | 'dépense';
  department: string;
  status: 'validé' | 'en attente' | 'rejeté';
}

export const MayorDashboard: React.FC<MayorDashboardProps> = ({ onLogout }) => {
  const [timeFilter, setTimeFilter] = useState('month');
  const [searchTerm, setSearchTerm] = useState('');
  const [categoryFilter, setategoryFilter] = useState<string | null>(null);

  const transactions: Transaction[] = [
    {
      id: '1',
      date: '2024-05-02',
      description: 'Recette fiscale - Impôts locaux',
      category: 'Fiscalité',
      amount: 45000,
      type: 'recette',
      department: 'Finances',
      status: 'validé',
    },
    {
      id: '2',
      date: '2024-05-01',
      description: 'Subvention État - Équipements',
      category: 'Subventions',
      amount: 12500,
      type: 'recette',
      department: 'Développement',
      status: 'validé',
    },
    {
      id: '3',
      date: '2024-04-30',
      description: 'Dépense - Travaux rue principale',
      category: 'Infrastructure',
      amount: 8750,
      type: 'dépense',
      department: 'Travaux Publics',
      status: 'validé',
    },
    {
      id: '4',
      date: '2024-04-28',
      description: 'Recette - Droits d\'occupation domaine',
      category: 'Domaine',
      amount: 3200,
      type: 'recette',
      department: 'Domaine',
      status: 'validé',
    },
    {
      id: '5',
      date: '2024-04-27',
      description: 'Dépense - Entretien des espaces verts',
      category: 'Maintenance',
      amount: 2150,
      type: 'dépense',
      department: 'Environnement',
      status: 'validé',
    },
    {
      id: '6',
      date: '2024-04-25',
      description: 'Recette - Partenariats commerciaux',
      category: 'Partenariats',
      amount: 5600,
      type: 'recette',
      department: 'Partenariats',
      status: 'en attente',
    },
    {
      id: '7',
      date: '2024-04-23',
      description: 'Dépense - Salaires et charges',
      category: 'Ressources Humaines',
      amount: 125000,
      type: 'dépense',
      department: 'RH',
      status: 'validé',
    },
    {
      id: '8',
      date: '2024-04-20',
      description: 'Recette - Service publics',
      category: 'Services',
      amount: 7850,
      type: 'recette',
      department: 'Services',
      status: 'validé',
    },
  ];

  const filteredTransactions = transactions.filter((t) => {
    const matchesSearch =
      t.description.toLowerCase().includes(searchTerm.toLowerCase()) ||
      t.department.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesCategory = !categoryFilter || t.category === categoryFilter;
    return matchesSearch && matchesCategory;
  });

  const totalRecettes = transactions
    .filter((t) => t.type === 'recette')
    .reduce((sum, t) => sum + t.amount, 0);

  const totalDépenses = transactions
    .filter((t) => t.type === 'dépense')
    .reduce((sum, t) => sum + t.amount, 0);

  const balance = totalRecettes - totalDépenses;

  const categories = Array.from(new Set(transactions.map((t) => t.category)));

  return (
    <div className="min-h-screen bg-gradient-to-br from-teal-50 via-white to-emerald-50">
      {/* Header */}
      <header className="bg-gradient-to-r from-teal-600 to-teal-700 px-8 py-4 flex items-center justify-between shadow-lg">
        <div className="flex items-center gap-4">
          <img src="/image.png" alt="Logo" className="h-12 w-12 drop-shadow-lg" />
          <div>
            <h1 className="text-2xl font-bold text-white">Budget Ouvert - Maire</h1>
            <p className="text-sm text-teal-100">Reporting des Finances Municipales</p>
          </div>
        </div>
        <button
          onClick={onLogout}
          className="flex items-center gap-2 px-4 py-2 bg-white/20 text-white hover:bg-white/30 rounded-lg transition font-medium"
        >
          <LogOut className="h-5 w-5" />
          Déconnexion
        </button>
      </header>

      {/* Main Content */}
      <main className="p-8">
        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <StatsCard
            title="Total Recettes"
            amount={totalRecettes}
            icon={<TrendingUp className="h-8 w-8" />}
            color="from-emerald-500 to-emerald-600"
            bgColor="bg-emerald-50"
          />
          <StatsCard
            title="Total Dépenses"
            amount={totalDépenses}
            icon={<BarChart3 className="h-8 w-8" />}
            color="from-orange-500 to-orange-600"
            bgColor="bg-orange-50"
          />
          <StatsCard
            title="Solde Net"
            amount={balance}
            icon={<Calendar className="h-8 w-8" />}
            color={balance >= 0 ? 'from-teal-500 to-teal-600' : 'from-red-500 to-red-600'}
            bgColor={balance >= 0 ? 'bg-teal-50' : 'bg-red-50'}
          />
        </div>

        {/* Filters and Search */}
        <div className="bg-white rounded-lg shadow-lg p-6 mb-6 border border-teal-100">
          <div className="flex flex-col md:flex-row gap-4 items-end">
            <div className="flex-1">
              <label className="block text-sm font-semibold text-gray-700 mb-2">Recherche</label>
              <div className="relative">
                <Search className="absolute left-3 top-3 h-5 w-5 text-gray-400" />
                <input
                  type="text"
                  placeholder="Rechercher par description ou département..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 outline-none"
                />
              </div>
            </div>
            <div className="flex-1">
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                <Filter className="inline h-4 w-4 mr-2" />
                Catégorie
              </label>
              <select
                value={categoryFilter || ''}
                onChange={(e) => setategoryFilter(e.target.value || null)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 outline-none"
              >
                <option value="">Toutes les catégories</option>
                {categories.map((cat) => (
                  <option key={cat} value={cat}>
                    {cat}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">Période</label>
              <select
                value={timeFilter}
                onChange={(e) => setTimeFilter(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 outline-none"
              >
                <option value="week">Cette semaine</option>
                <option value="month">Ce mois</option>
                <option value="quarter">Ce trimestre</option>
                <option value="year">Cette année</option>
              </select>
            </div>
          </div>
        </div>

        {/* Transactions Table */}
        <div className="bg-white rounded-lg shadow-lg overflow-hidden border border-teal-100">
          <div className="p-6 border-b border-gray-200">
            <h2 className="text-xl font-bold text-gray-900">Détail des Transactions</h2>
            <p className="text-sm text-gray-600 mt-1">
              {filteredTransactions.length} transaction{filteredTransactions.length > 1 ? 's' : ''} trouvée
              {filteredTransactions.length > 1 ? 's' : ''}
            </p>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr>
                  <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">Date</th>
                  <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">Description</th>
                  <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">Catégorie</th>
                  <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">Département</th>
                  <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">Type</th>
                  <th className="px-6 py-3 text-right text-sm font-semibold text-gray-900">Montant</th>
                  <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">Statut</th>
                </tr>
              </thead>
              <tbody>
                {filteredTransactions.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="px-6 py-8 text-center text-gray-600">
                      Aucune transaction trouvée
                    </td>
                  </tr>
                ) : (
                  filteredTransactions.map((transaction) => (
                    <tr key={transaction.id} className="border-b border-gray-200 hover:bg-gray-50 transition">
                      <td className="px-6 py-4 text-sm text-gray-900">
                        {new Date(transaction.date).toLocaleDateString('fr-FR')}
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-900 font-medium">{transaction.description}</td>
                      <td className="px-6 py-4 text-sm">
                        <span className="px-3 py-1 bg-teal-100 text-teal-800 rounded-full text-xs font-medium">
                          {transaction.category}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-600">{transaction.department}</td>
                      <td className="px-6 py-4 text-sm">
                        <span
                          className={`inline-block px-3 py-1 rounded-full text-xs font-medium ${
                            transaction.type === 'recette'
                              ? 'bg-emerald-100 text-emerald-800'
                              : 'bg-orange-100 text-orange-800'
                          }`}
                        >
                          {transaction.type === 'recette' ? '+ Recette' : '- Dépense'}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-right text-sm font-semibold text-gray-900">
                        <span className={transaction.type === 'recette' ? 'text-emerald-600' : 'text-orange-600'}>
                          {transaction.type === 'recette' ? '+' : '-'} {transaction.amount.toLocaleString('fr-FR')} €
                        </span>
                      </td>
                      <td className="px-6 py-4 text-sm">
                        <StatusBadge status={transaction.status} />
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>

          {/* Summary Footer */}
          <div className="bg-gray-50 px-6 py-4 border-t border-gray-200 grid grid-cols-3 gap-4">
            <div>
              <p className="text-xs text-gray-600 uppercase font-semibold">Recettes affichées</p>
              <p className="text-lg font-bold text-emerald-600">
                +{filteredTransactions
                  .filter((t) => t.type === 'recette')
                  .reduce((sum, t) => sum + t.amount, 0)
                  .toLocaleString('fr-FR')} €
              </p>
            </div>
            <div>
              <p className="text-xs text-gray-600 uppercase font-semibold">Dépenses affichées</p>
              <p className="text-lg font-bold text-orange-600">
                -{filteredTransactions
                  .filter((t) => t.type === 'dépense')
                  .reduce((sum, t) => sum + t.amount, 0)
                  .toLocaleString('fr-FR')} €
              </p>
            </div>
            <div>
              <p className="text-xs text-gray-600 uppercase font-semibold">Solde filtré</p>
              <p
                className={`text-lg font-bold ${
                  filteredTransactions.reduce((sum, t) => sum + (t.type === 'recette' ? t.amount : -t.amount), 0) >= 0
                    ? 'text-teal-600'
                    : 'text-red-600'
                }`}
              >
                {filteredTransactions.reduce((sum, t) => sum + (t.type === 'recette' ? t.amount : -t.amount), 0) >= 0
                  ? '+'
                  : '-'}
                {Math.abs(
                  filteredTransactions.reduce((sum, t) => sum + (t.type === 'recette' ? t.amount : -t.amount), 0)
                ).toLocaleString('fr-FR')}{' '}
                €
              </p>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
};

interface StatsCardProps {
  title: string;
  amount: number;
  icon: React.ReactNode;
  color: string;
  bgColor: string;
}

const StatsCard: React.FC<StatsCardProps> = ({ title, amount, icon, color, bgColor }) => (
  <div className={`${bgColor} rounded-lg p-6 border border-gray-200`}>
    <div className="flex items-center justify-between">
      <div>
        <p className="text-gray-600 text-sm font-medium">{title}</p>
        <p className="text-3xl font-bold text-gray-900 mt-2">{amount.toLocaleString('fr-FR')} €</p>
      </div>
      <div className={`bg-gradient-to-br ${color} p-3 rounded-lg text-white`}>{icon}</div>
    </div>
  </div>
);

interface StatusBadgeProps {
  status: 'validé' | 'en attente' | 'rejeté';
}

const StatusBadge: React.FC<StatusBadgeProps> = ({ status }) => {
  const statusConfig = {
    validé: { bg: 'bg-green-100', text: 'text-green-800', label: 'Validé' },
    'en attente': { bg: 'bg-yellow-100', text: 'text-yellow-800', label: 'En attente' },
    rejeté: { bg: 'bg-red-100', text: 'text-red-800', label: 'Rejeté' },
  };

  const config = statusConfig[status];
  return <span className={`px-3 py-1 ${config.bg} ${config.text} rounded-full text-xs font-medium`}>{config.label}</span>;
};
