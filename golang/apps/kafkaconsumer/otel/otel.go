package otel

import (
	"context"
	"io"
	"os"
	"strings"
	"time"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetricgrpc"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
	"go.opentelemetry.io/otel/exporters/stdout/stdoutmetric"
	"go.opentelemetry.io/otel/exporters/stdout/stdouttrace"
	"go.opentelemetry.io/otel/propagation"
	sdkmetric "go.opentelemetry.io/otel/sdk/metric"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.21.0"
)

var otelExporterType = os.Getenv("OTEL_EXPORTER_TYPE")

func NewTraceProvider(
	ctx context.Context,
) *sdktrace.TracerProvider {

	var exp sdktrace.SpanExporter
	var err error

	switch otelExporterType {
	case "otlp":
		exp, err = otlptracegrpc.New(ctx)
	default:
		exp, err = stdouttrace.New(
			// Use human readable output.
			stdouttrace.WithPrettyPrint(),
		)
	}

	if err != nil {
		panic(err)
	}

	// Ensure default SDK resources and the required service name are set
	r, err := resource.Merge(
		resource.Default(),
		resource.NewWithAttributes(
			semconv.SchemaURL,
		),
	)
	if err != nil {
		panic(err)
	}

	// Create trace provider
	tp := sdktrace.NewTracerProvider(
		sdktrace.WithSampler(sdktrace.AlwaysSample()),
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

func ShutdownTraceProvider(
	ctx context.Context,
	tp *sdktrace.TracerProvider,
) {
	// Do not make the application hang when it is shutdown.
	ctx, cancel := context.WithTimeout(ctx, time.Second*5)
	defer cancel()
	if err := tp.Shutdown(ctx); err != nil {
		panic(err)
	}
}

// Creates new meter provider
func NewMetricProvider(
	ctx context.Context,
) *sdkmetric.MeterProvider {
	var exp sdkmetric.Exporter
	var err error

	switch otelExporterType {
	case "otlp":
		exp, err = otlpmetricgrpc.New(ctx)
	default:
		isTesting := strings.HasSuffix(os.Args[0], ".test")
		var w io.Writer
		if isTesting {
			w = io.Discard
		} else {
			w = os.Stdout
		}
		exp, err = stdoutmetric.New(
			stdoutmetric.WithPrettyPrint(),
			stdoutmetric.WithWriter(w),
		)
	}

	if err != nil {
		panic(err)
	}

	mp := sdkmetric.NewMeterProvider(
		sdkmetric.WithReader(sdkmetric.NewPeriodicReader(exp)))
	otel.SetMeterProvider(mp)
	return mp
}

// Shuts down meter provider
func ShutdownMetricProvider(
	ctx context.Context,
	mp *sdkmetric.MeterProvider,
) {
	// Do not make the application hang when it is shutdown.
	ctx, cancel := context.WithTimeout(ctx, time.Second*5)
	defer cancel()
	if err := mp.Shutdown(ctx); err != nil {
		panic(err)
	}
}
