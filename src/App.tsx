import { useState } from 'react';
import { AdminDashboard } from './pages/AdminDashboard';
import { MayorDashboard } from './pages/MayorDashboard';
import { ChiefDashboard } from './pages/ChiefDashboard';
import { Login } from './pages/Login';
import FinancialDirectorDashboard from './pages/FinancialDirectorDashboard';

function App() {
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [userRole, setUserRole] = useState<string>('');
  const [currentView, setCurrentView] = useState<'dashboard' | 'users' | 'permissions'>('dashboard');

  const handleLogin = (email: string, password: string, role: string) => {
    // Simple validation for demo
    if (email && password && password.length >= 6) {
      setIsLoggedIn(true);
      setUserRole(role);
      setCurrentView('dashboard');
    }
  };

  const handleLogout = () => {
    setIsLoggedIn(false);
    setUserRole('');
    setCurrentView('dashboard');
  };

  if (!isLoggedIn) {
    return <Login onLogin={handleLogin} />;
  }

  if (userRole === 'Maire') {
    return <MayorDashboard onLogout={handleLogout} />;
  }

  if (userRole === 'Chef de Service') {
    return <ChiefDashboard onLogout={handleLogout} />;
  }
  if (userRole === 'Directeur des Finances') {
    return <FinancialDirectorDashboard onLogout={handleLogout} />;
  }

  return (
    <AdminDashboard
      currentView={currentView}
      onViewChange={setCurrentView}
      onLogout={handleLogout}
    />
  );
}

export default App;
