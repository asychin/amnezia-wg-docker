package api

import (
	"net/http"
	"strconv"
	"time"

	"amneziawg-web-api/internal/models"
	"amneziawg-web-api/internal/service"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
	"github.com/sirupsen/logrus"
)

type Handler struct {
	amneziawg *service.AmneziaWGService
	logs      *service.LogService
	logger    *logrus.Logger
	upgrader  websocket.Upgrader
}

func NewHandler(amneziawg *service.AmneziaWGService, logs *service.LogService) *Handler {
	return &Handler{
		amneziawg: amneziawg,
		logs:      logs,
		logger:    logrus.New(),
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool {
				// В продакшене добавить проверку домена
				return true
			},
		},
	}
}

func (h *Handler) SetupRoutes(router *gin.Engine) {
	// API v1 группа
	v1 := router.Group("/api/v1")
	{
		// Server management
		server := v1.Group("/server")
		{
			server.GET("/status", h.GetServerStatus)
			server.POST("/start", h.StartServer)
			server.POST("/stop", h.StopServer)
			server.POST("/restart", h.RestartServer)
			server.GET("/config", h.GetServerConfig)
			server.PUT("/config", h.UpdateServerConfig)
		}

		// Client management
		clients := v1.Group("/clients")
		{
			clients.GET("", h.GetClients)
			clients.POST("", h.CreateClient)
			clients.DELETE("/:name", h.DeleteClient)
			clients.GET("/:name/config", h.GetClientConfig)
			clients.GET("/:name/qr", h.GetClientQRCode)
		}

		// Logs
		logs := v1.Group("/logs")
		{
			logs.GET("", h.GetLogs)
			logs.GET("/stream", h.StreamLogs)
		}

		// Statistics (placeholder)
		stats := v1.Group("/stats")
		{
			stats.GET("/connections", h.GetConnectionStats)
			stats.GET("/traffic", h.GetTrafficStats)
		}
	}

	// Health check
	router.GET("/health", h.HealthCheck)

	// Запускаем потоковое чтение логов
	h.logs.StartLogStreaming()
}

// Helper functions
func (h *Handler) sendSuccess(c *gin.Context, data interface{}) {
	c.JSON(http.StatusOK, models.APIResponse{
		Success: true,
		Data:    data,
	})
}

func (h *Handler) sendError(c *gin.Context, status int, message string) {
	c.JSON(status, models.APIResponse{
		Success: false,
		Error:   message,
	})
}

// Health check
func (h *Handler) HealthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "ok",
		"service": "amneziawg-web-api",
	})
}

// Server handlers
func (h *Handler) GetServerStatus(c *gin.Context) {
	status, err := h.amneziawg.GetServerStatus()
	if err != nil {
		h.logger.WithError(err).Error("Failed to get server status")
		h.sendError(c, http.StatusInternalServerError, "Failed to get server status")
		return
	}

	h.sendSuccess(c, status)
}

func (h *Handler) StartServer(c *gin.Context) {
	if err := h.amneziawg.StartServer(); err != nil {
		h.logger.WithError(err).Error("Failed to start server")
		h.sendError(c, http.StatusInternalServerError, "Failed to start server")
		return
	}

	h.sendSuccess(c, nil)
}

func (h *Handler) StopServer(c *gin.Context) {
	if err := h.amneziawg.StopServer(); err != nil {
		h.logger.WithError(err).Error("Failed to stop server")
		h.sendError(c, http.StatusInternalServerError, "Failed to stop server")
		return
	}

	h.sendSuccess(c, nil)
}

func (h *Handler) RestartServer(c *gin.Context) {
	if err := h.amneziawg.RestartServer(); err != nil {
		h.logger.WithError(err).Error("Failed to restart server")
		h.sendError(c, http.StatusInternalServerError, "Failed to restart server")
		return
	}

	h.sendSuccess(c, nil)
}

func (h *Handler) GetServerConfig(c *gin.Context) {
	config, err := h.amneziawg.GetServerConfig()
	if err != nil {
		h.logger.WithError(err).Error("Failed to get server config")
		h.sendError(c, http.StatusInternalServerError, "Failed to get server config")
		return
	}

	h.sendSuccess(c, config)
}

func (h *Handler) UpdateServerConfig(c *gin.Context) {
	var config models.ServerConfig
	if err := c.ShouldBindJSON(&config); err != nil {
		h.sendError(c, http.StatusBadRequest, "Invalid request body")
		return
	}

	if err := h.amneziawg.UpdateServerConfig(config); err != nil {
		h.logger.WithError(err).Error("Failed to update server config")
		h.sendError(c, http.StatusInternalServerError, "Failed to update server config")
		return
	}

	h.sendSuccess(c, nil)
}

// Client handlers
func (h *Handler) GetClients(c *gin.Context) {
	clients, err := h.amneziawg.GetClients()
	if err != nil {
		h.logger.WithError(err).Error("Failed to get clients")
		h.sendError(c, http.StatusInternalServerError, "Failed to get clients")
		return
	}

	h.sendSuccess(c, clients)
}

func (h *Handler) CreateClient(c *gin.Context) {
	var req models.CreateClientRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.sendError(c, http.StatusBadRequest, "Invalid request body")
		return
	}

	client, err := h.amneziawg.CreateClient(req)
	if err != nil {
		h.logger.WithError(err).WithField("client", req.Name).Error("Failed to create client")
		h.sendError(c, http.StatusInternalServerError, "Failed to create client")
		return
	}

	h.sendSuccess(c, client)
}

func (h *Handler) DeleteClient(c *gin.Context) {
	name := c.Param("name")
	if name == "" {
		h.sendError(c, http.StatusBadRequest, "Client name is required")
		return
	}

	if err := h.amneziawg.DeleteClient(name); err != nil {
		h.logger.WithError(err).WithField("client", name).Error("Failed to delete client")
		h.sendError(c, http.StatusInternalServerError, "Failed to delete client")
		return
	}

	h.sendSuccess(c, nil)
}

func (h *Handler) GetClientConfig(c *gin.Context) {
	name := c.Param("name")
	if name == "" {
		h.sendError(c, http.StatusBadRequest, "Client name is required")
		return
	}

	config, err := h.amneziawg.GetClientConfig(name)
	if err != nil {
		h.logger.WithError(err).WithField("client", name).Error("Failed to get client config")
		h.sendError(c, http.StatusInternalServerError, "Failed to get client config")
		return
	}

	h.sendSuccess(c, config)
}

func (h *Handler) GetClientQRCode(c *gin.Context) {
	name := c.Param("name")
	if name == "" {
		h.sendError(c, http.StatusBadRequest, "Client name is required")
		return
	}

	qrCode, err := h.amneziawg.GetClientQRCode(name)
	if err != nil {
		h.logger.WithError(err).WithField("client", name).Error("Failed to get client QR code")
		h.sendError(c, http.StatusInternalServerError, "Failed to get client QR code")
		return
	}

	h.sendSuccess(c, qrCode)
}

// Log handlers
func (h *Handler) GetLogs(c *gin.Context) {
	limitStr := c.DefaultQuery("limit", "100")
	limit, err := strconv.Atoi(limitStr)
	if err != nil || limit <= 0 {
		limit = 100
	}

	logs, err := h.logs.GetLogs(limit)
	if err != nil {
		h.logger.WithError(err).Error("Failed to get logs")
		h.sendError(c, http.StatusInternalServerError, "Failed to get logs")
		return
	}

	h.sendSuccess(c, logs)
}

func (h *Handler) StreamLogs(c *gin.Context) {
	conn, err := h.upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		h.logger.WithError(err).Error("Failed to upgrade to websocket")
		return
	}

	h.logs.AddClient(conn)

	// Обрабатываем отключение клиента
	defer h.logs.RemoveClient(conn)

	// Читаем сообщения от клиента (для поддержания соединения)
	for {
		_, _, err := conn.ReadMessage()
		if err != nil {
			break
		}
	}
}

// Statistics handlers (заглушки)
func (h *Handler) GetConnectionStats(c *gin.Context) {
	// Заглушка для статистики подключений
	stats := []models.ConnectionStats{
		{
			Timestamp:        time.Now().Add(-1 * time.Hour),
			ConnectedClients: 5,
			BandwidthIn:      1024 * 1024,
			BandwidthOut:     2 * 1024 * 1024,
			TotalTraffic:     3 * 1024 * 1024,
		},
	}

	h.sendSuccess(c, stats)
}

func (h *Handler) GetTrafficStats(c *gin.Context) {
	// Заглушка для статистики трафика
	stats := []models.ConnectionStats{
		{
			Timestamp:        time.Now().Add(-1 * time.Hour),
			ConnectedClients: 5,
			BandwidthIn:      1024 * 1024,
			BandwidthOut:     2 * 1024 * 1024,
			TotalTraffic:     3 * 1024 * 1024,
		},
	}

	h.sendSuccess(c, stats)
}
