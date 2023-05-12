package main

import (
	"context"

	"github.com/sirupsen/logrus"
	"go.opentelemetry.io/otel/trace"
)

func initLogger() {

	// Set log level
	logrus.SetLevel(logrus.InfoLevel)

	// Set formatter
	logrus.SetFormatter(&logrus.JSONFormatter{})
}

func log(
	lvl logrus.Level,
	ctx context.Context,
	user string,
	msg string,
) {
	span := trace.SpanFromContext(ctx)
	if span.SpanContext().HasTraceID() && span.SpanContext().HasSpanID() {
		logrus.WithFields(logrus.Fields{
			"service.name": appName,
			"trace.id":     span.SpanContext().TraceID().String(),
			"span.id":      span.SpanContext().SpanID().String(),
		}).Log(lvl, "user:"+user+"|message:"+msg)
	} else {
		logrus.WithFields(logrus.Fields{}).Log(lvl, "user:"+user+"|message:"+msg)
	}
}
