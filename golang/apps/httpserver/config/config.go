package config

import (
	"os"
)

type HttpServerConfig struct {

	// App name
	ServiceName string

	// App port
	ServicePort string

	// MySQL
	MysqlServer   string
	MysqlUsername string
	MysqlPassword string
	MysqlDatabase string
	MysqlTable    string
	MysqlPort     string
}

var cfg *HttpServerConfig

// Creates new config object by parsing environment variables
func NewConfig() {
	cfg = &HttpServerConfig{
		ServiceName: os.Getenv("OTEL_SERVICE_NAME"),
		ServicePort: os.Getenv("APP_PORT"),

		MysqlServer:   os.Getenv("MYSQL_SERVER"),
		MysqlUsername: os.Getenv("MYSQL_USERNAME"),
		MysqlPassword: os.Getenv("MYSQL_PASSWORD"),
		MysqlDatabase: os.Getenv("MYSQL_DATABASE"),
		MysqlTable:    os.Getenv("MYSQL_TABLE"),
		MysqlPort:     os.Getenv("MYSQL_PORT"),
	}
}

// Returns instantiated config object
func GetConfig() *HttpServerConfig {
	return cfg
}
