package com.newrelic.otelplayground.kafkaconsumer.services;

import java.time.Duration;
import java.util.Collections;
import java.util.Properties;

import org.apache.kafka.clients.consumer.Consumer;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.instrumentation.kafkaclients.v2_6.KafkaTelemetry;
import io.opentelemetry.instrumentation.kafkaclients.v2_6.TracingConsumerInterceptor;

@Component
public class KafkaConsumer implements CommandLineRunner {

  private final Logger logger = LoggerFactory.getLogger(KafkaConsumer.class);

  private OpenTelemetry openTelemetry;

  private Consumer<String, String> consumer;

  @Value(value = "${KAFKA_BROKER_ADDRESS}")
  private String kafkaBrokerAddress;

  @Value(value = "${KAFKA_TOPIC}")
  private String kafkaTopic;

  @Value(value = "${KAFKA_CONSUMER_GROUP_ID}")
  private String kafkaConsumerGroupId;

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
        logger.info(record.topic());
        logger.info(record.value());
        logger.info(String.valueOf(record.offset()));
        logger.info(String.valueOf(record.partition()));
      }
    }
  }
}