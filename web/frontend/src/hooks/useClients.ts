import { useQuery, useMutation, useQueryClient } from 'react-query';
import { useCurrentServerApi } from './useCurrentServerApi';
import type { Client, CreateClientRequest, ClientConfig } from '@/types/api';

export function useClients() {
  const { apis, currentServer, isConnected } = useCurrentServerApi();

  return useQuery<Client[]>({
    queryKey: ['clients', currentServer?.id],
    queryFn: async () => {
      if (!apis) {
        throw new Error('No server connected');
      }
      const response = await apis.clients.getAll();
      if (!response.data.success) {
        throw new Error(response.data.error || 'Failed to fetch clients');
      }
      return response.data.data!;
    },
    enabled: isConnected && !!apis,
    refetchInterval: isConnected ? 10000 : false, // Обновляем список клиентов каждые 10 секунд
  });
}

export function useClientConfig(name: string, enabled = true) {
  const { apis, currentServer, isConnected } = useCurrentServerApi();

  return useQuery<ClientConfig>({
    queryKey: ['clients', name, 'config', currentServer?.id],
    queryFn: async () => {
      if (!apis) {
        throw new Error('No server connected');
      }
      const response = await apis.clients.getConfig(name);
      if (!response.data.success) {
        throw new Error(response.data.error || 'Failed to fetch client config');
      }
      return response.data.data!;
    },
    enabled: enabled && isConnected && !!apis,
  });
}

export function useClientQrCode(name: string, enabled = true) {
  const { apis, currentServer, isConnected } = useCurrentServerApi();

  return useQuery<string>({
    queryKey: ['clients', name, 'qr', currentServer?.id],
    queryFn: async () => {
      if (!apis) {
        throw new Error('No server connected');
      }
      const response = await apis.clients.getQrCode(name);
      if (!response.data.success) {
        throw new Error(response.data.error || 'Failed to fetch QR code');
      }
      return response.data.data!;
    },
    enabled: enabled && isConnected && !!apis,
  });
}

export function useClientManagement() {
  const queryClient = useQueryClient();
  const { apis, currentServer, isConnected } = useCurrentServerApi();

  const createClient = useMutation({
    mutationFn: async (data: CreateClientRequest) => {
      if (!apis) throw new Error('No server connected');
      return apis.clients.create(data);
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['clients', currentServer?.id]);
      queryClient.invalidateQueries(['server', 'status', currentServer?.id]);
    },
  });

  const deleteClient = useMutation({
    mutationFn: async (name: string) => {
      if (!apis) throw new Error('No server connected');
      return apis.clients.delete(name);
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['clients', currentServer?.id]);
      queryClient.invalidateQueries(['server', 'status', currentServer?.id]);
    },
  });

  return {
    createClient,
    deleteClient,
    isConnected,
    hasServer: !!currentServer,
  };
}
