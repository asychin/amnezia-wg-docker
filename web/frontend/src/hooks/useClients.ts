import { useQuery, useMutation, useQueryClient } from 'react-query';
import { clientsApi } from '@/services/api';
import type { Client, CreateClientRequest, ClientConfig } from '@/types/api';

export function useClients() {
  return useQuery<Client[]>({
    queryKey: ['clients'],
    queryFn: async () => {
      const response = await clientsApi.getAll();
      if (!response.data.success) {
        throw new Error(response.data.error || 'Failed to fetch clients');
      }
      return response.data.data!;
    },
    refetchInterval: 10000, // Обновляем список клиентов каждые 10 секунд
  });
}

export function useClientConfig(name: string, enabled = true) {
  return useQuery<ClientConfig>({
    queryKey: ['clients', name, 'config'],
    queryFn: async () => {
      const response = await clientsApi.getConfig(name);
      if (!response.data.success) {
        throw new Error(response.data.error || 'Failed to fetch client config');
      }
      return response.data.data!;
    },
    enabled,
  });
}

export function useClientQrCode(name: string, enabled = true) {
  return useQuery<string>({
    queryKey: ['clients', name, 'qr'],
    queryFn: async () => {
      const response = await clientsApi.getQrCode(name);
      if (!response.data.success) {
        throw new Error(response.data.error || 'Failed to fetch QR code');
      }
      return response.data.data!;
    },
    enabled,
  });
}

export function useClientManagement() {
  const queryClient = useQueryClient();

  const createClient = useMutation({
    mutationFn: (data: CreateClientRequest) => clientsApi.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries(['clients']);
      queryClient.invalidateQueries(['server', 'status']);
    },
  });

  const deleteClient = useMutation({
    mutationFn: (name: string) => clientsApi.delete(name),
    onSuccess: () => {
      queryClient.invalidateQueries(['clients']);
      queryClient.invalidateQueries(['server', 'status']);
    },
  });

  return {
    createClient,
    deleteClient,
  };
}
