import { useQuery } from '@tanstack/react-query';
import { 
  Users, 
  Wifi, 
  WifiOff, 
  ArrowDownToLine, 
  Plus,
  Settings,
  Activity
} from 'lucide-react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { fetchClients } from '../api/client';

interface DashboardProps {
  onNavigate: (page: 'clients' | 'settings') => void;
  onAddClient: () => void;
}

export function Dashboard({ onNavigate, onAddClient }: DashboardProps) {
  const { data: clients = [], isLoading } = useQuery({
    queryKey: ['clients'],
    queryFn: fetchClients,
  });

  const totalClients = clients.length;
  const activeClients = clients.filter(c => c.enabled).length;
  const downloadedConfigs = clients.filter(c => c.configDownloadedAt).length;

  const stats = [
    {
      title: 'Всего клиентов',
      value: totalClients,
      icon: Users,
      color: 'blue',
      description: 'Зарегистрировано в системе'
    },
    {
      title: 'Активные',
      value: activeClients,
      icon: Wifi,
      color: 'green',
      description: 'Включены и готовы к подключению'
    },
    {
      title: 'Конфиги скачаны',
      value: downloadedConfigs,
      icon: ArrowDownToLine,
      color: 'purple',
      description: 'Клиенты получили конфигурацию'
    },
    {
      title: 'Ожидают настройки',
      value: totalClients - downloadedConfigs,
      icon: WifiOff,
      color: 'orange',
      description: 'Не скачали конфигурацию'
    },
  ];

  const colorClasses = {
    blue: 'bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400',
    green: 'bg-green-50 dark:bg-green-900/20 text-green-600 dark:text-green-400',
    purple: 'bg-purple-50 dark:bg-purple-900/20 text-purple-600 dark:text-purple-400',
    orange: 'bg-orange-50 dark:bg-orange-900/20 text-orange-600 dark:text-orange-400',
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-slate-500 dark:text-slate-400">Загрузка...</div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Stats Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {stats.map((stat) => {
          const Icon = stat.icon;
          return (
            <Card key={stat.title} className="bg-white dark:bg-slate-800 border-slate-200 dark:border-slate-700">
              <CardContent className="p-6">
                <div className="flex items-start justify-between">
                  <div>
                    <p className="text-sm font-medium text-slate-500 dark:text-slate-400">
                      {stat.title}
                    </p>
                    <p className="text-3xl font-bold text-slate-900 dark:text-white mt-1">
                      {stat.value}
                    </p>
                    <p className="text-xs text-slate-400 dark:text-slate-500 mt-1">
                      {stat.description}
                    </p>
                  </div>
                  <div className={`p-3 rounded-lg ${colorClasses[stat.color as keyof typeof colorClasses]}`}>
                    <Icon className="w-5 h-5" />
                  </div>
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {/* Quick Actions */}
      <Card className="bg-white dark:bg-slate-800 border-slate-200 dark:border-slate-700">
        <CardHeader>
          <CardTitle className="text-lg text-slate-900 dark:text-white">Быстрые действия</CardTitle>
          <CardDescription className="text-slate-500 dark:text-slate-400">
            Часто используемые операции
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex flex-wrap gap-3">
            <Button onClick={onAddClient} className="bg-blue-600 hover:bg-blue-700">
              <Plus className="w-4 h-4 mr-2" />
              Добавить клиента
            </Button>
            <Button variant="outline" onClick={() => onNavigate('clients')} className="dark:border-slate-600 dark:text-slate-300">
              <Users className="w-4 h-4 mr-2" />
              Управление клиентами
            </Button>
            <Button variant="outline" onClick={() => onNavigate('settings')} className="dark:border-slate-600 dark:text-slate-300">
              <Settings className="w-4 h-4 mr-2" />
              Настройки
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Recent Clients */}
      <Card className="bg-white dark:bg-slate-800 border-slate-200 dark:border-slate-700">
        <CardHeader>
          <CardTitle className="text-lg text-slate-900 dark:text-white">Последние клиенты</CardTitle>
          <CardDescription className="text-slate-500 dark:text-slate-400">
            Недавно добавленные VPN клиенты
          </CardDescription>
        </CardHeader>
        <CardContent>
          {clients.length === 0 ? (
            <div className="text-center py-8 text-slate-500 dark:text-slate-400">
              <Users className="w-12 h-12 mx-auto mb-3 opacity-50" />
              <p>Нет клиентов</p>
              <p className="text-sm mt-1">Добавьте первого клиента для начала работы</p>
            </div>
          ) : (
            <div className="space-y-3">
              {clients.slice(0, 5).map((client) => (
                <div 
                  key={client.id}
                  className="flex items-center justify-between p-3 rounded-lg bg-slate-50 dark:bg-slate-700/50"
                >
                  <div className="flex items-center gap-3">
                    <div className={`w-2 h-2 rounded-full ${client.enabled ? 'bg-green-500' : 'bg-slate-400'}`} />
                    <div>
                      <p className="font-medium text-slate-900 dark:text-white">{client.name}</p>
                      <p className="text-sm text-slate-500 dark:text-slate-400">{client.ipAddress}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="text-xs text-slate-500 dark:text-slate-400">
                      {new Date(client.createdAt).toLocaleDateString('ru-RU')}
                    </p>
                    {client.configDownloadedAt && (
                      <p className="text-xs text-green-600 dark:text-green-400">Настроен</p>
                    )}
                  </div>
                </div>
              ))}
              {clients.length > 5 && (
                <Button 
                  variant="ghost" 
                  className="w-full text-slate-500 dark:text-slate-400"
                  onClick={() => onNavigate('clients')}
                >
                  Показать всех ({clients.length})
                </Button>
              )}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Server Info */}
      <Card className="bg-white dark:bg-slate-800 border-slate-200 dark:border-slate-700">
        <CardHeader>
          <div className="flex items-center gap-2">
            <Activity className="w-5 h-5 text-green-600" />
            <CardTitle className="text-lg text-slate-900 dark:text-white">Статус сервера</CardTitle>
          </div>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
            <div>
              <p className="text-slate-500 dark:text-slate-400">Статус</p>
              <p className="font-medium text-green-600 dark:text-green-400 flex items-center gap-1">
                <span className="w-2 h-2 bg-green-500 rounded-full animate-pulse" />
                Активен
              </p>
            </div>
            <div>
              <p className="text-slate-500 dark:text-slate-400">VPN порт</p>
              <p className="font-medium text-slate-900 dark:text-white">51820/UDP</p>
            </div>
            <div>
              <p className="text-slate-500 dark:text-slate-400">Web порт</p>
              <p className="font-medium text-slate-900 dark:text-white">8080</p>
            </div>
            <div>
              <p className="text-slate-500 dark:text-slate-400">Версия</p>
              <p className="font-medium text-slate-900 dark:text-white">2.0.0</p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
