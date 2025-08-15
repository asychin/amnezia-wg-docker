package service

import (
	"bufio"
	"encoding/json"
	"os/exec"
	"strings"
	"time"

	"amneziawg-web-api/internal/models"

	"github.com/gorilla/websocket"
	"github.com/sirupsen/logrus"
)

type LogService struct {
	logger    *logrus.Logger
	clients   map[*websocket.Conn]bool
	broadcast chan models.LogEntry
}

func NewLogService() *LogService {
	service := &LogService{
		logger:    logrus.New(),
		clients:   make(map[*websocket.Conn]bool),
		broadcast: make(chan models.LogEntry),
	}

	// Запускаем горутину для рассылки логов
	go service.handleBroadcast()

	return service
}

// GetLogs возвращает последние логи
func (s *LogService) GetLogs(limit int) ([]models.LogEntry, error) {
	var logs []models.LogEntry

	// Получаем логи через docker logs
	cmd := exec.Command("docker", "logs", "--tail", string(rune(limit)), "amneziawg-server")
	cmd.Dir = "/home/blacksazha/amnezia-wg-docker"

	output, err := cmd.Output()
	if err != nil {
		s.logger.WithError(err).Error("Failed to get docker logs")
		return logs, nil // Возвращаем пустой массив вместо ошибки
	}

	lines := strings.Split(string(output), "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}

		logEntry := s.parseLogLine(line)
		logs = append(logs, logEntry)
	}

	return logs, nil
}

// parseLogLine парсит строку лога в структуру LogEntry
func (s *LogService) parseLogLine(line string) models.LogEntry {
	// Простой парсер логов
	// Можно улучшить для более точного парсинга различных форматов

	entry := models.LogEntry{
		Timestamp: time.Now(),
		Level:     "info",
		Message:   line,
	}

	// Пытаемся найти уровень лога в строке
	line = strings.ToLower(line)
	if strings.Contains(line, "error") || strings.Contains(line, "err") {
		entry.Level = "error"
	} else if strings.Contains(line, "warn") || strings.Contains(line, "warning") {
		entry.Level = "warn"
	} else if strings.Contains(line, "debug") {
		entry.Level = "debug"
	}

	// Пытаемся найти источник лога
	if strings.Contains(line, "awg") || strings.Contains(line, "wireguard") {
		entry.Source = "amneziawg"
	} else if strings.Contains(line, "docker") {
		entry.Source = "docker"
	} else if strings.Contains(line, "system") {
		entry.Source = "system"
	}

	return entry
}

// WebSocket connection management
func (s *LogService) AddClient(conn *websocket.Conn) {
	s.clients[conn] = true
	s.logger.WithField("clients", len(s.clients)).Info("WebSocket client connected")
}

func (s *LogService) RemoveClient(conn *websocket.Conn) {
	delete(s.clients, conn)
	conn.Close()
	s.logger.WithField("clients", len(s.clients)).Info("WebSocket client disconnected")
}

func (s *LogService) BroadcastLog(entry models.LogEntry) {
	select {
	case s.broadcast <- entry:
	default:
		// Канал заполнен, пропускаем
	}
}

func (s *LogService) handleBroadcast() {
	for {
		select {
		case logEntry := <-s.broadcast:
			message := models.WSMessage{
				Type: models.WSMessageTypeLog,
				Data: logEntry,
			}

			messageBytes, err := json.Marshal(message)
			if err != nil {
				s.logger.WithError(err).Error("Failed to marshal websocket message")
				continue
			}

			// Отправляем всем подключенным клиентам
			for client := range s.clients {
				err := client.WriteMessage(websocket.TextMessage, messageBytes)
				if err != nil {
					s.logger.WithError(err).Error("Failed to write websocket message")
					s.RemoveClient(client)
				}
			}
		}
	}
}

// StartLogStreaming запускает потоковое чтение логов
func (s *LogService) StartLogStreaming() {
	go func() {
		cmd := exec.Command("docker", "logs", "-f", "amneziawg-server")
		cmd.Dir = "/home/blacksazha/amnezia-wg-docker"

		stdout, err := cmd.StdoutPipe()
		if err != nil {
			s.logger.WithError(err).Error("Failed to create stdout pipe")
			return
		}

		if err := cmd.Start(); err != nil {
			s.logger.WithError(err).Error("Failed to start log streaming")
			return
		}

		scanner := bufio.NewScanner(stdout)
		for scanner.Scan() {
			line := strings.TrimSpace(scanner.Text())
			if line != "" {
				logEntry := s.parseLogLine(line)
				s.BroadcastLog(logEntry)
			}
		}

		if err := scanner.Err(); err != nil {
			s.logger.WithError(err).Error("Error reading log stream")
		}

		cmd.Wait()
	}()
}
