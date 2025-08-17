package api

import (
	"net/http"
	"strconv"
	"strings"
	"time"

	"amneziawg-web-api/internal/auth"
	"amneziawg-web-api/internal/database"
	"amneziawg-web-api/internal/models"
	"amneziawg-web-api/internal/vpn"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
	"github.com/sirupsen/logrus"
)

type Handler struct {
	vpnService *vpn.VPNService
	authService *auth.JWTService
	db         *database.SQLiteDB
	logger     *logrus.Logger
	upgrader   websocket.Upgrader
	authMiddleware *auth.AuthMiddleware
}

func NewHandler(vpnService *vpn.VPNService, authService *auth.JWTService, db *database.SQLiteDB, logger *logrus.Logger) *Handler {
	authMiddleware := auth.NewAuthMiddleware(authService, logger)
	
	return &Handler{
		vpnService: vpnService,
		authService: authService,
		db:         db,
		logger:     logger,
		authMiddleware: authMiddleware,
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
		// Public endpoints (no auth required)
		auth := v1.Group("/auth")
		{
			auth.POST("/login", h.Login)
			auth.POST("/refresh", h.RefreshToken)
		}

		// Server discovery (public)
		v1.GET("/server/info", h.GetServerInfo)

		// Protected endpoints
		protected := v1.Group("")
		protected.Use(h.authMiddleware.RequireAuth())
		{
			// Server management
			server := protected.Group("/server")
			{
				server.GET("/status", h.authMiddleware.RequireCapability("stats"), h.GetServerStatus)
				server.GET("/config", h.authMiddleware.RequireCapability("config"), h.GetServerConfig)
				server.PUT("/config", h.authMiddleware.RequireCapability("config"), h.UpdateServerConfig)
			}

			// Client management
			clients := protected.Group("/clients")
			{
				clients.GET("", h.authMiddleware.RequireCapability("clients"), h.GetClients)
				clients.POST("", h.authMiddleware.RequireCapability("clients"), h.CreateClient)
				clients.DELETE("/:name", h.authMiddleware.RequireCapability("clients"), h.DeleteClient)
				clients.GET("/:name/config", h.authMiddleware.RequireCapability("clients"), h.GetClientConfig)
				clients.GET("/:name/qr", h.authMiddleware.RequireCapability("clients"), h.GetClientQRCode)
			}

			// Logs
			logs := protected.Group("/logs")
			{
				logs.GET("", h.authMiddleware.RequireCapability("logs"), h.GetLogs)
				logs.GET("/stream", h.authMiddleware.RequireCapability("logs"), h.StreamLogs)
			}

			// Statistics
			stats := protected.Group("/stats")
			{
				stats.GET("/connections", h.authMiddleware.RequireCapability("stats"), h.GetConnectionStats)
				stats.GET("/traffic", h.authMiddleware.RequireCapability("stats"), h.GetTrafficStats)
			}

			// Connection strings management (admin only)
			connections := protected.Group("/connections")
			connections.Use(h.authMiddleware.RequireAdminRole())
			{
				connections.POST("/generate", h.GenerateConnectionString)
				connections.GET("", h.ListConnectionStrings)
				connections.POST("/:id/revoke", h.RevokeConnectionString)
				connections.POST("/test", h.TestConnectionString)
			}

			// User management (admin only)
			users := protected.Group("/users")
			users.Use(h.authMiddleware.RequireAdminRole())
			{
				users.POST("", h.CreateUser)
				users.GET("", h.ListUsers)
			}
		}
	}

	// Health check (public)
	router.GET("/health", h.HealthCheck)
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
	ctx := c.Request.Context()
	status, err := h.vpnService.GetServerStatus(ctx)
	if err != nil {
		h.logger.WithError(err).Error("Failed to get server status")
		h.sendError(c, http.StatusInternalServerError, "Failed to get server status")
		return
	}

	h.sendSuccess(c, status)
}

func (h *Handler) GetServerConfig(c *gin.Context) {
	ctx := c.Request.Context()
	config, err := h.vpnService.GetServerConfig(ctx)
	if err != nil {
		h.logger.WithError(err).Error("Failed to get server config")
		h.sendError(c, http.StatusInternalServerError, "Failed to get server config")
		return
	}

	h.sendSuccess(c, config)
}

func (h *Handler) UpdateServerConfig(c *gin.Context) {
	var config models.VPNServerConfig
	if err := c.ShouldBindJSON(&config); err != nil {
		h.sendError(c, http.StatusBadRequest, "Invalid request body")
		return
	}

	ctx := c.Request.Context()
	if err := h.vpnService.UpdateServerConfig(ctx, &config); err != nil {
		h.logger.WithError(err).Error("Failed to update server config")
		h.sendError(c, http.StatusInternalServerError, "Failed to update server config")
		return
	}

	h.sendSuccess(c, nil)
}

// Client handlers
func (h *Handler) GetClients(c *gin.Context) {
	ctx := c.Request.Context()
	clients, err := h.vpnService.GetClients(ctx)
	if err != nil {
		h.logger.WithError(err).Error("Failed to get clients")
		h.sendError(c, http.StatusInternalServerError, "Failed to get clients")
		return
	}

	h.sendSuccess(c, clients)
}

func (h *Handler) CreateClient(c *gin.Context) {
	var req models.CreateVPNClientRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.sendError(c, http.StatusBadRequest, "Invalid request body")
		return
	}

	ctx := c.Request.Context()
	client, err := h.vpnService.CreateClient(ctx, &req)
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

	ctx := c.Request.Context()
	if err := h.vpnService.DeleteClient(ctx, name); err != nil {
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

	ctx := c.Request.Context()
	config, err := h.vpnService.GetClientConfig(ctx, name)
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

	ctx := c.Request.Context()
	qrCode, err := h.vpnService.GetClientQRCode(ctx, name)
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

	ctx := c.Request.Context()
	logsStr, err := h.vpnService.GetLogs(ctx, limitStr)
	if err != nil {
		h.logger.WithError(err).Error("Failed to get logs")
		h.sendError(c, http.StatusInternalServerError, "Failed to get logs")
		return
	}

	// Parse logs into structured format
	logs := h.parseLogsString(logsStr)
	h.sendSuccess(c, logs)
}

func (h *Handler) StreamLogs(c *gin.Context) {
	conn, err := h.upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		h.logger.WithError(err).Error("Failed to upgrade to websocket")
		return
	}
	defer conn.Close()

	h.logger.Info("WebSocket client connected for log streaming")

	// Send initial logs
	ctx := c.Request.Context()
	initialLogs, err := h.vpnService.GetLogs(ctx, "50")
	if err == nil {
		logs := h.parseLogsString(initialLogs)
		for _, log := range logs {
			if err := conn.WriteJSON(log); err != nil {
				h.logger.WithError(err).Error("Failed to send initial log")
				return
			}
		}
	}

	// Keep connection alive and handle disconnection
	for {
		_, _, err := conn.ReadMessage()
		if err != nil {
			h.logger.Info("WebSocket client disconnected")
			break
		}
	}
}

// Statistics handlers  
func (h *Handler) GetConnectionStats(c *gin.Context) {
	// Generate mock statistics based on current server status
	ctx := c.Request.Context()
	status, err := h.vpnService.GetServerStatus(ctx)
	if err != nil {
		h.logger.WithError(err).Warn("Failed to get server status for stats")
		status = &models.VPNServerStatus{}
	}

	// Generate sample data points for the last 24 hours
	var stats []models.VPNStatistics
	now := time.Now()
	for i := 24; i >= 0; i-- {
		timestamp := now.Add(-time.Duration(i) * time.Hour)
		stat := models.VPNStatistics{
			Timestamp:       timestamp,
			ConnectedClients: status.Clients.Connected + (i % 3), // Slight variation
			BandwidthIn:     status.Traffic.Received / 24,
			BandwidthOut:    status.Traffic.Sent / 24,
			TotalTraffic:    (status.Traffic.Sent + status.Traffic.Received) / 24,
		}
		stats = append(stats, stat)
	}

	h.sendSuccess(c, stats)
}

func (h *Handler) GetTrafficStats(c *gin.Context) {
	// Similar to connection stats but focused on traffic
	ctx := c.Request.Context()
	status, err := h.vpnService.GetServerStatus(ctx)
	if err != nil {
		h.logger.WithError(err).Warn("Failed to get server status for traffic stats")
		status = &models.VPNServerStatus{}
	}

	var stats []models.VPNStatistics
	now := time.Now()
	for i := 24; i >= 0; i-- {
		timestamp := now.Add(-time.Duration(i) * time.Hour)
		// Generate some variation in traffic
		variation := int64(i*1024*1024) + int64(timestamp.Unix()%1000)*1024
		stat := models.VPNStatistics{
			Timestamp:       timestamp,
			ConnectedClients: status.Clients.Connected,
			BandwidthIn:     variation,
			BandwidthOut:    variation * 2,
			TotalTraffic:    variation * 3,
		}
		stats = append(stats, stat)
	}

	h.sendSuccess(c, stats)
}

// Helper functions
func (h *Handler) parseLogsString(logsStr string) []models.LogEntry {
	var logs []models.LogEntry
	lines := strings.Split(logsStr, "\n")
	
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}

		logEntry := models.LogEntry{
			Timestamp: time.Now(),
			Level:     "info",
			Message:   line,
			Source:    "amneziawg",
		}

		// Simple parsing to extract log level
		lineLower := strings.ToLower(line)
		if strings.Contains(lineLower, "error") || strings.Contains(lineLower, "err") {
			logEntry.Level = "error"
		} else if strings.Contains(lineLower, "warn") || strings.Contains(lineLower, "warning") {
			logEntry.Level = "warn"
		} else if strings.Contains(lineLower, "debug") {
			logEntry.Level = "debug"
		}

		logs = append(logs, logEntry)
	}

	return logs
}
