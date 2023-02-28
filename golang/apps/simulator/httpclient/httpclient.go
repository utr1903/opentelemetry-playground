package httpclient

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
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/metric/global"
	"go.opentelemetry.io/otel/metric/instrument"
	"go.opentelemetry.io/otel/propagation"
	semconv "go.opentelemetry.io/otel/semconv/v1.17.0"
)

var (
	appName = os.Getenv("APP_NAME")

	httpserverRequestInterval = os.Getenv("HTTP_SERVER_REQUEST_INTERVAL")
	httpserverEndpoint        = os.Getenv("HTTP_SERVER_ENDPOINT")
	httpserverPort            = os.Getenv("HTTP_SERVER_PORT")

	httpClient *http.Client

	httpClientDuration instrument.Float64Histogram
)

func SimulateHttpServer() {

	interval, err := strconv.ParseInt(httpserverRequestInterval, 10, 64)
	if err != nil {
		fmt.Println(err.Error())
		return
	}

	httpClient = &http.Client{
		Transport: otelhttp.NewTransport(http.DefaultTransport),
		Timeout:   time.Duration(30 * time.Second),
	}

	httpClientDuration, err = global.MeterProvider().
		Meter(appName).
		Float64Histogram("http.client.duration")
	if err != nil {
		fmt.Println(err.Error())
		return
	}

	// LIST simulator
	go func() {
		for {

			// Make request after each interval
			time.Sleep(time.Duration(interval) * time.Millisecond)

			// List
			httpList()
		}
	}()

	// DELETE simulator
	go func() {
		for {

			// Make request after each interval * 4
			time.Sleep(4 * time.Duration(interval) * time.Millisecond)

			// Delete
			httpDelete()
		}
	}()
}

func httpList() {

	// Start timer
	requestStartTime := time.Now()

	// Get context
	ctx := context.Background()

	// Create request propagation
	carrier := propagation.HeaderCarrier(http.Header{})
	otel.GetTextMapPropagator().Inject(ctx, carrier)

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

	elapsedTime := float64(time.Since(requestStartTime)) / float64(time.Millisecond)

	httpserverPortAsInt, _ := strconv.Atoi(httpserverPort)
	attributes := attribute.NewSet(
		semconv.HTTPSchemeHTTP,
		semconv.HTTPFlavorKey.String(fmt.Sprintf("1.%d", req.ProtoMinor)),
		semconv.HTTPMethod("GET"),
		semconv.NetPeerName(httpserverEndpoint),
		semconv.NetPeerPort(httpserverPortAsInt),
		semconv.HTTPStatusCode(res.StatusCode),
	)

	httpClientDuration.Record(ctx, elapsedTime, attributes.ToSlice()...)
}

func httpDelete() {

	// Start timer
	requestStartTime := time.Now()

	// Get context
	ctx := context.Background()

	// Create request propagation
	carrier := propagation.HeaderCarrier(http.Header{})
	otel.GetTextMapPropagator().Inject(ctx, carrier)

	// Create HTTP request with trace context
	req, err := http.NewRequestWithContext(
		ctx, http.MethodDelete,
		"http://"+httpserverEndpoint+":"+httpserverPort+"/delete",
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

	elapsedTime := float64(time.Since(requestStartTime)) / float64(time.Millisecond)

	httpserverPortAsInt, _ := strconv.Atoi(httpserverPort)
	attributes := attribute.NewSet(
		semconv.HTTPSchemeHTTP,
		semconv.HTTPFlavorKey.String(fmt.Sprintf("1.%d", req.ProtoMinor)),
		semconv.HTTPMethod("DELETE"),
		semconv.NetPeerName(httpserverEndpoint),
		semconv.NetPeerPort(httpserverPortAsInt),
		semconv.HTTPStatusCode(res.StatusCode),
	)

	httpClientDuration.Record(ctx, elapsedTime, attributes.ToSlice()...)
}
