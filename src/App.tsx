// src/App.tsx
import { useState } from 'react';
import { BlockchainProvider } from './contexts/BlockchainContext';
import { AdminDashboard }         from './pages/AdminDashboard';
import { MayorDashboard }         from './pages/MayorDashboard';
import { ChiefDashboard }         from './pages/ChiefDashboard';
import { Login }                  from './pages/Login';
import FinancialDirectorDashboard from './pages/FinancialDirectorDashboard';

type AdminView = 'dashboard' | 'users' | 'permissions';

function App() {
  const [isLoggedIn,   setIsLoggedIn]  = useState(false);
  const [userRole,     setUserRole]    = useState('');
  const [currentView,  setCurrentView] = useState<AdminView>('dashboard');

  const handleLogin = (email: string, password: string, role: string) => {
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

  if (!isLoggedIn) return <Login onLogin={handleLogin} />;

  return (
    <BlockchainProvider>
      {userRole === 'Maire'                  && <MayorDashboard onLogout={handleLogout} />}
      {userRole === 'Chef de Service'        && <ChiefDashboard onLogout={handleLogout} />}
      {userRole === 'Directeur des Finances' && <FinancialDirectorDashboard onLogout={handleLogout} />}
      {userRole !== 'Maire' &&
       userRole !== 'Chef de Service' &&
       userRole !== 'Directeur des Finances' && (
        <AdminDashboard
          currentView={currentView}
          onViewChange={setCurrentView}
          onLogout={handleLogout}
        />
      )}
    </BlockchainProvider>
  );
}

export default App;