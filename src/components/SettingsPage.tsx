import { useState } from 'react';
import { useQuery, useMutation } from '@tanstack/react-query';
import { Settings, AlertTriangle, Database, ArrowRight, RefreshCw, Shield } from 'lucide-react';
import { Button } from './ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from './ui/dialog';
import { useToast } from '../hooks/use-toast';
import { fetchLegacyClients, migrateAllClients, syncClients } from '../api/client';

interface SettingsPageProps {
  onBack: () => void;
}

export function SettingsPage({ onBack }: SettingsPageProps) {
  const { toast } = useToast();
  const [migrateDialogOpen, setMigrateDialogOpen] = useState(false);

  const { data: legacyData, isLoading: legacyLoading, refetch: refetchLegacy } = useQuery({
    queryKey: ['legacy-clients'],
    queryFn: fetchLegacyClients,
  });

  const migrateMutation = useMutation({
    mutationFn: migrateAllClients,
    onSuccess: (data) => {
      toast({
        title: 'Миграция завершена',
        description: `Успешно мигрировано ${data.migratedCount} клиентов`,
      });
      setMigrateDialogOpen(false);
      refetchLegacy();
    },
    onError: (error: Error) => {
      toast({
        title: 'Ошибка миграции',
        description: error.message || 'Не удалось выполнить миграцию',
      });
    },
  });

  const syncMutation = useMutation({
    mutationFn: syncClients,
    onSuccess: () => {
      toast({
        title: 'Синхронизация завершена',
        description: 'Клиенты успешно синхронизированы с файловой системой',
      });
      refetchLegacy();
    },
    onError: (error: Error) => {
      toast({
        title: 'Ошибка синхронизации',
        description: error.message || 'Не удалось синхронизировать клиентов',
      });
    },
  });

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-indigo-50 to-purple-50 p-4 md:p-8">
      <div className="max-w-4xl mx-auto">
        <div className="mb-8">
          <Button variant="outline" onClick={onBack} className="mb-4">
            <ArrowRight className="w-4 h-4 mr-2 rotate-180" />
            Назад к клиентам
          </Button>
          <div className="flex items-center gap-3 mb-2">
            <div className="p-2 bg-gradient-to-br from-slate-600 to-slate-700 rounded-lg">
              <Settings className="w-8 h-8 text-white" />
            </div>
            <div>
              <h1 className="text-4xl font-bold bg-gradient-to-r from-slate-700 to-slate-900 bg-clip-text text-transparent">
                Настройки
              </h1>
              <p className="text-slate-600 font-medium">Управление сервером и миграция данных</p>
            </div>
          </div>
        </div>

        <div className="space-y-6">
          <Card className="shadow-xl border-slate-200/50 backdrop-blur-sm bg-white/80">
            <CardHeader>
              <div className="flex items-center gap-2">
                <Database className="w-5 h-5 text-blue-600" />
                <CardTitle className="text-xl">Миграция с версии 1.x</CardTitle>
              </div>
              <CardDescription className="text-base">
                Перенос клиентов из flat-file конфигураций в базу данных PostgreSQL
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                <h4 className="font-semibold text-blue-800 mb-2">Что делает миграция?</h4>
                <ul className="text-sm text-blue-700 space-y-1">
                  <li>- Сканирует папку <code className="bg-blue-100 px-1 rounded">clients/</code> на наличие .conf файлов</li>
                  <li>- Извлекает данные клиентов (имя, IP, публичный ключ)</li>
                  <li>- Создает записи в базе данных PostgreSQL</li>
                  <li>- Оригинальные файлы конфигурации сохраняются</li>
                </ul>
              </div>

              {legacyLoading ? (
                <div className="text-center py-4 text-muted-foreground">
                  Проверка legacy клиентов...
                </div>
              ) : (
                <div className="bg-slate-50 border border-slate-200 rounded-lg p-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="font-medium">Найдено legacy клиентов:</p>
                      <p className="text-2xl font-bold text-slate-700">
                        {legacyData?.count || 0}
                      </p>
                    </div>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => refetchLegacy()}
                    >
                      <RefreshCw className="w-4 h-4 mr-2" />
                      Обновить
                    </Button>
                  </div>
                  
                  {legacyData && legacyData.count > 0 && (
                    <div className="mt-4">
                      <p className="text-sm text-slate-600 mb-2">Клиенты для миграции:</p>
                      <div className="flex flex-wrap gap-2">
                        {legacyData.legacyClients.map((client) => (
                          <span
                            key={client.name}
                            className="bg-white px-2 py-1 rounded border border-slate-200 text-sm"
                          >
                            {client.name} ({client.ipAddress})
                          </span>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              )}

              <div className="flex gap-2">
                <Button
                  onClick={() => setMigrateDialogOpen(true)}
                  disabled={!legacyData || legacyData.count === 0 || migrateMutation.isPending}
                  className="bg-blue-600 hover:bg-blue-700"
                >
                  <Database className="w-4 h-4 mr-2" />
                  Мигрировать всех клиентов
                </Button>
                <Button
                  variant="outline"
                  onClick={() => syncMutation.mutate()}
                  disabled={syncMutation.isPending}
                >
                  <RefreshCw className={`w-4 h-4 mr-2 ${syncMutation.isPending ? 'animate-spin' : ''}`} />
                  Синхронизировать
                </Button>
              </div>
            </CardContent>
          </Card>

          <Card className="shadow-xl border-red-200/50 backdrop-blur-sm bg-white/80">
            <CardHeader>
              <div className="flex items-center gap-2">
                <AlertTriangle className="w-5 h-5 text-red-600" />
                <CardTitle className="text-xl text-red-700">Danger Zone</CardTitle>
              </div>
              <CardDescription className="text-base">
                Опасные операции, которые могут привести к потере данных
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="bg-red-50 border border-red-200 rounded-lg p-4">
                <div className="flex items-start gap-3">
                  <AlertTriangle className="w-5 h-5 text-red-500 mt-0.5" />
                  <div>
                    <h4 className="font-semibold text-red-800">Внимание!</h4>
                    <p className="text-sm text-red-700">
                      Операции в этой секции необратимы. Перед выполнением убедитесь, 
                      что у вас есть резервная копия данных.
                    </p>
                  </div>
                </div>
              </div>

              <div className="border border-red-200 rounded-lg p-4 space-y-3">
                <div className="flex items-center justify-between">
                  <div>
                    <h4 className="font-medium text-slate-900">Сбросить базу данных</h4>
                    <p className="text-sm text-slate-500">
                      Удалить все записи клиентов из базы данных (файлы конфигурации сохранятся)
                    </p>
                  </div>
                  <Button variant="destructive" size="sm" disabled>
                    Сбросить БД
                  </Button>
                </div>
              </div>

              <div className="border border-red-200 rounded-lg p-4 space-y-3">
                <div className="flex items-center justify-between">
                  <div>
                    <h4 className="font-medium text-slate-900">Удалить все данные</h4>
                    <p className="text-sm text-slate-500">
                      Полное удаление всех клиентов из БД и файловой системы
                    </p>
                  </div>
                  <Button variant="destructive" size="sm" disabled>
                    Удалить всё
                  </Button>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="shadow-xl border-slate-200/50 backdrop-blur-sm bg-white/80">
            <CardHeader>
              <div className="flex items-center gap-2">
                <Shield className="w-5 h-5 text-green-600" />
                <CardTitle className="text-xl">Информация о системе</CardTitle>
              </div>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <p className="text-slate-500">Версия</p>
                  <p className="font-medium">2.0.0</p>
                </div>
                <div>
                  <p className="text-slate-500">Режим работы</p>
                  <p className="font-medium">Full Stack (VPN + Web + PostgreSQL)</p>
                </div>
                <div>
                  <p className="text-slate-500">VPN порт</p>
                  <p className="font-medium">51820/UDP</p>
                </div>
                <div>
                  <p className="text-slate-500">Web порт</p>
                  <p className="font-medium">8080</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        <Dialog open={migrateDialogOpen} onOpenChange={setMigrateDialogOpen}>
          <DialogContent className="bg-white border-2 border-blue-200 shadow-2xl">
            <DialogHeader>
              <DialogTitle className="text-2xl font-bold text-slate-900">
                Подтверждение миграции
              </DialogTitle>
              <DialogDescription className="text-base text-slate-600">
                Вы собираетесь мигрировать {legacyData?.count || 0} клиентов из flat-file 
                конфигураций в базу данных PostgreSQL.
              </DialogDescription>
            </DialogHeader>
            <div className="py-4">
              <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                <p className="text-sm text-blue-700">
                  После миграции все клиенты будут управляться через базу данных. 
                  Оригинальные файлы конфигурации останутся на месте.
                </p>
              </div>
            </div>
            <DialogFooter>
              <Button variant="outline" onClick={() => setMigrateDialogOpen(false)}>
                Отмена
              </Button>
              <Button
                onClick={() => migrateMutation.mutate()}
                disabled={migrateMutation.isPending}
                className="bg-blue-600 hover:bg-blue-700"
              >
                {migrateMutation.isPending ? 'Миграция...' : 'Начать миграцию'}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>
    </div>
  );
}
