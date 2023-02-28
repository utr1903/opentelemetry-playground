package main

import (
	"context"
	"os"
	"os/signal"

	"github.com/utr1903/opentelemetry-playground/golang/apps/simulator/otel"
)

var (
	appName = os.Getenv("APP_NAME")
)

func main() {
	// Get context
	ctx := context.Background()

	// Create tracer provider
	tp := otel.NewTraceProvider(ctx)
	defer otel.ShutdownTraceProvider(ctx, tp)

	// Create metric provider
	mp := otel.NewMetricProvider(ctx)
	defer otel.ShutdownMetricProvider(ctx, mp)

	// Simulate
	go simulateHttpServer()
	go simulateKafka()

	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
	defer cancel()

	<-ctx.Done()
}
