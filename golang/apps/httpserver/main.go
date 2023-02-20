package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"

	_ "github.com/go-sql-driver/mysql"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/trace"
)

var (
	appPort = os.Getenv("APP_PORT")

	mysqlServer   = os.Getenv("MYSQL_SERVER")
	mysqlUsername = os.Getenv("MYSQL_USERNAME")
	mysqlPassword = os.Getenv("MYSQL_PASSWORD")
	mysqlDatabase = os.Getenv("MYSQL_DATABASE")
	mysqlTable    = os.Getenv("MYSQL_TABLE")
	mysqlPort     = os.Getenv("MYSQL_PORT")

	db *sql.DB
)

func main() {
	// Get context
	ctx := context.Background()

	// Create tracer provider
	tp := newTraceProvider()
	defer shutdownTraceProvider(ctx, tp)

	// Create metric provider
	mp := newMetricProvider()
	defer shutdownMetricProvider(ctx, mp)

	// Connect to MySQL
	db = createDatabaseConnection()
	defer db.Close()

	// Serve
	http.Handle("/", otelhttp.NewHandler(http.HandlerFunc(helloHandler), "hello"))
	http.Handle("/list", otelhttp.NewHandler(http.HandlerFunc(listHandler), "list"))
	http.ListenAndServe(":"+appPort, nil)
}

func helloHandler(w http.ResponseWriter, r *http.Request) {
	// Get current span
	span := trace.SpanFromContext(r.Context())
	defer span.End()

	// Set additional span attributes
	span.SetAttributes(
		attribute.Bool("exampleBool", true),
		attribute.String("exampleString", "Hey!"),
	)

	w.WriteHeader(http.StatusOK)
	w.Write([]byte("Hello!"))
}

func listHandler(w http.ResponseWriter, r *http.Request) {
	// Get current span
	span := trace.SpanFromContext(r.Context())
	defer span.End()

	// Set additional span attributes
	span.SetAttributes(
		attribute.String("handler", "list"),
	)

	// Perform a query
	rows, err := db.Query("SELECT name FROM " + mysqlTable)
	if err != nil {
		log.Fatal(err)
	}
	defer rows.Close()

	// Iterate over the results
	names := make([]string, 0, 10)
	for rows.Next() {
		var name string
		err = rows.Scan(&name)
		if err != nil {
			fmt.Println(err)
			w.WriteHeader(http.StatusInternalServerError)
			w.Write([]byte(err.Error()))
			break
		}
		names = append(names, name)
	}

	resBody, err := json.Marshal(names)
	if err != nil {
		fmt.Println(err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(err.Error()))
	}

	w.WriteHeader(http.StatusOK)
	w.Write(resBody)
}
