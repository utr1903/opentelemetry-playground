package otel

import (
	"net/http"
	"time"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/metric"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/trace"
)

type httpMiddleware struct {
	spanName string

	tracer     trace.Tracer
	meter      metric.Meter
	propagator propagation.TextMapPropagator

	latency metric.Float64Histogram
}

func NewHttpHandler(handler http.Handler, spanName string) http.Handler {
	return NewOtelHttpInterceptor(spanName)(handler)
}

func NewOtelHttpInterceptor(
	spanName string,
	// opts ...Opts,
) func(http.Handler) http.Handler {

	m := &httpMiddleware{
		spanName: spanName,
	}

	// Instantiate trace provider
	m.tracer = otel.GetTracerProvider().Tracer(HttpInterceptor)

	// Instantiate meter provider
	m.meter = otel.GetMeterProvider().Meter(HttpInterceptor)

	// Instantiate propagator
	m.propagator = otel.GetTextMapPropagator()

	// Create HTTP server latency histogram
	latency, err := m.meter.Float64Histogram(
		HttpServerLatency,
		metric.WithUnit("ms"),
		metric.WithDescription("Measures the duration of HTTP request handling"),
		metric.WithExplicitBucketBoundaries(HttpExplicitBucketBoundaries...),
	)
	if err != nil {
		panic(err)
	}
	m.latency = latency

	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			m.serve(w, r, next)
		})
	}
}

func (m *httpMiddleware) serve(
	w http.ResponseWriter,
	r *http.Request,
	next http.Handler,
) {
	requestStartTime := time.Now()

	ctx := m.propagator.Extract(r.Context(), propagation.HeaderCarrier(r.Header))

	// Parse HTTP attributes from the request for both span and metrics
	spanAttrs, metricAttrs := GetSpanAndMetricServerAttributes(r)

	// Create span options
	spanOpts := []trace.SpanStartOption{
		trace.WithSpanKind(trace.SpanKindServer),
		trace.WithAttributes(spanAttrs...),
	}

	// Start HTTP server span
	ctx, span := m.tracer.Start(ctx, m.spanName, spanOpts...)
	defer span.End()

	// Instantiate the wrapper writer to get the HTTP status code
	rww := &respWriterWrapper{
		ResponseWriter: w,
		statusCode:     http.StatusOK,
	}

	// Run the next
	next.ServeHTTP(rww, r.WithContext(ctx))

	// Add HTTP status code to the attributes
	span.SetAttributes(HttpResponseStatusCode.Int(rww.statusCode))
	metricAttrs = append(metricAttrs, HttpResponseStatusCode.Int(rww.statusCode))

	// Create metric options
	metricOpts := metric.WithAttributes(metricAttrs...)

	// Record server latency
	elapsedTime := float64(time.Since(requestStartTime)) / float64(time.Millisecond)
	m.latency.Record(ctx, elapsedTime, metricOpts)
}

func GetSpanAndMetricServerAttributes(
	r *http.Request,
) (
	[]attribute.KeyValue,
	[]attribute.KeyValue,
) {
	spanAttrs := WithHttpServerAttributes(r)
	metricAttrs := make([]attribute.KeyValue, len(spanAttrs))

	copy(metricAttrs, spanAttrs)
	return spanAttrs, metricAttrs
}

type respWriterWrapper struct {
	http.ResponseWriter
	statusCode int
}

func (w *respWriterWrapper) Header() http.Header {
	return w.ResponseWriter.Header()
}

func (w *respWriterWrapper) Write(
	p []byte,
) (
	int,
	error,
) {
	return w.ResponseWriter.Write(p)
}

func (w *respWriterWrapper) WriteHeader(
	statusCode int,
) {
	w.statusCode = statusCode
	w.ResponseWriter.WriteHeader(statusCode)
}
