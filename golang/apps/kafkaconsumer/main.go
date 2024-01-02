package main

import (
	"context"
	"os"
	"os/signal"
	"time"

	_ "github.com/go-sql-driver/mysql"
	"github.com/utr1903/opentelemetry-playground/golang/apps/kafkaconsumer/config"
	"github.com/utr1903/opentelemetry-playground/golang/apps/kafkaconsumer/consumer"
	"github.com/utr1903/opentelemetry-playground/golang/apps/kafkaconsumer/logger"
	"github.com/utr1903/opentelemetry-playground/golang/apps/kafkaconsumer/mysql"
	"github.com/utr1903/opentelemetry-playground/golang/apps/kafkaconsumer/otel"
	"go.opentelemetry.io/contrib/instrumentation/runtime"
)

func main() {

	// Create new config
	config.NewConfig()
	cfg := config.GetConfig()

	// Initialize logger
	logger.NewLogger(cfg)

	// Get context
	ctx := context.Background()

	// Create tracer provider
	tp := otel.NewTraceProvider(ctx)
	defer otel.ShutdownTraceProvider(ctx, tp)

	// Create metric provider
	mp := otel.NewMetricProvider(ctx)
	defer otel.ShutdownMetricProvider(ctx, mp)

	// Start runtime metric collection
	err := runtime.Start(runtime.WithMinimumReadMemStatsInterval(time.Second))
	if err != nil {
		panic(err)
	}

	// Instantiate MySQL database
	db := mysql.New(
		mysql.WithServer(cfg.MysqlServer),
		mysql.WithPort(cfg.MysqlPort),
		mysql.WithUsername(cfg.MysqlUsername),
		mysql.WithPassword(cfg.MysqlPassword),
		mysql.WithDatabase(cfg.MysqlDatabase),
		mysql.WithTable(cfg.MysqlTable),
	)
	db.CreateDatabaseConnection()
	defer db.Instance.Close()

	ctx, cancel := signal.NotifyContext(ctx, os.Interrupt)
	defer cancel()

	// Instantiate Kafka consumer
	kafkaConsumer := consumer.New(db,
		consumer.WithServiceName(cfg.ServiceName),
		consumer.WithBrokerAddress(cfg.KafkaBrokerAddress),
		consumer.WithBrokerTopic(cfg.KafkaTopic),
		consumer.WithConsumerGroupId(cfg.KafkaGroupId),
	)
	if err := kafkaConsumer.StartConsumerGroup(ctx); err != nil {
		panic(err.Error())
	}

	<-ctx.Done()
}
