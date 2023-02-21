package main

import (
	"context"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"strconv"
	"time"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/trace"
)

var (
	httpserverListRequestInterval = os.Getenv("HTTP_SERVER_LIST_REQUEST_INTERVAL")
	httpserverEndpoint            = os.Getenv("HTTP_SERVER_ENDPOINT")
	httpserverPort                = os.Getenv("HTTP_SERVER_PORT")
)

func simulateHttpServer() {

	interval, err := strconv.ParseInt(httpserverListRequestInterval, 10, 64)
	if err != nil {
		fmt.Println(err.Error())
		return
	}

	client := &http.Client{
		Timeout: time.Duration(30 * time.Second),
	}

	for {

		// Make request after each interval
		time.Sleep(time.Duration(interval) * time.Second)

		// Create request
		req, err := http.NewRequest(
			http.MethodPost,
			httpserverEndpoint+"/list",
			nil,
		)
		if err != nil {
			fmt.Println(err.Error())
			return
		}

		// Create span
		span := createHttpClientSpan()
		defer (*span).End()

		// Add headers
		req.Header.Add("Content-Type", "application/json")

		// Perform HTTP request
		res, err := client.Do(req)
		if err != nil {
			fmt.Println(err.Error())
			updateHttpClientSpan(span, http.StatusInternalServerError)
			return
		}
		defer res.Body.Close()

		// Read HTTP response
		_, err = ioutil.ReadAll(res.Body)
		if err != nil {
			fmt.Println(err.Error())
			updateHttpClientSpan(span, http.StatusInternalServerError)
			return
		}

		// Check if call was successful
		if res.StatusCode != http.StatusOK {
			fmt.Println(err.Error())
			updateHttpClientSpan(span, res.StatusCode)
			return
		}

		updateHttpClientSpan(span, res.StatusCode)
	}
}

func createHttpClientSpan() *trace.Span {
	// Create span
	_, span := otel.GetTracerProvider().Tracer(appName).Start(context.Background(), "/list")

	// Set additional span attributes
	span.SetAttributes(
		attribute.String("http.method", "GET"),
		attribute.String("http.target", "/list"),
		attribute.String("net.host.name", httpserverEndpoint),
		attribute.String("net.peer.port", httpserverPort),
		attribute.String("http.scheme", "http"),
		attribute.String("http.route", "/list"),
	)

	return &span
}

func updateHttpClientSpan(
	span *trace.Span,
	statusCode int,
) {

	// Set status code
	(*span).SetAttributes(
		attribute.Int("http.status_code", statusCode),
	)
}
