package com.newrelic.otelplayground.simulator.services;

import java.util.Collections;
import java.util.Properties;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import org.apache.kafka.clients.admin.AdminClient;
import org.apache.kafka.clients.admin.NewTopic;
import org.apache.kafka.clients.producer.Callback;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.clients.producer.RecordMetadata;
import org.apache.kafka.common.errors.UnknownTopicOrPartitionException;
import org.apache.kafka.common.serialization.StringSerializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.SpanKind;
import io.opentelemetry.api.trace.Tracer;
import io.opentelemetry.context.Scope;
import io.opentelemetry.context.propagation.TextMapPropagator;
import io.opentelemetry.semconv.trace.attributes.SemanticAttributes;
import io.opentelemetry.semconv.trace.attributes.SemanticAttributes.OtelStatusCodeValues;

@Component
public class KafkaProducer implements CommandLineRunner {

  private final Logger logger = LoggerFactory.getLogger(HttpClient.class);

  private org.apache.kafka.clients.producer.KafkaProducer<String, String> producer;
  private Tracer tracer;
  private TextMapPropagator propagator;

  @Value(value = "${KAFKA_BROKER_ADDRESS}")
  private String kafkaBrokerAddress;

  @Value(value = "${KAFKA_TOPIC}")
  private String kafkaTopic;

  @Value(value = "${KAFKA_REQUEST_INTERVAL}")
  private int kafkaRequestInterval;

  public KafkaProducer(OpenTelemetry openTelemetry) {
    // Initialize tracer
    tracer = openTelemetry.getTracer(HttpClient.class.getName());

    // Initialize propagator
    propagator = openTelemetry.getPropagators().getTextMapPropagator();
  }

  @Override
  public void run(String... args) throws Exception {
    // Create Kafka producer
    createKafkaProducer();

    // Create scheduler
    var scheduler = Executors.newScheduledThreadPool(1);

    // Simulate
    scheduler.scheduleAtFixedRate(() -> create(), kafkaRequestInterval, kafkaRequestInterval,
        TimeUnit.MILLISECONDS);
  }

  private void createKafkaProducer() {

    // Create Kafka properties
    Properties properties = new Properties();
    properties.put(
        ProducerConfig.BOOTSTRAP_SERVERS_CONFIG,
        kafkaBrokerAddress);
    properties.put(
        ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG,
        StringSerializer.class);
    properties.put(
        ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG,
        StringSerializer.class);

    // Create the admin client
    try (AdminClient adminClient = AdminClient.create(properties)) {

      // Check if the topic exists
      logger.info("Checking if Kafka topic exists...");
      boolean topicExists = adminClient.listTopics().names().get().contains(kafkaTopic);
      if (!topicExists) {

        // Create the NewTopic with desired configuration
        logger.info("Creating Kafka topic...");
        NewTopic newTopic = new NewTopic(kafkaTopic, 1, (short) 1);

        // Create the topic
        adminClient.createTopics(Collections.singletonList(newTopic)).all().get();
        logger.info("Kafka is topic created.");
      } else {
        logger.info("Kafka topic already exists.");
      }
    } catch (InterruptedException | ExecutionException | UnknownTopicOrPartitionException e) {
      logger.error("Kafka topic could not be found or created!");
    }

    // Create the KafkaProducer
    logger.info("Creating Kafka producer...");
    producer = new org.apache.kafka.clients.producer.KafkaProducer<>(properties);
    logger.info("Kafka producer is created.");
  }

  private void create() {
    Span span = tracer.spanBuilder(kafkaTopic + " send").setSpanKind(SpanKind.PRODUCER).startSpan();

    // Make the span the current span
    try (Scope scope = span.makeCurrent()) {

      // Set common span attributes
      setCommonSpanAttributes(span);

      // Create the ProducerRecord with the topic and message
      ProducerRecord<String, String> record = new ProducerRecord<>(kafkaTopic, "HELLO");

      // Send the record to the topic
      logger.info("Message is being sent to '" + kafkaTopic + "'...");
      producer.send(record, new Callback() {

        @Override
        public void onCompletion(RecordMetadata metadata, Exception exception) {
          span.setAttribute(SemanticAttributes.MESSAGING_KAFKA_DESTINATION_PARTITION, metadata.partition());
        }
      });

      logger.info("Message is published successfully to '" + kafkaTopic + "'!");
    } catch (Exception e) {
      setExceptionSpanAttributes(span, e);
      logger.error(e.getMessage(), e);
    } finally {
      span.end();
    }
  }

  private void setCommonSpanAttributes(Span span) {
    span.setAttribute(SemanticAttributes.MESSAGING_SYSTEM, "kafka");
    span.setAttribute(SemanticAttributes.MESSAGING_DESTINATION_KIND, "topic");
    span.setAttribute(SemanticAttributes.MESSAGING_DESTINATION_NAME, kafkaTopic);
    span.setAttribute(SemanticAttributes.MESSAGING_OPERATION, "send");
    span.setAttribute(SemanticAttributes.NET_PEER_NAME, kafkaBrokerAddress);
    span.setAttribute(SemanticAttributes.NET_PEER_PORT, Integer.parseInt("9092"));
  }

  private void setExceptionSpanAttributes(Span span, Exception e) {
    span.setAttribute(SemanticAttributes.OTEL_STATUS_CODE, OtelStatusCodeValues.ERROR);
    span.setAttribute(SemanticAttributes.EXCEPTION_MESSAGE, e.getMessage());
    span.setAttribute(SemanticAttributes.EXCEPTION_STACKTRACE, e.getStackTrace().toString());
  }
}
