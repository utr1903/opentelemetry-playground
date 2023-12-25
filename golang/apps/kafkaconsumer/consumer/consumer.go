package consumer

import (
	"context"

	"github.com/Shopify/sarama"
	"github.com/sirupsen/logrus"
	"github.com/utr1903/opentelemetry-playground/golang/apps/kafkaconsumer/logger"
	"github.com/utr1903/opentelemetry-playground/golang/apps/kafkaconsumer/mysql"
	"go.opentelemetry.io/contrib/instrumentation/github.com/Shopify/sarama/otelsarama"
	"go.opentelemetry.io/otel/attribute"
	semconv "go.opentelemetry.io/otel/semconv/v1.20.0"
	"go.opentelemetry.io/otel/trace"
)

type Opts struct {
	ServiceName     string
	BrokerAddress   string
	BrokerTopic     string
	ConsumerGroupId string
}

type OptFunc func(*Opts)

func defaultOpts() *Opts {
	return &Opts{
		BrokerAddress:   "kafka",
		BrokerTopic:     "otel",
		ConsumerGroupId: "kafkaconsumer",
	}
}

type KafkaConsumer struct {
	Opts  *Opts
	MySql *mysql.MySqlDatabase
}

// Create a kafka consumer instance
func New(
	db *mysql.MySqlDatabase,
	optFuncs ...OptFunc,
) *KafkaConsumer {

	// Instantiate options with default values
	opts := defaultOpts()

	// Apply external options
	for _, f := range optFuncs {
		f(opts)
	}

	return &KafkaConsumer{
		MySql: db,
		Opts:  opts,
	}
}

// Configure service name of consumer
func WithServiceName(serviceName string) OptFunc {
	return func(opts *Opts) {
		opts.ServiceName = serviceName
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

// Configure Kafka consumer group ID
func WithConsumerGroupId(groupId string) OptFunc {
	return func(opts *Opts) {
		opts.ConsumerGroupId = groupId
	}
}

func (k *KafkaConsumer) StartConsumerGroup(
	ctx context.Context,
) error {
	saramaConfig := sarama.NewConfig()
	saramaConfig.Version = sarama.V3_0_0_0
	saramaConfig.Producer.Return.Successes = true

	consumerGroup, err := sarama.NewConsumerGroup(
		[]string{k.Opts.BrokerAddress},
		k.Opts.ConsumerGroupId,
		saramaConfig,
	)
	if err != nil {
		return err
	}

	handler := groupHandler{
		ServiceName: k.Opts.ServiceName,
		MySql:       k.MySql,
	}
	wrappedHandler := otelsarama.WrapConsumerGroupHandler(&handler)

	err = consumerGroup.Consume(
		ctx,
		[]string{k.Opts.BrokerTopic},
		wrappedHandler,
	)
	if err != nil {
		return err
	}
	return nil
}

type groupHandler struct {
	ServiceName string
	MySql       *mysql.MySqlDatabase
}

func (g *groupHandler) Setup(_ sarama.ConsumerGroupSession) error {
	return nil
}

func (g *groupHandler) Cleanup(_ sarama.ConsumerGroupSession) error {
	return nil
}

func (g *groupHandler) ConsumeClaim(
	session sarama.ConsumerGroupSession,
	claim sarama.ConsumerGroupClaim,
) error {
	for {
		select {
		case message := <-claim.Messages():

			ctx := session.Context()

			// Parse name out of the message
			name := string(message.Value)

			logger.Log(logrus.InfoLevel, ctx, name, "Consuming message...")

			// Store it into db
			err := g.storeIntoDb(ctx, name)
			if err != nil {
				logger.Log(logrus.InfoLevel, ctx, name, "Consuming message is failed.")
				return nil
			}

			// Acknowledge message
			session.MarkMessage(message, "")
			logger.Log(logrus.InfoLevel, ctx, name, "Consuming message is succeeded.")

		case <-session.Context().Done():
			return nil
		}
	}
}

func (g *groupHandler) storeIntoDb(
	ctx context.Context,
	name string,
) error {

	logger.Log(logrus.InfoLevel, ctx, name, "Storing into DB...")

	// Build db query
	dbOperation := "INSERT"
	dbStatement := dbOperation + " INTO " + g.MySql.Opts.Table + " (name) VALUES (?)"

	// Get current parentSpan
	parentSpan := trace.SpanFromContext(ctx)
	defer parentSpan.End()

	// Create db span
	spanName := dbOperation + " " + g.MySql.Opts.Database + "." + g.MySql.Opts.Table
	ctx, dbSpan := parentSpan.TracerProvider().
		Tracer(g.ServiceName).
		Start(
			ctx,
			spanName,
			trace.WithSpanKind(trace.SpanKindClient),
		)
	defer dbSpan.End()

	// Set additional span attributes
	dbSpanAttrs := []attribute.KeyValue{
		semconv.DBSystemMySQL,
		semconv.DBUser(g.MySql.Opts.Username),
		semconv.NetPeerName(g.MySql.Opts.Server),
		// semconv.NetPeerPort(int(s.MySql.Opts.Port)),
		semconv.NetTransportTCP,
		semconv.DBName(g.MySql.Opts.Database),
		semconv.DBSQLTable(g.MySql.Opts.Table),
		semconv.DBOperation(dbOperation),
		semconv.DBStatement(dbStatement),
	}

	// Prepare a statement
	stmt, err := g.MySql.Instance.Prepare(dbStatement)
	if err != nil {
		msg := "Preparing DB statement is failed."
		logger.Log(logrus.ErrorLevel, ctx, name, msg)

		dbSpanAttrs = append(dbSpanAttrs, semconv.OTelStatusCodeError)
		dbSpanAttrs = append(dbSpanAttrs, semconv.OTelStatusDescription(msg))
		dbSpan.SetAttributes(dbSpanAttrs...)

		dbSpan.RecordError(err, trace.WithAttributes(
			semconv.ExceptionEscaped(true),
		))

		return err
	}
	defer stmt.Close()

	// Execute the statement
	_, err = stmt.Exec(name)
	if err != nil {
		msg := "Storing into DB is failed."
		logger.Log(logrus.ErrorLevel, ctx, name, msg)

		dbSpanAttrs = append(dbSpanAttrs, semconv.OTelStatusCodeError)
		dbSpanAttrs = append(dbSpanAttrs, semconv.OTelStatusDescription(msg))
		dbSpan.SetAttributes(dbSpanAttrs...)

		dbSpan.RecordError(err, trace.WithAttributes(
			semconv.ExceptionEscaped(true),
		))

		return err
	}

	dbSpan.SetAttributes(dbSpanAttrs...)
	logger.Log(logrus.InfoLevel, ctx, name, "Storing into DB is succeeded.")
	return nil
}
