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

	// Parse arguments and feature flags
	parseFlags()

	// Initialize logger
	initLogger()

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
	http.Handle("/api", otelhttp.NewHandler(http.HandlerFunc(handler), "api"))
	http.ListenAndServe(":"+appPort, nil)
}

func parseFlags() {
	appName = os.Getenv("APP_NAME")
	appPort = os.Getenv("APP_PORT")
}
