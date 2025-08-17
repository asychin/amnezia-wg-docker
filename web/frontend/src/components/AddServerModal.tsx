import React, { useState, useRef, useEffect } from 'react';
import {
  Button,
  VStack,
  Textarea,
  Text,
  HStack,
  Badge,
  Box,
  Code,
  Dialog,
  Field,
  Separator,
  Portal,
} from '@chakra-ui/react';
import { Alert } from '@chakra-ui/react';
import { LuPlus, LuServer, LuWifi, LuX } from 'react-icons/lu';
import { useServers } from '@/contexts/ServerContext';
import { parseConnectionString, validateConnectionString } from '@/utils/connectionString';

interface AddServerModalProps {
  isOpen: boolean;
  onClose: () => void;
}

const AddServerModal: React.FC<AddServerModalProps> = ({ isOpen, onClose }) => {
  const { addServer, isLoading } = useServers();
  const [connectionString, setConnectionString] = useState('');
  const [parsedData, setParsedData] = useState<any>(null);
  const [error, setError] = useState<string>('');
  const [addError, setAddError] = useState<string>('');
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  useEffect(() => {
    if (isOpen && textareaRef.current) {
      // Небольшая задержка для корректного фокусирования
      setTimeout(() => {
        textareaRef.current?.focus();
      }, 100);
    }
  }, [isOpen]);

  const handleConnectionStringChange = (value: string) => {
    // Ограничиваем длину ввода для предотвращения проблем с производительностью
    const maxLength = 5000;
    const trimmedValue = value.length > maxLength ? value.substring(0, maxLength) : value;
    
    setConnectionString(trimmedValue);
    setError('');
    setParsedData(null);
    setAddError('');

    if (trimmedValue.trim()) {
      const validation = validateConnectionString(trimmedValue.trim());
      if (validation.isValid) {
        try {
          const parsed = parseConnectionString(trimmedValue.trim());
          setParsedData(parsed);
        } catch (err) {
          setError(err instanceof Error ? err.message : 'Failed to parse connection string');
        }
      } else {
        setError(validation.error || 'Invalid connection string');
      }
    }
  };

  const handlePaste = (e: React.ClipboardEvent) => {
    const pastedText = e.clipboardData.getData('text');
    if (pastedText.length > 5000) {
      e.preventDefault();
      setError('Connection string is too long. Please check the format.');
      return;
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    // Ctrl+Enter для быстрого добавления сервера
    if (e.ctrlKey && e.key === 'Enter' && parsedData && !error) {
      handleAddServer();
    }
    // Escape для закрытия модального окна
    if (e.key === 'Escape') {
      handleClose();
    }
  };

  const handleAddServer = async () => {
    if (!connectionString.trim()) {
      setAddError('Please enter a connection string');
      return;
    }

    if (!parsedData) {
      setAddError('Please enter a valid connection string');
      return;
    }

    const result = await addServer(connectionString.trim());
    if (result.success) {
      // Success - close modal and reset form
      setConnectionString('');
      setParsedData(null);
      setError('');
      setAddError('');
      onClose();
    } else {
      setAddError(result.error || 'Failed to add server');
    }
  };

  const handleClose = () => {
    setConnectionString('');
    setParsedData(null);
    setError('');
    setAddError('');
    onClose();
  };

  return (
    <Dialog.Root open={isOpen} onOpenChange={({ open }) => !open && handleClose()} size={{ base: "full", md: "lg" }}>
      <Portal>
        <Dialog.Backdrop />
        <Dialog.Positioner>
          <Dialog.Content maxWidth={{ base: "100vw", md: "500px" }} maxHeight={{ base: "100vh", md: "70vh" }}>
            <Dialog.CloseTrigger asChild>
              <Button size="sm" variant="ghost" position="absolute" top="3" right="3">
                <LuX size="16" />
              </Button>
            </Dialog.CloseTrigger>
            
            <Dialog.Header>
              <Dialog.Title>
                <HStack>
                  <LuPlus size="20" />
                  <Text>Add New Server</Text>
                </HStack>
              </Dialog.Title>
            </Dialog.Header>
            
            <Dialog.Body overflow={{ base: "auto", md: "visible" }} maxHeight={{ base: "calc(100vh - 200px)", md: "none" }}>
              <VStack gap="3" align="stretch" p="3">
                <Field.Root>
                  <Field.Label>Connection String</Field.Label>
                  <Box position="relative" width="100%">
                    <Textarea
                      ref={textareaRef}
                      placeholder="Paste your awgwc:// connection string here..."
                      value={connectionString}
                      onChange={(e) => handleConnectionStringChange(e.target.value)}
                      onPaste={handlePaste}
                      onKeyDown={handleKeyDown}
                      rows={4}
                      fontFamily="mono"
                      fontSize="sm"
                      resize="vertical"
                      minHeight="120px"
                      maxHeight="300px"
                      overflow="auto"
                      pr={connectionString ? "10" : "3"}
                      width="100%"
                      boxSizing="border-box"
                    />
                    {connectionString && (
                      <Button
                        size="sm"
                        variant="ghost"
                        position="absolute"
                        top="2"
                        right="2"
                        onClick={() => setConnectionString('')}
                        colorPalette="gray"
                      >
                        <LuX size="14" />
                      </Button>
                    )}
                  </Box>
                  <Field.HelperText>
                    Connection string should start with <Code>awgwc://</Code>
                    {connectionString.length > 2000 && (
                      <Text as="span" color="orange.500" ml="2">
                        ({connectionString.length} characters)
                      </Text>
                    )}
                    <Text as="span" color="fg.muted" ml="2">
                      • Ctrl+Enter to add • Esc to close
                    </Text>
                  </Field.HelperText>
                </Field.Root>

                {error && (
                  <Alert.Root status="error">
                    <Alert.Description>{error}</Alert.Description>
                  </Alert.Root>
                )}

                {addError && (
                  <Alert.Root status="error">
                    <Alert.Description>{addError}</Alert.Description>
                  </Alert.Root>
                )}

                {parsedData && (
                  <Box 
                    border="1px" 
                    borderColor="border.muted" 
                    borderRadius="md" 
                    p="2" 
                    bg="bg.subtle"
                    width="fit-content"
                    minWidth="500px"
                    maxHeight={{ base: "200px", md: "none" }}
                    overflow={{ base: "auto", md: "visible" }}
                  >
                    <Separator mb="4" />
                    <VStack gap="4" align="stretch">
                      <Text fontWeight="medium" fontSize="sm">
                        Preview:
                      </Text>
                      
                      <HStack justify="space-between">
                        <HStack>
                          <LuServer size="16" />
                          <Text fontSize="sm" fontWeight="medium">
                            {parsedData.name}
                          </Text>
                        </HStack>
                        <Badge colorPalette="green" variant="subtle">
                          Valid
                        </Badge>
                      </HStack>

                      {parsedData.server_info.location && (
                        <Text fontSize="sm" color="fg.muted">
                          Location: {parsedData.server_info.location}
                        </Text>
                      )}

                      <HStack>
                        <LuWifi size="14" />
                        <Text fontSize="sm" color="fg.muted">
                          {parsedData.api_endpoint}
                        </Text>
                      </HStack>

                      {parsedData.capabilities && parsedData.capabilities.length > 0 && (
                        <Box>
                          <Text fontSize="xs" color="fg.muted" mb="2">
                            Capabilities:
                          </Text>
                          <HStack wrap="wrap" gap="1">
                            {parsedData.capabilities.map((capability: string) => (
                              <Badge key={capability} size="sm" variant="outline">
                                {capability}
                              </Badge>
                            ))}
                          </HStack>
                        </Box>
                      )}

                      <Text fontSize="xs" color="fg.muted">
                        Version: {parsedData.version} • Expires: {new Date(parsedData.expires_at).toLocaleDateString()}
                      </Text>
                    </VStack>
                  </Box>
                )}
              </VStack>
            </Dialog.Body>

            <Dialog.Footer p="4">
              <HStack>
                <Button variant="outline" onClick={handleClose}>
                  Cancel
                </Button>
                <Button
                  colorPalette="blue"
                  onClick={handleAddServer}
                  loading={isLoading}
                  disabled={!parsedData || !!error}
                >
                  <LuPlus size="16" />
                  Add Server
                </Button>
              </HStack>
            </Dialog.Footer>
          </Dialog.Content>
        </Dialog.Positioner>
      </Portal>
    </Dialog.Root>
  );
};

export default AddServerModal;
