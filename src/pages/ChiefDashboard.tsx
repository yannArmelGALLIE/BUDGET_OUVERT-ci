import React, { useState } from 'react';
import { LogOut, ChevronDown, Plus, Edit2, Trash2, Send, MapPin, Phone, AlertCircle, CheckCircle, Clock, Users } from 'lucide-react';

interface ChiefDashboardProps {
  onLogout: () => void;
}

interface Complaint {
  id: string;
  date: string;
  title: string;
  description: string;
  location: string;
  phone: string;
  image: string;
  priority: 'urgent' | 'normal' | 'basse';
  status: 'nouveau' | 'en cours' | 'résolu';
  category: string;
}

interface Team {
  id: string;
  name: string;
  members: number;
  specialization: string;
}

interface Assignment {
  id: string;
  complaintId: string;
  complaintTitle: string;
  teams: string[];
  status: 'assignée' | 'en cours' | 'complétée';
  budget: number;
  startDate: string;
  notes: string;
}

export const ChiefDashboard: React.FC<ChiefDashboardProps> = ({ onLogout }) => {
  const [expandedComplaintId, setExpandedComplaintId] = useState<string | null>(null);
  const [selectedComplaintId, setSelectedComplaintId] = useState<string | null>(null);
  const [showAssignmentForm, setShowAssignmentForm] = useState(false);
  const [assignments, setAssignments] = useState<Assignment[]>([
    {
      id: '1',
      complaintId: '1',
      complaintTitle: 'Nid de poule rue principale',
      teams: ['Équipe Voirie 1', 'Équipe Équipements'],
      status: 'en cours',
      budget: 2500,
      startDate: '2024-04-28',
      notes: 'Réparation en cours, fermeture partielle de la rue',
    },
  ]);

  const [formData, setFormData] = useState({
    complaintId: '',
    teams: [] as string[],
    budget: '',
    startDate: '',
    notes: '',
  });

  const complaints: Complaint[] = [
    {
      id: '1',
      date: '2024-05-02',
      title: 'Nid de poule rue principale',
      description:
        'Un grand nid de poule s\'est formé sur la chaussée au niveau du croisement avec la rue de la Mairie. Danger pour les véhicules et piétons.',
      location: 'Rue Principale, Croisement rue de la Mairie',
      phone: '06 12 34 56 78',
      image: 'https://images.pexels.com/photos/3962286/pexels-photo-3962286.jpeg?auto=compress&cs=tinysrgb&w=400',
      priority: 'urgent',
      status: 'en cours',
      category: 'Infrastructure',
    },
    {
      id: '2',
      date: '2024-05-01',
      title: 'Éclairage public défaillant',
      description:
        'Plusieurs lampadaires ne fonctionnent plus dans la rue des Fleurs. L\'éclairage est très faible en soirée, créant un sentiment d\'insécurité.',
      location: 'Rue des Fleurs',
      phone: '06 98 76 54 32',
      image: 'https://images.pexels.com/photos/5235812/pexels-photo-5235812.jpeg?auto=compress&cs=tinysrgb&w=400',
      priority: 'normal',
      status: 'nouveau',
      category: 'Éclairage',
    },
    {
      id: '3',
      date: '2024-04-30',
      title: 'Poubelles débordantes parc central',
      description:
        'Les poubelles du parc central sont constamment pleines. Les déchets s\'accumulent autour, attirant les rongeurs et créant une nuisance sanitaire.',
      location: 'Parc Central',
      phone: '06 45 67 89 01',
      image: 'https://images.pexels.com/photos/3807517/pexels-photo-3807517.jpeg?auto=compress&cs=tinysrgb&w=400',
      priority: 'normal',
      status: 'nouveau',
      category: 'Nettoyage',
    },
    {
      id: '4',
      date: '2024-04-29',
      title: 'Arbres mal entretenus',
      description:
        'Les arbres de l\'avenue centrale ont besoin d\'un entretien urgent. Plusieurs branches mortes créent un risque de chute. Demande de taille et élagage.',
      location: 'Avenue Centrale',
      phone: '06 23 45 67 89',
      image: 'https://images.pexels.com/photos/3571547/pexels-photo-3571547.jpeg?auto=compress&cs=tinysrgb&w=400',
      priority: 'urgent',
      status: 'nouveau',
      category: 'Environnement',
    },
    {
      id: '5',
      date: '2024-04-28',
      title: 'Trottoir endommagé',
      description:
        'Le trottoir près de la mairie présente des fissures importantes et des dénivellations dangereuses pour les piétons, particulièrement les personnes âgées et handicapées.',
      location: 'Rue de la Mairie, devant mairie',
      phone: '06 56 78 90 12',
      image: 'https://images.pexels.com/photos/3808220/pexels-photo-3808220.jpeg?auto=compress&cs=tinysrgb&w=400',
      priority: 'urgent',
      status: 'nouveau',
      category: 'Infrastructure',
    },
  ];

  const availableTeams: Team[] = [
    { id: '1', name: 'Équipe Voirie 1', members: 6, specialization: 'Routes et chaussées' },
    { id: '2', name: 'Équipe Voirie 2', members: 5, specialization: 'Routes et chaussées' },
    { id: '3', name: 'Équipe Équipements', members: 4, specialization: 'Éclairage et mobilier' },
    { id: '4', name: 'Équipe Environnement', members: 5, specialization: 'Espaces verts et nettoyage' },
    { id: '5', name: 'Équipe Maintenance', members: 3, specialization: 'Réparations générales' },
  ];

  const handleAssignComplaint = (complaintId: string) => {
    setSelectedComplaintId(complaintId);
    setShowAssignmentForm(true);
  };

  const handleSubmitAssignment = () => {
    if (selectedComplaintId && formData.teams.length > 0 && formData.budget && formData.startDate) {
      const complaint = complaints.find((c) => c.id === selectedComplaintId);
      const newAssignment: Assignment = {
        id: Date.now().toString(),
        complaintId: selectedComplaintId,
        complaintTitle: complaint?.title || '',
        teams: formData.teams,
        status: 'assignée',
        budget: parseInt(formData.budget),
        startDate: formData.startDate,
        notes: formData.notes,
      };

      setAssignments([...assignments, newAssignment]);
      setShowAssignmentForm(false);
      setSelectedComplaintId(null);
      setFormData({
        complaintId: '',
        teams: [],
        budget: '',
        startDate: '',
        notes: '',
      });
    }
  };

  const handleDeleteAssignment = (assignmentId: string) => {
    setAssignments(assignments.filter((a) => a.id !== assignmentId));
  };

  const toggleTeamSelection = (teamName: string) => {
    setFormData((prev) => ({
      ...prev,
      teams: prev.teams.includes(teamName)
        ? prev.teams.filter((t) => t !== teamName)
        : [...prev.teams, teamName],
    }));
  };

  const newComplaints = complaints.filter((c) => c.status === 'nouveau');
  const inProgressComplaints = complaints.filter((c) => c.status === 'en cours');
  const resolvedComplaints = complaints.filter((c) => c.status === 'résolu');

  const totalBudgetAssigned = assignments.reduce((sum, a) => sum + a.budget, 0);

  return (
    <div className="min-h-screen bg-gradient-to-br from-teal-50 via-white to-emerald-50">
      {/* Header */}
      <header className="bg-gradient-to-r from-teal-600 to-teal-700 px-8 py-4 flex items-center justify-between shadow-lg">
        <div className="flex items-center gap-4">
          <img src="/image.png" alt="Logo" className="h-12 w-12 drop-shadow-lg" />
          <div>
            <h1 className="text-2xl font-bold text-white">Budget Ouvert - Chef de Service</h1>
            <p className="text-sm text-teal-100">Gestion des Plaintes et Assignation d'Équipes</p>
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
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <StatCard
            title="Plaintes Nouvelles"
            value={newComplaints.length}
            icon={<AlertCircle className="h-8 w-8" />}
            bgColor="bg-red-50"
            color="from-red-500 to-red-600"
          />
          <StatCard
            title="En Cours"
            value={inProgressComplaints.length}
            icon={<Clock className="h-8 w-8" />}
            bgColor="bg-yellow-50"
            color="from-yellow-500 to-yellow-600"
          />
          <StatCard
            title="Résolues"
            value={resolvedComplaints.length}
            icon={<CheckCircle className="h-8 w-8" />}
            bgColor="bg-emerald-50"
            color="from-emerald-500 to-emerald-600"
          />
          <StatCard
            title="Budget Assigné"
            value={`${totalBudgetAssigned.toLocaleString('fr-FR')} €`}
            icon={<Users className="h-8 w-8" />}
            bgColor="bg-teal-50"
            color="from-teal-500 to-teal-600"
          />
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Plaintes Section - 2 columns */}
          <div className="lg:col-span-2 space-y-6">
            <h2 className="text-2xl font-bold text-gray-900">Plaintes Signalées</h2>

            {/* Plaintes Grid */}
            <div className="grid grid-cols-1 gap-6">
              {complaints.map((complaint) => (
                <div
                  key={complaint.id}
                  className="bg-white rounded-lg shadow-lg border border-teal-100 overflow-hidden hover:shadow-xl transition"
                >
                  <div className="grid grid-cols-1 md:grid-cols-4 gap-4 p-6">
                    {/* Image */}
                    <div className="md:col-span-1">
                      <img
                        src={complaint.image}
                        alt={complaint.title}
                        className="w-full h-40 object-cover rounded-lg"
                      />
                    </div>

                    {/* Content */}
                    <div className="md:col-span-2 space-y-3">
                      <div className="flex items-start justify-between">
                        <div>
                          <h3 className="text-lg font-bold text-gray-900">{complaint.title}</h3>
                          <p className="text-sm text-gray-600 mt-1">{complaint.category}</p>
                        </div>
                        <PriorityBadge priority={complaint.priority} />
                      </div>

                      <p className="text-gray-700 text-sm line-clamp-2">{complaint.description}</p>

                      <div className="space-y-1 text-sm text-gray-600">
                        <div className="flex items-center gap-2">
                          <MapPin className="h-4 w-4 text-teal-600" />
                          {complaint.location}
                        </div>
                        <div className="flex items-center gap-2">
                          <Phone className="h-4 w-4 text-teal-600" />
                          {complaint.phone}
                        </div>
                      </div>

                      <div className="flex items-center gap-2">
                        <span className={`px-2 py-1 rounded text-xs font-medium ${getStatusColor(complaint.status)}`}>
                          {complaint.status === 'nouveau'
                            ? 'Nouveau'
                            : complaint.status === 'en cours'
                              ? 'En cours'
                              : 'Résolu'}
                        </span>
                        <span className="text-xs text-gray-500">{complaint.date}</span>
                      </div>

                      {/* Expandable Description */}
                      {expandedComplaintId === complaint.id && (
                        <div className="mt-4 pt-4 border-t border-gray-200">
                          <p className="text-gray-700 text-sm">{complaint.description}</p>
                        </div>
                      )}
                    </div>

                    {/* Actions */}
                    <div className="md:col-span-1 flex flex-col gap-2">
                      <button
                        onClick={() =>
                          setExpandedComplaintId(
                            expandedComplaintId === complaint.id ? null : complaint.id
                          )
                        }
                        className="w-full px-3 py-2 bg-gray-100 text-gray-900 rounded-lg hover:bg-gray-200 transition text-sm font-medium"
                      >
                        <ChevronDown className="h-4 w-4 inline mr-1" />
                        Détails
                      </button>
                      {complaint.status === 'nouveau' && (
                        <button
                          onClick={() => handleAssignComplaint(complaint.id)}
                          className="w-full px-3 py-2 bg-gradient-to-r from-teal-600 to-teal-700 text-white rounded-lg hover:from-teal-700 hover:to-teal-800 transition text-sm font-medium"
                        >
                          <Plus className="h-4 w-4 inline mr-1" />
                          Assigner
                        </button>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Assignments Section - 1 column */}
          <div className="space-y-6">
            <h2 className="text-2xl font-bold text-gray-900">Assignations</h2>

            {/* Assignment Form */}
            {showAssignmentForm && selectedComplaintId && (
              <div className="bg-white rounded-lg shadow-lg border border-teal-100 p-6 space-y-4">
                <h3 className="font-bold text-gray-900">
                  {complaints.find((c) => c.id === selectedComplaintId)?.title}
                </h3>

                {/* Teams Selection */}
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-2">Équipes</label>
                  <div className="space-y-2 max-h-32 overflow-y-auto">
                    {availableTeams.map((team) => (
                      <label key={team.id} className="flex items-center gap-3 p-2 hover:bg-gray-50 cursor-pointer">
                        <input
                          type="checkbox"
                          checked={formData.teams.includes(team.name)}
                          onChange={() => toggleTeamSelection(team.name)}
                          className="h-4 w-4 text-teal-600 rounded"
                        />
                        <div className="flex-1">
                          <p className="text-sm font-medium text-gray-900">{team.name}</p>
                          <p className="text-xs text-gray-600">{team.specialization}</p>
                        </div>
                      </label>
                    ))}
                  </div>
                </div>

                {/* Budget */}
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1">Budget (€)</label>
                  <input
                    type="number"
                    value={formData.budget}
                    onChange={(e) => setFormData({ ...formData, budget: e.target.value })}
                    placeholder="0"
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 outline-none text-sm"
                  />
                </div>

                {/* Start Date */}
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1">Date de Début</label>
                  <input
                    type="date"
                    value={formData.startDate}
                    onChange={(e) => setFormData({ ...formData, startDate: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 outline-none text-sm"
                  />
                </div>

                {/* Notes */}
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1">Notes</label>
                  <textarea
                    value={formData.notes}
                    onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                    placeholder="Notes supplémentaires..."
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 outline-none text-sm resize-none"
                    rows={3}
                  />
                </div>

                {/* Actions */}
                <div className="flex gap-2">
                  <button
                    onClick={handleSubmitAssignment}
                    className="flex-1 px-3 py-2 bg-gradient-to-r from-emerald-500 to-emerald-600 text-white rounded-lg hover:from-emerald-600 hover:to-emerald-700 transition font-medium text-sm"
                  >
                    <Send className="h-4 w-4 inline mr-1" />
                    Créer
                  </button>
                  <button
                    onClick={() => {
                      setShowAssignmentForm(false);
                      setSelectedComplaintId(null);
                      setFormData({
                        complaintId: '',
                        teams: [],
                        budget: '',
                        startDate: '',
                        notes: '',
                      });
                    }}
                    className="flex-1 px-3 py-2 bg-gray-300 text-gray-900 rounded-lg hover:bg-gray-400 transition font-medium text-sm"
                  >
                    Annuler
                  </button>
                </div>
              </div>
            )}

            {/* Assignments List */}
            <div className="space-y-4 max-h-96 overflow-y-auto">
              {assignments.length === 0 ? (
                <div className="bg-gray-50 rounded-lg p-4 text-center text-gray-600 text-sm">
                  Aucune assignation pour le moment
                </div>
              ) : (
                assignments.map((assignment) => (
                  <div key={assignment.id} className="bg-white rounded-lg shadow-md border border-emerald-100 p-4">
                    <div className="space-y-2">
                      <h4 className="font-bold text-gray-900 text-sm">{assignment.complaintTitle}</h4>
                      <div className="text-xs space-y-1 text-gray-600">
                        <p>
                          <span className="font-semibold">Équipes:</span> {assignment.teams.join(', ')}
                        </p>
                        <p>
                          <span className="font-semibold">Budget:</span> {assignment.budget.toLocaleString('fr-FR')} €
                        </p>
                        <p>
                          <span className="font-semibold">Début:</span> {assignment.startDate}
                        </p>
                        {assignment.notes && (
                          <p>
                            <span className="font-semibold">Notes:</span> {assignment.notes}
                          </p>
                        )}
                      </div>
                      <div className="flex items-center justify-between pt-2 border-t border-gray-100">
                        <span className={`px-2 py-1 rounded text-xs font-medium ${getAssignmentStatusColor(assignment.status)}`}>
                          {assignment.status}
                        </span>
                        <button
                          onClick={() => handleDeleteAssignment(assignment.id)}
                          className="p-1 text-red-600 hover:bg-red-50 rounded transition"
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </div>
                    </div>
                  </div>
                ))
              )}
            </div>

            {/* Send to Finance Button */}
            {assignments.length > 0 && (
              <button className="w-full px-4 py-3 bg-gradient-to-r from-orange-500 to-orange-600 text-white rounded-lg hover:from-orange-600 hover:to-orange-700 transition font-bold text-sm shadow-lg">
                <Send className="h-4 w-4 inline mr-2" />
                Envoyer les Budgets aux Finances
              </button>
            )}
          </div>
        </div>
      </main>
    </div>
  );
};

interface StatCardProps {
  title: string;
  value: string | number;
  icon: React.ReactNode;
  bgColor: string;
  color: string;
}

const StatCard: React.FC<StatCardProps> = ({ title, value, icon, bgColor, color }) => (
  <div className={`${bgColor} rounded-lg p-4 border border-gray-200`}>
    <div className="flex items-center justify-between">
      <div>
        <p className="text-gray-600 text-xs font-medium">{title}</p>
        <p className="text-2xl font-bold text-gray-900 mt-1">{value}</p>
      </div>
      <div className={`bg-gradient-to-br ${color} p-2 rounded-lg text-white`}>{icon}</div>
    </div>
  </div>
);

interface PriorityBadgeProps {
  priority: 'urgent' | 'normal' | 'basse';
}

const PriorityBadge: React.FC<PriorityBadgeProps> = ({ priority }) => {
  const config = {
    urgent: 'bg-red-100 text-red-800',
    normal: 'bg-yellow-100 text-yellow-800',
    basse: 'bg-green-100 text-green-800',
  };

  const labels = {
    urgent: 'Urgent',
    normal: 'Normal',
    basse: 'Basse',
  };

  return (
    <span className={`px-3 py-1 rounded-full text-xs font-bold ${config[priority]}`}>{labels[priority]}</span>
  );
};

const getStatusColor = (status: string): string => {
  switch (status) {
    case 'nouveau':
      return 'bg-red-100 text-red-800';
    case 'en cours':
      return 'bg-yellow-100 text-yellow-800';
    case 'résolu':
      return 'bg-emerald-100 text-emerald-800';
    default:
      return 'bg-gray-100 text-gray-800';
  }
};

const getAssignmentStatusColor = (status: string): string => {
  switch (status) {
    case 'assignée':
      return 'bg-blue-100 text-blue-800';
    case 'en cours':
      return 'bg-yellow-100 text-yellow-800';
    case 'complétée':
      return 'bg-emerald-100 text-emerald-800';
    default:
      return 'bg-gray-100 text-gray-800';
  }
};
