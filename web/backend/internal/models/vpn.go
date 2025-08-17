package models

import (
	"time"
)

// VPN Server Status
type VPNServerStatus struct {
	Running   bool          `json:"running"`
	Uptime    int64         `json:"uptime"`
	Version   string        `json:"version"`
	PublicIP  string        `json:"public_ip"`
	Port      int           `json:"port"`
	Interface string        `json:"interface"`
	Clients   ClientsStatus `json:"clients"`
	Traffic   TrafficStats  `json:"traffic"`
}



// VPN Server Configuration
type VPNServerConfig struct {
	Interface   string            `json:"interface"`
	Port        int               `json:"port"`
	Network     string            `json:"network"`
	ServerIP    string            `json:"server_ip"`
	DNS         []string          `json:"dns"`
	PublicIP    string            `json:"public_ip"`
	Obfuscation ObfuscationConfig `json:"obfuscation"`
}



// VPN Client Management
type VPNClient struct {
	Name          string       `json:"name"`
	IP            string       `json:"ip"`
	PublicKey     string       `json:"public_key"`
	CreatedAt     time.Time    `json:"created_at"`
	LastHandshake *time.Time   `json:"last_handshake,omitempty"`
	Connected     bool         `json:"connected"`
	Traffic       TrafficStats `json:"traffic"`
	Endpoint      string       `json:"endpoint,omitempty"`
}

type CreateVPNClientRequest struct {
	Name string `json:"name" binding:"required,min=1,max=50"`
	IP   string `json:"ip,omitempty"`
}

type VPNClientConfig struct {
	Name   string `json:"name"`
	Config string `json:"config"`
	QRCode string `json:"qr_code,omitempty"`
}

// Docker Integration Models
type DockerContainerInfo struct {
	ID      string            `json:"id"`
	Name    string            `json:"name"`
	State   string            `json:"state"`
	Status  string            `json:"status"`
	Image   string            `json:"image"`
	Labels  map[string]string `json:"labels"`
	Created time.Time         `json:"created"`
}

type DockerExecResult struct {
	ExitCode int    `json:"exit_code"`
	StdOut   string `json:"stdout"`
	StdErr   string `json:"stderr"`
}

// VPN Command Types
type VPNCommand struct {
	Command string   `json:"command"`
	Args    []string `json:"args"`
	Timeout int      `json:"timeout"` // seconds
}


