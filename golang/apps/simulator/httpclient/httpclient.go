package httpclient

import (
	"context"
	"errors"
	"io/ioutil"
	"math/rand"
	"net/http"
	"strconv"
	"time"

	"github.com/sirupsen/logrus"
	"github.com/utr1903/opentelemetry-playground/golang/apps/simulator/config"
	"github.com/utr1903/opentelemetry-playground/golang/apps/simulator/logger"

	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/metric"
	"go.opentelemetry.io/otel/propagation"
	semconv "go.opentelemetry.io/otel/semconv/v1.17.0"
)

var (
	serviceName string

	httpserverRequestInterval int64
	httpserverEndpoint        string
	httpserverPort            string

	randomizer *rand.Rand

	httpClient *http.Client

	httpClientDuration metric.Float64Histogram

	randomErrors = map[int]string{
		1: "databaseConnectionError",
		2: "tableDoesNotExistError",
		3: "preprocessingException",
		4: "schemaNotFoundInCacheWarning",
	}
)

// Starts simulating HTTP server
func SimulateHttpServer(
	cfg *config.SimulatorConfig,
) {

	// Initialize simulator
	initSimulator(cfg)

	// LIST simulator
	go func() {
		for {

			// Make request after each interval
			time.Sleep(time.Duration(httpserverRequestInterval) * time.Millisecond)

			// List
			performHttpCall(
				context.Background(),
				http.MethodGet,
				cfg.Users[randomizer.Intn(len(cfg.Users))],
				causeRandomError(),
			)
		}
	}()

	// DELETE simulator
	go func() {
		for {

			// Make request after each interval * 4
			time.Sleep(4 * time.Duration(httpserverRequestInterval) * time.Millisecond)

			// Delete
			performHttpCall(
				context.Background(),
				http.MethodDelete,
				cfg.Users[randomizer.Intn(len(cfg.Users))],
				causeRandomError(),
			)
		}
	}()
}

// Initializes the HTTP server simulator by setting the necessary variables
func initSimulator(
	cfg *config.SimulatorConfig,
) {
	// Set HTTP server related parameters
	setHttpServerParameters(cfg)

	// Create HTTP client
	createHttpClient()

	// Create histogram metric meter for HTTP client duration
	createHttpClientDurationMetric()

	// Initialize random number generator
	randomizer = rand.New(rand.NewSource(time.Now().UnixNano()))
}

// Sets HTTP server related parameters
func setHttpServerParameters(
	cfg *config.SimulatorConfig,
) {
	serviceName = cfg.ServiceName

	interval, err := strconv.ParseInt(cfg.HttpserverRequestInterval, 10, 64)
	if err != nil {
		panic(err.Error())
	}

	httpserverRequestInterval = interval

	httpserverEndpoint = cfg.HttpserverEndpoint
	httpserverPort = cfg.HttpserverPort
}

// Creates a fresh HTTP client
func createHttpClient() {
	httpClient = &http.Client{
		Transport: otelhttp.NewTransport(http.DefaultTransport),
		Timeout:   time.Duration(30 * time.Second),
	}
}

// Creates a histogram metric meter for HTTP client duration
func createHttpClientDurationMetric() {
	meter, err := otel.GetMeterProvider().
		Meter(serviceName).
		Float64Histogram("http.client.duration")
	if err != nil {
		panic(err.Error())
	}

	httpClientDuration = meter
}

// Puts necessary request parameters into a map in order to
// cause a random error
func causeRandomError() map[string]string {

	randomNum := randomizer.Intn(15)
	reqParams := map[string]string{}

	if randomNum == 1 || randomNum == 2 || randomNum == 3 || randomNum == 4 {
		reqParams[randomErrors[randomNum]] = "true"
	}

	return reqParams
}

// Performs the HTTP call to the HTTP server
func performHttpCall(
	ctx context.Context,
	httpMethod string,
	user string,
	reqParams map[string]string,
) error {

	logger.Log(logrus.InfoLevel, ctx, user, "Preparing HTTP call...")

	// Create request propagation
	carrier := propagation.HeaderCarrier(http.Header{})
	otel.GetTextMapPropagator().Inject(ctx, carrier)

	// Create HTTP request with trace context
	req, err := http.NewRequestWithContext(
		ctx, httpMethod,
		"http://"+httpserverEndpoint+":"+httpserverPort+"/api",
		nil,
	)
	if err != nil {
		logger.Log(logrus.ErrorLevel, ctx, user, err.Error())
		return err
	}

	// Add headers
	req.Header.Add("Content-Type", "application/json")
	req.Header.Add("X-User-ID", user)

	// Add request params
	qps := req.URL.Query()
	for k, v := range reqParams {
		qps.Add(k, v)
	}
	if len(qps) > 0 {
		req.URL.RawQuery = qps.Encode()
		logger.Log(logrus.InfoLevel, ctx, user, "Request params->"+req.URL.RawQuery)
	}
	logger.Log(logrus.InfoLevel, ctx, user, "HTTP call is prepared.")

	// Start timer
	requestStartTime := time.Now()

	// Perform HTTP request
	logger.Log(logrus.InfoLevel, ctx, user, "Performing HTTP call")
	res, err := httpClient.Do(req)
	if err != nil {
		logger.Log(logrus.ErrorLevel, ctx, user, err.Error())
		recordClientDuration(ctx, httpMethod, http.StatusInternalServerError, requestStartTime)
		return err
	}
	defer res.Body.Close()

	// Read HTTP response
	resBody, err := ioutil.ReadAll(res.Body)
	if err != nil {
		logger.Log(logrus.ErrorLevel, ctx, user, err.Error())
		recordClientDuration(ctx, httpMethod, res.StatusCode, requestStartTime)
		return err
	}

	// Check status code
	if res.StatusCode != http.StatusOK {
		logger.Log(logrus.ErrorLevel, ctx, user, string(resBody))
		recordClientDuration(ctx, httpMethod, res.StatusCode, requestStartTime)
		return errors.New("call to donald returned not ok status")
	}

	recordClientDuration(ctx, httpMethod, res.StatusCode, requestStartTime)
	logger.Log(logrus.InfoLevel, ctx, user, "HTTP call is performed successfully.")
	return nil
}

// Records HTTP client duration
func recordClientDuration(
	ctx context.Context,
	httpMethod string,
	statusCode int,
	startTime time.Time,
) {
	elapsedTime := float64(time.Since(startTime)) / float64(time.Millisecond)
	httpserverPortAsInt, _ := strconv.Atoi(httpserverPort)
	attributes := attribute.NewSet(
		semconv.HTTPSchemeHTTP,
		semconv.HTTPFlavorHTTP11,
		semconv.HTTPMethod(httpMethod),
		semconv.NetPeerName(httpserverEndpoint),
		semconv.NetPeerPort(httpserverPortAsInt),
		semconv.HTTPStatusCode(statusCode),
	)

	httpClientDuration.Record(ctx, elapsedTime, metric.WithAttributes(attributes.ToSlice()...))
}
