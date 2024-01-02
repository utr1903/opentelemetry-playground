package semconv

import (
	"net"
	"net/http"
	"strconv"
	"strings"

	"go.opentelemetry.io/otel/attribute"
)

// GENERAL
// https://github.com/open-telemetry/semantic-conventions/tree/v1.24.0/docs/database
const (
	OtelStatusCodeName        = "otel.status_code"
	OtelStatusCode            = attribute.Key(OtelStatusCodeName)
	OtelStatusDescriptionName = "otel.status_description"
	OtelStatusDescription     = attribute.Key(OtelStatusDescriptionName)

	ExceptionEscapedName = "exception.escaped"
	ExceptionEscaped     = attribute.Key(ExceptionEscapedName)

	NetworkProtocolVersionName = "network.protocol.version"
	NetworkProtocolVersion     = attribute.Key(NetworkProtocolVersionName)
	UserAgentOriginalName      = "user_agent.original"
	UserAgentOriginal          = attribute.Key(UserAgentOriginalName)
	ServerAddressName          = "server.address"
	ServerAddress              = attribute.Key(ServerAddressName)
	ServerPortName             = "server.port"
	ServerPort                 = attribute.Key(ServerPortName)
	ClientAddressName          = "client.address"
	ClientAddress              = attribute.Key(ClientAddressName)
	ClientPortName             = "client.port"
	ClientPort                 = attribute.Key(ClientPortName)
)

// HTTP
// https://github.com/open-telemetry/semantic-conventions/tree/v1.24.0/docs/http
const (
	HttpInterceptorName   = "http_interceptor"
	HttpServerLatencyName = "http.server.request.duration"

	HttpMethodKeyName = "http.request.method"
	HttpMethodKey     = attribute.Key(HttpMethodKeyName)
	HttpSchemeKeyName = "url.scheme"
	HttpSchemeKey     = attribute.Key(HttpSchemeKeyName)

	HttpResponseStatusCodeName = "http.response.status_code"
	HttpResponseStatusCode     = attribute.Key(HttpResponseStatusCodeName)
)

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
		attrs = append(attrs, UserAgentOriginal.String(userAgent))
	}

	// Server address & port
	attrs = append(attrs, ServerAddress.String(serverAddress))
	if serverPort > 0 {
		attrs = append(attrs, ServerPort.Int(serverPort))
	}

	// Client address & port
	if clientAddress != "" {
		attrs = append(attrs, ClientAddress.String(clientAddress))
		if serverPort > 0 {
			attrs = append(attrs, ClientPort.Int(clientPort))
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
		return NetworkProtocolVersion.String("1.0")
	case "HTTP/1.1":
		return NetworkProtocolVersion.String("1.1")
	case "HTTP/2":
		return NetworkProtocolVersion.String("2.0")
	case "HTTP/3":
		return NetworkProtocolVersion.String("3.0")
	default:
		return NetworkProtocolVersion.String(proto)
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

// DATABASE

const (
	DatabaseSystem      = attribute.Key("db.system")
	DatabaseUser        = attribute.Key("db.user")
	DatabaseDbName      = attribute.Key("db.name")
	DatabaseDbTable     = attribute.Key("db.table")
	DatabaseDbOperation = attribute.Key("db.operation")
	DatabaseDbStatement = attribute.Key("db.statement")
)
