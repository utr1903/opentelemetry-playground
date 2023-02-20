package main

import (
	"context"
	"log"
	"net/http"
	"time"

	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/exporters/stdout/stdoutmetric"
	"go.opentelemetry.io/otel/exporters/stdout/stdouttrace"
	"go.opentelemetry.io/otel/metric/global"
	"go.opentelemetry.io/otel/propagation"
	sdkmetric "go.opentelemetry.io/otel/sdk/metric"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.17.0"
	"go.opentelemetry.io/otel/trace"
)

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

	mp, err := newMetricProvider()
	if err != nil {
		log.Fatal(err)
	}
	// Cleanly shutdown and flush telemetry when the application exits.
	defer func(ctx context.Context) {
		// Do not make the application hang when it is shutdown.
		ctx, cancel := context.WithTimeout(ctx, time.Second*5)
		defer cancel()
		if err := mp.Shutdown(ctx); err != nil {
			log.Fatal(err)
		}
	}(ctx)

	http.Handle("/", otelhttp.NewHandler(http.HandlerFunc(helloHandler), "Hello"))
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

	// Create trace provider
	tp := sdktrace.NewTracerProvider(
		sdktrace.WithSampler(sdktrace.NeverSample()),
		sdktrace.WithBatcher(exp),
		sdktrace.WithResource(r),
	)

	// Set global trace provider
	otel.SetTracerProvider(tp)

	// Set trace propagator
	otel.SetTextMapPropagator(
		propagation.NewCompositeTextMapPropagator(
			propagation.TraceContext{},
			propagation.Baggage{},
		))

	return tp
}

func newMetricProvider() (*sdkmetric.MeterProvider, error) {
	exp, err := stdoutmetric.New()
	if err != nil {
		return nil, err
	}

	mp := sdkmetric.NewMeterProvider(sdkmetric.WithReader(sdkmetric.NewPeriodicReader(exp)))
	global.SetMeterProvider(mp)
	return mp, nil
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
