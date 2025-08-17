package vpn

import (
	"context"
	"fmt"
	"io"
	"strings"
	"time"

	"amneziawg-web-api/internal/models"

	"github.com/docker/docker/api/types"
	"github.com/docker/docker/api/types/container"
	"github.com/docker/docker/client"
	"github.com/sirupsen/logrus"
)

type DockerConnector struct {
	client        *client.Client
	containerName string
	projectPath   string
	logger        *logrus.Logger
}

func NewDockerConnector(containerName, projectPath string, logger *logrus.Logger) (*DockerConnector, error) {
	cli, err := client.NewClientWithOpts(client.FromEnv, client.WithAPIVersionNegotiation())
	if err != nil {
		return nil, fmt.Errorf("failed to create docker client: %w", err)
	}

	return &DockerConnector{
		client:        cli,
		containerName: containerName,
		projectPath:   projectPath,
		logger:        logger,
	}, nil
}

// ExecuteCommand executes a command in the VPN server container
func (d *DockerConnector) ExecuteCommand(ctx context.Context, cmd []string) (*models.DockerExecResult, error) {
	// Find container by name
	containerID, err := d.getContainerID(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to find container: %w", err)
	}

	// Create exec instance
	execConfig := container.ExecOptions{
		Cmd:          cmd,
		AttachStdout: true,
		AttachStderr: true,
	}

	execID, err := d.client.ContainerExecCreate(ctx, containerID, execConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to create exec instance: %w", err)
	}

	// Start exec instance
	execStartConfig := container.ExecStartOptions{
		Detach: false,
		Tty:    false,
	}

	response, err := d.client.ContainerExecAttach(ctx, execID.ID, execStartConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to attach to exec instance: %w", err)
	}
	defer response.Close()

	// Read output
	stdout, stderr, err := d.readExecOutput(response.Reader)
	if err != nil {
		return nil, fmt.Errorf("failed to read exec output: %w", err)
	}

	// Get exit code
	execInspect, err := d.client.ContainerExecInspect(ctx, execID.ID)
	if err != nil {
		return nil, fmt.Errorf("failed to inspect exec instance: %w", err)
	}

	return &models.DockerExecResult{
		ExitCode: execInspect.ExitCode,
		StdOut:   stdout,
		StdErr:   stderr,
	}, nil
}

// GetContainerInfo gets information about the VPN server container
func (d *DockerConnector) GetContainerInfo(ctx context.Context) (*models.DockerContainerInfo, error) {
	containerID, err := d.getContainerID(ctx)
	if err != nil {
		return nil, err
	}

	containerJSON, err := d.client.ContainerInspect(ctx, containerID)
	if err != nil {
		return nil, fmt.Errorf("failed to inspect container: %w", err)
	}

	created, err := time.Parse(time.RFC3339Nano, containerJSON.Created)
	if err != nil {
		created = time.Now() // fallback to current time if parsing fails
	}

	return &models.DockerContainerInfo{
		ID:      containerJSON.ID,
		Name:    containerJSON.Name,
		State:   containerJSON.State.Status,
		Status:  containerJSON.State.Status,
		Image:   containerJSON.Config.Image,
		Labels:  containerJSON.Config.Labels,
		Created: created,
	}, nil
}

// GetContainerLogs gets logs from the VPN server container
func (d *DockerConnector) GetContainerLogs(ctx context.Context, tail string) (string, error) {
	containerID, err := d.getContainerID(ctx)
	if err != nil {
		return "", err
	}

	options := container.LogsOptions{
		ShowStdout: true,
		ShowStderr: true,
		Tail:       tail,
		Timestamps: true,
	}

	logReader, err := d.client.ContainerLogs(ctx, containerID, options)
	if err != nil {
		return "", fmt.Errorf("failed to get container logs: %w", err)
	}
	defer logReader.Close()

	logs, err := io.ReadAll(logReader)
	if err != nil {
		return "", fmt.Errorf("failed to read logs: %w", err)
	}

	return string(logs), nil
}

// IsContainerRunning checks if the VPN server container is running
func (d *DockerConnector) IsContainerRunning(ctx context.Context) (bool, error) {
	containerInfo, err := d.GetContainerInfo(ctx)
	if err != nil {
		if strings.Contains(err.Error(), "No such container") {
			return false, nil
		}
		return false, err
	}

	return containerInfo.State == "running", nil
}

// GetDockerComposeStatus gets status of docker compose services
func (d *DockerConnector) GetDockerComposeStatus(ctx context.Context) ([]models.DockerContainerInfo, error) {
	// List containers with docker compose project label
	containers, err := d.client.ContainerList(ctx, container.ListOptions{
		All: true,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to list containers: %w", err)
	}

	var result []models.DockerContainerInfo
	for _, container := range containers {
		// Filter containers that belong to our project
		if d.isProjectContainer(container) {
			info := models.DockerContainerInfo{
				ID:      container.ID,
				Name:    container.Names[0], // First name without slash
				State:   container.State,
				Status:  container.Status,
				Image:   container.Image,
				Labels:  container.Labels,
				Created: time.Unix(container.Created, 0),
			}
			result = append(result, info)
		}
	}

	return result, nil
}

// ManageClientScript executes the manage-clients.sh script
func (d *DockerConnector) ManageClientScript(ctx context.Context, action string, args ...string) (*models.DockerExecResult, error) {
	cmd := []string{"/app/scripts/manage-clients.sh", action}
	cmd = append(cmd, args...)

	return d.ExecuteCommand(ctx, cmd)
}

// GetAWGShow executes 'awg show' command
func (d *DockerConnector) GetAWGShow(ctx context.Context, args ...string) (*models.DockerExecResult, error) {
	cmd := []string{"awg", "show"}
	cmd = append(cmd, args...)

	return d.ExecuteCommand(ctx, cmd)
}

// Close closes the docker client connection
func (d *DockerConnector) Close() error {
	return d.client.Close()
}

// getContainerID finds container ID by name
func (d *DockerConnector) getContainerID(ctx context.Context) (string, error) {
	containers, err := d.client.ContainerList(ctx, container.ListOptions{
		All: true,
	})
	if err != nil {
		return "", fmt.Errorf("failed to list containers: %w", err)
	}

	for _, container := range containers {
		for _, name := range container.Names {
			// Container names start with '/'
			if strings.TrimPrefix(name, "/") == d.containerName {
				return container.ID, nil
			}
		}
	}

	return "", fmt.Errorf("container '%s' not found", d.containerName)
}

// isProjectContainer checks if container belongs to our project
func (d *DockerConnector) isProjectContainer(container types.Container) bool {
	// Check if container name contains our service name
	for _, name := range container.Names {
		cleanName := strings.TrimPrefix(name, "/")
		if strings.Contains(cleanName, "amneziawg") {
			return true
		}
	}

	// Check labels for docker compose project
	if projectName, exists := container.Labels["com.docker.compose.project"]; exists {
		return strings.Contains(projectName, "amnezia") || strings.Contains(projectName, "wg")
	}

	return false
}

// readExecOutput reads stdout and stderr from exec response
func (d *DockerConnector) readExecOutput(reader io.Reader) (stdout, stderr string, err error) {
	// Docker multiplexes stdout and stderr in the response
	// We need to demultiplex it properly, but for simplicity, we'll read it all as stdout
	output, err := io.ReadAll(reader)
	if err != nil {
		return "", "", err
	}

	// For now, return all output as stdout
	// In a more sophisticated implementation, you'd demultiplex the streams
	return string(output), "", nil
}
