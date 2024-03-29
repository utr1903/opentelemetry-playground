package httpclient

import (
	"context"
	"errors"
	"fmt"
	"io"
	"math/rand"
	"net/http"
	"strconv"
	"time"

	"github.com/sirupsen/logrus"
	"github.com/utr1903/opentelemetry-playground/golang/apps/simulator/logger"

	otelhttp "github.com/utr1903/opentelemetry-playground/golang/apps/simulator/otel/http"
)

var (
	randomErrors = map[int]string{
		1: "databaseConnectionError",
		2: "tableDoesNotExistError",
		3: "preprocessingException",
		4: "schemaNotFoundInCacheWarning",
	}
)

type Opts struct {
	ServiceName     string
	RequestInterval int64
	ServerEndpoint  string
	ServerPort      string
}

type OptFunc func(*Opts)

func defaultOpts() *Opts {
	return &Opts{
		RequestInterval: 2000,
		ServerEndpoint:  "httpserver",
		ServerPort:      "8080",
	}
}

type HttpServerSimulator struct {
	Opts       *Opts
	Client     *otelhttp.HttpClient
	Randomizer *rand.Rand
}

// Create an HTTP server simulator instance
func New(
	optFuncs ...OptFunc,
) *HttpServerSimulator {

	// Instantiate options with default values
	opts := defaultOpts()

	// Apply external options
	for _, f := range optFuncs {
		f(opts)
	}

	httpClient := otelhttp.New(
		otelhttp.WithTimeout(time.Duration(10 * time.Second)),
	)

	randomizer := rand.New(rand.NewSource(time.Now().UnixNano()))

	return &HttpServerSimulator{
		Opts:       opts,
		Client:     httpClient,
		Randomizer: randomizer,
	}
}

// Configure service name of simulator
func WithServiceName(serviceName string) OptFunc {
	return func(opts *Opts) {
		opts.ServiceName = serviceName
	}
}

// Configure HTTP server request interval
func WithRequestInterval(requestInterval string) OptFunc {
	interval, err := strconv.ParseInt(requestInterval, 10, 64)
	if err != nil {
		panic(err.Error())
	}
	return func(opts *Opts) {
		opts.RequestInterval = interval
	}
}

// Configure HTTP server endpoint
func WithServerEndpoint(serverEndpoint string) OptFunc {
	return func(opts *Opts) {
		opts.ServerEndpoint = serverEndpoint
	}
}

// Configure HTTP server port
func WithServerPort(serverPort string) OptFunc {
	return func(opts *Opts) {
		opts.ServerPort = serverPort
	}
}

// Starts simulating HTTP server
func (h *HttpServerSimulator) Simulate(
	users []string,
) {

	// LIST simulator
	go func() {
		for {

			// Make request after each interval
			time.Sleep(time.Duration(h.Opts.RequestInterval) * time.Millisecond)

			// List
			h.performHttpCall(
				context.Background(),
				http.MethodGet,
				users[h.Randomizer.Intn(len(users))],
				h.causeRandomError(),
			)
		}
	}()

	// DELETE simulator
	go func() {
		for {

			// Make request after each interval * 4
			time.Sleep(4 * time.Duration(h.Opts.RequestInterval) * time.Millisecond)

			// Delete
			h.performHttpCall(
				context.Background(),
				http.MethodDelete,
				users[h.Randomizer.Intn(len(users))],
				h.causeRandomError(),
			)
		}
	}()
}

// Puts necessary request parameters into a map in order to
// cause a random error
func (h *HttpServerSimulator) causeRandomError() map[string]string {

	randomNum := h.Randomizer.Intn(15)
	reqParams := map[string]string{}

	if randomNum == 1 || randomNum == 2 || randomNum == 3 || randomNum == 4 {
		reqParams[randomErrors[randomNum]] = "true"
	}

	return reqParams
}

// Performs the HTTP call to the HTTP server
func (h *HttpServerSimulator) performHttpCall(
	ctx context.Context,
	httpMethod string,
	user string,
	reqParams map[string]string,
) error {

	logger.Log(logrus.InfoLevel, ctx, user, "Preparing HTTP call...")

	// Create HTTP request with trace context
	req, err := http.NewRequest(
		httpMethod,
		"http://"+h.Opts.ServerEndpoint+":"+h.Opts.ServerPort+"/api",
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

	// Perform HTTP request
	logger.Log(logrus.InfoLevel, ctx, user, "Performing HTTP call")
	res, err := h.Client.Do(ctx, req, fmt.Sprintf("HTTP %s", req.Method))
	if err != nil {
		logger.Log(logrus.ErrorLevel, ctx, user, err.Error())
		return err
	}
	defer res.Body.Close()

	// Read HTTP response
	resBody, err := io.ReadAll(res.Body)
	if err != nil {
		logger.Log(logrus.ErrorLevel, ctx, user, err.Error())
		return err
	}

	// Check status code
	if res.StatusCode != http.StatusOK {
		logger.Log(logrus.ErrorLevel, ctx, user, string(resBody))
		return errors.New("call to donald returned not ok status")
	}

	logger.Log(logrus.InfoLevel, ctx, user, "HTTP call is performed successfully.")
	return nil
}
