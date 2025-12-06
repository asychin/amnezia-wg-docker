import { useState, useMemo } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { 
  Plus, 
  Search, 
  ArrowUpDown,
  ArrowUp,
  ArrowDown,
  Users
} from 'lucide-react';
import { useToast } from '../hooks/use-toast';
import { Button } from './ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Input } from './ui/input';
import {
  Table,
  TableBody,
  TableHead,
  TableHeader,
  TableRow,
} from './ui/table';
import {
  fetchClients,
  createClient,
  deleteClient,
  fetchClientQR,
  fetchClientConfig,
  downloadConfig,
  downloadQRCode,
} from '../api/client';
import { ClientRow } from './ClientRow';
import { AddClientDialog } from './AddClientDialog';
import { QRDialog } from './QRDialog';
import { ConfigDialog } from './ConfigDialog';
import { DeleteDialog } from './DeleteDialog';
import type { VpnClient } from '../types';

type SortField = 'name' | 'ipAddress' | 'createdAt' | 'enabled';
type SortDirection = 'asc' | 'desc';

interface ClientsPageProps {
  addDialogOpen: boolean;
  setAddDialogOpen: (open: boolean) => void;
}

export function ClientsPage({ addDialogOpen, setAddDialogOpen }: ClientsPageProps) {
  const queryClient = useQueryClient();
  const { toast } = useToast();
  
  const [searchQuery, setSearchQuery] = useState('');
  const [sortField, setSortField] = useState<SortField>('createdAt');
  const [sortDirection, setSortDirection] = useState<SortDirection>('desc');
  
  const [qrDialogOpen, setQrDialogOpen] = useState(false);
  const [configDialogOpen, setConfigDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedClient, setSelectedClient] = useState<VpnClient | null>(null);
  const [newClientName, setNewClientName] = useState('');
  const [newClientIp, setNewClientIp] = useState('');
  const [newClientAllowedIps, setNewClientAllowedIps] = useState('');
  const [qrCodeData, setQrCodeData] = useState('');
  const [configData, setConfigData] = useState('');

  const { data: clients = [], isLoading } = useQuery({
    queryKey: ['clients'],
    queryFn: fetchClients,
  });

  const createMutation = useMutation({
    mutationFn: createClient,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['clients'] });
      setAddDialogOpen(false);
      setNewClientName('');
      setNewClientIp('');
      setNewClientAllowedIps('');
      toast({
        title: 'Клиент создан',
        description: 'VPN клиент успешно создан',
      });
    },
    onError: (error: Error) => {
      toast({
        title: 'Ошибка создания',
        description: error.message || 'Не удалось создать клиента',
      });
    },
  });

  const deleteMutation = useMutation({
    mutationFn: deleteClient,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['clients'] });
      setDeleteDialogOpen(false);
      setSelectedClient(null);
      toast({
        title: 'Клиент удален',
        description: 'VPN клиент успешно удален',
      });
    },
    onError: (error: Error) => {
      toast({
        title: 'Ошибка удаления',
        description: error.message || 'Не удалось удалить клиента',
      });
    },
  });

  // Filter and sort clients
  const filteredAndSortedClients = useMemo(() => {
    let result = [...clients];
    
    // Filter by search query
    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      result = result.filter(client => 
        client.name.toLowerCase().includes(query) ||
        client.ipAddress.toLowerCase().includes(query)
      );
    }
    
    // Sort
    result.sort((a, b) => {
      let comparison = 0;
      switch (sortField) {
        case 'name':
          comparison = a.name.localeCompare(b.name);
          break;
        case 'ipAddress':
          comparison = a.ipAddress.localeCompare(b.ipAddress);
          break;
        case 'createdAt':
          comparison = new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime();
          break;
        case 'enabled':
          comparison = (a.enabled === b.enabled) ? 0 : a.enabled ? -1 : 1;
          break;
      }
      return sortDirection === 'asc' ? comparison : -comparison;
    });
    
    return result;
  }, [clients, searchQuery, sortField, sortDirection]);

  const handleSort = (field: SortField) => {
    if (sortField === field) {
      setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc');
    } else {
      setSortField(field);
      setSortDirection('asc');
    }
  };

  const SortIcon = ({ field }: { field: SortField }) => {
    if (sortField !== field) return <ArrowUpDown className="w-4 h-4 ml-1 opacity-50" />;
    return sortDirection === 'asc' 
      ? <ArrowUp className="w-4 h-4 ml-1" />
      : <ArrowDown className="w-4 h-4 ml-1" />;
  };

  const handleAddClient = () => {
    if (newClientName.trim()) {
      createMutation.mutate({
        name: newClientName.trim(),
        ipAddress: newClientIp.trim() || undefined,
        allowedIps: newClientAllowedIps.trim() || undefined,
      });
    }
  };

  const handleDeleteClient = () => {
    if (selectedClient) {
      deleteMutation.mutate(selectedClient.name);
    }
  };

  const handleShowQR = async (client: VpnClient) => {
    try {
      const { qrCode } = await fetchClientQR(client.name);
      setQrCodeData(qrCode);
      setSelectedClient(client);
      setQrDialogOpen(true);
    } catch (error) {
      console.error('Failed to fetch QR code:', error);
      toast({
        title: 'Ошибка загрузки QR кода',
        description: 'Не удалось загрузить QR код',
      });
    }
  };

  const handleShowConfig = async (client: VpnClient) => {
    try {
      const config = await fetchClientConfig(client.name);
      setConfigData(config);
      setSelectedClient(client);
      setConfigDialogOpen(true);
    } catch (error) {
      console.error('Failed to fetch config:', error);
      toast({
        title: 'Ошибка загрузки конфигурации',
        description: 'Не удалось загрузить конфигурацию',
      });
    }
  };

  const handleDeleteClick = (client: VpnClient) => {
    setSelectedClient(client);
    setDeleteDialogOpen(true);
  };

  const handleDownloadConfig = async () => {
    if (selectedClient && configData) {
      downloadConfig(selectedClient.name, configData);
    }
  };

  const handleDownloadQR = async () => {
    if (selectedClient && qrCodeData) {
      downloadQRCode(selectedClient.name, qrCodeData);
    }
  };

  return (
    <div className="space-y-4">
      <Card className="bg-white dark:bg-slate-800 border-slate-200 dark:border-slate-700">
        <CardHeader>
          <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
            <div>
              <CardTitle className="text-xl text-slate-900 dark:text-white">VPN Клиенты</CardTitle>
              <CardDescription className="text-slate-500 dark:text-slate-400">
                {clients.length} {clients.length === 1 ? 'клиент' : clients.length < 5 ? 'клиента' : 'клиентов'}
              </CardDescription>
            </div>
            <Button onClick={() => setAddDialogOpen(true)} className="w-full sm:w-auto bg-blue-600 hover:bg-blue-700">
              <Plus className="w-4 h-4 mr-2" />
              Добавить клиента
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          {/* Search */}
          <div className="mb-4">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-slate-400" />
              <Input
                placeholder="Поиск по имени или IP..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-10 bg-white dark:bg-slate-700 border-slate-200 dark:border-slate-600 text-slate-900 dark:text-white placeholder:text-slate-400"
              />
            </div>
          </div>

          {isLoading ? (
            <div className="text-center py-8 text-slate-500 dark:text-slate-400">Загрузка...</div>
          ) : filteredAndSortedClients.length === 0 ? (
            <div className="text-center py-12">
              <Users className="w-12 h-12 mx-auto mb-3 text-slate-300 dark:text-slate-600" />
              <p className="text-slate-500 dark:text-slate-400">
                {searchQuery ? 'Клиенты не найдены' : 'Нет клиентов'}
              </p>
              {!searchQuery && (
                <p className="text-sm text-slate-400 dark:text-slate-500 mt-1">
                  Добавьте первого клиента для начала работы
                </p>
              )}
            </div>
          ) : (
            <div className="overflow-x-auto -mx-6 sm:mx-0">
              <Table>
                <TableHeader>
                  <TableRow className="border-slate-200 dark:border-slate-700">
                    <TableHead 
                      className="cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-700 text-slate-600 dark:text-slate-300"
                      onClick={() => handleSort('name')}
                    >
                      <div className="flex items-center">
                        Имя
                        <SortIcon field="name" />
                      </div>
                    </TableHead>
                    <TableHead 
                      className="cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-700 text-slate-600 dark:text-slate-300"
                      onClick={() => handleSort('ipAddress')}
                    >
                      <div className="flex items-center">
                        IP адрес
                        <SortIcon field="ipAddress" />
                      </div>
                    </TableHead>
                    <TableHead 
                      className="cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-700 text-slate-600 dark:text-slate-300"
                      onClick={() => handleSort('enabled')}
                    >
                      <div className="flex items-center">
                        Статус
                        <SortIcon field="enabled" />
                      </div>
                    </TableHead>
                    <TableHead 
                      className="cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-700 text-slate-600 dark:text-slate-300"
                      onClick={() => handleSort('createdAt')}
                    >
                      <div className="flex items-center">
                        Создан
                        <SortIcon field="createdAt" />
                      </div>
                    </TableHead>
                    <TableHead className="text-right text-slate-600 dark:text-slate-300">Действия</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredAndSortedClients.map((client) => (
                    <ClientRow
                      key={client.id}
                      client={client}
                      onShowQR={handleShowQR}
                      onShowConfig={handleShowConfig}
                      onDelete={handleDeleteClick}
                    />
                  ))}
                </TableBody>
              </Table>
            </div>
          )}
        </CardContent>
      </Card>

      <AddClientDialog
        open={addDialogOpen}
        onOpenChange={setAddDialogOpen}
        clientName={newClientName}
        setClientName={setNewClientName}
        clientIp={newClientIp}
        setClientIp={setNewClientIp}
        clientAllowedIps={newClientAllowedIps}
        setClientAllowedIps={setNewClientAllowedIps}
        onSubmit={handleAddClient}
        isPending={createMutation.isPending}
      />

      <QRDialog
        open={qrDialogOpen}
        onOpenChange={setQrDialogOpen}
        clientName={selectedClient?.name || ''}
        qrCodeData={qrCodeData}
        onDownload={handleDownloadQR}
      />

      <ConfigDialog
        open={configDialogOpen}
        onOpenChange={setConfigDialogOpen}
        clientName={selectedClient?.name || ''}
        configData={configData}
        onDownload={handleDownloadConfig}
      />

      <DeleteDialog
        open={deleteDialogOpen}
        onOpenChange={setDeleteDialogOpen}
        clientName={selectedClient?.name || ''}
        onConfirm={handleDeleteClient}
        isPending={deleteMutation.isPending}
      />
    </div>
  );
}
