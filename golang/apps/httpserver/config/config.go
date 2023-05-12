package config

import (
	"os"
	"strconv"
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
	MysqlPort     int64
}

var cfg *HttpServerConfig

func NewConfig() {
	port, err := strconv.ParseInt(os.Getenv("MYSQL_PORT"), 10, 64)
	if err != nil {
		panic(err.Error())
	}

	cfg = &HttpServerConfig{
		ServiceName: os.Getenv("OTEL_SERVICE_NAME"),
		ServicePort: os.Getenv("APP_PORT"),

		MysqlServer:   os.Getenv("MYSQL_SERVER"),
		MysqlUsername: os.Getenv("MYSQL_USERNAME"),
		MysqlPassword: os.Getenv("MYSQL_PASSWORD"),
		MysqlDatabase: os.Getenv("MYSQL_DATABASE"),
		MysqlTable:    os.Getenv("MYSQL_TABLE"),
		MysqlPort:     port,
	}
}

func GetConfig() *HttpServerConfig {
	return cfg
}