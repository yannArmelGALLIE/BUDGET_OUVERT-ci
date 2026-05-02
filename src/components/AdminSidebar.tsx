import React from 'react';
import { LayoutDashboard, Users, Key } from 'lucide-react';

interface AdminSidebarProps {
  currentView: 'dashboard' | 'users' | 'permissions';
  onViewChange: (view: 'dashboard' | 'users' | 'permissions') => void;
}

export const AdminSidebar: React.FC<AdminSidebarProps> = ({ currentView, onViewChange }) => {
  const menuItems = [
    { id: 'dashboard', label: 'Tableau de Bord', icon: LayoutDashboard },
    { id: 'users', label: 'Utilisateurs', icon: Users },
    { id: 'permissions', label: 'Permissions', icon: Key },
  ];

  return (
    <aside className="w-64 bg-gradient-to-b from-teal-900 to-teal-950 text-white flex flex-col shadow-lg">
      <div className="p-6 border-b border-teal-800">
        <div className="flex items-center gap-3">
          <img src="/image.png" alt="Logo" className="h-10 w-10 drop-shadow" />
          <div>
            <h1 className="font-bold text-lg">Budget Ouvert</h1>
            <p className="text-xs text-teal-300">Administrateur</p>
          </div>
        </div>
      </div>

      <nav className="flex-1 p-4">
        <p className="text-xs font-semibold text-teal-300 uppercase px-4 mb-4">Menu Principal</p>
        <ul className="space-y-2">
          {menuItems.map((item) => {
            const Icon = item.icon;
            const isActive = currentView === item.id;
            return (
              <li key={item.id}>
                <button
                  onClick={() => onViewChange(item.id as 'dashboard' | 'users' | 'permissions')}
                  className={`w-full flex items-center gap-3 px-4 py-3 rounded-lg transition ${
                    isActive
                      ? 'bg-orange-500 text-white shadow-lg'
                      : 'text-teal-200 hover:bg-teal-800'
                  }`}
                >
                  <Icon className="h-5 w-5" />
                  <span className="text-sm font-medium">{item.label}</span>
                </button>
              </li>
            );
          })}
        </ul>
      </nav>
    </aside>
  );
};
