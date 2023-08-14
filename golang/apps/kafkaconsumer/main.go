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

	// Connect to MySQL
	mysql.CreateDatabaseConnection(cfg)
	defer mysql.Get().Close()

	ctx, cancel := signal.NotifyContext(ctx, os.Interrupt)
	defer cancel()
	if err := consumer.StartConsumerGroup(ctx, cfg); err != nil {
		panic(err.Error())
	}

	<-ctx.Done()
}
