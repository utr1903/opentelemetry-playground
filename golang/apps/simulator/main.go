package main

import (
	"context"
	"os"
	"os/signal"

	"github.com/utr1903/opentelemetry-playground/golang/apps/simulator/config"
	"github.com/utr1903/opentelemetry-playground/golang/apps/simulator/httpclient"
	"github.com/utr1903/opentelemetry-playground/golang/apps/simulator/kafkaproducer"
	"github.com/utr1903/opentelemetry-playground/golang/apps/simulator/logger"
	"github.com/utr1903/opentelemetry-playground/golang/apps/simulator/otel"
)

func main() {
	// Get context
	ctx := context.Background()

	// Create new config
	cfg := config.NewConfig()

	// Initialize logger
	logger.NewLogger(cfg)

	// Create tracer provider
	tp := otel.NewTraceProvider(ctx)
	defer otel.ShutdownTraceProvider(ctx, tp)

	// Create metric provider
	mp := otel.NewMetricProvider(ctx)
	defer otel.ShutdownMetricProvider(ctx, mp)

	// Simulate
	go httpclient.SimulateHttpServer(cfg)
	go kafkaproducer.SimulateKafka(cfg)

	// Wait for signal to shutdown the simulator
	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
	defer cancel()

	<-ctx.Done()
}
