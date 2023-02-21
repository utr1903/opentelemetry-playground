package main

import (
	"context"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"strconv"
	"time"

	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/propagation"
)

var (
	httpserverListRequestInterval = os.Getenv("HTTP_SERVER_REQUEST_INTERVAL")
	httpserverEndpoint            = os.Getenv("HTTP_SERVER_ENDPOINT")
	httpserverPort                = os.Getenv("HTTP_SERVER_PORT")

	httpClient *http.Client
)

func simulateHttpServer() {

	interval, err := strconv.ParseInt(httpserverListRequestInterval, 10, 64)
	if err != nil {
		fmt.Println(err.Error())
		return
	}

	httpClient = &http.Client{
		Transport: otelhttp.NewTransport(http.DefaultTransport),
		Timeout:   time.Duration(30 * time.Second),
	}

	for {

		// Make request after each interval
		time.Sleep(time.Duration(interval) * time.Millisecond)

		// Make HTTP request
		makeHttpRequest()
	}
}

func makeHttpRequest() {

	// Get context
	ctx := context.Background()

	// Create request propagation
	carrier := propagation.HeaderCarrier(http.Header{})
	otel.GetTextMapPropagator().Inject(context.Background(), carrier)

	// Create HTTP request with trace context
	req, err := http.NewRequestWithContext(
		ctx, http.MethodGet,
		"http://"+httpserverEndpoint+":"+httpserverPort+"/list",
		nil,
	)
	if err != nil {
		fmt.Println(err.Error())
		return
	}

	// Add headers
	req.Header.Add("Content-Type", "application/json")

	// Perform HTTP request
	res, err := httpClient.Do(req)
	if err != nil {
		fmt.Println(err.Error())
		return
	}
	defer res.Body.Close()

	// Read HTTP response
	_, err = ioutil.ReadAll(res.Body)
	if err != nil {
		fmt.Println(err.Error())
		return
	}

	// Check if call was successful
	if res.StatusCode != http.StatusOK {
		fmt.Println(err.Error())
		return
	}
}
