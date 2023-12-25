package kafkaproducer

import (
	"context"
	"fmt"
	"math/rand"
	"strconv"
	"time"

	"github.com/IBM/sarama"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/propagation"
	semconv "go.opentelemetry.io/otel/semconv/v1.21.0"
	"go.opentelemetry.io/otel/trace"
)

type Opts struct {
	ServiceName     string
	RequestInterval int64
	BrokerAddress   string
	BrokerTopic     string
}

type OptFunc func(*Opts)

func defaultOpts() *Opts {
	return &Opts{
		RequestInterval: 2000,
		BrokerAddress:   "kafka",
		BrokerTopic:     "otel",
	}
}

type KafkaConsumerSimulator struct {
	Opts       *Opts
	Randomizer *rand.Rand
}

// Create an kafka consumer simulator instance
func New(
	optFuncs ...OptFunc,
) *KafkaConsumerSimulator {

	// Instantiate options with default values
	opts := defaultOpts()

	// Apply external options
	for _, f := range optFuncs {
		f(opts)
	}

	randomizer := rand.New(rand.NewSource(time.Now().UnixNano()))

	return &KafkaConsumerSimulator{
		Opts:       opts,
		Randomizer: randomizer,
	}
}

// Configure service name of simulator
func WithServiceName(serviceName string) OptFunc {
	return func(opts *Opts) {
		opts.ServiceName = serviceName
	}
}

// Configure Kafka request interval
func WithRequestInterval(requestInterval string) OptFunc {
	interval, err := strconv.ParseInt(requestInterval, 10, 64)
	if err != nil {
		panic(err.Error())
	}
	return func(opts *Opts) {
		opts.RequestInterval = interval
	}
}

// Configure Kafka broker address
func WithBrokerAddress(address string) OptFunc {
	return func(opts *Opts) {
		opts.BrokerAddress = address
	}
}

// Configure Kafka broker topic
func WithBrokerTopic(topic string) OptFunc {
	return func(opts *Opts) {
		opts.BrokerTopic = topic
	}
}

// Starts simulating Kafka consumer
func (k *KafkaConsumerSimulator) Simulate(
	users []string,
) {

	// Create Kafka topic
	k.createKafkaTopic()

	// Create producer
	producer := k.createKafkaProducer()

	// Publish messages
	go k.publishMessages(producer, users)
}

// Creates Kafta topic to publish the messages into
func (k *KafkaConsumerSimulator) createKafkaTopic() {

	// Set up configuration
	config := sarama.NewConfig()
	config.Version = sarama.V3_0_0_0
	config.Producer.Return.Successes = true

	// Create client
	client, err := sarama.NewClient(
		[]string{k.Opts.BrokerAddress},
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
	_, topicExists := topics[k.Opts.BrokerTopic]
	if !topicExists {

		err = admin.CreateTopic(
			k.Opts.BrokerTopic,
			&sarama.TopicDetail{
				NumPartitions:     1,
				ReplicationFactor: 1,
			}, false)
		if err != nil {
			panic(err)
		}

		fmt.Println("Topic " + k.Opts.BrokerTopic + " is created")
	}
}

// Creates the Kafka producer
func (k *KafkaConsumerSimulator) createKafkaProducer() sarama.AsyncProducer {

	// Create config
	saramaConfig := sarama.NewConfig()
	saramaConfig.Version = sarama.V3_0_0_0
	saramaConfig.Producer.Return.Successes = true

	// Create producer
	producer, err := sarama.NewAsyncProducer(
		[]string{k.Opts.BrokerAddress},
		saramaConfig,
	)
	if err != nil {
		panic(err)
	}

	// Wrap producer
	// producer = otelsarama.WrapAsyncProducer(saramaConfig, producer)

	// Print errors if message publishing goes wrong
	go func() {
		for err := range producer.Errors() {
			fmt.Println("Failed to write message: " + err.Error())
		}
	}()

	return producer
}

// Publish messages to topic
func (k *KafkaConsumerSimulator) publishMessages(
	producer sarama.AsyncProducer,
	users []string,
) {

	// Keep publishing messages
	for {
		func() {
			// Make request after each interval
			time.Sleep(time.Duration(k.Opts.RequestInterval) * time.Millisecond)

			// Get a random name
			name := users[k.Randomizer.Intn(len(users))]

			// Create message
			msg := sarama.ProducerMessage{
				Topic: k.Opts.BrokerTopic,
				Value: sarama.ByteEncoder([]byte(name)),
			}

			// Inject tracing info into message
			ctx := context.Background()
			span := k.createProducerSpan(ctx, &msg)
			defer span.End()

			// Publish message
			producer.Input() <- &msg
			<-producer.Successes()
		}()
	}
}

func (k *KafkaConsumerSimulator) createProducerSpan(
	ctx context.Context,
	msg *sarama.ProducerMessage,
) trace.Span {
	spanContext, span := otel.GetTracerProvider().Tracer(k.Opts.ServiceName).
		Start(
			ctx,
			fmt.Sprintf("%s publish", msg.Topic),
			trace.WithSpanKind(trace.SpanKindProducer),
			trace.WithAttributes(
				semconv.PeerService("kafka"),
				semconv.NetTransportTCP,
				semconv.MessagingSystem("kafka"),
				semconv.MessagingDestinationName(msg.Topic),
				semconv.MessagingOperationPublish,
				semconv.MessagingKafkaDestinationPartition(int(msg.Partition)),
			),
		)

	carrier := propagation.MapCarrier{}
	propagator := otel.GetTextMapPropagator()
	propagator.Inject(spanContext, carrier)

	for key, value := range carrier {
		msg.Headers = append(msg.Headers, sarama.RecordHeader{Key: []byte(key), Value: []byte(value)})
	}

	return span
}
