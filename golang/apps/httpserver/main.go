package main

import (
	"context"
	"net/http"
	"time"

	_ "github.com/go-sql-driver/mysql"
	"github.com/utr1903/opentelemetry-playground/golang/apps/httpserver/config"
	"github.com/utr1903/opentelemetry-playground/golang/apps/httpserver/logger"
	"github.com/utr1903/opentelemetry-playground/golang/apps/httpserver/mysql"
	"github.com/utr1903/opentelemetry-playground/golang/apps/httpserver/otel"
	"github.com/utr1903/opentelemetry-playground/golang/apps/httpserver/server"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/contrib/instrumentation/runtime"
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

	// Start runtime metric collection
	err := runtime.Start(runtime.WithMinimumReadMemStatsInterval(time.Second))
	if err != nil {
		panic(err)
	}

	// Instantiate MySQL database
	db := mysql.New(
		mysql.WithServer(cfg.MysqlServer),
		mysql.WithPort(cfg.MysqlPort),
		mysql.WithUsername(cfg.MysqlUsername),
		mysql.WithPassword(cfg.MysqlPassword),
		mysql.WithDatabase(cfg.MysqlDatabase),
		mysql.WithTable(cfg.MysqlTable),
	)
	db.CreateDatabaseConnection()
	defer db.Instance.Close()

	// Instantiate server
	server := server.New(db)

	// Serve
	http.Handle("/api", otelhttp.NewHandler(http.HandlerFunc(server.Handler), "api"))
	http.ListenAndServe(":"+cfg.ServicePort, nil)
}
