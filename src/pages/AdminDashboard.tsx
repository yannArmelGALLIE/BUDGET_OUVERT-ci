import React, { useState } from 'react';
import { Users, Key, LayoutDashboard, Plus, Edit2, Trash2, Search, Check, X, LogOut } from 'lucide-react';
import { AdminSidebar } from '../components/AdminSidebar';

interface User {
  id: string;
  name: string;
  email: string;
  role: string;
  status: 'active' | 'inactive';
  joinDate: string;
}

interface AdminDashboardProps {
  currentView: 'dashboard' | 'users' | 'permissions';
  onViewChange: (view: 'dashboard' | 'users' | 'permissions') => void;
  onLogout: () => void;
}

export const AdminDashboard: React.FC<AdminDashboardProps> = ({ currentView, onViewChange, onLogout }) => {
  const [users, setUsers] = useState<User[]>([
    { id: '1', name: 'Jean Dupont', email: 'jean@ville.fr', role: 'Directeur Financier', status: 'active', joinDate: '2024-01-15' },
    { id: '2', name: 'Marie Martin', email: 'marie@ville.fr', role: 'Chef de Service', status: 'active', joinDate: '2024-02-01' },
    { id: '3', name: 'Pierre Bernard', email: 'pierre@ville.fr', role: 'Chef de Service', status: 'active', joinDate: '2024-02-15' },
    { id: '4', name: 'Sophie Lefevre', email: 'sophie@ville.fr', role: 'Maire', status: 'active', joinDate: '2024-03-01' },
  ]);

  const [searchTerm, setSearchTerm] = useState('');
  const [showAddUser, setShowAddUser] = useState(false);
  const [editingUser, setEditingUser] = useState<User | null>(null);
  const [formData, setFormData] = useState({ name: '', email: '', role: '' });

  const filteredUsers = users.filter(
    (user) =>
      user.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      user.email.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const handleAddUser = () => {
    if (formData.name && formData.email && formData.role) {
      const newUser: User = {
        id: Math.random().toString(36).substr(2, 9),
        name: formData.name,
        email: formData.email,
        role: formData.role,
        status: 'active',
        joinDate: new Date().toISOString().split('T')[0],
      };
      setUsers([...users, newUser]);
      setFormData({ name: '', email: '', role: '' });
      setShowAddUser(false);
    }
  };

  const handleUpdateUser = () => {
    if (editingUser && formData.name && formData.email && formData.role) {
      setUsers(
        users.map((u) =>
          u.id === editingUser.id
            ? { ...u, name: formData.name, email: formData.email, role: formData.role }
            : u
        )
      );
      setFormData({ name: '', email: '', role: '' });
      setEditingUser(null);
    }
  };

  const handleDeleteUser = (id: string) => {
    setUsers(users.filter((u) => u.id !== id));
  };

  const openEditUser = (user: User) => {
    setEditingUser(user);
    setFormData({ name: user.name, email: user.email, role: user.role });
  };

  return (
    <div className="min-h-screen bg-gray-50 flex">
      <AdminSidebar currentView={currentView} onViewChange={onViewChange} />

      <div className="flex-1 flex flex-col">
        {/* Header */}
        <header className="bg-gradient-to-r from-teal-600 to-teal-700 px-8 py-4 flex items-center justify-between shadow-lg">
          <div className="flex items-center gap-4">
            <img src="/image.png" alt="Logo" className="h-12 w-12 drop-shadow-lg" />
            <div>
              <h1 className="text-2xl font-bold text-white">Budget Ouvert</h1>
              <p className="text-sm text-teal-100">Tableau de Bord Administrateur</p>
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
        <main className="flex-1 overflow-auto">
          {currentView === 'dashboard' && <DashboardView users={users} />}
          {currentView === 'users' && (
            <UsersView
              users={filteredUsers}
              searchTerm={searchTerm}
              onSearchChange={setSearchTerm}
              onAddUser={() => {
                setFormData({ name: '', email: '', role: '' });
                setEditingUser(null);
                setShowAddUser(!showAddUser);
              }}
              onEditUser={openEditUser}
              onDeleteUser={handleDeleteUser}
              showAddForm={showAddUser}
              editingUser={editingUser}
              formData={formData}
              onFormChange={setFormData}
              onSaveUser={editingUser ? handleUpdateUser : handleAddUser}
              onCancel={() => {
                setShowAddUser(false);
                setEditingUser(null);
                setFormData({ name: '', email: '', role: '' });
              }}
            />
          )}
          {currentView === 'permissions' && <PermissionsView />}
        </main>
      </div>
    </div>
  );
};

const DashboardView: React.FC<{ users: User[] }> = ({ users }) => {
  const activeUsers = users.filter((u) => u.status === 'active').length;
  const roles = new Set(users.map((u) => u.role)).size;

  return (
    <div className="p-8">
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <DashboardCard
          icon={<Users className="h-8 w-8" />}
          title="Utilisateurs Actifs"
          value={activeUsers.toString()}
          color="bg-teal-50"
          iconColor="text-teal-600"
        />
        <DashboardCard
          icon={<Key className="h-8 w-8" />}
          title="Rôles Configurés"
          value={roles.toString()}
          color="bg-orange-50"
          iconColor="text-orange-600"
        />
        <DashboardCard
          icon={<LayoutDashboard className="h-8 w-8" />}
          title="Total Utilisateurs"
          value={users.length.toString()}
          color="bg-emerald-50"
          iconColor="text-emerald-600"
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-lg font-bold text-gray-900 mb-4">Rôles du Système</h2>
          <div className="space-y-3">
            <RoleItem name="Admin" desc="Gère les utilisateurs et les permissions" />
            <RoleItem name="Directeur Financier" desc="Gère les budgets et les plaintes" />
            <RoleItem name="Chef de Service" desc="Gère les équipes et les budgets" />
            <RoleItem name="Maire" desc="Accès lecture seule" />
          </div>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-lg font-bold text-gray-900 mb-4">Permissions Disponibles</h2>
          <div className="space-y-3">
            <PermissionItem name="Gérer les utilisateurs" />
            <PermissionItem name="Assigner les rôles" />
            <PermissionItem name="Gérer les permissions" />
            <PermissionItem name="Afficher les plaintes" />
            <PermissionItem name="Enregistrer les budgets" />
            <PermissionItem name="Assigner les équipes" />
          </div>
        </div>
      </div>
    </div>
  );
};

const DashboardCard: React.FC<{
  icon: React.ReactNode;
  title: string;
  value: string;
  color: string;
  iconColor: string;
}> = ({ icon, title, value, color, iconColor }) => (
  <div className={`${color} rounded-lg p-6`}>
    <div className="flex items-center justify-between">
      <div>
        <p className="text-gray-600 text-sm font-medium">{title}</p>
        <p className="text-4xl font-bold text-gray-900 mt-2">{value}</p>
      </div>
      <div className={`${iconColor}`}>{icon}</div>
    </div>
  </div>
);

const RoleItem: React.FC<{ name: string; desc: string }> = ({ name, desc }) => (
  <div className="flex items-start gap-3 p-3 bg-gray-50 rounded-lg">
    <div className="h-3 w-3 bg-orange-500 rounded-full mt-1.5 flex-shrink-0" />
    <div>
      <p className="font-semibold text-gray-900">{name}</p>
      <p className="text-sm text-gray-600">{desc}</p>
    </div>
  </div>
);

const PermissionItem: React.FC<{ name: string }> = ({ name }) => (
  <div className="flex items-center gap-3 p-2">
    <div className="h-2 w-2 bg-green-500 rounded-full" />
    <p className="text-gray-700">{name}</p>
  </div>
);

interface UsersViewProps {
  users: User[];
  searchTerm: string;
  onSearchChange: (term: string) => void;
  onAddUser: () => void;
  onEditUser: (user: User) => void;
  onDeleteUser: (id: string) => void;
  showAddForm: boolean;
  editingUser: User | null;
  formData: { name: string; email: string; role: string };
  onFormChange: (data: { name: string; email: string; role: string }) => void;
  onSaveUser: () => void;
  onCancel: () => void;
}

const UsersView: React.FC<UsersViewProps> = ({
  users,
  searchTerm,
  onSearchChange,
  onAddUser,
  onEditUser,
  onDeleteUser,
  showAddForm,
  editingUser,
  formData,
  onFormChange,
  onSaveUser,
  onCancel,
}) => (
  <div className="p-8">
    <div className="flex items-center justify-between mb-6">
      <h2 className="text-2xl font-bold text-gray-900">Gestion des Utilisateurs</h2>
      <button
        onClick={onAddUser}
        className="flex items-center gap-2 bg-gradient-to-r from-teal-600 to-teal-700 text-white px-4 py-2 rounded-lg hover:from-teal-700 hover:to-teal-800 transition font-medium"
      >
        <Plus className="h-5 w-5" />
        Ajouter Utilisateur
      </button>
    </div>

    {(showAddForm || editingUser) && (
      <UserForm
        formData={formData}
        onFormChange={onFormChange}
        onSave={onSaveUser}
        onCancel={onCancel}
        isEditing={!!editingUser}
      />
    )}

    <div className="bg-white rounded-lg shadow mb-6">
      <div className="p-4 border-b border-gray-200">
        <div className="relative">
          <Search className="absolute left-3 top-3 h-5 w-5 text-gray-400" />
          <input
            type="text"
            placeholder="Rechercher par nom ou email..."
            value={searchTerm}
            onChange={(e) => onSearchChange(e.target.value)}
            className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-orange-500 outline-none"
          />
        </div>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">Nom</th>
              <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">Email</th>
              <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">Rôle</th>
              <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">Statut</th>
              <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">Actions</th>
            </tr>
          </thead>
          <tbody>
            {users.map((user) => (
              <tr key={user.id} className="border-b border-gray-200 hover:bg-gray-50">
                <td className="px-6 py-4 text-gray-900">{user.name}</td>
                <td className="px-6 py-4 text-gray-600">{user.email}</td>
                <td className="px-6 py-4">
                  <span className="px-3 py-1 bg-teal-100 text-teal-800 rounded-full text-sm font-medium">
                    {user.role}
                  </span>
                </td>
                <td className="px-6 py-4">
                  <span className="px-3 py-1 bg-emerald-100 text-emerald-800 rounded-full text-sm">
                    {user.status === 'active' ? 'Actif' : 'Inactif'}
                  </span>
                </td>
                <td className="px-6 py-4 flex items-center gap-2">
                  <button
                    onClick={() => onEditUser(user)}
                    className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition"
                  >
                    <Edit2 className="h-4 w-4" />
                  </button>
                  <button
                    onClick={() => onDeleteUser(user.id)}
                    className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  </div>
);

interface UserFormProps {
  formData: { name: string; email: string; role: string };
  onFormChange: (data: { name: string; email: string; role: string }) => void;
  onSave: () => void;
  onCancel: () => void;
  isEditing: boolean;
}

const UserForm: React.FC<UserFormProps> = ({ formData, onFormChange, onSave, onCancel, isEditing }) => (
  <div className="bg-white rounded-lg shadow p-6 mb-6">
    <h3 className="text-lg font-bold text-gray-900 mb-4">{isEditing ? 'Modifier' : 'Ajouter'} Utilisateur</h3>
    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
      <input
        type="text"
        placeholder="Nom complet"
        value={formData.name}
        onChange={(e) => onFormChange({ ...formData, name: e.target.value })}
        className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-orange-500 outline-none"
      />
      <input
        type="email"
        placeholder="Email"
        value={formData.email}
        onChange={(e) => onFormChange({ ...formData, email: e.target.value })}
        className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-orange-500 outline-none"
      />
      <select
        value={formData.role}
        onChange={(e) => onFormChange({ ...formData, role: e.target.value })}
        className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-orange-500 outline-none"
      >
        <option value="">Sélectionner un rôle</option>
        <option value="Admin">Admin</option>
        <option value="Directeur Financier">Directeur Financier</option>
        <option value="Chef de Service">Chef de Service</option>
        <option value="Maire">Maire</option>
      </select>
    </div>
    <div className="flex gap-3 mt-4">
      <button
        onClick={onSave}
        className="px-4 py-2 bg-gradient-to-r from-emerald-500 to-emerald-600 text-white rounded-lg hover:from-emerald-600 hover:to-emerald-700 transition font-medium"
      >
        {isEditing ? 'Mettre à jour' : 'Ajouter'}
      </button>
      <button onClick={onCancel} className="px-4 py-2 bg-gray-300 text-gray-900 rounded-lg hover:bg-gray-400 transition font-medium">
        Annuler
      </button>
    </div>
  </div>
);

interface Permission {
  id: string;
  name: string;
  description: string;
}

interface RoleWithPermissions {
  id: string;
  name: string;
  description: string;
  permissions: string[];
}

const PermissionsView: React.FC = () => {
  const allPermissions: Permission[] = [
    { id: '1', name: 'Gérer les utilisateurs', description: 'Créer, modifier et supprimer les utilisateurs' },
    { id: '2', name: 'Assigner les rôles', description: 'Assigner et modifier les rôles des utilisateurs' },
    { id: '3', name: 'Gérer les permissions', description: 'Gérer les permissions des rôles' },
    { id: '4', name: 'Afficher les plaintes', description: 'Visualiser les plaintes de la population' },
    { id: '5', name: 'Enregistrer les budgets', description: 'Enregistrer les recettes et dépenses' },
    { id: '6', name: 'Assigner les équipes', description: 'Assigner les équipes de service' },
    { id: '7', name: 'Afficher les rapports', description: 'Générer et afficher les rapports financiers' },
  ];

  const [roles, setRoles] = useState<RoleWithPermissions[]>([
    {
      id: '1',
      name: 'Admin',
      description: 'Administrateur du système',
      permissions: ['1', '2', '3', '4', '5', '6', '7'],
    },
    {
      id: '2',
      name: 'Directeur Financier',
      description: 'Gère les finances et budgets',
      permissions: ['4', '5', '7'],
    },
    {
      id: '3',
      name: 'Chef de Service',
      description: 'Gère les équipes et les budgets',
      permissions: ['4', '5', '6'],
    },
    {
      id: '4',
      name: 'Maire',
      description: 'Accès en lecture seule',
      permissions: ['4', '7'],
    },
  ]);

  const [editingRoleId, setEditingRoleId] = useState<string | null>(null);
  const [editingPermissions, setEditingPermissions] = useState<string[]>([]);

  const handleEditRole = (role: RoleWithPermissions) => {
    setEditingRoleId(role.id);
    setEditingPermissions([...role.permissions]);
  };

  const handleTogglePermission = (permissionId: string) => {
    setEditingPermissions((prev) =>
      prev.includes(permissionId) ? prev.filter((p) => p !== permissionId) : [...prev, permissionId]
    );
  };

  const handleSavePermissions = () => {
    setRoles((prev) =>
      prev.map((role) =>
        role.id === editingRoleId ? { ...role, permissions: editingPermissions } : role
      )
    );
    setEditingRoleId(null);
    setEditingPermissions([]);
  };

  const handleCancelEdit = () => {
    setEditingRoleId(null);
    setEditingPermissions([]);
  };

  return (
    <div className="p-8">
      <h2 className="text-2xl font-bold text-gray-900 mb-8">Gestion des Permissions par Rôle</h2>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {roles.map((role) => (
          <div key={role.id} className="bg-white rounded-lg shadow-lg overflow-hidden border border-gray-200">
            {/* Role Header */}
            <div className="bg-gradient-to-r from-teal-600 to-teal-700 px-6 py-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="h-3 w-3 bg-orange-400 rounded-full" />
                  <div>
                    <h3 className="text-lg font-bold text-white">{role.name}</h3>
                    <p className="text-sm text-teal-100">{role.description}</p>
                  </div>
                </div>
                {editingRoleId !== role.id && (
                  <button
                    onClick={() => handleEditRole(role)}
                    className="p-2 hover:bg-teal-500 rounded-lg transition text-teal-100 hover:text-white"
                  >
                    <Edit2 className="h-5 w-5" />
                  </button>
                )}
              </div>
            </div>

            {/* Permissions Content */}
            <div className="p-6">
              {editingRoleId === role.id ? (
                <div className="space-y-4">
                  <p className="text-sm text-gray-600 font-medium mb-4">Sélectionner les permissions pour ce rôle:</p>
                  <div className="space-y-3 max-h-64 overflow-y-auto">
                    {allPermissions.map((perm) => {
                      const isChecked = editingPermissions.includes(perm.id);
                      return (
                        <label
                          key={perm.id}
                          className="flex items-start gap-3 p-3 rounded-lg hover:bg-gray-50 cursor-pointer transition"
                        >
                          <input
                            type="checkbox"
                            checked={isChecked}
                            onChange={() => handleTogglePermission(perm.id)}
                            className="h-5 w-5 text-teal-600 rounded mt-0.5"
                          />
                          <div className="flex-1">
                            <p className="font-medium text-gray-900">{perm.name}</p>
                            <p className="text-sm text-gray-600">{perm.description}</p>
                          </div>
                        </label>
                      );
                    })}
                  </div>

                  <div className="flex gap-3 pt-4 border-t border-gray-200 mt-4">
                    <button
                      onClick={handleSavePermissions}
                      className="flex-1 px-4 py-2 bg-gradient-to-r from-emerald-500 to-emerald-600 text-white rounded-lg hover:from-emerald-600 hover:to-emerald-700 transition font-medium"
                    >
                      Enregistrer
                    </button>
                    <button
                      onClick={handleCancelEdit}
                      className="flex-1 px-4 py-2 bg-gray-300 text-gray-900 rounded-lg hover:bg-gray-400 transition font-medium"
                    >
                      Annuler
                    </button>
                  </div>
                </div>
              ) : (
                <div className="space-y-2">
                  {role.permissions.length === 0 ? (
                    <p className="text-gray-600 text-sm italic">Aucune permission assignée</p>
                  ) : (
                    allPermissions
                      .filter((perm) => role.permissions.includes(perm.id))
                      .map((perm) => (
                        <div key={perm.id} className="flex items-start gap-3 p-3 bg-emerald-50 rounded-lg border border-emerald-200">
                          <div className="h-2 w-2 bg-emerald-600 rounded-full mt-1.5 flex-shrink-0" />
                          <div>
                            <p className="font-medium text-gray-900">{perm.name}</p>
                            <p className="text-xs text-gray-600">{perm.description}</p>
                          </div>
                        </div>
                      ))
                  )}
                </div>
              )}
            </div>

            {/* Permission Count Footer */}
            {editingRoleId !== role.id && (
              <div className="bg-gray-50 px-6 py-3 border-t border-gray-200">
                <p className="text-sm text-gray-600">
                  <span className="font-semibold text-gray-900">{role.permissions.length}</span> permission
                  {role.permissions.length > 1 ? 's' : ''} assignée
                  {role.permissions.length > 1 ? 's' : ''}
                </p>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
};
