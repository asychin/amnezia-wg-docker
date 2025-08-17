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

// Create a function that returns a configured API instance for a specific server
export const createApiInstance = (endpoint: string, token?: string) => {
  const api = axios.create({
    baseURL: `${endpoint}/api/v1`,
    timeout: 10000,
    headers: {
      'Content-Type': 'application/json',
      ...(token && { Authorization: `Bearer ${token}` }),
    },
  });

  // Interceptors для обработки ошибок
  api.interceptors.response.use(
    (response) => response,
    (error) => {
      console.error('API Error:', error);
      // Handle token expiration
      if (error.response?.status === 401) {
        // TODO: Refresh token logic
        console.warn('Token expired, need to refresh');
      }
      return Promise.reject(error);
    }
  );

  return api;
};

// Legacy single-server API (for backward compatibility)
const defaultApi = createApiInstance('/api/v1');

// Server API functions that accept an API instance
export const createServerApi = (api: ReturnType<typeof createApiInstance>) => ({
  // Server info (public endpoint)
  getInfo: (): Promise<AxiosResponse<ApiResponse<any>>> =>
    api.get('/server/info'),

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
});

export const createClientsApi = (api: ReturnType<typeof createApiInstance>) => ({
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
});

export const createLogsApi = (api: ReturnType<typeof createApiInstance>, endpoint: string) => ({
  // Получение логов
  getLogs: (limit = 100): Promise<AxiosResponse<ApiResponse<LogEntry[]>>> =>
    api.get(`/logs?limit=${limit}`),

  // WebSocket для real-time логов
  connectToLogs: (): WebSocket => {
    const url = new URL(endpoint);
    const protocol = url.protocol === 'https:' ? 'wss:' : 'ws:';
    const wsUrl = `${protocol}//${url.host}/api/v1/logs/stream`;
    return new WebSocket(wsUrl);
  },
});

export const createStatsApi = (api: ReturnType<typeof createApiInstance>) => ({
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
});

// Legacy APIs for backward compatibility
export const serverApi = createServerApi(defaultApi);
export const clientsApi = createClientsApi(defaultApi);
export const logsApi = createLogsApi(defaultApi, window.location.origin);
export const statsApi = createStatsApi(defaultApi);

export default defaultApi;
