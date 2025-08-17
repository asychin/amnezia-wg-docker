import React, { useState, useEffect, useRef } from 'react';
import {
  Box,
  Button,
  Card,
  Flex,
  Heading,
  HStack,
  Text,
  VStack,
  Badge,
  Switch,
  Input,
  Select,
  IconButton,
  createListCollection,
} from '@chakra-ui/react';
import { 
  LuPlay, 
  LuPause, 
  LuTrash2, 
  LuDownload, 
  LuFilter,
  LuSearch,
  LuRefreshCw
} from 'react-icons/lu';
import { useQuery } from 'react-query';
import { logsApi } from '@/services/api';
import { withServerConnection } from '@/components/ServerStates';
import { format } from 'date-fns';
import { ru } from 'date-fns/locale';
import type { LogEntry } from '@/types/api';

const Logs: React.FC = () => {
  const [isLiveMode, setIsLiveMode] = useState(false);
  const [filterLevel, setFilterLevel] = useState<string>('all');
  const [searchTerm, setSearchTerm] = useState('');
  const [logs, setLogs] = useState<LogEntry[]>([]);
  const logsEndRef = useRef<HTMLDivElement>(null);
  const wsRef = useRef<WebSocket | null>(null);

  const logLevels = createListCollection({
    items: [
      { label: 'All levels', value: 'all' },
      { label: 'Error', value: 'error' },
      { label: 'Warning', value: 'warn' },
      { label: 'Info', value: 'info' },
      { label: 'Debug', value: 'debug' }
    ]
  });

  const { data: initialLogs, refetch } = useQuery({
    queryKey: ['logs'],
    queryFn: async () => {
      const response = await logsApi.getLogs(100);
      if (!response.data.success) {
        throw new Error(response.data.error || 'Failed to fetch logs');
      }
      return response.data.data!;
    },
    refetchInterval: isLiveMode ? false : 5000, // Обновляем каждые 5 секунд если не в live режиме
  });

  useEffect(() => {
    if (initialLogs) {
      setLogs(initialLogs);
    }
  }, [initialLogs]);

  useEffect(() => {
    if (isLiveMode) {
      // Подключаемся к WebSocket для real-time логов
      try {
        wsRef.current = logsApi.connectToLogs();
        
        wsRef.current.onmessage = (event) => {
          try {
            const logEntry: LogEntry = JSON.parse(event.data);
            setLogs(prev => [...prev.slice(-99), logEntry]); // Храним последние 100 записей
          } catch (error) {
            console.error('Failed to parse log entry:', error);
          }
        };

        wsRef.current.onerror = (error) => {
          console.error('WebSocket error:', error);
          setIsLiveMode(false);
        };

        wsRef.current.onclose = () => {
          console.log('WebSocket connection closed');
        };
      } catch (error) {
        console.error('Failed to connect to logs WebSocket:', error);
        setIsLiveMode(false);
      }
    } else {
      // Закрываем WebSocket соединение
      if (wsRef.current) {
        wsRef.current.close();
        wsRef.current = null;
      }
    }

    return () => {
      if (wsRef.current) {
        wsRef.current.close();
      }
    };
  }, [isLiveMode]);

  useEffect(() => {
    // Автоскролл к концу логов в live режиме
    if (isLiveMode && logsEndRef.current) {
      logsEndRef.current.scrollIntoView({ behavior: 'smooth' });
    }
  }, [logs, isLiveMode]);

  const filteredLogs = logs.filter(log => {
    const matchesLevel = filterLevel === 'all' || log.level === filterLevel;
    const matchesSearch = searchTerm === '' || 
      log.message.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (log.source && log.source.toLowerCase().includes(searchTerm.toLowerCase()));
    return matchesLevel && matchesSearch;
  });

  const clearLogs = () => {
    setLogs([]);
  };

  const downloadLogs = () => {
    const logText = filteredLogs
      .map(log => `[${format(new Date(log.timestamp), 'yyyy-MM-dd HH:mm:ss')}] ${log.level.toUpperCase()}: ${log.message}`)
      .join('\n');
    
    const blob = new Blob([logText], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `amneziawg-logs-${format(new Date(), 'yyyy-MM-dd-HH-mm-ss')}.txt`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  const getLevelColor = (level: string) => {
    switch (level) {
      case 'error':
        return 'red';
      case 'warn':
        return 'orange';
      case 'info':
        return 'blue';
      case 'debug':
        return 'gray';
      default:
        return 'gray';
    }
  };

  const getLevelIcon = (level: string) => {
    switch (level) {
      case 'error':
        return '❌';
      case 'warn':
        return '⚠️';
      case 'info':
        return 'ℹ️';
      case 'debug':
        return '🔍';
      default:
        return '📝';
    }
  };

  return (
    <Box>
      {/* Header */}
      <Flex justify="space-between" align="center" mb="6">
        <Box>
          <Heading size="lg" mb="1">
            Server Logs
          </Heading>
          <Text color="fg.muted">
            Monitor AmneziaWG server activity and debug information
          </Text>
        </Box>
        
        <HStack gap="2">
          <IconButton
            size="sm"
            variant="outline"
            onClick={() => refetch()}
            title="Refresh logs"
            disabled={isLiveMode}
          >
            <LuRefreshCw />
          </IconButton>
          <Button
            size="sm"
            variant="outline"
            onClick={downloadLogs}
            title="Download logs"
          >
            <LuDownload />
            Export
          </Button>
          <Button
            size="sm"
            variant="outline"
            colorPalette="red"
            onClick={clearLogs}
            title="Clear logs"
          >
            <LuTrash2 />
            Clear
          </Button>
        </HStack>
      </Flex>

      {/* Controls */}
      <Card.Root mb="6">
        <Card.Body>
          <Flex wrap="wrap" gap="4" align="center">
            {/* Live Mode Toggle */}
            <HStack gap="3">
              <Switch.Root
                checked={isLiveMode}
                onCheckedChange={(details) => setIsLiveMode(details.checked)}
              >
                <Switch.Control>
                  <Switch.Thumb />
                </Switch.Control>
              </Switch.Root>
              <HStack gap="2">
                {isLiveMode ? <LuPause /> : <LuPlay />}
                <Text fontSize="sm" fontWeight="medium">
                  {isLiveMode ? 'Live Mode' : 'Static Mode'}
                </Text>
              </HStack>
              {isLiveMode && (
                <Badge colorScheme="green" variant="subtle">
                  Live
                </Badge>
              )}
            </HStack>

            {/* Level Filter */}
            <HStack gap="2">
              <LuFilter size="16" />
              <Text fontSize="sm">Level:</Text>
              <Select.Root
                value={[filterLevel]}
                onValueChange={(details) => setFilterLevel(details.value[0])}
                size="sm"
                minW="120px"
                collection={logLevels}
              >
                <Select.Trigger>
                  <Select.ValueText placeholder="All levels" />
                </Select.Trigger>
                <Select.Content>
                  <Select.Item item="all">All levels</Select.Item>
                  <Select.Item item="error">Error</Select.Item>
                  <Select.Item item="warn">Warning</Select.Item>
                  <Select.Item item="info">Info</Select.Item>
                  <Select.Item item="debug">Debug</Select.Item>
                </Select.Content>
              </Select.Root>
            </HStack>

            {/* Search */}
            <HStack gap="2" flex="1" maxW="300px">
              <LuSearch size="16" />
              <Input
                placeholder="Search logs..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                size="sm"
              />
            </HStack>

            {/* Stats */}
            <Text fontSize="sm" color="fg.muted">
              Showing {filteredLogs.length} of {logs.length} entries
            </Text>
          </Flex>
        </Card.Body>
      </Card.Root>

      {/* Logs */}
      <Card.Root>
        <Card.Header>
          <Card.Title>Log Entries</Card.Title>
        </Card.Header>
        <Card.Body p="0">
          <Box
            maxH="600px"
            overflowY="auto"
            bg="bg.subtle"
            border="1px"
            borderColor="border.muted"
          >
            {filteredLogs.length === 0 ? (
              <VStack p="8" gap="3">
                <Text color="fg.muted" fontSize="lg">
                  📝
                </Text>
                <Text color="fg.muted">
                  {logs.length === 0 ? 'No logs available' : 'No logs match your filters'}
                </Text>
                {logs.length === 0 && (
                  <Button size="sm" onClick={() => refetch()}>
                    Refresh
                  </Button>
                )}
              </VStack>
            ) : (
              <VStack gap="0" align="stretch">
                {filteredLogs.map((log, index) => (
                  <Box
                    key={index}
                    p="3"
                    borderBottomWidth="1px"
                    borderColor="border.muted"
                    _hover={{ bg: 'bg.emphasized' }}
                    fontFamily="mono"
                    fontSize="sm"
                  >
                    <Flex align="start" gap="3">
                      <Text color="fg.muted" minW="20" flexShrink={0}>
                        {format(new Date(log.timestamp), 'HH:mm:ss', { locale: ru })}
                      </Text>
                      
                      <Badge
                        colorScheme={getLevelColor(log.level)}
                        variant="subtle"
                        minW="16"
                        textAlign="center"
                      >
                        {getLevelIcon(log.level)} {log.level.toUpperCase()}
                      </Badge>
                      
                      {log.source && (
                        <Text color="fg.muted" minW="20" flexShrink={0}>
                          [{log.source}]
                        </Text>
                      )}
                      
                      <Text flex="1" wordBreak="break-word">
                        {log.message}
                      </Text>
                    </Flex>
                  </Box>
                ))}
                <div ref={logsEndRef} />
              </VStack>
            )}
          </Box>
        </Card.Body>
      </Card.Root>
    </Box>
  );
};

export default withServerConnection(Logs);
