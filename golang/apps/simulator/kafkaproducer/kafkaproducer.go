package kafkaproducer

import (
	"context"
	"fmt"
	"math/rand"
	"strconv"
	"time"

	"github.com/Shopify/sarama"
	"github.com/utr1903/opentelemetry-playground/golang/apps/simulator/config"
	"go.opentelemetry.io/contrib/instrumentation/github.com/Shopify/sarama/otelsarama"
	"go.opentelemetry.io/otel"
)

var (
	kafkaRequestInterval string
	kafkaBrokerAddress   string
	kafkaTopic           string

	randomizer *rand.Rand
)

// Starts simulating Kafka consumer
func SimulateKafka(
	cfg *config.SimulatorConfig,
) {

	// Initialize simulator
	initSimulator(cfg)

	interval, err := strconv.ParseInt(kafkaRequestInterval, 10, 64)
	if err != nil {
		fmt.Println(err.Error())
		return
	}

	// Create Kafka topic
	createKafkaTopic()

	// Create producer
	producer := createKafkaProducer()

	go func() {

		// Keep publishing messages
		for {

			// Make request after each interval
			time.Sleep(time.Duration(interval) * time.Millisecond)

			// Get a random name
			name := cfg.Users[randomizer.Intn(len(cfg.Users))]

			// Create message
			msg := sarama.ProducerMessage{
				Topic: kafkaTopic,
				Value: sarama.ByteEncoder([]byte(name)),
			}

			// Inject tracing info into message
			ctx := context.Background()
			otel.GetTextMapPropagator().Inject(ctx, otelsarama.NewProducerMessageCarrier(&msg))

			// Publish message
			producer.Input() <- &msg
			<-producer.Successes()
		}
	}()
}

// Initializes the Kafka producer by setting the necessary variables
func initSimulator(
	cfg *config.SimulatorConfig,
) {
	// Set Kafka producer related parameters
	setKafkaParameters(cfg)

	// Initialize random number generator
	randomizer = rand.New(rand.NewSource(time.Now().UnixNano()))
}

// Sets Kafka related parameters
func setKafkaParameters(
	cfg *config.SimulatorConfig,
) {
	kafkaRequestInterval = cfg.KafkaRequestInterval
	kafkaBrokerAddress = cfg.KafkaBrokerAddress
	kafkaTopic = cfg.KafkaTopic
}

// Creates Kafta topic to publish the messages into
func createKafkaTopic() {

	// Set up configuration
	config := sarama.NewConfig()
	config.Version = sarama.V3_0_0_0
	config.Producer.Return.Successes = true

	// Create client
	client, err := sarama.NewClient(
		[]string{kafkaBrokerAddress},
		config,
	)
	if err != nil {
		panic(err)
	}
	defer client.Close()

	// Create admin
	admin, err := sarama.NewClusterAdminFromClient(client)
	if err != nil {
		panic(err)
	}
	defer admin.Close()

	// Check if topic exists
	topics, err := admin.ListTopics()
	if err != nil {
		panic(err)
	}

	// Create topic if not exists
	_, topicExists := topics[kafkaTopic]
	if !topicExists {

		err = admin.CreateTopic(
			kafkaTopic,
			&sarama.TopicDetail{
				NumPartitions:     1,
				ReplicationFactor: 1,
			}, false)
		if err != nil {
			panic(err)
		}

		fmt.Println("Topic " + kafkaTopic + " is created")
	}
}

// Creates the Kafka producer
func createKafkaProducer() sarama.AsyncProducer {

	// Create config
	saramaConfig := sarama.NewConfig()
	saramaConfig.Version = sarama.V3_0_0_0
	saramaConfig.Producer.Return.Successes = true

	// Create producer
	producer, err := sarama.NewAsyncProducer(
		[]string{kafkaBrokerAddress},
		saramaConfig,
	)
	if err != nil {
		panic(err)
	}

	// Wrap producer
	producer = otelsarama.WrapAsyncProducer(saramaConfig, producer)

	// Print errors if message publishing goes wrong
	go func() {
		for err := range producer.Errors() {
			fmt.Println("Failed to write message: " + err.Error())
		}
	}()

	return producer
}
