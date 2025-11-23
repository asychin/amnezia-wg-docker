import React from 'react';
import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Plus, Trash2, QrCode, FileText, RefreshCw, Shield } from 'lucide-react';
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
    },
  });

  const deleteMutation = useMutation({
    mutationFn: deleteClient,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['clients'] });
      setDeleteDialogOpen(false);
      setSelectedClient(null);
    },
  });

  const syncMutation = useMutation({
    mutationFn: syncClients,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['clients'] });
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
    }
  };

  const handleDeleteClick = (client: VpnClient) => {
    setSelectedClient(client);
    setDeleteDialogOpen(true);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 p-4 md:p-8">
      <div className="max-w-7xl mx-auto">
        <div className="mb-8">
          <div className="flex items-center gap-3 mb-2">
            <Shield className="w-10 h-10 text-primary" />
            <h1 className="text-4xl font-bold text-slate-900">AmneziaWG VPN</h1>
          </div>
          <p className="text-slate-600">Управление VPN клиентами</p>
        </div>

        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <div>
                <CardTitle>VPN Клиенты</CardTitle>
                <CardDescription>Список всех подключенных клиентов</CardDescription>
              </div>
              <div className="flex gap-2">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => syncMutation.mutate()}
                  disabled={syncMutation.isPending}
                >
                  <RefreshCw className={`w-4 h-4 mr-2 ${syncMutation.isPending ? 'animate-spin' : ''}`} />
                  Синхронизировать
                </Button>
                <Button onClick={() => setAddDialogOpen(true)}>
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
                        <div className="flex justify-end gap-2">
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => handleShowQR(client)}
                          >
                            <QrCode className="w-4 h-4" />
                          </Button>
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => handleShowConfig(client)}
                          >
                            <FileText className="w-4 h-4" />
                          </Button>
                          <Button
                            variant="destructive"
                            size="sm"
                            onClick={() => handleDeleteClick(client)}
                          >
                            <Trash2 className="w-4 h-4" />
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            )}
          </CardContent>
        </Card>

        <Dialog open={addDialogOpen} onOpenChange={setAddDialogOpen}>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Добавить нового клиента</DialogTitle>
              <DialogDescription>
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
            <DialogFooter>
              <Button variant="outline" onClick={() => setAddDialogOpen(false)}>
                Отмена
              </Button>
              <Button onClick={handleAddClient} disabled={createMutation.isPending}>
                {createMutation.isPending ? 'Создание...' : 'Создать'}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>

        <Dialog open={qrDialogOpen} onOpenChange={setQrDialogOpen}>
          <DialogContent className="max-w-md">
            <DialogHeader>
              <DialogTitle>QR код для {selectedClient?.name}</DialogTitle>
              <DialogDescription>
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
          <DialogContent className="max-w-2xl">
            <DialogHeader>
              <DialogTitle>Конфигурация {selectedClient?.name}</DialogTitle>
              <DialogDescription>
                WireGuard конфигурационный файл
              </DialogDescription>
            </DialogHeader>
            <div className="py-4">
              <pre className="bg-slate-100 p-4 rounded-md overflow-auto text-xs">
                {configData}
              </pre>
            </div>
          </DialogContent>
        </Dialog>

        <Dialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Удалить клиента</DialogTitle>
              <DialogDescription>
                Вы уверены что хотите удалить клиента "{selectedClient?.name}"? Это
                действие нельзя отменить.
              </DialogDescription>
            </DialogHeader>
            <DialogFooter>
              <Button variant="outline" onClick={() => setDeleteDialogOpen(false)}>
                Отмена
              </Button>
              <Button
                variant="destructive"
                onClick={handleDeleteClient}
                disabled={deleteMutation.isPending}
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
