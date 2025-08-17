package api

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"strings"
	"time"

	"amneziawg-web-api/internal/models"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// GenerateConnectionString generates a new awgwc:// connection string
func (h *Handler) GenerateConnectionString(c *gin.Context) {
	var req models.GenerateConnectionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.sendError(c, http.StatusBadRequest, "Invalid request body")
		return
	}

	// Set defaults
	if req.Location == "" {
		req.Location = getEnvDefault("SERVER_DEFAULT_LOCATION", "Unknown")
	}
	if req.TTL == 0 {
		ttlStr := getEnvDefault("CONNECTION_DEFAULT_TTL", "720h")
		if ttl, err := time.ParseDuration(ttlStr); err == nil {
			req.TTL = ttl
		} else {
			req.TTL = 720 * time.Hour // 30 days default
		}
	}
	if req.APIEndpoint == "" {
		protocol := getEnvDefault("API_ENDPOINT_PROTOCOL", "http")
		host := getEnvDefault("API_ENDPOINT_HOST", "localhost:8080")
		req.APIEndpoint = fmt.Sprintf("%s://%s/api/v1", protocol, host)
	}
	if len(req.Capabilities) == 0 {
		req.Capabilities = []string{"clients", "logs", "stats", "config"}
	}

	// Generate connection data
	now := time.Now()
	serverID := uuid.New().String()
	
	connectionData := models.ConnectionData{
		Version:     "1.0",
		Name:        req.Name,
		APIEndpoint: req.APIEndpoint,
		ServerInfo: models.ServerInfo{
			ID:                   serverID,
			Location:            req.Location,
			PublicKeyFingerprint: h.generateServerFingerprint(req.Name),
		},
		Capabilities: req.Capabilities,
		Auth: models.AuthInfo{
			Method:          "jwt",
			RefreshEndpoint: "/auth/refresh",
		},
		CreatedAt: now,
		ExpiresAt: now.Add(req.TTL),
	}

	// Encode to awgwc:// format
	jsonData, err := json.Marshal(connectionData)
	if err != nil {
		h.logger.WithError(err).Error("Failed to marshal connection data")
		h.sendError(c, http.StatusInternalServerError, "Failed to generate connection string")
		return
	}

	encoded := base64.URLEncoding.EncodeToString(jsonData)
	connectionString := "awgwc://" + encoded

	// Store in database
	capabilitiesJSON, _ := json.Marshal(req.Capabilities)
	dbConnection := &models.ConnectionString{
		ID:           uuid.New().String(),
		Name:         req.Name,
		ServerID:     serverID,
		Location:     req.Location,
		APIEndpoint:  req.APIEndpoint,
		Capabilities: string(capabilitiesJSON),
		CreatedAt:    now,
		ExpiresAt:    connectionData.ExpiresAt,
		Revoked:      false,
		UsageCount:   0,
	}

	if err := h.db.StoreConnectionString(dbConnection); err != nil {
		h.logger.WithError(err).Error("Failed to store connection string in database")
		// Continue anyway, as the connection string is still valid
	}

	response := &models.ConnectionStringResponse{
		ID:               dbConnection.ID,
		Name:             req.Name,
		ConnectionString: connectionString,
		ExpiresAt:        connectionData.ExpiresAt,
		QRCode:           h.generateSimpleQR(connectionString),
	}

	h.logger.WithFields(map[string]interface{}{
		"connection_id": dbConnection.ID,
		"server_name":   req.Name,
		"location":      req.Location,
		"expires_at":    connectionData.ExpiresAt,
	}).Info("Connection string generated successfully")

	h.sendSuccess(c, response)
}

// ListConnectionStrings lists all generated connection strings
func (h *Handler) ListConnectionStrings(c *gin.Context) {
	connections, err := h.db.ListConnectionStrings()
	if err != nil {
		h.logger.WithError(err).Error("Failed to list connection strings")
		h.sendError(c, http.StatusInternalServerError, "Failed to list connection strings")
		return
	}

	// Convert to response format
	var connectionInfos []models.ConnectionStringInfo
	for _, conn := range connections {
		info := models.ConnectionStringInfo{
			ID:          conn.ID,
			Name:        conn.Name,
			Location:    conn.Location,
			CreatedAt:   conn.CreatedAt,
			ExpiresAt:   conn.ExpiresAt,
			Revoked:     conn.Revoked,
			UsageCount:  conn.UsageCount,
			LastUsedAt:  conn.LastUsedAt,
			IsExpired:   time.Now().After(conn.ExpiresAt),
		}
		connectionInfos = append(connectionInfos, info)
	}

	response := &models.ConnectionStringListResponse{
		Connections: connectionInfos,
		Total:       len(connectionInfos),
	}

	h.sendSuccess(c, response)
}

// RevokeConnectionString revokes a connection string
func (h *Handler) RevokeConnectionString(c *gin.Context) {
	id := c.Param("id")
	if id == "" {
		h.sendError(c, http.StatusBadRequest, "Connection string ID is required")
		return
	}

	// Check if connection string exists
	_, err := h.db.GetConnectionString(id)
	if err != nil {
		h.logger.WithError(err).WithField("connection_id", id).Error("Connection string not found")
		h.sendError(c, http.StatusNotFound, "Connection string not found")
		return
	}

	// Revoke the connection string
	if err := h.db.RevokeConnectionString(id); err != nil {
		h.logger.WithError(err).WithField("connection_id", id).Error("Failed to revoke connection string")
		h.sendError(c, http.StatusInternalServerError, "Failed to revoke connection string")
		return
	}

	h.logger.WithField("connection_id", id).Info("Connection string revoked successfully")
	h.sendSuccess(c, map[string]interface{}{
		"message": "Connection string revoked successfully",
	})
}

// TestConnectionString tests/parses a connection string
func (h *Handler) TestConnectionString(c *gin.Context) {
	var req struct {
		ConnectionString string `json:"connection_string" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		h.sendError(c, http.StatusBadRequest, "Invalid request body")
		return
	}

	// Parse connection string
	connectionData, err := h.parseConnectionString(req.ConnectionString)
	if err != nil {
		h.sendError(c, http.StatusBadRequest, fmt.Sprintf("Invalid connection string: %v", err))
		return
	}

	// Check if expired
	isExpired := time.Now().After(connectionData.ExpiresAt)
	
	response := map[string]interface{}{
		"valid":        true,
		"parsed_data":  connectionData,
		"is_expired":   isExpired,
		"time_to_expire": time.Until(connectionData.ExpiresAt).String(),
	}

	if isExpired {
		response["warning"] = "Connection string has expired"
	}

	h.sendSuccess(c, response)
}

// GetServerInfo returns public server information for connection
func (h *Handler) GetServerInfo(c *gin.Context) {
	// Get server status
	ctx := c.Request.Context()
	status, err := h.vpnService.GetServerStatus(ctx)
	if err != nil {
		h.logger.WithError(err).Warn("Failed to get server status for server info")
		// Continue with default values
		status = &models.VPNServerStatus{
			Running:   false,
			Version:   "1.0.0",
			Interface: "awg0",
			Port:      51820,
		}
	}

	// Get server config
	config, err := h.vpnService.GetServerConfig(ctx)
	if err != nil {
		h.logger.WithError(err).Warn("Failed to get server config for server info")
		config = &models.VPNServerConfig{
			Interface: "awg0",
			Port:      51820,
			PublicIP:  "auto",
		}
	}

	serverInfo := map[string]interface{}{
		"server_id":    uuid.New().String(),
		"name":         getEnvDefault("VITE_APP_NAME", "AmneziaWG Server"),
		"version":      status.Version,
		"capabilities": []string{"clients", "logs", "stats", "config"},
		"public_ip":    config.PublicIP,
		"port":         config.Port,
		"interface":    config.Interface,
		"running":      status.Running,
		"uptime":       status.Uptime,
		"health":       "healthy",
		"location":     getEnvDefault("SERVER_DEFAULT_LOCATION", "Unknown"),
	}

	h.sendSuccess(c, serverInfo)
}

// Helper functions

func (h *Handler) parseConnectionString(connectionString string) (*models.ConnectionData, error) {
	if !strings.HasPrefix(connectionString, "awgwc://") {
		return nil, fmt.Errorf("invalid connection string format, expected awgwc:// prefix")
	}

	encoded := connectionString[8:] // Remove 'awgwc://'
	decoded, err := base64.URLEncoding.DecodeString(encoded)
	if err != nil {
		return nil, fmt.Errorf("failed to decode base64: %w", err)
	}

	var data models.ConnectionData
	if err := json.Unmarshal(decoded, &data); err != nil {
		return nil, fmt.Errorf("failed to parse JSON: %w", err)
	}

	if data.Version != "1.0" {
		return nil, fmt.Errorf("unsupported connection string version: %s", data.Version)
	}

	return &data, nil
}

func (h *Handler) generateServerFingerprint(serverName string) string {
	// Simple fingerprint generation - in real implementation this would be actual server public key
	hash := 0
	for _, r := range serverName {
		hash = hash*31 + int(r)
	}
	return fmt.Sprintf("sha256:%08x", hash)
}

func (h *Handler) generateSimpleQR(connectionString string) string {
	// Simple ASCII QR code representation - in production use a real QR code library
	return fmt.Sprintf("QR code for: %s", connectionString[:50]+"...")
}

func getEnvDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
