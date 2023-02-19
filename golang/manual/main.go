package main

import (
	"context"
	"log"
	"net/http"
	"time"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/exporters/stdout/stdouttrace"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.17.0"
	"go.opentelemetry.io/otel/trace"
)

var tracer trace.Tracer

func main() {
	// Get context
	ctx := context.Background()

	// Create a new tracer provider with a batch span processor and the given exporter
	tp := newTraceProvider()

	// Cleanly shutdown and flush telemetry when the application exits.
	defer func(ctx context.Context) {
		// Do not make the application hang when it is shutdown.
		ctx, cancel := context.WithTimeout(ctx, time.Second*5)
		defer cancel()
		if err := tp.Shutdown(ctx); err != nil {
			log.Fatal(err)
		}
	}(ctx)

	// Set trace provider
	otel.SetTracerProvider(tp)

	// Set the tracer that can be used for this package
	tracer = otel.GetTracerProvider().Tracer("main")

	http.HandleFunc("/", httpHandler)
	http.ListenAndServe(":8080", nil)
}

func newTraceProvider() *sdktrace.TracerProvider {

	// Create exporter
	exp, err := stdouttrace.New(
		// Use human readable output.
		stdouttrace.WithPrettyPrint(),
	)
	if err != nil {
		panic(err)
	}

	// Ensure default SDK resources and the required service name are set
	r, err := resource.Merge(
		resource.Default(),
		resource.NewWithAttributes(
			semconv.SchemaURL,
			semconv.ServiceNameKey.String("ExampleService"),
		),
	)

	if err != nil {
		panic(err)
	}

	return sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(exp),
		sdktrace.WithResource(r),
	)
}

func httpHandler(w http.ResponseWriter, r *http.Request) {
	_, span := tracer.Start(r.Context(), "hello-span")
	defer span.End()

	span.SetAttributes(
		attribute.Bool("exampleBool", true),
		attribute.String("exampleString", "Hey!"),
	)

	w.WriteHeader(http.StatusOK)
	w.Write([]byte("Hello!"))
}
