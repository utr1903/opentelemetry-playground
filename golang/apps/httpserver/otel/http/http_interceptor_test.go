package http

import (
	"context"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strconv"
	"testing"

	semconv "github.com/utr1903/opentelemetry-playground/golang/apps/httpserver/otel/semconv/v1.24.0"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/trace"
)

func Test_CommonAttributesCreatedSuccessfully(t *testing.T) {
	httpMethod := http.MethodPost
	host := "localhost"
	port := "8080"
	userAgent := "test_agent"

	// Set headers
	headers := http.Header{}
	headers.Set("User-Agent", userAgent)

	req, err := http.NewRequest(
		httpMethod,
		fmt.Sprintf("http://%s:%s/", host, port),
		nil,
	)
	if err != nil {
		t.Fatal(err)
	}
	req.Header = headers

	m := &httpMiddleware{}
	spanAttrs, metricAttrs := m.getSpanAndMetricServerAttributes(req)

	// Check lengths of span and metric attributes
	if len(spanAttrs) != len(metricAttrs) {
		t.Error("Number of span and metric attributes are not the same!")
	}

	for i, spanAttr := range spanAttrs {
		metricAttr := metricAttrs[i]

		// Check span and metric attribute key and value
		if spanAttr != metricAttr {
			t.Error("Span and metric attribute are not the same!")
		}

		if spanAttr.Key == semconv.NetworkProtocolVersionName &&
			spanAttr.Value.AsString() != "1.1" {
			t.Errorf("%s is set incorrectly!", semconv.NetworkProtocolVersionName)
		}

		if spanAttr.Key == semconv.HttpMethodKeyName &&
			spanAttr.Value.AsString() != httpMethod {
			t.Errorf("%s is set incorrectly!", semconv.HttpMethodKeyName)
		}

		if spanAttr.Key == semconv.ServerAddressName &&
			spanAttr.Value.AsString() != host {
			t.Errorf("%s is set incorrectly!", semconv.ServerAddressName)
		}

		if spanAttr.Key == semconv.ServerPortName {
			portAsInt, _ := strconv.ParseInt(port, 10, 64)
			if spanAttr.Value.AsInt64() != portAsInt {
				t.Errorf("%s is set incorrectly!", semconv.ServerPortName)
			}
		}

		if spanAttr.Key == semconv.UserAgentOriginalName &&
			spanAttr.Value.AsString() != userAgent {
			t.Errorf("%s is set incorrectly!", semconv.UserAgentOriginalName)
		}
	}
}

func Test_ExtractTraceContextCorrectly(t *testing.T) {
	prop := propagation.TraceContext{}

	// Generate a new context out of a new span
	ctxMock := context.Background()
	spanCtx := trace.NewSpanContext(
		trace.SpanContextConfig{
			TraceID: trace.TraceID{0x01},
			SpanID:  trace.SpanID{0x01},
		})
	ctxMock = trace.ContextWithRemoteSpanContext(ctxMock, spanCtx)

	// Inject the trace context into the headers
	headers := http.Header{}
	prop.Inject(ctxMock, propagation.HeaderCarrier(headers))

	// Createa a mock HTTP server
	mockServer := httptest.NewServer(
		NewHandler(http.HandlerFunc(
			func(w http.ResponseWriter, r *http.Request) {

				// Get context of the request -> This should have the mock context
				ctx := prop.Extract(r.Context(), propagation.HeaderCarrier(r.Header))
				span := trace.SpanContextFromContext(ctx)

				// Check whether the span ID is the same as what is defined in the mock context
				if span.SpanID() != spanCtx.SpanID() {
					t.Fatalf("testing remote SpanID: got %s, expected %s", span.SpanID(), spanCtx.SpanID())
				}
			}), "test"))
	defer mockServer.Close()

	// Create a request with mock context
	r, err := http.NewRequestWithContext(
		ctxMock,
		http.MethodGet,
		mockServer.URL,
		nil,
	)
	if err != nil {
		t.Fatal(err)
	}

	// Add headers to the request
	r.Header = headers

	// Perform HTTP request
	c := http.Client{}
	_, err = c.Do(r)
	if err != nil {
		t.Fatal(err)
	}
}
