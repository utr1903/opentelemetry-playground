package kafka

import (
	"context"
	"fmt"

	"github.com/IBM/sarama"
	semconv "github.com/utr1903/opentelemetry-playground/golang/apps/simulator/otel/semconv/v1.24.0"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/metric"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/trace"
)

type KafkaProducer struct {
	producer sarama.AsyncProducer

	tracer     trace.Tracer
	meter      metric.Meter
	propagator propagation.TextMapPropagator

	latency metric.Float64Histogram
}

func New(
	producer sarama.AsyncProducer,
) *KafkaProducer {

	// Instantiate trace provider
	tracer := otel.GetTracerProvider().Tracer(semconv.KafkaProducerName)

	// Instantiate meter provider
	meter := otel.GetMeterProvider().Meter(semconv.KafkaProducerName)

	// Instantiate propagator
	propagator := otel.GetTextMapPropagator()

	// Create HTTP client latency histogram
	latency, err := meter.Float64Histogram(
		semconv.MessagingProducerLatencyName,
		metric.WithUnit("ms"),
		metric.WithDescription("Measures the duration of publish operation"),
		metric.WithExplicitBucketBoundaries(semconv.MessagingExplicitBucketBoundaries...),
	)
	if err != nil {
		panic(err)
	}

	return &KafkaProducer{
		producer: producer,

		tracer:     tracer,
		meter:      meter,
		propagator: propagator,

		latency: latency,
	}
}

func (k *KafkaProducer) Publish(
	ctx context.Context,
	msg *sarama.ProducerMessage,
) {
	// Inject tracing info into message
	span := k.createProducerSpan(ctx, msg)
	defer span.End()

	// Publish message
	k.producer.Input() <- msg
	<-k.producer.Successes()
}

func (k *KafkaProducer) createProducerSpan(
	ctx context.Context,
	msg *sarama.ProducerMessage,
) trace.Span {
	spanAttrs := semconv.WithMessagingKafkaProducerAttributes(msg)
	spanContext, span := k.tracer.Start(
		ctx,
		fmt.Sprintf("%s publish", msg.Topic),
		trace.WithSpanKind(trace.SpanKindProducer),
		trace.WithAttributes(spanAttrs...),
	)

	carrier := propagation.MapCarrier{}
	propagator := otel.GetTextMapPropagator()
	propagator.Inject(spanContext, carrier)

	for key, value := range carrier {
		msg.Headers = append(msg.Headers, sarama.RecordHeader{Key: []byte(key), Value: []byte(value)})
	}

	return span
}
