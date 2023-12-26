package config

import (
	"os"
)

type KafkaConsumerConfig struct {

	// App name
	ServiceName string

	// App port
	ServicePort string

	// Kafka
	KafkaBrokerAddress string
	KafkaTopic         string
	KafkaGroupId       string

	// MySQL
	MysqlServer   string
	MysqlUsername string
	MysqlPassword string
	MysqlDatabase string
	MysqlTable    string
	MysqlPort     string
}

var cfg *KafkaConsumerConfig

// Creates new config object by parsing environment variables
func NewConfig() {
	cfg = &KafkaConsumerConfig{
		ServiceName: os.Getenv("OTEL_SERVICE_NAME"),
		ServicePort: os.Getenv("APP_PORT"),

		KafkaBrokerAddress: os.Getenv("KAFKA_BROKER_ADDRESS"),
		KafkaTopic:         os.Getenv("KAFKA_TOPIC"),
		KafkaGroupId:       os.Getenv("KAFKA_CONSUMER_GROUP_ID"),

		MysqlServer:   os.Getenv("MYSQL_SERVER"),
		MysqlUsername: os.Getenv("MYSQL_USERNAME"),
		MysqlPassword: os.Getenv("MYSQL_PASSWORD"),
		MysqlDatabase: os.Getenv("MYSQL_DATABASE"),
		MysqlTable:    os.Getenv("MYSQL_TABLE"),
		MysqlPort:     os.Getenv("MYSQL_PORT"),
	}
}

// Returns instantiated config object
func GetConfig() *KafkaConsumerConfig {
	return cfg
}
