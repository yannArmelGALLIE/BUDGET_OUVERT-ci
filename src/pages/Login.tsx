import React, { useState } from 'react';
import { Eye, EyeOff, AlertCircle } from 'lucide-react';

interface LoginProps {
  onLogin: (email: string, password: string, role: string) => void;
}

export const Login: React.FC<LoginProps> = ({ onLogin }) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');

  const getRoleFromEmail = (email: string): string => {
    if (email === 'maire@ville.fr') return 'Maire';
    if (email === 'chef@ville.fr') return 'Chef de Service';
    if (email === 'directeurFinances@ville.fr') return 'Directeur des Finances';
    return 'Admin';
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!email || !password) {
      setError('Veuillez remplir tous les champs');
      return;
    }

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      setError('Email invalide');
      return;
    }

    const role = getRoleFromEmail(email);
    onLogin(email, password, role);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-teal-50 via-white to-emerald-50 flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        {/* Main Card */}
        <div className="bg-white rounded-2xl shadow-xl overflow-hidden border border-teal-100">
          {/* Header with teal background */}
          <div className="bg-gradient-to-r from-teal-600 to-teal-700 px-8 py-12 text-center">
            <div className="flex justify-center mb-4">
              <img src="/image.png" alt="Logo" className="h-16 w-16 drop-shadow-lg" />
            </div>
            <h1 className="text-3xl font-bold text-white mb-2">Budget Ouvert</h1>
            <p className="text-teal-100 text-sm">Plateforme de Gestion Administrative</p>
          </div>

          {/* Form Content */}
          <div className="px-8 py-8">
            <form onSubmit={handleSubmit} className="space-y-6">
              {/* Error Alert */}
              {error && (
                <div className="flex items-center gap-3 p-3 bg-red-50 border border-red-200 rounded-lg">
                  <AlertCircle className="h-5 w-5 text-red-600 flex-shrink-0" />
                  <p className="text-sm text-red-700">{error}</p>
                </div>
              )}

              {/* Email Field */}
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">Adresse Email</label>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="admin@ville.fr"
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-transparent outline-none transition bg-white text-gray-900 placeholder-gray-500"
                />
              </div>

              {/* Password Field */}
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">Mot de Passe</label>
                <div className="relative">
                  <input
                    type={showPassword ? 'text' : 'password'}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="••••••••"
                    className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-transparent outline-none transition bg-white text-gray-900 placeholder-gray-500 pr-12"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-700 transition"
                  >
                    {showPassword ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
                  </button>
                </div>
              </div>

              {/* Submit Button */}
              <button
                type="submit"
                className="w-full bg-gradient-to-r from-teal-600 to-teal-700 text-white font-semibold py-3 rounded-lg hover:from-teal-700 hover:to-teal-800 transition shadow-lg hover:shadow-xl transform hover:scale-105 duration-200"
              >
                Se Connecter
              </button>
            </form>

            {/* Divider */}
            <div className="my-6 flex items-center gap-3">
              <div className="flex-1 h-px bg-gray-200" />
              <p className="text-xs text-gray-500">Accès Administrateur</p>
              <div className="flex-1 h-px bg-gray-200" />
            </div>

            {/* Test Credentials */}
            <div className="bg-teal-50 border border-teal-200 rounded-lg p-4 space-y-3">
              <p className="text-xs font-semibold text-gray-700">Identifiants de Test:</p>
              <div className="space-y-2 text-xs text-gray-600 border-b border-teal-200 pb-3">
                <p className="font-medium text-gray-900">Admin</p>
                <p>
                  <span className="font-medium text-gray-900">Email:</span> admin@ville.fr
                </p>
                <p>
                  <span className="font-medium text-gray-900">Mot de passe:</span> admin123
                </p>
              </div>
              <div className="space-y-2 text-xs text-gray-600 border-b border-teal-200 pb-3">
                <p className="font-medium text-gray-900">Maire</p>
                <p>
                  <span className="font-medium text-gray-900">Email:</span> maire@ville.fr
                </p>
                <p>
                  <span className="font-medium text-gray-900">Mot de passe:</span> maire123
                </p>
              </div>
              <div className="space-y-2 text-xs text-gray-600">
                <p className="font-medium text-gray-900">Chef de Service</p>
                <p>
                  <span className="font-medium text-gray-900">Email:</span> chef@ville.fr
                </p>
                <p>
                  <span className="font-medium text-gray-900">Mot de passe:</span> chef123
                </p>
              </div>
              <div className="space-y-2 text-xs text-gray-600">
                <p className="font-medium text-gray-900">Directeur des Finances</p>
                <p>
                  <span className="font-medium text-gray-900">Email:</span> directeurFinances@ville.fr
                </p>
                <p>
                  <span className="font-medium text-gray-900">Mot de passe:</span> directeur123
                </p>
              </div>
            </div>
          </div>

          {/* Footer */}
          <div className="bg-gray-50 px-8 py-4 border-t border-gray-200">
            <p className="text-xs text-gray-600 text-center">
              © 2026 Budget Ouvert. Tous droits réservés.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};
