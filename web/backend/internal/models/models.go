package models

import (
	"time"
)

// API Response структуры
type APIResponse struct {
	Success bool        `json:"success"`
	Data    interface{} `json:"data,omitempty"`
	Message string      `json:"message,omitempty"`
	Error   string      `json:"error,omitempty"`
}

// Server Status
type ServerStatus struct {
	Running   bool          `json:"running"`
	Uptime    int64         `json:"uptime"`
	Version   string        `json:"version"`
	PublicIP  string        `json:"publicIp"`
	Port      int           `json:"port"`
	Interface string        `json:"interface"`
	Clients   ClientsStatus `json:"clients"`
	Traffic   TrafficStats  `json:"traffic"`
}

type ClientsStatus struct {
	Total     int `json:"total"`
	Connected int `json:"connected"`
}

type TrafficStats struct {
	Sent     int64 `json:"sent"`
	Received int64 `json:"received"`
}

// Client Management
type Client struct {
	Name          string       `json:"name"`
	IP            string       `json:"ip"`
	PublicKey     string       `json:"publicKey"`
	CreatedAt     time.Time    `json:"createdAt"`
	LastHandshake *time.Time   `json:"lastHandshake,omitempty"`
	Connected     bool         `json:"connected"`
	Traffic       TrafficStats `json:"traffic"`
}

type CreateClientRequest struct {
	Name string `json:"name" binding:"required,min=1,max=50"`
	IP   string `json:"ip,omitempty"`
}

type ClientConfig struct {
	Name   string `json:"name"`
	Config string `json:"config"`
	QRCode string `json:"qrCode,omitempty"`
}

// Server Configuration
type ServerConfig struct {
	Interface   string            `json:"interface"`
	Port        int               `json:"port"`
	Network     string            `json:"network"`
	ServerIP    string            `json:"serverIp"`
	DNS         []string          `json:"dns"`
	PublicIP    string            `json:"publicIp"`
	Obfuscation ObfuscationConfig `json:"obfuscation"`
}

type ObfuscationConfig struct {
	Jc   int `json:"jc"`
	Jmin int `json:"jmin"`
	Jmax int `json:"jmax"`
	S1   int `json:"s1"`
	S2   int `json:"s2"`
	H1   int `json:"h1"`
	H2   int `json:"h2"`
	H3   int `json:"h3"`
	H4   int `json:"h4"`
}

// Logs
type LogEntry struct {
	Timestamp time.Time `json:"timestamp"`
	Level     string    `json:"level"`
	Message   string    `json:"message"`
	Source    string    `json:"source,omitempty"`
}

// Statistics
type ConnectionStats struct {
	Timestamp       time.Time `json:"timestamp"`
	ConnectedClients int      `json:"connectedClients"`
	BandwidthIn     int64    `json:"bandwidthIn"`
	BandwidthOut    int64    `json:"bandwidthOut"`
	TotalTraffic    int64    `json:"totalTraffic"`
}

// WebSocket Messages
type WSMessage struct {
	Type string      `json:"type"`
	Data interface{} `json:"data"`
}

const (
	WSMessageTypeLog    = "log"
	WSMessageTypeStatus = "status"
	WSMessageTypeError  = "error"
)

// VPN Statistics (for backend implementation)
type VPNStatistics struct {
	Timestamp       time.Time `json:"timestamp"`
	ConnectedClients int      `json:"connected_clients"`
	BandwidthIn     int64    `json:"bandwidth_in"`
	BandwidthOut    int64    `json:"bandwidth_out"`
	TotalTraffic    int64    `json:"total_traffic"`
}
