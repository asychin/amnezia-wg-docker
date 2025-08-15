import React, { useState } from 'react';
import {
  Box,
  Button,
  Card,
  Flex,
  Heading,
  HStack,
  IconButton,
  Input,
  DialogRoot,

  DialogContent,
  DialogHeader,
  DialogBody,
  DialogFooter,
  DialogTitle,

  Stack,
  Table,
  Text,
  Badge,
  VStack,
  useDisclosure,
  Field,
  Textarea,
} from '@chakra-ui/react';
import { 
  LuPlus, 
  LuTrash2, 
  LuQrCode, 
  LuDownload, 
  LuUsers,
  LuWifi,
  LuWifiOff,
  LuCopy
} from 'react-icons/lu';
import { useClients, useClientManagement, useClientConfig, useClientQrCode } from '@/hooks/useClients';
import { formatDistanceToNow } from 'date-fns';
import { ru } from 'date-fns/locale';

const Clients: React.FC = () => {
  const { data: clients, isLoading } = useClients();
  const { createClient, deleteClient } = useClientManagement();
  const [selectedClient, setSelectedClient] = useState<string | null>(null);
  const [newClientName, setNewClientName] = useState('');
  const [newClientIp, setNewClientIp] = useState('');
  
  const { open: isCreateOpen, onOpen: onCreateOpen, onClose: onCreateClose } = useDisclosure();
  const { open: isQrOpen, onOpen: onQrOpen, onClose: onQrClose } = useDisclosure();
  const { open: isConfigOpen, onOpen: onConfigOpen, onClose: onConfigClose } = useDisclosure();

  const { data: clientConfig } = useClientConfig(selectedClient || '', !!selectedClient && isConfigOpen);
  const { data: qrCode } = useClientQrCode(selectedClient || '', !!selectedClient && isQrOpen);

  const handleCreateClient = async () => {
    if (!newClientName.trim()) return;
    
    try {
      await createClient.mutateAsync({
        name: newClientName.trim(),
        ip: newClientIp.trim() || undefined,
      });
      setNewClientName('');
      setNewClientIp('');
      onCreateClose();
    } catch (error) {
      console.error('Failed to create client:', error);
    }
  };

  const handleDeleteClient = async (name: string) => {
    if (confirm(`Are you sure you want to delete client "${name}"?`)) {
      try {
        await deleteClient.mutateAsync(name);
      } catch (error) {
        console.error('Failed to delete client:', error);
      }
    }
  };

  const handleShowQr = (clientName: string) => {
    setSelectedClient(clientName);
    onQrOpen();
  };

  const handleShowConfig = (clientName: string) => {
    setSelectedClient(clientName);
    onConfigOpen();
  };

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text);
  };

  const downloadConfig = (name: string, config: string) => {
    const blob = new Blob([config], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${name}.conf`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  const formatBytes = (bytes: number) => {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  return (
    <Box>
      {/* Header */}
      <Flex justify="space-between" align="center" mb="6">
        <Box>
          <Heading size="lg" mb="1">
            Client Management
          </Heading>
          <Text color="fg.muted">
            Manage VPN clients and their configurations
          </Text>
        </Box>
        
        <Button
          colorPalette="blue"
          onClick={onCreateOpen}
        >
          <LuPlus />
          Add Client
        </Button>
      </Flex>

      {/* Stats */}
      <HStack gap="6" mb="6">
        <Card.Root>
          <Card.Body>
            <HStack>
              <Box color="blue.solid">
                <LuUsers size="24" />
              </Box>
              <Box>
                <Text fontSize="sm" color="fg.muted">
                  Total Clients
                </Text>
                <Text fontSize="xl" fontWeight="bold">
                  {clients?.length || 0}
                </Text>
              </Box>
            </HStack>
          </Card.Body>
        </Card.Root>

        <Card.Root>
          <Card.Body>
            <HStack>
              <Box color="green.solid">
                <LuWifi size="24" />
              </Box>
              <Box>
                <Text fontSize="sm" color="fg.muted">
                  Connected
                </Text>
                <Text fontSize="xl" fontWeight="bold">
                  {clients?.filter(c => c.connected).length || 0}
                </Text>
              </Box>
            </HStack>
          </Card.Body>
        </Card.Root>
      </HStack>

      {/* Clients Table */}
      <Card.Root>
        <Card.Header>
          <Card.Title>Clients</Card.Title>
        </Card.Header>
        <Card.Body p="0">
          <Table.Root size="sm">
            <Table.Header>
              <Table.Row>
                <Table.ColumnHeader>Name</Table.ColumnHeader>
                <Table.ColumnHeader>IP Address</Table.ColumnHeader>
                <Table.ColumnHeader>Status</Table.ColumnHeader>
                <Table.ColumnHeader>Last Handshake</Table.ColumnHeader>
                <Table.ColumnHeader>Traffic</Table.ColumnHeader>
                <Table.ColumnHeader>Actions</Table.ColumnHeader>
              </Table.Row>
            </Table.Header>
            <Table.Body>
              {isLoading ? (
                <Table.Row>
                  <Table.Cell colSpan={6}>
                    <Text textAlign="center" p="4" color="fg.muted">
                      Loading clients...
                    </Text>
                  </Table.Cell>
                </Table.Row>
              ) : clients?.length === 0 ? (
                <Table.Row>
                  <Table.Cell colSpan={6}>
                    <VStack p="8" gap="3">
                      <LuUsers size="48" color="var(--chakra-colors-fg-muted)" />
                      <Text color="fg.muted">No clients found</Text>
                      <Button size="sm" onClick={onCreateOpen}>
                        <LuPlus />
                        Add your first client
                      </Button>
                    </VStack>
                  </Table.Cell>
                </Table.Row>
              ) : (
                clients?.map((client) => (
                  <Table.Row key={client.name}>
                    <Table.Cell>
                      <Text fontWeight="medium">{client.name}</Text>
                    </Table.Cell>
                    <Table.Cell>
                      <Text fontFamily="mono" fontSize="sm">{client.ip}</Text>
                    </Table.Cell>
                    <Table.Cell>
                      <HStack gap="2">
                        {client.connected ? (
                          <LuWifi size="16" color="var(--chakra-colors-green-solid)" />
                        ) : (
                          <LuWifiOff size="16" color="var(--chakra-colors-gray-muted)" />
                        )}
                        <Badge
                          colorScheme={client.connected ? 'green' : 'gray'}
                          variant="subtle"
                        >
                          {client.connected ? 'Connected' : 'Offline'}
                        </Badge>
                      </HStack>
                    </Table.Cell>
                    <Table.Cell>
                      <Text fontSize="sm" color="fg.muted">
                        {client.lastHandshake
                          ? formatDistanceToNow(new Date(client.lastHandshake), { 
                              addSuffix: true, 
                              locale: ru 
                            })
                          : 'Never'
                        }
                      </Text>
                    </Table.Cell>
                    <Table.Cell>
                      <VStack align="start" gap="0">
                        <Text fontSize="xs" color="fg.muted">
                          ↑ {formatBytes(client.traffic.sent)}
                        </Text>
                        <Text fontSize="xs" color="fg.muted">
                          ↓ {formatBytes(client.traffic.received)}
                        </Text>
                      </VStack>
                    </Table.Cell>
                    <Table.Cell>
                      <HStack gap="1">
                        <IconButton
                          size="sm"
                          variant="ghost"
                          onClick={() => handleShowQr(client.name)}
                          title="Show QR Code"
                        >
                          <LuQrCode />
                        </IconButton>
                        <IconButton
                          size="sm"
                          variant="ghost"
                          onClick={() => handleShowConfig(client.name)}
                          title="Show Config"
                        >
                          <LuDownload />
                        </IconButton>
                        <IconButton
                          size="sm"
                          variant="ghost"
                          colorPalette="red"
                          onClick={() => handleDeleteClient(client.name)}
                          title="Delete Client"
                        >
                          <LuTrash2 />
                        </IconButton>
                      </HStack>
                    </Table.Cell>
                  </Table.Row>
                ))
              )}
            </Table.Body>
          </Table.Root>
        </Card.Body>
      </Card.Root>

      {/* Create Client Modal */}
      <DialogRoot open={isCreateOpen} onOpenChange={onCreateClose}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Add New Client</DialogTitle>
          </DialogHeader>
          <DialogBody>
            <Stack gap="4">
              <Field.Root>
                <Field.Label>Client Name</Field.Label>
                <Input
                  value={newClientName}
                  onChange={(e) => setNewClientName(e.target.value)}
                  placeholder="Enter client name"
                />
                <Field.HelperText>
                  Choose a unique name for this client
                </Field.HelperText>
              </Field.Root>
              
              <Field.Root>
                <Field.Label>IP Address (Optional)</Field.Label>
                <Input
                  value={newClientIp}
                  onChange={(e) => setNewClientIp(e.target.value)}
                  placeholder="e.g., 10.13.13.15"
                />
                <Field.HelperText>
                  Leave empty for automatic IP assignment
                </Field.HelperText>
              </Field.Root>
            </Stack>
          </DialogBody>
          <DialogFooter>
            <Button variant="outline" onClick={onCreateClose}>
              Cancel
            </Button>
            <Button
              colorPalette="blue"
              onClick={handleCreateClient}
              loading={createClient.isLoading}
              disabled={!newClientName.trim()}
            >
              Add Client
            </Button>
          </DialogFooter>
        </DialogContent>
      </DialogRoot>

      {/* QR Code Modal */}
      <DialogRoot open={isQrOpen} onOpenChange={onQrClose}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>QR Code - {selectedClient}</DialogTitle>
          </DialogHeader>
          <DialogBody>
            <VStack gap="4">
              {qrCode ? (
                <Box
                  p="4"
                  bg="bg"
                  borderRadius="md"
                  border="1px"
                  borderColor="border.muted"
                >
                  <pre style={{ fontSize: '8px', lineHeight: '8px', fontFamily: 'monospace' }}>
                    {qrCode}
                  </pre>
                </Box>
              ) : (
                <Text>Loading QR code...</Text>
              )}
              <Text fontSize="sm" color="fg.muted" textAlign="center">
                Scan this QR code with your AmneziaWG client app
              </Text>
            </VStack>
          </DialogBody>
          <DialogFooter>
            <Button onClick={onQrClose}>Close</Button>
          </DialogFooter>
        </DialogContent>
      </DialogRoot>

      {/* Config Modal */}
      <DialogRoot open={isConfigOpen} onOpenChange={onConfigClose}>
        <DialogContent maxW="2xl">
          <DialogHeader>
            <DialogTitle>Client Configuration - {selectedClient}</DialogTitle>
          </DialogHeader>
          <DialogBody>
            <VStack gap="4" align="stretch">
              {clientConfig ? (
                <>
                  <Textarea
                    value={clientConfig.config}
                    readOnly
                    rows={15}
                    fontFamily="mono"
                    fontSize="sm"
                  />
                  <HStack>
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => copyToClipboard(clientConfig.config)}
                    >
                      <LuCopy />
                      Copy to Clipboard
                    </Button>
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => downloadConfig(selectedClient!, clientConfig.config)}
                    >
                      <LuDownload />
                      Download Config
                    </Button>
                  </HStack>
                </>
              ) : (
                <Text>Loading configuration...</Text>
              )}
            </VStack>
          </DialogBody>
          <DialogFooter>
            <Button onClick={onConfigClose}>Close</Button>
          </DialogFooter>
        </DialogContent>
      </DialogRoot>
    </Box>
  );
};

export default Clients;
