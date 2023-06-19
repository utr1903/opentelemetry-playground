package com.newrelic.otelplayground.simulator.services;

import java.util.Collections;
import java.util.Properties;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import org.apache.kafka.clients.admin.AdminClient;
import org.apache.kafka.clients.admin.NewTopic;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.errors.UnknownTopicOrPartitionException;
import org.apache.kafka.common.serialization.StringSerializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.instrumentation.kafkaclients.v2_6.KafkaTelemetry;
import io.opentelemetry.instrumentation.kafkaclients.v2_6.TracingProducerInterceptor;

@Component
public class KafkaProducer implements CommandLineRunner {

  private final Logger logger = LoggerFactory.getLogger(KafkaProducer.class);

  private Producer<String, String> producer;
  private OpenTelemetry openTelemetry;

  @Value(value = "${KAFKA_BROKER_ADDRESS}")
  private String kafkaBrokerAddress;

  @Value(value = "${KAFKA_TOPIC}")
  private String kafkaTopic;

  @Value(value = "${KAFKA_REQUEST_INTERVAL}")
  private int kafkaRequestInterval;

  public KafkaProducer(OpenTelemetry openTelemetry) {
    this.openTelemetry = openTelemetry;
  }

  @Override
  public void run(String... args) throws Exception {

    // Create Kafka topic if not exists
    createKafkaTopicIfNotExists();

    // Create Kafka producer
    createKafkaProducer();

    // Create scheduler
    var scheduler = Executors.newScheduledThreadPool(1);

    // Simulate
    scheduler.scheduleAtFixedRate(() -> create(), kafkaRequestInterval, kafkaRequestInterval,
        TimeUnit.MILLISECONDS);
  }

  private void createKafkaTopicIfNotExists() throws Exception {
    // Create Kafka properties
    Properties properties = new Properties();
    properties.put(
        ProducerConfig.BOOTSTRAP_SERVERS_CONFIG,
        kafkaBrokerAddress);

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
      String msg = "Kafka topic could not be found or created!";
      logger.error(msg);
      logger.error(e.getMessage(), e);
      throw new Exception(msg);
    }
  }

  private void createKafkaProducer() throws Exception {

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
    properties.put(
        ConsumerConfig.INTERCEPTOR_CLASSES_CONFIG,
        TracingProducerInterceptor.class.getName());

    // Create the KafkaProducer
    logger.info("Creating Kafka producer...");
    org.apache.kafka.clients.producer.KafkaProducer<String, String> kafkaProducer = new org.apache.kafka.clients.producer.KafkaProducer<>(
        properties);
    logger.info("Kafka producer is created.");

    KafkaTelemetry telemetry = KafkaTelemetry.create(openTelemetry);
    producer = telemetry.wrap(kafkaProducer);
    logger.info("Kafka producer is wrapped with OTel.");
  }

  private void create() {
    try {
      // Create the ProducerRecord with the topic and message
      ProducerRecord<String, String> record = new ProducerRecord<>(kafkaTopic, "HELLO");

      // Send the record to the topic
      logger.info("Message is being sent to '" + kafkaTopic + "'...");
      producer.send(record);
      logger.info("Message is published successfully to '" + kafkaTopic + "'!");

    } catch (Exception e) {
      logger.error(e.getMessage(), e);
    }
  }
}
