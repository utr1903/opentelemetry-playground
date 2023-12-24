package main

import (
	"context"
	"os"
	"os/signal"
	"time"

	"github.com/utr1903/opentelemetry-playground/golang/apps/simulator/config"
	"github.com/utr1903/opentelemetry-playground/golang/apps/simulator/httpclient"
	"github.com/utr1903/opentelemetry-playground/golang/apps/simulator/kafkaproducer"
	"github.com/utr1903/opentelemetry-playground/golang/apps/simulator/logger"
	"github.com/utr1903/opentelemetry-playground/golang/apps/simulator/otel"
	"go.opentelemetry.io/contrib/instrumentation/runtime"
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

	// Start runtime metric collection
	err := runtime.Start(runtime.WithMinimumReadMemStatsInterval(time.Second))
	if err != nil {
		panic(err)
	}

	// Instantiate HTTP server simulator
	httpserverSimulator := httpclient.New(
		httpclient.WithServiceName(cfg.ServiceName),
		httpclient.WithRequestInterval(cfg.HttpserverRequestInterval),
		httpclient.WithServerEndpoint(cfg.HttpserverEndpoint),
		httpclient.WithServerPort(cfg.HttpserverPort),
	)

	// Simulate
	go httpserverSimulator.SimulateHttpServer(cfg.Users)
	go kafkaproducer.SimulateKafka(cfg)

	// Wait for signal to shutdown the simulator
	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
	defer cancel()

	<-ctx.Done()
}
