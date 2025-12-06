import { useState } from 'react';
import { ChevronDown, ChevronUp, QrCode, FileText, Trash2, Download, Wifi, WifiOff, ArrowDownToLine, ArrowUpFromLine, Package } from 'lucide-react';
import { Button } from './ui/button';
import { Badge } from './ui/badge';
import { TableCell, TableRow } from './ui/table';
import { fetchClientStats, fetchClientQR, fetchClientConfig, downloadConfig, downloadQRCode, downloadBundle } from '../api/client';
import type { VpnClient, ClientStats } from '../types';

interface ClientRowProps {
  client: VpnClient;
  onShowQR: (client: VpnClient) => void;
  onShowConfig: (client: VpnClient) => void;
  onDelete: (client: VpnClient) => void;
}

function formatBytes(bytes: number): string {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

function formatTimeAgo(timestamp: number | null): string {
  if (!timestamp) return 'Никогда';
  const seconds = Math.floor((Date.now() - timestamp) / 1000);
  if (seconds < 60) return `${seconds} сек. назад`;
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes} мин. назад`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours} ч. назад`;
  const days = Math.floor(hours / 24);
  return `${days} дн. назад`;
}

export function ClientRow({ client, onShowQR, onShowConfig, onDelete }: ClientRowProps) {
  const [expanded, setExpanded] = useState(false);
  const [stats, setStats] = useState<ClientStats | null>(null);
  const [loading, setLoading] = useState(false);
  const [downloading, setDownloading] = useState(false);

  const handleExpand = async () => {
    if (!expanded) {
      setLoading(true);
      try {
        const clientStats = await fetchClientStats(client.name);
        setStats(clientStats);
      } catch (error) {
        console.error('Failed to fetch stats:', error);
      } finally {
        setLoading(false);
      }
    }
    setExpanded(!expanded);
  };

  const handleDownloadConfig = async () => {
    setDownloading(true);
    try {
      const config = await fetchClientConfig(client.name);
      downloadConfig(client.name, config);
    } catch (error) {
      console.error('Failed to download config:', error);
    } finally {
      setDownloading(false);
    }
  };

  const handleDownloadQR = async () => {
    setDownloading(true);
    try {
      const { qrCode } = await fetchClientQR(client.name);
      downloadQRCode(client.name, qrCode);
    } catch (error) {
      console.error('Failed to download QR:', error);
    } finally {
      setDownloading(false);
    }
  };

  const handleDownloadBundle = async () => {
    setDownloading(true);
    try {
      const result = await downloadBundle(client.name);
      if (!result.success) {
        alert(result.error || 'Не удалось скачать конфигурацию');
      } else {
        window.location.reload();
      }
    } catch (error) {
      console.error('Failed to download bundle:', error);
      alert('Не удалось скачать конфигурацию');
    } finally {
      setDownloading(false);
    }
  };

  return (
    <>
      <TableRow 
        className="cursor-pointer hover:bg-slate-50 transition-colors"
        onClick={handleExpand}
      >
        <TableCell className="font-medium">
          <div className="flex items-center gap-2">
            {expanded ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
            {client.name}
          </div>
        </TableCell>
        <TableCell>{client.ipAddress}</TableCell>
                <TableCell>
                  <Badge variant={client.enabled ? 'success' : 'secondary'}>
                    {client.enabled ? 'Активен' : 'Неактивен'}
                  </Badge>
                </TableCell>
        <TableCell>
          {new Date(client.createdAt).toLocaleDateString('ru-RU')}
        </TableCell>
                <TableCell className="text-right" onClick={(e) => e.stopPropagation()}>
                  <div className="flex flex-col sm:flex-row justify-end gap-2">
                    <Button
                      variant="default"
                      size="sm"
                      onClick={handleDownloadBundle}
                      disabled={downloading}
                      className="w-full sm:w-auto bg-green-600 hover:bg-green-700"
                      title="Скачать ZIP с конфигом и QR кодом"
                    >
                      <Package className="w-4 h-4 mr-1" />
                      {downloading ? '...' : 'ZIP'}
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => onShowQR(client)}
                      className="w-full sm:w-auto"
                      title="Показать QR код"
                    >
                      <QrCode className="w-4 h-4" />
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => onShowConfig(client)}
                      className="w-full sm:w-auto"
                      title="Показать конфигурацию"
                    >
                      <FileText className="w-4 h-4" />
                    </Button>
                    <Button
                      variant="destructive"
                      size="sm"
                      onClick={() => onDelete(client)}
                      className="w-full sm:w-auto"
                      title="Удалить клиента"
                    >
                      <Trash2 className="w-4 h-4" />
                    </Button>
                  </div>
                </TableCell>
      </TableRow>
      
      {expanded && (
        <TableRow className="bg-gradient-to-r from-slate-50 to-blue-50">
          <TableCell colSpan={5} className="p-0">
            <div className="p-4 space-y-4">
              {loading ? (
                <div className="text-center py-4 text-muted-foreground">
                  Загрузка статистики...
                </div>
              ) : stats ? (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                  <div className="bg-white rounded-lg p-4 shadow-sm border border-slate-200">
                    <div className="flex items-center gap-2 text-sm text-slate-500 mb-1">
                      {stats.connected ? (
                        <Wifi className="w-4 h-4 text-green-500" />
                      ) : (
                        <WifiOff className="w-4 h-4 text-slate-400" />
                      )}
                      Статус подключения
                    </div>
                    <div className="text-lg font-semibold">
                      {stats.connected ? (
                        <span className="text-green-600">Онлайн</span>
                      ) : (
                        <span className="text-slate-500">Оффлайн</span>
                      )}
                    </div>
                    {stats.endpoint && (
                      <div className="text-xs text-slate-400 mt-1">
                        IP: {stats.endpoint}
                      </div>
                    )}
                  </div>
                  
                  <div className="bg-white rounded-lg p-4 shadow-sm border border-slate-200">
                    <div className="text-sm text-slate-500 mb-1">Последний handshake</div>
                    <div className="text-lg font-semibold">
                      {formatTimeAgo(stats.latestHandshake)}
                    </div>
                    {stats.latestHandshake && (
                      <div className="text-xs text-slate-400 mt-1">
                        {new Date(stats.latestHandshake).toLocaleString('ru-RU')}
                      </div>
                    )}
                  </div>
                  
                  <div className="bg-white rounded-lg p-4 shadow-sm border border-slate-200">
                    <div className="flex items-center gap-2 text-sm text-slate-500 mb-1">
                      <ArrowDownToLine className="w-4 h-4 text-blue-500" />
                      Получено
                    </div>
                    <div className="text-lg font-semibold text-blue-600">
                      {formatBytes(stats.transferRx)}
                    </div>
                  </div>
                  
                  <div className="bg-white rounded-lg p-4 shadow-sm border border-slate-200">
                    <div className="flex items-center gap-2 text-sm text-slate-500 mb-1">
                      <ArrowUpFromLine className="w-4 h-4 text-green-500" />
                      Отправлено
                    </div>
                    <div className="text-lg font-semibold text-green-600">
                      {formatBytes(stats.transferTx)}
                    </div>
                  </div>
                </div>
              ) : (
                <div className="text-center py-4 text-muted-foreground">
                  Статистика недоступна
                </div>
              )}
              
                            <div className="flex flex-wrap gap-2 pt-2 border-t border-slate-200">
                              <Button
                                variant="default"
                                size="sm"
                                onClick={handleDownloadBundle}
                                disabled={downloading}
                                className="bg-green-600 hover:bg-green-700"
                              >
                                <Package className="w-4 h-4 mr-2" />
                                Скачать ZIP (конфиг + QR)
                              </Button>
                              <Button
                                variant="outline"
                                size="sm"
                                onClick={handleDownloadConfig}
                                disabled={downloading}
                              >
                                <Download className="w-4 h-4 mr-2" />
                                Скачать .conf
                              </Button>
                              <Button
                                variant="outline"
                                size="sm"
                                onClick={handleDownloadQR}
                                disabled={downloading}
                              >
                                <Download className="w-4 h-4 mr-2" />
                                Скачать QR (PNG)
                              </Button>
                            </div>
            </div>
          </TableCell>
        </TableRow>
      )}
    </>
  );
}
