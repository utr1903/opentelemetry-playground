package http

import (
	"context"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strconv"
	"testing"
	"time"

	"github.com/utr1903/opentelemetry-playground/golang/apps/simulator/otel"
	semconv "github.com/utr1903/opentelemetry-playground/golang/apps/simulator/otel/semconv/v1.24.0"
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

	c := &HttpClient{}
	spanAttrs, metricAttrs := c.getSpanAndMetricServerAttributes(req)

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

func Test_InjectTraceContextCorrectly(t *testing.T) {

	mockCtx := context.Background()

	// Create tracer provider
	tp := otel.NewTraceProvider(mockCtx)
	defer otel.ShutdownTraceProvider(mockCtx, tp)

	// prop := propagation.TraceContext{}

	httpMethod := http.MethodPost
	httpStatusCode := http.StatusAccepted

	// Createa a mock HTTP server
	mockServer := httptest.NewServer(
		http.HandlerFunc(
			func(w http.ResponseWriter, r *http.Request) {
				w.WriteHeader(httpStatusCode)
				w.Write([]byte("Test"))
			}))
	defer mockServer.Close()

	httpClient := New(
		WithTimeout(time.Duration(10 * time.Second)),
	)

	req, err := http.NewRequest(
		httpMethod,
		mockServer.URL,
		nil,
	)
	if err != nil {
		t.Fatal(err)
	}

	res, _ := httpClient.Do(mockCtx, req, fmt.Sprintf("HTTP %s", req.Method))
	if res.StatusCode != httpStatusCode {
		t.Error("HTTP status code is not the as given.")
	}

	traceparent := req.Header.Get("Traceparent")
	if len(traceparent) == 0 {
		t.Error("Span context is not set to the outgoing request.")
	}
}
