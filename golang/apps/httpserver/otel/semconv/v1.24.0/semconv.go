package semconv

import (
	"net"
	"net/http"
	"strconv"
	"strings"

	"go.opentelemetry.io/otel/attribute"
)

const (
	HttpInterceptor   = "http_interceptor"
	HttpServerLatency = "http.server.request.duration"

	HttpMethodKey              = attribute.Key("http.request.method")
	HttpSchemeKey              = attribute.Key("url.scheme")
	HttpNetworkProtocolVersion = attribute.Key("network.protocol.version")
	HttpUserAgentOriginal      = attribute.Key("user_agent.original")
	HttpServerAddress          = attribute.Key("server.address")
	HttpServerPort             = attribute.Key("server.port")
	HttpClientAddress          = attribute.Key("client.address")
	HttpClientPort             = attribute.Key("client.port")
	HttpResponseStatusCode     = attribute.Key("http.response.status_code")
)

// https://github.com/open-telemetry/semantic-conventions/tree/v1.24.0/docs/http
var (
	HttpExplicitBucketBoundaries = []float64{
		0.005,
		0.010,
		0.025,
		0.050,
		0.075,
		0.100,
		0.250,
		0.500,
		0.750,
		1.000,
		2.500,
		5.000,
		7.500,
		10.000,
	}
)

func WithHttpServerAttributes(
	req *http.Request,
) []attribute.KeyValue {

	numAttributes := 4 // Method, scheme, proto & server address

	// Get user agent
	userAgent := req.UserAgent()
	if userAgent != "" {
		numAttributes++
	}

	// Get server address & serverPort
	serverAddress, serverPort := splitAddressAndPort(req.Host)
	if serverPort > 0 {
		numAttributes++
	}

	// Get client address & port
	clientAddress, clientPort := splitAddressAndPort(req.RemoteAddr)
	if clientPort > 0 {
		numAttributes++
	}

	// Create attributes array
	attrs := make([]attribute.KeyValue, 0, numAttributes)

	// Method, scheme & protocol version
	attrs = append(attrs, httpMethod(req.Method))
	attrs = append(attrs, httpScheme(req.TLS != nil))
	attrs = append(attrs, httpNetworkProtocolVersion(req.Proto))

	// User agent
	if userAgent != "" {
		attrs = append(attrs, HttpUserAgentOriginal.String(userAgent))
	}

	// Server address & port
	attrs = append(attrs, HttpServerAddress.String(serverAddress))
	if serverPort > 0 {
		attrs = append(attrs, HttpServerPort.Int(serverPort))
	}

	// Client address & port
	if clientAddress != "" {
		attrs = append(attrs, HttpClientAddress.String(clientAddress))
		if serverPort > 0 {
			attrs = append(attrs, HttpClientPort.Int(clientPort))
		}
	}

	return attrs
}

// Parses the HTTP method
func httpMethod(
	method string,
) attribute.KeyValue {
	if method == "" {
		return HttpMethodKey.String(http.MethodGet)
	}
	return HttpMethodKey.String(method)
}

// Parses the HTTP scheme
func httpScheme(
	isHttps bool,
) attribute.KeyValue {
	if isHttps {
		return HttpSchemeKey.String("https")
	}
	return HttpSchemeKey.String("http")
}

// Parses the HTTP flavor
func httpNetworkProtocolVersion(
	proto string,
) attribute.KeyValue {
	switch proto {
	case "HTTP/1.0":
		return HttpNetworkProtocolVersion.String("1.0")
	case "HTTP/1.1":
		return HttpNetworkProtocolVersion.String("1.1")
	case "HTTP/2":
		return HttpNetworkProtocolVersion.String("2.0")
	case "HTTP/3":
		return HttpNetworkProtocolVersion.String("3.0")
	default:
		return HttpNetworkProtocolVersion.String(proto)
	}
}

func splitAddressAndPort(
	hostAndport string,
) (
	host string,
	port int,
) {
	port = -1

	if strings.HasPrefix(hostAndport, "[") {
		addrEnd := strings.LastIndex(hostAndport, "]")
		if addrEnd < 0 {
			// Invalid hostport.
			return
		}
		if i := strings.LastIndex(hostAndport[addrEnd:], ":"); i < 0 {
			host = hostAndport[1:addrEnd]
			return
		}
	} else {
		if i := strings.LastIndex(hostAndport, ":"); i < 0 {
			host = hostAndport
			return
		}
	}

	host, pStr, err := net.SplitHostPort(hostAndport)
	if err != nil {
		return
	}

	p, err := strconv.ParseUint(pStr, 10, 16)
	if err != nil {
		return
	}

	return host, int(p)
}
