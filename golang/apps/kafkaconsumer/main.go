package main

import (
	"context"
	"os"
	"os/signal"
	"time"

	_ "github.com/go-sql-driver/mysql"
	"github.com/utr1903/opentelemetry-playground/golang/apps/kafkaconsumer/config"
	"github.com/utr1903/opentelemetry-playground/golang/apps/kafkaconsumer/consumer"
	"github.com/utr1903/opentelemetry-playground/golang/apps/kafkaconsumer/mysql"
	"github.com/utr1903/opentelemetry-playground/golang/apps/kafkaconsumer/otel"
	"go.opentelemetry.io/contrib/instrumentation/runtime"
)

func main() {

	// Create new config
	config.NewConfig()
	cfg := config.GetConfig()

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
	if err := consumer.StartConsumerGroup(ctx, cfg); err != nil {
		panic(err.Error())
	}

	<-ctx.Done()
}
