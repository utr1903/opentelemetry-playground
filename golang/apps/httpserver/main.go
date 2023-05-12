package main

import (
	"context"
	"net/http"
	"os"
	"strconv"

	_ "github.com/go-sql-driver/mysql"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
)

var (
	appName string
	appPort string
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

	mysqlServer = os.Getenv("MYSQL_SERVER")
	mysqlUsername = os.Getenv("MYSQL_USERNAME")
	mysqlPassword = os.Getenv("MYSQL_PASSWORD")
	mysqlDatabase = os.Getenv("MYSQL_DATABASE")
	mysqlTable = os.Getenv("MYSQL_TABLE")
	mysqlPort, _ = strconv.Atoi(os.Getenv("MYSQL_PORT"))
}
