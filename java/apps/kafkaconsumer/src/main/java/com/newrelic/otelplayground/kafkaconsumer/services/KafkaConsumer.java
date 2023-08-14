package com.newrelic.otelplayground.kafkaconsumer.services;

import java.time.Duration;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Properties;

import org.apache.kafka.clients.consumer.Consumer;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.common.header.Header;
import org.apache.kafka.common.header.Headers;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import com.newrelic.otelplayground.kafkaconsumer.entities.Name;
import com.newrelic.otelplayground.kafkaconsumer.repositories.NameRepository;

import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.api.common.Attributes;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.SpanKind;
import io.opentelemetry.context.Context;
import io.opentelemetry.context.Scope;
import io.opentelemetry.context.propagation.TextMapGetter;
import io.opentelemetry.context.propagation.TextMapPropagator;
import io.opentelemetry.instrumentation.kafkaclients.v2_6.KafkaTelemetry;
import io.opentelemetry.instrumentation.kafkaclients.v2_6.TracingConsumerInterceptor;
import io.opentelemetry.semconv.trace.attributes.SemanticAttributes;
import io.opentelemetry.semconv.trace.attributes.SemanticAttributes.OtelStatusCodeValues;

@Component
public class KafkaConsumer implements CommandLineRunner {

  private final Logger logger = LoggerFactory.getLogger(KafkaConsumer.class);

  private OpenTelemetry openTelemetry;
  private TextMapGetter<Headers> textMapGetter = new TextMapGetter<Headers>() {

    @Override
    public Iterable<String> keys(Headers headers) {
      List<String> keys = new ArrayList<>();
      for (Header header : headers)
        keys.add(header.key());
      // System.out.println(keys);
      return keys;
    }

    @Override
    public String get(Headers headers, String key) {
      System.out.println(key);
      Header header = headers.lastHeader(key);
      if (header != null) {
        // System.out.println(new String(header.value()));
        return new String(header.value());
      }
      return null;
    }
  };

  private Consumer<String, String> consumer;

  @Value(value = "${KAFKA_BROKER_ADDRESS}")
  private String kafkaBrokerAddress;

  @Value(value = "${KAFKA_TOPIC}")
  private String kafkaTopic;

  @Value(value = "${KAFKA_CONSUMER_GROUP_ID}")
  private String kafkaConsumerGroupId;

  @Value(value = "${MYSQL_SERVER}")
  private String mysqlServer;

  @Value(value = "${MYSQL_USERNAME}")
  private String mysqlUser;

  @Value(value = "${MYSQL_PORT}")
  private String mysqlPort;

  @Value(value = "${MYSQL_DATABASE}")
  private String mysqlDatabase;

  @Value(value = "${MYSQL_TABLE}")
  private String mysqlTable;

  private final String DB_OPERATION = "INSERT";

  @Autowired
  private NameRepository repository;

  public KafkaConsumer(OpenTelemetry openTelemetry) {
    this.openTelemetry = openTelemetry;
  }

  @Override
  public void run(String... args) throws Exception {
    // Create Kafka consumer
    createKafkaConsumer();

    // Consume & create
    create();
  }

  private void createKafkaConsumer() throws Exception {

    // Create Kafka properties
    Properties properties = new Properties();
    properties.put(
        ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG,
        kafkaBrokerAddress);
    properties.put(
        ConsumerConfig.GROUP_ID_CONFIG,
        kafkaConsumerGroupId);
    properties.put(
        ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG,
        StringDeserializer.class);
    properties.put(
        ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG,
        StringDeserializer.class);
    properties.put(
        ConsumerConfig.INTERCEPTOR_CLASSES_CONFIG,
        TracingConsumerInterceptor.class.getName());

    // Create the KafkaConsumer
    logger.info("Creating Kafka consumer...");
    org.apache.kafka.clients.consumer.KafkaConsumer<String, String> kafkaConsumer = new org.apache.kafka.clients.consumer.KafkaConsumer<>(
        properties);
    kafkaConsumer.subscribe(Collections.singletonList(kafkaTopic));
    logger.info("Kafka consumer is created.");

    KafkaTelemetry telemetry = KafkaTelemetry.create(openTelemetry);
    consumer = telemetry.wrap(kafkaConsumer);
    logger.info("Kafka consumer is wrapped with OTel.");
  }

  private void create() {
    while (true) {
      ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(100));
      for (ConsumerRecord<String, String> record : records) {

        // Extract context
        TextMapPropagator propagator = openTelemetry.getPropagators().getTextMapPropagator();
        Context ctx = propagator.extract(Context.current(), record.headers(),
            textMapGetter);

        String dbStatement = DB_OPERATION + " INTO name " + mysqlTable + " FROM " + mysqlTable;

        // Create span from current context
        // Span span = Span.fromContext(ctx);
        Span dbSpan = openTelemetry.getTracer(KafkaConsumer.class.getName())
            .spanBuilder(dbStatement)
            .setParent(ctx)
            .setSpanKind(SpanKind.CLIENT)
            .startSpan();
        // ctx = ctx.with(dbSpan);

        // logger.info(dbSpan.getSpanContext().getTraceId());

        try (Scope scope = dbSpan.makeCurrent()) {
          setCommonSpanAttributes(dbSpan, dbStatement);

          logger.info("Storing name...");
          Name name = new Name();
          name.setName(record.value());
          repository.save(name);
          logger.info("Name is stored.");

        } catch (Exception e) {
          setExceptionSpanAttributes(dbSpan, e);
          logger.error(e.getMessage(), e);
        } finally {
          dbSpan.end();
        }
      }
    }
  }

  private void setCommonSpanAttributes(
      Span span,
      String dbStatement) {
    span.setAttribute(SemanticAttributes.DB_SYSTEM, "mysql");
    span.setAttribute(SemanticAttributes.DB_USER, mysqlUser);
    span.setAttribute(SemanticAttributes.DB_NAME, mysqlDatabase);
    span.setAttribute(SemanticAttributes.DB_SQL_TABLE, mysqlTable);
    span.setAttribute(SemanticAttributes.NET_PEER_NAME, mysqlServer);
    span.setAttribute(SemanticAttributes.NET_PEER_PORT, Integer.parseInt(mysqlPort));
    span.setAttribute(SemanticAttributes.NET_TRANSPORT, "IP.TCP");
    span.setAttribute(SemanticAttributes.DB_OPERATION, DB_OPERATION);
    span.setAttribute(SemanticAttributes.DB_STATEMENT, dbStatement);
  }

  private void setExceptionSpanAttributes(
      Span span,
      Exception e) {
    span.setAttribute(SemanticAttributes.OTEL_STATUS_CODE, OtelStatusCodeValues.ERROR);
    span.setAttribute(SemanticAttributes.OTEL_STATUS_DESCRIPTION, e.getMessage());

    span.recordException(e, Attributes.of(SemanticAttributes.EXCEPTION_ESCAPED, true));
  }
}