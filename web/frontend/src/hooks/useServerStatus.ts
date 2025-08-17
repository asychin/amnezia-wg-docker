import { useQuery, useMutation, useQueryClient } from 'react-query';
import { useCurrentServerApi } from './useCurrentServerApi';
import type { ServerStatus, ServerConfig } from '@/types/api';

export function useServerStatus() {
  const { apis, currentServer, isConnected } = useCurrentServerApi();

  return useQuery<ServerStatus>({
    queryKey: ['server', 'status', currentServer?.id],
    queryFn: async () => {
      if (!apis) {
        throw new Error('No server connected');
      }
      const response = await apis.server.getStatus();
      if (!response.data.success) {
        throw new Error(response.data.error || 'Failed to fetch server status');
      }
      return response.data.data!;
    },
    enabled: isConnected && !!apis,
    refetchInterval: isConnected ? 5000 : false, // Обновляем статус каждые 5 секунд только если подключены
    retry: 3,
  });
}

export function useServerConfig() {
  const { apis, currentServer, isConnected } = useCurrentServerApi();

  return useQuery<ServerConfig>({
    queryKey: ['server', 'config', currentServer?.id],
    queryFn: async () => {
      if (!apis) {
        throw new Error('No server connected');
      }
      const response = await apis.server.getConfig();
      if (!response.data.success) {
        throw new Error(response.data.error || 'Failed to fetch server config');
      }
      return response.data.data!;
    },
    enabled: isConnected && !!apis,
  });
}

export function useServerControl() {
  const queryClient = useQueryClient();
  const { apis, currentServer, isConnected } = useCurrentServerApi();

  const startServer = useMutation({
    mutationFn: async () => {
      if (!apis) throw new Error('No server connected');
      return apis.server.start();
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['server', 'status', currentServer?.id]);
    },
  });

  const stopServer = useMutation({
    mutationFn: async () => {
      if (!apis) throw new Error('No server connected');
      return apis.server.stop();
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['server', 'status', currentServer?.id]);
    },
  });

  const restartServer = useMutation({
    mutationFn: async () => {
      if (!apis) throw new Error('No server connected');
      return apis.server.restart();
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['server', 'status', currentServer?.id]);
    },
  });

  const updateConfig = useMutation({
    mutationFn: async (config: Partial<ServerConfig>) => {
      if (!apis) throw new Error('No server connected');
      return apis.server.updateConfig(config);
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['server', 'config', currentServer?.id]);
      queryClient.invalidateQueries(['server', 'status', currentServer?.id]);
    },
  });

  return {
    startServer,
    stopServer,
    restartServer,
    updateConfig,
    isConnected,
    hasServer: !!currentServer,
  };
}
