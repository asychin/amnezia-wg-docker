import React, { useState } from 'react';
import {
  Button,
  VStack,
  Textarea,
  Text,
  HStack,
  Badge,
  Box,
  Code,
  DialogRoot,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogBody,
  DialogFooter,
  DialogCloseTrigger,
  Field,
  Separator,
} from '@chakra-ui/react';
import { Alert } from '@chakra-ui/react';
import { LuPlus, LuServer, LuWifi } from 'react-icons/lu';
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

  const handleConnectionStringChange = (value: string) => {
    setConnectionString(value);
    setError('');
    setParsedData(null);
    setAddError('');

    if (value.trim()) {
      const validation = validateConnectionString(value.trim());
      if (validation.isValid) {
        try {
          const parsed = parseConnectionString(value.trim());
          setParsedData(parsed);
        } catch (err) {
          setError(err instanceof Error ? err.message : 'Failed to parse connection string');
        }
      } else {
        setError(validation.error || 'Invalid connection string');
      }
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
    <DialogRoot open={isOpen} onOpenChange={({ open }) => !open && handleClose()} size="lg">
      <DialogContent>
        <DialogHeader>
          <DialogTitle>
            <HStack>
              <LuPlus size="20" />
              <Text>Add New Server</Text>
            </HStack>
          </DialogTitle>
          <DialogCloseTrigger />
        </DialogHeader>
        
        <DialogBody>
          <VStack gap="4" align="stretch">
            <Field.Root>
              <Field.Label>Connection String</Field.Label>
              <Textarea
                placeholder="Paste your awgwc:// connection string here..."
                value={connectionString}
                onChange={(e) => handleConnectionStringChange(e.target.value)}
                rows={4}
                fontFamily="mono"
                fontSize="sm"
              />
              <Field.HelperText>
                Connection string should start with <Code>awgwc://</Code>
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
              <Box>
                <Separator mb="4" />
                <VStack gap="3" align="stretch">
                  <Text fontWeight="medium" fontSize="sm">
                    Preview:
                  </Text>
                  
                  <HStack justify="space-between">
                    <HStack>
                      <LuServer size="16" />
                      <Text fontSize="sm" fontWeight="medium">
                        {parsedData.server_info.name}
                      </Text>
                    </HStack>
                    <Badge colorScheme="green" variant="subtle">
                      Valid
                    </Badge>
                  </HStack>

                  {parsedData.server_info.description && (
                    <Text fontSize="sm" color="fg.muted">
                      {parsedData.server_info.description}
                    </Text>
                  )}

                  <HStack>
                    <LuWifi size="14" />
                    <Text fontSize="sm" color="fg.muted">
                      {parsedData.endpoint}
                    </Text>
                  </HStack>

                  {parsedData.server_info.capabilities && parsedData.server_info.capabilities.length > 0 && (
                    <Box>
                      <Text fontSize="xs" color="fg.muted" mb="2">
                        Capabilities:
                      </Text>
                      <HStack wrap="wrap" gap="1">
                        {parsedData.server_info.capabilities.map((capability: string) => (
                          <Badge key={capability} size="sm" variant="outline">
                            {capability}
                          </Badge>
                        ))}
                      </HStack>
                    </Box>
                  )}
                </VStack>
              </Box>
            )}
          </VStack>
        </DialogBody>

        <DialogFooter>
          <HStack>
            <Button variant="outline" onClick={handleClose}>
              Cancel
            </Button>
            <Button
              colorScheme="blue"
              onClick={handleAddServer}
              loading={isLoading}
              disabled={!parsedData || !!error}
            >
              <LuPlus size="16" />
              Add Server
            </Button>
          </HStack>
        </DialogFooter>
      </DialogContent>
    </DialogRoot>
  );
};

export default AddServerModal;
