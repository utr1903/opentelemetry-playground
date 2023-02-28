package main

import (
	"context"
	"os"

	"github.com/Shopify/sarama"
	"go.opentelemetry.io/contrib/instrumentation/github.com/Shopify/sarama/otelsarama"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/trace"
)

var (
	kafkaBrokerAddress = os.Getenv("KAFKA_BROKER_ADDRESS")
	kafkaTopic         = os.Getenv("KAFKA_TOPIC")
	kafkaGroupId       = os.Getenv("KAFKA_CONSUMER_GROUP_ID")
)

func startConsumerGroup(ctx context.Context) error {
	saramaConfig := sarama.NewConfig()
	saramaConfig.Version = sarama.V3_0_0_0
	saramaConfig.Producer.Return.Successes = true

	consumerGroup, err := sarama.NewConsumerGroup(
		[]string{kafkaBrokerAddress},
		kafkaGroupId,
		saramaConfig,
	)
	if err != nil {
		return err
	}

	handler := groupHandler{}
	wrappedHandler := otelsarama.WrapConsumerGroupHandler(&handler)

	err = consumerGroup.Consume(
		ctx,
		[]string{kafkaTopic},
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

func (g *groupHandler) ConsumeClaim(session sarama.ConsumerGroupSession, claim sarama.ConsumerGroupClaim) error {
	for {
		select {
		case message := <-claim.Messages():

			// Parse name out of the message
			name := string(message.Value)

			// Store it into db
			storeIntoDb(session.Context(), name)

			// Acknowledge message
			session.MarkMessage(message, "")

		case <-session.Context().Done():
			return nil
		}
	}
}

func storeIntoDb(
	ctx context.Context,
	name string,
) {
	// Build db query
	dbOperation := "INSERT"
	dbStatement := dbOperation + "INTO name " + mysqlTable + "FROM " + mysqlTable

	// Get current parentSpan
	parentSpan := trace.SpanFromContext(ctx)
	defer parentSpan.End()

	// Create db span
	_, dbSpan := parentSpan.TracerProvider().
		Tracer(appName).
		Start(
			ctx,
			dbOperation+" "+mysqlDatabase+"."+mysqlTable,
			trace.WithSpanKind(trace.SpanKindClient),
		)
	defer dbSpan.End()

	// Set additional span attributes
	dbSpan.SetAttributes(
		attribute.String("db.system", "mysql"),
		attribute.String("db.user", mysqlUsername),
		attribute.String("net.peer.name", mysqlServer),
		attribute.String("net.peer.port", mysqlPort),
		attribute.String("net.transport", "IP.TCP"),
		attribute.String("db.name", mysqlDatabase),
		attribute.String("db.sql.table", mysqlTable),
		attribute.String("db.statement", dbStatement),
		attribute.String("db.operation", dbOperation),
	)

	// Prepare a statement
	stmt, err := db.Prepare("INSERT INTO " + mysqlTable + " (name) VALUES (?)")
	if err != nil {
		panic(err.Error())
	}
	defer stmt.Close()

	// Execute the statement
	_, err = stmt.Exec(name)
	if err != nil {
		panic(err.Error())
	}
}
