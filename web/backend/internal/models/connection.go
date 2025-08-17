package models

import (
	"time"
)

// Connection String Data Structure
type ConnectionData struct {
	Version     string     `json:"version"`
	Name        string     `json:"name"`
	APIEndpoint string     `json:"api_endpoint"`
	ServerInfo  ServerInfo `json:"server_info"`
	Capabilities []string  `json:"capabilities"`
	Auth        AuthInfo   `json:"auth"`
	CreatedAt   time.Time  `json:"created_at"`
	ExpiresAt   time.Time  `json:"expires_at"`
}

type ServerInfo struct {
	ID                   string `json:"id"`
	Location             string `json:"location"`
	PublicKeyFingerprint string `json:"public_key_fingerprint"`
}

type AuthInfo struct {
	Method          string `json:"method"`
	RefreshEndpoint string `json:"refresh_endpoint"`
}

// Connection String Database Storage
type ConnectionString struct {
	ID          string    `json:"id" db:"id"`
	Name        string    `json:"name" db:"name"`
	ServerID    string    `json:"server_id" db:"server_id"`
	Location    string    `json:"location" db:"location"`
	APIEndpoint string    `json:"api_endpoint" db:"api_endpoint"`
	Capabilities string   `json:"capabilities" db:"capabilities"` // JSON string
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
	ExpiresAt   time.Time `json:"expires_at" db:"expires_at"`
	Revoked     bool      `json:"revoked" db:"revoked"`
	UsageCount  int       `json:"usage_count" db:"usage_count"`
	LastUsedAt  *time.Time `json:"last_used_at" db:"last_used_at"`
}

// Connection String Generation Request
type GenerateConnectionRequest struct {
	Name         string        `json:"name" binding:"required"`
	Location     string        `json:"location"`
	APIEndpoint  string        `json:"api_endpoint"`
	TTL          time.Duration `json:"ttl"`
	Capabilities []string      `json:"capabilities"`
}

// Connection String Response
type ConnectionStringResponse struct {
	ID               string    `json:"id"`
	Name             string    `json:"name"`
	ConnectionString string    `json:"connection_string"`
	ExpiresAt        time.Time `json:"expires_at"`
	QRCode           string    `json:"qr_code,omitempty"`
}

// Connection String List Response
type ConnectionStringListResponse struct {
	Connections []ConnectionStringInfo `json:"connections"`
	Total       int                   `json:"total"`
}

type ConnectionStringInfo struct {
	ID          string     `json:"id"`
	Name        string     `json:"name"`
	Location    string     `json:"location"`
	CreatedAt   time.Time  `json:"created_at"`
	ExpiresAt   time.Time  `json:"expires_at"`
	Revoked     bool       `json:"revoked"`
	UsageCount  int        `json:"usage_count"`
	LastUsedAt  *time.Time `json:"last_used_at"`
	IsExpired   bool       `json:"is_expired"`
}

// Connection String Revoke Request
type RevokeConnectionRequest struct {
	ID string `json:"id" binding:"required"`
}
