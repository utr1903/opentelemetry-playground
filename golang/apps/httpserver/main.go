package main

import (
	"context"
	"net/http"

	_ "github.com/go-sql-driver/mysql"
	"github.com/utr1903/opentelemetry-playground/golang/apps/httpserver/config"
	"github.com/utr1903/opentelemetry-playground/golang/apps/httpserver/logger"
	"github.com/utr1903/opentelemetry-playground/golang/apps/httpserver/mysql"
	"github.com/utr1903/opentelemetry-playground/golang/apps/httpserver/otel"
	"github.com/utr1903/opentelemetry-playground/golang/apps/httpserver/server"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
)

func main() {

	// Create new config
	config.NewConfig()
	cfg := config.GetConfig()

	// Initialize logger
	logger.NewLogger(cfg)

	// Get context
	ctx := context.Background()

	// Create tracer provider
	tp := otel.NewTraceProvider(ctx)
	defer otel.ShutdownTraceProvider(ctx, tp)

	// Create metric provider
	mp := otel.NewMetricProvider(ctx)
	defer otel.ShutdownMetricProvider(ctx, mp)

	// Connect to MySQL
	mysql.CreateDatabaseConnection(cfg)
	defer mysql.Get().Close()

	// Serve
	http.Handle("/api", otelhttp.NewHandler(http.HandlerFunc(server.Handler), "api"))
	http.ListenAndServe(":"+cfg.ServicePort, nil)
}
