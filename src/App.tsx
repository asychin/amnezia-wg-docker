import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Plus, Trash2, QrCode, FileText, RefreshCw, Shield } from 'lucide-react';
import { useToast } from './hooks/use-toast';
import { Button } from './components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './components/ui/card';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from './components/ui/dialog';
import { Input } from './components/ui/input';
import { Label } from './components/ui/label';
import { Badge } from './components/ui/badge';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from './components/ui/table';
import {
  fetchClients,
  createClient,
  deleteClient,
  fetchClientQR,
  fetchClientConfig,
  syncClients,
} from './api/client';
import type { VpnClient } from './types';

function App() {
  const queryClient = useQueryClient();
  const { toast } = useToast();
  const [addDialogOpen, setAddDialogOpen] = useState(false);
  const [qrDialogOpen, setQrDialogOpen] = useState(false);
  const [configDialogOpen, setConfigDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedClient, setSelectedClient] = useState<VpnClient | null>(null);
  const [newClientName, setNewClientName] = useState('');
  const [newClientIp, setNewClientIp] = useState('');
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

  const syncMutation = useMutation({
    mutationFn: syncClients,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['clients'] });
      toast({
        title: 'Синхронизация завершена',
        description: 'Клиенты успешно синхронизированы',
      });
    },
    onError: (error: Error) => {
      toast({
        title: 'Ошибка синхронизации',
        description: error.message || 'Не удалось синхронизировать клиентов',
      });
    },
  });

  const handleAddClient = () => {
    if (newClientName.trim()) {
      createMutation.mutate({
        name: newClientName.trim(),
        ipAddress: newClientIp.trim() || undefined,
      });
    }
  };

  const handleDeleteClient = () => {
    if (selectedClient) {
      deleteMutation.mutate(selectedClient.name);
    }
  };

  // SECURITY: QR код и конфигурация загружаются ТОЛЬКО при явном действии пользователя
  // Эти функции вызываются только когда пользователь кликает на кнопки QR или Config
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

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-indigo-50 to-purple-50 p-4 md:p-8">
      <div className="max-w-7xl mx-auto">
        <div className="mb-8">
          <div className="flex items-center gap-3 mb-2">
            <div className="p-2 bg-gradient-to-br from-blue-600 to-indigo-600 rounded-lg">
              <Shield className="w-8 h-8 text-white" />
            </div>
            <div>
              <h1 className="text-4xl font-bold bg-gradient-to-r from-blue-700 to-indigo-700 bg-clip-text text-transparent">
                AmneziaWG VPN
              </h1>
              <p className="text-slate-600 font-medium">Управление VPN клиентами</p>
            </div>
          </div>
        </div>

        <Card className="shadow-xl border-slate-200/50 backdrop-blur-sm bg-white/80">
          <CardHeader>
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
              <div>
                <CardTitle className="text-2xl">VPN Клиенты</CardTitle>
                <CardDescription className="text-base">Список всех подключенных клиентов</CardDescription>
              </div>
              <div className="flex flex-col sm:flex-row gap-2 w-full sm:w-auto">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => syncMutation.mutate()}
                  disabled={syncMutation.isPending}
                  className="w-full sm:w-auto"
                >
                  <RefreshCw className={`w-4 h-4 mr-2 ${syncMutation.isPending ? 'animate-spin' : ''}`} />
                  Синхронизировать
                </Button>
                <Button onClick={() => setAddDialogOpen(true)} className="w-full sm:w-auto">
                  <Plus className="w-4 h-4 mr-2" />
                  Добавить клиента
                </Button>
              </div>
            </div>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <div className="text-center py-8 text-muted-foreground">Загрузка...</div>
            ) : clients.length === 0 ? (
              <div className="text-center py-8 text-muted-foreground">
                Нет клиентов. Добавьте первого клиента!
              </div>
            ) : (
              <div className="overflow-x-auto -mx-6 sm:mx-0">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Имя</TableHead>
                    <TableHead>IP адрес</TableHead>
                    <TableHead>Статус</TableHead>
                    <TableHead>Создан</TableHead>
                    <TableHead className="text-right">Действия</TableHead>
                  </TableRow>
                </TableHeader>
                {/* SECURITY: Отображаем ТОЛЬКО безопасные данные (name, ipAddress, enabled, createdAt) */}
                {/* НЕ отображаем приватные ключи! publicKey также не показывается. */}
                {/* QR код и конфигурация загружаются ТОЛЬКО при явном клике пользователя */}
                <TableBody>
                  {clients.map((client) => (
                    <TableRow key={client.id}>
                      <TableCell className="font-medium">{client.name}</TableCell>
                      <TableCell>{client.ipAddress}</TableCell>
                      <TableCell>
                        <Badge variant={client.enabled ? 'success' : 'secondary'}>
                          {client.enabled ? 'Активен' : 'Неактивен'}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        {new Date(client.createdAt).toLocaleDateString('ru-RU')}
                      </TableCell>
                      <TableCell className="text-right">
                        <div className="flex flex-col sm:flex-row justify-end gap-2">
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => handleShowQR(client)}
                            className="w-full sm:w-auto"
                          >
                            <QrCode className="w-4 h-4" />
                          </Button>
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => handleShowConfig(client)}
                            className="w-full sm:w-auto"
                          >
                            <FileText className="w-4 h-4" />
                          </Button>
                          <Button
                            variant="destructive"
                            size="sm"
                            onClick={() => handleDeleteClick(client)}
                            className="w-full sm:w-auto"
                          >
                            <Trash2 className="w-4 h-4" />
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
              </div>
            )}
          </CardContent>
        </Card>

        <Dialog open={addDialogOpen} onOpenChange={setAddDialogOpen}>
          <DialogContent className="bg-white border-2 border-slate-200 shadow-2xl sm:max-w-[425px] w-[calc(100%-2rem)]">
            <DialogHeader>
              <DialogTitle className="text-2xl font-bold text-slate-900">Добавить нового клиента</DialogTitle>
              <DialogDescription className="text-base text-slate-600">
                Укажите имя клиента. IP адрес будет назначен автоматически.
              </DialogDescription>
            </DialogHeader>
            <div className="grid gap-4 py-4">
              <div className="grid gap-2">
                <Label htmlFor="name">Имя клиента *</Label>
                <Input
                  id="name"
                  placeholder="client1"
                  value={newClientName}
                  onChange={(e) => setNewClientName(e.target.value)}
                />
              </div>
              <div className="grid gap-2">
                <Label htmlFor="ip">IP адрес (опционально)</Label>
                <Input
                  id="ip"
                  placeholder="10.13.13.5"
                  value={newClientIp}
                  onChange={(e) => setNewClientIp(e.target.value)}
                />
              </div>
            </div>
            <DialogFooter className="flex-col sm:flex-row gap-2">
              <Button variant="outline" onClick={() => setAddDialogOpen(false)} className="w-full sm:w-auto">
                Отмена
              </Button>
              <Button onClick={handleAddClient} disabled={createMutation.isPending} className="w-full sm:w-auto">
                {createMutation.isPending ? 'Создание...' : 'Создать'}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>

        <Dialog open={qrDialogOpen} onOpenChange={setQrDialogOpen}>
          <DialogContent className="max-w-md bg-white border-2 border-slate-200 shadow-2xl w-[calc(100%-2rem)] sm:max-w-md">
            <DialogHeader>
              <DialogTitle className="text-2xl font-bold text-slate-900">QR код для {selectedClient?.name}</DialogTitle>
              <DialogDescription className="text-base text-slate-600">
                Отсканируйте QR код в приложении AmneziaWG
              </DialogDescription>
            </DialogHeader>
            <div className="flex justify-center p-4">
              {qrCodeData && (
                <img src={qrCodeData} alt="QR Code" className="max-w-full h-auto" />
              )}
            </div>
          </DialogContent>
        </Dialog>

        <Dialog open={configDialogOpen} onOpenChange={setConfigDialogOpen}>
          <DialogContent className="max-w-2xl bg-white border-2 border-slate-200 shadow-2xl w-[calc(100%-2rem)] sm:max-w-2xl">
            <DialogHeader>
              <DialogTitle className="text-2xl font-bold text-slate-900">Конфигурация {selectedClient?.name}</DialogTitle>
              <DialogDescription className="text-base text-slate-600">
                WireGuard конфигурационный файл
              </DialogDescription>
            </DialogHeader>
            <div className="py-4">
              <pre className="bg-gradient-to-br from-slate-50 to-slate-100 p-4 rounded-md overflow-auto text-xs border border-slate-200 text-slate-900">
                {configData}
              </pre>
            </div>
          </DialogContent>
        </Dialog>

        <Dialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
          <DialogContent className="bg-white border-2 border-red-200 shadow-2xl w-[calc(100%-2rem)] sm:max-w-[425px]">
            <DialogHeader>
              <DialogTitle className="text-2xl font-bold text-red-700">Удалить клиента</DialogTitle>
              <DialogDescription className="text-base text-slate-600">
                Вы уверены что хотите удалить клиента "{selectedClient?.name}"? Это
                действие нельзя отменить.
              </DialogDescription>
            </DialogHeader>
            <DialogFooter className="flex-col sm:flex-row gap-2">
              <Button variant="outline" onClick={() => setDeleteDialogOpen(false)} className="w-full sm:w-auto">
                Отмена
              </Button>
              <Button
                variant="destructive"
                onClick={handleDeleteClient}
                disabled={deleteMutation.isPending}
                className="w-full sm:w-auto"
              >
                {deleteMutation.isPending ? 'Удаление...' : 'Удалить'}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>
    </div>
  );
}

export default App;
