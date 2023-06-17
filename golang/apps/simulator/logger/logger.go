package logger

import (
	"context"

	"github.com/sirupsen/logrus"
	"github.com/utr1903/opentelemetry-playground/golang/apps/simulator/config"
	"go.opentelemetry.io/otel/trace"
)

var serviceName string

// Creates new logger
func NewLogger(cfg *config.SimulatorConfig) {

	// Set service name
	serviceName = cfg.ServiceName

	// Set log level
	logrus.SetLevel(logrus.InfoLevel)

	// Set formatter
	logrus.SetFormatter(&logrus.JSONFormatter{})
}

// Logs a message with trace context
func Log(
	lvl logrus.Level,
	ctx context.Context,
	user string,
	msg string,
) {
	span := trace.SpanFromContext(ctx)
	if span.SpanContext().HasTraceID() && span.SpanContext().HasSpanID() {
		logrus.WithFields(logrus.Fields{
			"service.name": serviceName,
			"trace.id":     span.SpanContext().TraceID().String(),
			"span.id":      span.SpanContext().SpanID().String(),
		}).Log(lvl, "user:"+user+"|message:"+msg)
	} else {
		logrus.WithFields(logrus.Fields{}).Log(lvl, "user:"+user+"|message:"+msg)
	}
}
