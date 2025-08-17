import React, { useState, useEffect } from 'react';
import {
  DialogRoot,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
  DialogBody,
  DialogCloseTrigger,
  Button,
  VStack,
  Text,
  Alert,
  Field,
  Input,
  HStack,
  Badge,
  Box,
  IconButton,
} from '@chakra-ui/react';
import { LuLogIn, LuEye, LuEyeOff, LuWifi } from 'react-icons/lu';
import { useServers } from '@/contexts/ServerContext';

interface ConnectServerModalProps {
  isOpen: boolean;
  onClose: () => void;
  serverId: string;
}

const ConnectServerModal: React.FC<ConnectServerModalProps> = ({ isOpen, onClose, serverId }) => {
  const { servers, connectToServer, isLoading } = useServers();
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState<string>('');

  const server = servers.find(s => s.id === serverId);

  // Reset form when modal opens/closes or server changes
  useEffect(() => {
    if (isOpen) {
      setUsername('');
      setPassword('');
      setError('');
      setShowPassword(false);
    }
  }, [isOpen, serverId]);

  const handleConnect = async () => {
    if (!username.trim() || !password.trim()) {
      setError('Please enter both username and password');
      return;
    }

    if (!server) {
      setError('Server not found');
      return;
    }

    setError('');
    const result = await connectToServer(serverId, { username: username.trim(), password });
    
    if (result.success) {
      // Success - close modal and reset form
      onClose();
    } else {
      setError(result.error || 'Failed to connect to server');
    }
  };

  const handleClose = () => {
    setUsername('');
    setPassword('');
    setError('');
    setShowPassword(false);
    onClose();
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && username.trim() && password.trim()) {
      handleConnect();
    }
  };

  if (!server) {
    return null;
  }

  return (
    <DialogRoot open={isOpen} onOpenChange={({ open }) => !open && handleClose()} size="md">
      <DialogContent>
        <DialogHeader>
          <DialogTitle>
            <HStack>
              <LuLogIn size="20" />
              <Text>Connect to Server</Text>
            </HStack>
          </DialogTitle>
          <DialogCloseTrigger />
        </DialogHeader>
        
        <DialogBody>
          <VStack gap="4" align="stretch">
            {/* Server Info */}
            <Box p="4" bg="bg.emphasized" borderRadius="md">
              <VStack gap="2" align="start">
                <HStack justify="space-between" w="full">
                  <HStack>
                    <LuWifi size="16" />
                    <Text fontWeight="medium">{server.name}</Text>
                  </HStack>
                  <Badge 
                    colorScheme={server.isConnected ? 'green' : 'red'} 
                    variant="subtle"
                  >
                    {server.isConnected ? 'Connected' : 'Disconnected'}
                  </Badge>
                </HStack>
                <Text fontSize="sm" color="fg.muted">
                  {server.endpoint}
                </Text>
                {server.description && (
                  <Text fontSize="sm" color="fg.muted">
                    {server.description}
                  </Text>
                )}
              </VStack>
            </Box>

            {/* Login Form */}
            <VStack gap="4">
              <Field.Root>
                <Field.Label>Username</Field.Label>
                <Input
                  type="text"
                  placeholder="Enter your username"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  onKeyPress={handleKeyPress}
                  autoComplete="username"
                />
              </Field.Root>

              <Field.Root position="relative">
                <Field.Label>Password</Field.Label>
                <Input
                  type={showPassword ? 'text' : 'password'}
                  placeholder="Enter your password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  onKeyPress={handleKeyPress}
                  autoComplete="current-password"
                  pr="12"
                />
                <Box position="absolute" right="2" top="50%" transform="translateY(-50%)">
                  <IconButton
                    aria-label={showPassword ? 'Hide password' : 'Show password'}
                    variant="ghost"
                    size="sm"
                    onClick={() => setShowPassword(!showPassword)}
                  >
                    {showPassword ? <LuEyeOff size="16" /> : <LuEye size="16" />}
                  </IconButton>
                </Box>
              </Field.Root>
            </VStack>

            {error && (
              <Alert.Root status="error">
                <Alert.Description>{error}</Alert.Description>
              </Alert.Root>
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
              onClick={handleConnect}
              loading={isLoading}
              disabled={!username.trim() || !password.trim()}
            >
              <LuLogIn size="16" />
              Connect
            </Button>
          </HStack>
        </DialogFooter>
      </DialogContent>
    </DialogRoot>
  );
};

export default ConnectServerModal;
