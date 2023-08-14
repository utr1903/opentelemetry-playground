package consumer

import (
	"context"

	"github.com/Shopify/sarama"
	"github.com/sirupsen/logrus"
	"github.com/utr1903/opentelemetry-playground/golang/apps/kafkaconsumer/config"
	"github.com/utr1903/opentelemetry-playground/golang/apps/kafkaconsumer/logger"
	"github.com/utr1903/opentelemetry-playground/golang/apps/kafkaconsumer/mysql"
	"go.opentelemetry.io/contrib/instrumentation/github.com/Shopify/sarama/otelsarama"
	"go.opentelemetry.io/otel/attribute"
	semconv "go.opentelemetry.io/otel/semconv/v1.20.0"
	"go.opentelemetry.io/otel/trace"
)

func StartConsumerGroup(
	ctx context.Context,
	cfg *config.KafkaConsumerConfig,
) error {
	saramaConfig := sarama.NewConfig()
	saramaConfig.Version = sarama.V3_0_0_0
	saramaConfig.Producer.Return.Successes = true

	consumerGroup, err := sarama.NewConsumerGroup(
		[]string{cfg.KafkaBrokerAddress},
		cfg.KafkaGroupId,
		saramaConfig,
	)
	if err != nil {
		return err
	}

	handler := groupHandler{}
	wrappedHandler := otelsarama.WrapConsumerGroupHandler(&handler)

	err = consumerGroup.Consume(
		ctx,
		[]string{cfg.KafkaTopic},
		wrappedHandler,
	)
	if err != nil {
		return err
	}
	return nil
}

type groupHandler struct{}

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
			err := storeIntoDb(ctx, name)
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

func storeIntoDb(
	ctx context.Context,
	name string,
) error {

	logger.Log(logrus.InfoLevel, ctx, name, "Storing into DB...")

	// Build db query
	dbOperation := "INSERT"
	dbStatement := dbOperation + " INTO " + config.GetConfig().MysqlTable + " (name) VALUES (?)"

	// Get current parentSpan
	parentSpan := trace.SpanFromContext(ctx)
	defer parentSpan.End()

	// Create db span
	spanName := dbOperation + " " + config.GetConfig().MysqlDatabase + "." + config.GetConfig().MysqlTable
	ctx, dbSpan := parentSpan.TracerProvider().
		Tracer(config.GetConfig().ServiceName).
		Start(
			ctx,
			spanName,
			trace.WithSpanKind(trace.SpanKindClient),
		)
	defer dbSpan.End()

	// Set additional span attributes
	dbSpanAttrs := []attribute.KeyValue{
		semconv.DBSystemMySQL,
		semconv.DBUser(config.GetConfig().MysqlUsername),
		semconv.NetPeerName(config.GetConfig().MysqlServer),
		semconv.NetPeerPort(int(config.GetConfig().MysqlPort)),
		semconv.NetTransportTCP,
		semconv.DBName(config.GetConfig().MysqlDatabase),
		semconv.DBSQLTable(config.GetConfig().MysqlTable),
		semconv.DBOperation(dbOperation),
		semconv.DBStatement(dbStatement),
	}
	dbSpanAttrs = append(dbSpanAttrs, semconv.DBOperation(dbOperation))
	dbSpanAttrs = append(dbSpanAttrs, semconv.DBStatement(dbStatement))

	// Prepare a statement
	stmt, err := mysql.Get().Prepare(dbStatement)
	if err != nil {
		msg := "Preparing DB statement is failed."
		logger.Log(logrus.ErrorLevel, ctx, name, msg)

		dbSpanAttrs = append(dbSpanAttrs, semconv.OTelStatusCodeError)
		dbSpanAttrs = append(dbSpanAttrs, semconv.OTelStatusDescription(msg))
		dbSpanAttrs = append(dbSpanAttrs, semconv.ExceptionMessage(err.Error()))
		dbSpan.SetAttributes(dbSpanAttrs...)

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
		dbSpanAttrs = append(dbSpanAttrs, semconv.ExceptionMessage(err.Error()))
		dbSpan.SetAttributes(dbSpanAttrs...)

		return err
	}

	dbSpan.SetAttributes(dbSpanAttrs...)
	logger.Log(logrus.InfoLevel, ctx, name, "Storing into DB is succeeded.")
	return nil
}
