package kafkaconsumer

import (
	"context"
	"os"
	"os/signal"

	_ "github.com/go-sql-driver/mysql"
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

	// Connect to MySQL
	db = createDatabaseConnection()
	defer db.Close()

	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
	defer cancel()
	if err := startConsumerGroup(ctx); err != nil {
		panic(err.Error())
	}

	<-ctx.Done()
}
