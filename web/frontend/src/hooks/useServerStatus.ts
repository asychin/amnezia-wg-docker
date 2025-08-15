import { useQuery, useMutation, useQueryClient } from 'react-query';
import { serverApi } from '@/services/api';
import type { ServerStatus, ServerConfig } from '@/types/api';

export function useServerStatus() {
  return useQuery<ServerStatus>({
    queryKey: ['server', 'status'],
    queryFn: async () => {
      const response = await serverApi.getStatus();
      if (!response.data.success) {
        throw new Error(response.data.error || 'Failed to fetch server status');
      }
      return response.data.data!;
    },
    refetchInterval: 5000, // Обновляем статус каждые 5 секунд
    retry: 3,
  });
}

export function useServerConfig() {
  return useQuery<ServerConfig>({
    queryKey: ['server', 'config'],
    queryFn: async () => {
      const response = await serverApi.getConfig();
      if (!response.data.success) {
        throw new Error(response.data.error || 'Failed to fetch server config');
      }
      return response.data.data!;
    },
  });
}

export function useServerControl() {
  const queryClient = useQueryClient();

  const startServer = useMutation({
    mutationFn: serverApi.start,
    onSuccess: () => {
      queryClient.invalidateQueries(['server', 'status']);
    },
  });

  const stopServer = useMutation({
    mutationFn: serverApi.stop,
    onSuccess: () => {
      queryClient.invalidateQueries(['server', 'status']);
    },
  });

  const restartServer = useMutation({
    mutationFn: serverApi.restart,
    onSuccess: () => {
      queryClient.invalidateQueries(['server', 'status']);
    },
  });

  const updateConfig = useMutation({
    mutationFn: serverApi.updateConfig,
    onSuccess: () => {
      queryClient.invalidateQueries(['server', 'config']);
      queryClient.invalidateQueries(['server', 'status']);
    },
  });

  return {
    startServer,
    stopServer,
    restartServer,
    updateConfig,
  };
}
