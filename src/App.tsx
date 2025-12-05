import { useState } from 'react';
import { Layout } from './components/Layout';
import { Dashboard } from './components/Dashboard';
import { ClientsPage } from './components/ClientsPage';
import { SettingsPage } from './components/SettingsPage';

type Page = 'dashboard' | 'clients' | 'settings';

function App() {
  const [currentPage, setCurrentPage] = useState<Page>('dashboard');
  const [addDialogOpen, setAddDialogOpen] = useState(false);

  const handleNavigate = (page: Page) => {
    setCurrentPage(page);
  };

  const handleAddClient = () => {
    setCurrentPage('clients');
    setAddDialogOpen(true);
  };

  return (
    <Layout currentPage={currentPage} onPageChange={handleNavigate}>
      {currentPage === 'dashboard' && (
        <Dashboard 
          onNavigate={handleNavigate} 
          onAddClient={handleAddClient}
        />
      )}
      {currentPage === 'clients' && (
        <ClientsPage 
          addDialogOpen={addDialogOpen}
          setAddDialogOpen={setAddDialogOpen}
        />
      )}
      {currentPage === 'settings' && (
        <SettingsPage onBack={() => setCurrentPage('dashboard')} />
      )}
    </Layout>
  );
}

export default App;
