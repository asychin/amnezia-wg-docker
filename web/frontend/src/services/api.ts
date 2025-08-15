import axios, { AxiosResponse } from 'axios';
import type {
  ServerStatus,
  Client,
  ServerConfig,
  LogEntry,
  ConnectionStats,
  ApiResponse,
  CreateClientRequest,
  ClientConfig,
} from '@/types/api';

const api = axios.create({
  baseURL: '/api/v1',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Interceptors для обработки ошибок
api.interceptors.response.use(
  (response) => response,
  (error) => {
    console.error('API Error:', error);
    return Promise.reject(error);
  }
);

export const serverApi = {
  // Статус сервера
  getStatus: (): Promise<AxiosResponse<ApiResponse<ServerStatus>>> =>
    api.get('/server/status'),

  // Управление сервером
  start: (): Promise<AxiosResponse<ApiResponse<null>>> =>
    api.post('/server/start'),

  stop: (): Promise<AxiosResponse<ApiResponse<null>>> =>
    api.post('/server/stop'),

  restart: (): Promise<AxiosResponse<ApiResponse<null>>> =>
    api.post('/server/restart'),

  // Конфигурация сервера
  getConfig: (): Promise<AxiosResponse<ApiResponse<ServerConfig>>> =>
    api.get('/server/config'),

  updateConfig: (config: Partial<ServerConfig>): Promise<AxiosResponse<ApiResponse<null>>> =>
    api.put('/server/config', config),
};

export const clientsApi = {
  // Список клиентов
  getAll: (): Promise<AxiosResponse<ApiResponse<Client[]>>> =>
    api.get('/clients'),

  // Создание клиента
  create: (data: CreateClientRequest): Promise<AxiosResponse<ApiResponse<Client>>> =>
    api.post('/clients', data),

  // Удаление клиента
  delete: (name: string): Promise<AxiosResponse<ApiResponse<null>>> =>
    api.delete(`/clients/${encodeURIComponent(name)}`),

  // Получение конфигурации клиента
  getConfig: (name: string): Promise<AxiosResponse<ApiResponse<ClientConfig>>> =>
    api.get(`/clients/${encodeURIComponent(name)}/config`),

  // Получение QR кода
  getQrCode: (name: string): Promise<AxiosResponse<ApiResponse<string>>> =>
    api.get(`/clients/${encodeURIComponent(name)}/qr`),
};

export const logsApi = {
  // Получение логов
  getLogs: (limit = 100): Promise<AxiosResponse<ApiResponse<LogEntry[]>>> =>
    api.get(`/logs?limit=${limit}`),

  // WebSocket для real-time логов
  connectToLogs: (): WebSocket => {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const wsUrl = `${protocol}//${window.location.host}/api/v1/logs/stream`;
    return new WebSocket(wsUrl);
  },
};

export const statsApi = {
  // Статистика подключений
  getConnectionStats: (
    period: '1h' | '6h' | '24h' | '7d' = '24h'
  ): Promise<AxiosResponse<ApiResponse<ConnectionStats[]>>> =>
    api.get(`/stats/connections?period=${period}`),

  // Статистика трафика
  getTrafficStats: (
    period: '1h' | '6h' | '24h' | '7d' = '24h'
  ): Promise<AxiosResponse<ApiResponse<ConnectionStats[]>>> =>
    api.get(`/stats/traffic?period=${period}`),
};

export default api;
