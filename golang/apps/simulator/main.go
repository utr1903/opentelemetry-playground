package simulator

import (
	"context"
	"os"
	"os/signal"
)

var (
	appName = os.Getenv("APP_NAME")
)

func main() {
	// Get context
	ctx := context.Background()

	// Create tracer provider
	tp := newTraceProvider(ctx)
	defer shutdownTraceProvider(ctx, tp)

	// Create metric provider
	mp := newMetricProvider(ctx)
	defer shutdownMetricProvider(ctx, mp)

	// Simulate
	go simulateHttpServer()
	go simulateKafka()

	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
	defer cancel()

	<-ctx.Done()
}
