# Build stage
FROM golang:1.23-alpine AS builder

WORKDIR /app

# Install git, gcc, musl-dev, and sqlite-dev for CGO and SQLite
RUN apk add --no-cache git gcc musl-dev sqlite-dev

# Copy go mod files first for better caching
COPY go.mod go.sum ./

# Download dependencies (this step will be cached if go.mod/go.sum don't change)
RUN go mod download && go mod verify

# Copy source code (this invalidates cache only when source changes)
COPY . .

# Build the main application with CGO enabled for SQLite
RUN CGO_ENABLED=1 GOOS=linux go build -a -ldflags '-linkmode external -extldflags "-static"' -o main ./cmd/main.go

# Build the connection generator tool
RUN CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-s -w' -o connection-gen ./cmd/connection-gen/main.go

# Runtime stage
FROM alpine:3.18

WORKDIR /app

# Install necessary packages
RUN apk --no-cache add ca-certificates docker-cli make curl sqlite

# Create directories for application data
RUN mkdir -p data logs

# Create non-root user
RUN addgroup -g 1001 appgroup && \
    adduser -u 1001 -G appgroup -s /bin/sh -D appuser

# Copy binaries from builder stage
COPY --from=builder /app/main .
COPY --from=builder /app/connection-gen .

# Make binaries executable
RUN chmod +x main connection-gen

# Change ownership
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Run the binary
CMD ["./main"]
