import React, { useState, useEffect } from 'react';
import {
  Box,
  Button,
  Card,
  Flex,
  Heading,
  Input,
  NumberInput,
  Stack,
  Text,
  VStack,
  HStack,
  Field,
  Badge,
  Separator,
  Alert,
} from '@chakra-ui/react';
import { LuSave, LuRotateCcw, LuSettings, LuShield } from 'react-icons/lu';
import { useServerConfig, useServerControl } from '@/hooks/useServerStatus';
import { withServerConnection } from '@/components/ServerStates';

const Settings: React.FC = () => {
  const { data: serverConfig, isLoading } = useServerConfig();
  const { updateConfig } = useServerControl();
  
  const [formData, setFormData] = useState({
    interface: 'awg0',
    port: 51820,
    network: '10.13.13.0/24',
    serverIp: '10.13.13.1',
    dns: ['8.8.8.8', '8.8.4.4'],
    publicIp: 'auto',
    obfuscation: {
      jc: 7,
      jmin: 50,
      jmax: 1000,
      s1: 86,
      s2: 574,
      h1: 1,
      h2: 2,
      h3: 3,
      h4: 4,
    },
  });

  const [hasChanges, setHasChanges] = useState(false);

  useEffect(() => {
    if (serverConfig) {
      setFormData(serverConfig);
      setHasChanges(false);
    }
  }, [serverConfig]);

  const handleInputChange = (field: string, value: any) => {
    setFormData(prev => ({
      ...prev,
      [field]: value,
    }));
    setHasChanges(true);
  };

  const handleObfuscationChange = (field: string, value: number) => {
    setFormData(prev => ({
      ...prev,
      obfuscation: {
        ...prev.obfuscation,
        [field]: value,
      },
    }));
    setHasChanges(true);
  };

  const handleDnsChange = (value: string) => {
    const dnsArray = value.split(',').map(dns => dns.trim()).filter(dns => dns);
    setFormData(prev => ({
      ...prev,
      dns: dnsArray,
    }));
    setHasChanges(true);
  };

  const handleSave = async () => {
    try {
      await updateConfig.mutateAsync(formData);
      setHasChanges(false);
    } catch (error) {
      console.error('Failed to update config:', error);
    }
  };

  const handleReset = () => {
    if (serverConfig) {
      setFormData(serverConfig);
      setHasChanges(false);
    }
  };

  const obfuscationProfiles = [
    {
      name: 'Standard',
      description: 'Default obfuscation settings',
      config: { jc: 7, jmin: 50, jmax: 1000, s1: 86, s2: 574 },
    },
    {
      name: 'Enhanced',
      description: 'Stronger obfuscation for strict DPI',
      config: { jc: 12, jmin: 75, jmax: 1500, s1: 96, s2: 684 },
    },
    {
      name: 'DNS Simulation',
      description: 'Mimic DNS traffic patterns',
      config: { jc: 5, jmin: 32, jmax: 512, s1: 53, s2: 253 },
    },
  ];

  const applyProfile = (profile: typeof obfuscationProfiles[0]) => {
    setFormData(prev => ({
      ...prev,
      obfuscation: {
        ...prev.obfuscation,
        ...profile.config,
      },
    }));
    setHasChanges(true);
  };

  if (isLoading) {
    return (
      <Box>
        <Text>Loading configuration...</Text>
      </Box>
    );
  }

  return (
    <Box>
      {/* Header */}
      <Flex justify="space-between" align="center" mb="6">
        <Box>
          <Heading size="lg" mb="1">
            ⚙️ Multi-Server Settings
          </Heading>
          <Text color="fg.muted">
            Configure parameters for the currently selected server
          </Text>
          <HStack gap="2" mt="2">
            <Badge colorScheme="green" variant="subtle">Server-Specific</Badge>
            <Text fontSize="sm" color="green.solid">
              Настройки применяются только к текущему серверу
            </Text>
          </HStack>
        </Box>
        
        <HStack gap="2">
          <Button
            variant="outline"
            onClick={handleReset}
            disabled={!hasChanges}
          >
            <LuRotateCcw />
            Reset
          </Button>
          <Button
            colorPalette="blue"
            onClick={handleSave}
            loading={updateConfig.isLoading}
            disabled={!hasChanges}
          >
            <LuSave />
            Save Changes
          </Button>
        </HStack>
      </Flex>

      {hasChanges && (
        <Alert.Root status="warning" mb="6">
          <Alert.Indicator />
          <Alert.Title>Unsaved Changes</Alert.Title>
          <Alert.Description>
            You have unsaved changes. Save them to apply the new configuration.
          </Alert.Description>
        </Alert.Root>
      )}

      <VStack gap="6" align="stretch">
        {/* Basic Settings */}
        <Card.Root>
          <Card.Header>
            <Card.Title>
              <HStack>
                <LuSettings />
                <Text>Basic Configuration</Text>
              </HStack>
            </Card.Title>
            <Card.Description>
              Core server parameters
            </Card.Description>
          </Card.Header>
          <Card.Body>
            <Stack gap="4">
              <HStack gap="4">
                <Field.Root flex="1">
                  <Field.Label>Interface Name</Field.Label>
                  <Input
                    value={formData.interface}
                    onChange={(e) => handleInputChange('interface', e.target.value)}
                  />
                  <Field.HelperText>Network interface name (e.g., awg0)</Field.HelperText>
                </Field.Root>
                
                <Field.Root flex="1">
                  <Field.Label>Port</Field.Label>
                  <NumberInput.Root
                    value={formData.port.toString()}
                    onValueChange={(e) => handleInputChange('port', parseInt(e.value) || 51820)}
                    min={1}
                    max={65535}
                  >
                    <NumberInput.Control />
                  </NumberInput.Root>
                  <Field.HelperText>UDP port for VPN connections</Field.HelperText>
                </Field.Root>
              </HStack>

              <HStack gap="4">
                <Field.Root flex="1">
                  <Field.Label>Network Range</Field.Label>
                  <Input
                    value={formData.network}
                    onChange={(e) => handleInputChange('network', e.target.value)}
                    placeholder="10.13.13.0/24"
                  />
                  <Field.HelperText>VPN network CIDR range</Field.HelperText>
                </Field.Root>
                
                <Field.Root flex="1">
                  <Field.Label>Server IP</Field.Label>
                  <Input
                    value={formData.serverIp}
                    onChange={(e) => handleInputChange('serverIp', e.target.value)}
                    placeholder="10.13.13.1"
                  />
                  <Field.HelperText>Server IP within VPN network</Field.HelperText>
                </Field.Root>
              </HStack>

              <HStack gap="4">
                <Field.Root flex="1">
                  <Field.Label>Public IP</Field.Label>
                  <Input
                    value={formData.publicIp}
                    onChange={(e) => handleInputChange('publicIp', e.target.value)}
                    placeholder="auto"
                  />
                  <Field.HelperText>Public IP address (auto-detect if 'auto')</Field.HelperText>
                </Field.Root>
                
                <Field.Root flex="1">
                  <Field.Label>DNS Servers</Field.Label>
                  <Input
                    value={formData.dns.join(', ')}
                    onChange={(e) => handleDnsChange(e.target.value)}
                    placeholder="8.8.8.8, 8.8.4.4"
                  />
                  <Field.HelperText>Comma-separated DNS servers</Field.HelperText>
                </Field.Root>
              </HStack>
            </Stack>
          </Card.Body>
        </Card.Root>

        {/* Obfuscation Settings */}
        <Card.Root>
          <Card.Header>
            <Card.Title>
              <HStack>
                <LuShield />
                <Text>Obfuscation Settings</Text>
              </HStack>
            </Card.Title>
            <Card.Description>
              Traffic obfuscation parameters to bypass DPI
            </Card.Description>
          </Card.Header>
          <Card.Body>
            <VStack gap="6" align="stretch">
              {/* Presets */}
              <Box>
                <Text fontSize="sm" fontWeight="medium" mb="3">
                  Quick Presets
                </Text>
                <HStack gap="3">
                  {obfuscationProfiles.map((profile) => (
                    <Button
                      key={profile.name}
                      size="sm"
                      variant="outline"
                      onClick={() => applyProfile(profile)}
                    >
                      {profile.name}
                    </Button>
                  ))}
                </HStack>
                <Text fontSize="xs" color="fg.muted" mt="2">
                  Apply predefined obfuscation profiles
                </Text>
              </Box>

              <Separator />

              {/* Manual Settings */}
              <Box>
                <Text fontSize="sm" fontWeight="medium" mb="4">
                  Manual Configuration
                </Text>
                <Stack gap="4">
                  <HStack gap="4">
                    <Field.Root flex="1">
                      <Field.Label>Junk Count (Jc)</Field.Label>
                      <NumberInput.Root
                        value={formData.obfuscation.jc.toString()}
                        onValueChange={(e) => handleObfuscationChange('jc', parseInt(e.value) || 7)}
                        min={3}
                        max={15}
                      >
                        <NumberInput.Control />
                        <NumberInput.Control>
                          <NumberInput.IncrementTrigger />
                          <NumberInput.DecrementTrigger />
                        </NumberInput.Control>
                      </NumberInput.Root>
                      <Field.HelperText>Number of junk packets (3-15)</Field.HelperText>
                    </Field.Root>
                    
                    <Field.Root flex="1">
                      <Field.Label>Min Junk Size (Jmin)</Field.Label>
                      <NumberInput.Root
                        value={formData.obfuscation.jmin.toString()}
                        onValueChange={(e) => handleObfuscationChange('jmin', parseInt(e.value) || 50)}
                        min={20}
                        max={200}
                      >
                        <NumberInput.Control />
                        <NumberInput.Control>
                          <NumberInput.IncrementTrigger />
                          <NumberInput.DecrementTrigger />
                        </NumberInput.Control>
                      </NumberInput.Root>
                      <Field.HelperText>Minimum junk packet size</Field.HelperText>
                    </Field.Root>
                  </HStack>

                  <HStack gap="4">
                    <Field.Root flex="1">
                      <Field.Label>Max Junk Size (Jmax)</Field.Label>
                      <NumberInput.Root
                        value={formData.obfuscation.jmax.toString()}
                        onValueChange={(e) => handleObfuscationChange('jmax', parseInt(e.value) || 1000)}
                        min={500}
                        max={2000}
                      >
                        <NumberInput.Control />
                        <NumberInput.Control>
                          <NumberInput.IncrementTrigger />
                          <NumberInput.DecrementTrigger />
                        </NumberInput.Control>
                      </NumberInput.Root>
                      <Field.HelperText>Maximum junk packet size</Field.HelperText>
                    </Field.Root>
                    
                    <Field.Root flex="1">
                      <Field.Label>Header Size 1 (S1)</Field.Label>
                      <NumberInput.Root
                        value={formData.obfuscation.s1.toString()}
                        onValueChange={(e) => handleObfuscationChange('s1', parseInt(e.value) || 86)}
                        min={50}
                        max={200}
                      >
                        <NumberInput.Control />
                        <NumberInput.Control>
                          <NumberInput.IncrementTrigger />
                          <NumberInput.DecrementTrigger />
                        </NumberInput.Control>
                      </NumberInput.Root>
                      <Field.HelperText>First header modification size</Field.HelperText>
                    </Field.Root>
                  </HStack>

                  <HStack gap="4">
                    <Field.Root flex="1">
                      <Field.Label>Header Size 2 (S2)</Field.Label>
                      <NumberInput.Root
                        value={formData.obfuscation.s2.toString()}
                        onValueChange={(e) => handleObfuscationChange('s2', parseInt(e.value) || 574)}
                        min={200}
                        max={800}
                      >
                        <NumberInput.Control />
                        <NumberInput.Control>
                          <NumberInput.IncrementTrigger />
                          <NumberInput.DecrementTrigger />
                        </NumberInput.Control>
                      </NumberInput.Root>
                      <Field.HelperText>Second header modification size</Field.HelperText>
                    </Field.Root>
                    
                    <Field.Root flex="1">
                      {/* Spacer */}
                    </Field.Root>
                  </HStack>

                  <Box>
                    <Text fontSize="sm" fontWeight="medium" mb="3">
                      Hash Functions (H1-H4)
                    </Text>
                    <HStack gap="4">
                      {[1, 2, 3, 4].map((num) => (
                        <Field.Root key={num} flex="1">
                          <Field.Label>H{num}</Field.Label>
                          <NumberInput.Root
                            value={formData.obfuscation[`h${num}` as keyof typeof formData.obfuscation].toString()}
                            onValueChange={(e) => handleObfuscationChange(`h${num}`, parseInt(e.value) || num)}
                            min={1}
                            max={10}
                          >
                            <NumberInput.Control />
                            <NumberInput.Control>
                              <NumberInput.IncrementTrigger />
                              <NumberInput.DecrementTrigger />
                            </NumberInput.Control>
                          </NumberInput.Root>
                        </Field.Root>
                      ))}
                    </HStack>
                    <Text fontSize="xs" color="fg.muted" mt="2">
                      Hash function parameters for header obfuscation
                    </Text>
                  </Box>
                </Stack>
              </Box>
            </VStack>
          </Card.Body>
        </Card.Root>
      </VStack>
    </Box>
  );
};

export default withServerConnection(Settings);
