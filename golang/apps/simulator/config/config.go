package config

import "os"

type SimulatorConfig struct {

	// App name
	ServiceName string

	// HTTP server
	HttpserverRequestInterval string
	HttpserverEndpoint        string
	HttpserverPort            string

	// Kafka producer
	KafkaRequestInterval string
	KafkaBrokerAddress   string
	KafkaTopic           string

	// Users
	Users []string
}

// Creates new config object by parsing environment variables
func NewConfig() *SimulatorConfig {
	return &SimulatorConfig{
		ServiceName: os.Getenv("OTEL_SERVICE_NAME"),

		HttpserverRequestInterval: os.Getenv("HTTP_SERVER_REQUEST_INTERVAL"),
		HttpserverEndpoint:        os.Getenv("HTTP_SERVER_ENDPOINT"),
		HttpserverPort:            os.Getenv("HTTP_SERVER_PORT"),

		KafkaRequestInterval: os.Getenv("KAFKA_REQUEST_INTERVAL"),
		KafkaBrokerAddress:   os.Getenv("KAFKA_BROKER_ADDRESS"),
		KafkaTopic:           os.Getenv("KAFKA_TOPIC"),

		Users: []string{
			"elon",
			"jeff",
			"warren",
			"bill",
			"mark",
		},
	}
}
