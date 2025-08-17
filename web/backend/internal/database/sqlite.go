package database

import (
	"database/sql"
	"fmt"
	"time"

	"amneziawg-web-api/internal/models"

	_ "modernc.org/sqlite"
	"github.com/google/uuid"
	"github.com/sirupsen/logrus"
)

type SQLiteDB struct {
	db     *sql.DB
	logger *logrus.Logger
}

func NewSQLiteDB(databaseURL string, logger *logrus.Logger) (*SQLiteDB, error) {
	db, err := sql.Open("sqlite", databaseURL)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	// Configure connection pool
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(25)
	db.SetConnMaxLifetime(5 * time.Minute)

	// Test connection
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	sqliteDB := &SQLiteDB{
		db:     db,
		logger: logger,
	}

	// Run migrations
	if err := sqliteDB.Migrate(); err != nil {
		return nil, fmt.Errorf("failed to run migrations: %w", err)
	}

	return sqliteDB, nil
}

// Migrate runs database migrations
func (s *SQLiteDB) Migrate() error {
	migrations := []string{
		`CREATE TABLE IF NOT EXISTS users (
			id TEXT PRIMARY KEY,
			username TEXT UNIQUE NOT NULL,
			password_hash TEXT NOT NULL,
			role TEXT NOT NULL DEFAULT 'readonly',
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
		)`,
		
		`CREATE TABLE IF NOT EXISTS auth_tokens (
			id TEXT PRIMARY KEY,
			user_id TEXT NOT NULL,
			token_hash TEXT UNIQUE NOT NULL,
			token_type TEXT NOT NULL,
			expires_at DATETIME NOT NULL,
			revoked BOOLEAN DEFAULT 0,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			last_used_at DATETIME,
			FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
		)`,
		
		`CREATE TABLE IF NOT EXISTS connection_strings (
			id TEXT PRIMARY KEY,
			name TEXT NOT NULL,
			server_id TEXT NOT NULL,
			location TEXT NOT NULL,
			api_endpoint TEXT NOT NULL,
			capabilities TEXT NOT NULL,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			expires_at DATETIME NOT NULL,
			revoked BOOLEAN DEFAULT 0,
			usage_count INTEGER DEFAULT 0,
			last_used_at DATETIME
		)`,

		`CREATE INDEX IF NOT EXISTS idx_auth_tokens_user_id ON auth_tokens(user_id)`,
		`CREATE INDEX IF NOT EXISTS idx_auth_tokens_hash ON auth_tokens(token_hash)`,
		`CREATE INDEX IF NOT EXISTS idx_auth_tokens_expires ON auth_tokens(expires_at)`,
		`CREATE INDEX IF NOT EXISTS idx_connection_strings_server_id ON connection_strings(server_id)`,
		`CREATE INDEX IF NOT EXISTS idx_connection_strings_expires ON connection_strings(expires_at)`,
	}

	for _, migration := range migrations {
		if _, err := s.db.Exec(migration); err != nil {
			return fmt.Errorf("failed to execute migration: %w", err)
		}
	}

	// Create default admin user if not exists
	if err := s.createDefaultUser(); err != nil {
		return fmt.Errorf("failed to create default user: %w", err)
	}

	s.logger.Info("Database migrations completed successfully")
	return nil
}

// createDefaultUser creates a default admin user
func (s *SQLiteDB) createDefaultUser() error {
	var count int
	err := s.db.QueryRow("SELECT COUNT(*) FROM users WHERE role = 'admin'").Scan(&count)
	if err != nil {
		return err
	}

	if count > 0 {
		return nil // Admin user already exists
	}

	// Create default admin user
	userID := uuid.New().String()
	// Default password: "admin" - should be changed in production
	passwordHash := "$2a$10$8K1p/a0dCNlgP52TKVVd3eH9VKhEQfhTCsYD8gEkV7FrQeOv0KjkW" // bcrypt hash of "admin"
	
	_, err = s.db.Exec(`
		INSERT INTO users (id, username, password_hash, role, created_at, updated_at)
		VALUES (?, ?, ?, ?, ?, ?)
	`, userID, "admin", passwordHash, "admin", time.Now(), time.Now())

	if err != nil {
		return err
	}

	s.logger.Info("Default admin user created (username: admin, password: admin)")
	return nil
}

// User operations
func (s *SQLiteDB) GetUserByUsername(username string) (*models.User, error) {
	user := &models.User{}
	err := s.db.QueryRow(`
		SELECT id, username, password_hash, role, created_at, updated_at
		FROM users WHERE username = ?
	`, username).Scan(&user.ID, &user.Username, &user.PasswordHash, &user.Role, &user.CreatedAt, &user.UpdatedAt)
	
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("user not found")
		}
		return nil, err
	}
	
	return user, nil
}

func (s *SQLiteDB) GetUserByID(id string) (*models.User, error) {
	user := &models.User{}
	err := s.db.QueryRow(`
		SELECT id, username, password_hash, role, created_at, updated_at
		FROM users WHERE id = ?
	`, id).Scan(&user.ID, &user.Username, &user.PasswordHash, &user.Role, &user.CreatedAt, &user.UpdatedAt)
	
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("user not found")
		}
		return nil, err
	}
	
	return user, nil
}

func (s *SQLiteDB) CreateUser(user *models.User) error {
	if user.ID == "" {
		user.ID = uuid.New().String()
	}
	
	now := time.Now()
	user.CreatedAt = now
	user.UpdatedAt = now

	_, err := s.db.Exec(`
		INSERT INTO users (id, username, password_hash, role, created_at, updated_at)
		VALUES (?, ?, ?, ?, ?, ?)
	`, user.ID, user.Username, user.PasswordHash, user.Role, user.CreatedAt, user.UpdatedAt)
	
	return err
}

// Token operations
func (s *SQLiteDB) StoreToken(token *models.AuthToken) error {
	_, err := s.db.Exec(`
		INSERT INTO auth_tokens (id, user_id, token_hash, token_type, expires_at, revoked, created_at)
		VALUES (?, ?, ?, ?, ?, ?, ?)
	`, token.ID, token.UserID, token.TokenHash, token.TokenType, token.ExpiresAt, token.Revoked, token.CreatedAt)
	
	return err
}

func (s *SQLiteDB) GetToken(tokenHash string) (*models.AuthToken, error) {
	token := &models.AuthToken{}
	err := s.db.QueryRow(`
		SELECT id, user_id, token_hash, token_type, expires_at, revoked, created_at, last_used_at
		FROM auth_tokens WHERE token_hash = ?
	`, tokenHash).Scan(
		&token.ID, &token.UserID, &token.TokenHash, &token.TokenType,
		&token.ExpiresAt, &token.Revoked, &token.CreatedAt, &token.LastUsedAt,
	)
	
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("token not found")
		}
		return nil, err
	}
	
	return token, nil
}

func (s *SQLiteDB) RevokeToken(tokenHash string) error {
	_, err := s.db.Exec(`
		UPDATE auth_tokens SET revoked = 1 WHERE token_hash = ?
	`, tokenHash)
	
	return err
}

func (s *SQLiteDB) CleanupExpiredTokens() error {
	_, err := s.db.Exec(`
		DELETE FROM auth_tokens WHERE expires_at < datetime('now')
	`)
	
	return err
}

func (s *SQLiteDB) UpdateTokenLastUsed(tokenHash string) error {
	_, err := s.db.Exec(`
		UPDATE auth_tokens SET last_used_at = datetime('now') WHERE token_hash = ?
	`, tokenHash)
	
	return err
}

// Connection String operations
func (s *SQLiteDB) StoreConnectionString(conn *models.ConnectionString) error {
	if conn.ID == "" {
		conn.ID = uuid.New().String()
	}
	
	if conn.CreatedAt.IsZero() {
		conn.CreatedAt = time.Now()
	}

	_, err := s.db.Exec(`
		INSERT INTO connection_strings (id, name, server_id, location, api_endpoint, capabilities, created_at, expires_at, revoked, usage_count)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
	`, conn.ID, conn.Name, conn.ServerID, conn.Location, conn.APIEndpoint, conn.Capabilities, conn.CreatedAt, conn.ExpiresAt, conn.Revoked, conn.UsageCount)
	
	return err
}

func (s *SQLiteDB) GetConnectionString(id string) (*models.ConnectionString, error) {
	conn := &models.ConnectionString{}
	err := s.db.QueryRow(`
		SELECT id, name, server_id, location, api_endpoint, capabilities, created_at, expires_at, revoked, usage_count, last_used_at
		FROM connection_strings WHERE id = ?
	`, id).Scan(
		&conn.ID, &conn.Name, &conn.ServerID, &conn.Location, &conn.APIEndpoint,
		&conn.Capabilities, &conn.CreatedAt, &conn.ExpiresAt, &conn.Revoked, &conn.UsageCount, &conn.LastUsedAt,
	)
	
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("connection string not found")
		}
		return nil, err
	}
	
	return conn, nil
}

func (s *SQLiteDB) ListConnectionStrings() ([]models.ConnectionString, error) {
	rows, err := s.db.Query(`
		SELECT id, name, server_id, location, api_endpoint, capabilities, created_at, expires_at, revoked, usage_count, last_used_at
		FROM connection_strings
		ORDER BY created_at DESC
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var connections []models.ConnectionString
	for rows.Next() {
		var conn models.ConnectionString
		err := rows.Scan(
			&conn.ID, &conn.Name, &conn.ServerID, &conn.Location, &conn.APIEndpoint,
			&conn.Capabilities, &conn.CreatedAt, &conn.ExpiresAt, &conn.Revoked, &conn.UsageCount, &conn.LastUsedAt,
		)
		if err != nil {
			return nil, err
		}
		connections = append(connections, conn)
	}
	
	return connections, nil
}

func (s *SQLiteDB) RevokeConnectionString(id string) error {
	_, err := s.db.Exec(`
		UPDATE connection_strings SET revoked = 1 WHERE id = ?
	`, id)
	
	return err
}

func (s *SQLiteDB) IncrementConnectionStringUsage(id string) error {
	_, err := s.db.Exec(`
		UPDATE connection_strings 
		SET usage_count = usage_count + 1, last_used_at = datetime('now')
		WHERE id = ?
	`, id)
	
	return err
}

func (s *SQLiteDB) CleanupExpiredConnectionStrings() error {
	_, err := s.db.Exec(`
		DELETE FROM connection_strings WHERE expires_at < datetime('now')
	`)
	
	return err
}

// Close closes the database connection
func (s *SQLiteDB) Close() error {
	return s.db.Close()
}

// Health check
func (s *SQLiteDB) Ping() error {
	return s.db.Ping()
}
