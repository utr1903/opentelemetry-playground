package main

import (
	"context"
	"net/http"
	"os"

	_ "github.com/go-sql-driver/mysql"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
)

var (
	appName = os.Getenv("APP_NAME")
	appPort = os.Getenv("APP_PORT")
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

	// Serve
	http.Handle("/list", otelhttp.NewHandler(http.HandlerFunc(listHandler), "list"))
	http.ListenAndServe(":"+appPort, nil)
}
