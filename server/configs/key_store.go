package configs

import (
	"fmt"
	"github.com/denisenkom/go-mssqldb/azuread"
	"github.com/joho/godotenv"
	"log"
	"os"
	"strconv"
	"time"
)

// KeyStoreConfig represents the configuration for the KeyStore.
// It contains the sensitive information for the KeyStore.
// This data will be loaded from the .env file, from a key vault or hard coded.
type KeyStoreConfig struct {
	// configs
	HMacSecretKey string

	// server
	GrpcServerPort string
	GrpcServerHost string
	HttpServerPort string
	HttpServerHost string

	// database
	DbConnUrl         string
	DbDriver          string
	dbUser            string
	dbPassword        string
	dbHost            string
	dbPort            string
	dbName            string
	DbConnMaxIdleTime time.Duration
	DbConnMaxLifetime time.Duration
	DbMaxOpenConns    int
	DbMaxIdleConns    int
	dbSslMode         bool
}

// NewKeyStoreConfigFromDotEnv creates a new KeyStoreConfig from .env file.
func NewKeyStoreConfigFromDotEnv() *KeyStoreConfig {
	// load env vars
	if err := godotenv.Load("./configs/.env"); err != nil {
		log.Fatalf("failed to load env vars: %v", err)
	}

	cfg := &KeyStoreConfig{
		GrpcServerPort: os.Getenv("GRPC_SERVER_PORT"),
		GrpcServerHost: os.Getenv("GRPC_SERVER_HOST"),
		HttpServerPort: os.Getenv("HTTP_SERVER_PORT"),
		HttpServerHost: os.Getenv("HTTP_SERVER_HOST"),
		DbDriver:       os.Getenv("DB_DRIVER"),
		dbUser:         os.Getenv("DB_USER"),
		dbPassword:     os.Getenv("DB_PASSWORD"),
		dbHost:         os.Getenv("DB_HOST"),
		dbPort:         os.Getenv("DB_PORT"),
		dbName:         os.Getenv("DB_NAME"),
		DbConnUrl:      os.Getenv("DB_CONN_URL"),
		HMacSecretKey:  os.Getenv("HMAC_SECRET_KEY"),
	}

	if len(cfg.HMacSecretKey) == 0 {
		cfg.HMacSecretKey = "secret@1234"
	}

	if len(cfg.GrpcServerPort) == 0 {
		cfg.GrpcServerPort = "50051"
	}

	if len(cfg.GrpcServerHost) == 0 {
		cfg.GrpcServerHost = "0.0.0.0"
	}

	if len(cfg.HttpServerPort) == 0 {
		cfg.HttpServerPort = "9900"
	}

	if len(cfg.HttpServerHost) == 0 {
		cfg.HttpServerHost = "0.0.0.0"
	}

	if idleTime, err := strconv.Atoi(os.Getenv("DB_CONN_MAX_IDLE_TIME")); err == nil {
		cfg.DbConnMaxIdleTime = time.Second * time.Duration(idleTime)
	}

	if lifetime, err := strconv.Atoi(os.Getenv("DB_CONN_MAX_LIFETIME")); err == nil {
		cfg.DbConnMaxLifetime = time.Second * time.Duration(lifetime)
	}

	if maxOpenConns, err := strconv.Atoi(os.Getenv("DB_MAX_OPEN_CONNS")); err == nil {
		cfg.DbMaxOpenConns = maxOpenConns
	}

	if maxIdleConns, err := strconv.Atoi(os.Getenv("DB_MAX_IDLE_CONNS")); err == nil {
		cfg.DbMaxIdleConns = maxIdleConns
	}

	if sslMode, err := strconv.ParseBool(os.Getenv("DB_SSL_MODE")); err == nil {
		cfg.dbSslMode = sslMode
	}

	// get database driver
	if len(cfg.DbDriver) == 0 {
		cfg.DbDriver = azuread.DriverName
	}

	// create database connection url if not provided
	if len(cfg.DbConnUrl) == 0 {
		cfg.DbConnUrl = fmt.Sprintf("%s://%s:%s@%s:%s?database=%s&connection+timeout=30&encrypt=disable&trustservercertificate=%v",
			cfg.DbDriver, cfg.dbUser, cfg.dbPassword, cfg.dbHost, cfg.dbPort, cfg.dbName, cfg.dbSslMode)
	}

	return cfg
}

// NewKeyStoreConfigFromVault creates a new KeyStoreConfig from a key vault.
func NewKeyStoreConfigFromVault() *KeyStoreConfig {
	// @todo -> implement this
	return &KeyStoreConfig{}
}
