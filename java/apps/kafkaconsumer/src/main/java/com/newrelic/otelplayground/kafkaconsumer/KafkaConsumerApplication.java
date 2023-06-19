package com.newrelic.otelplayground.kafkaconsumer;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.api.logs.GlobalLoggerProvider;
import io.opentelemetry.instrumentation.runtimemetrics.BufferPools;
import io.opentelemetry.instrumentation.runtimemetrics.Classes;
import io.opentelemetry.instrumentation.runtimemetrics.Cpu;
import io.opentelemetry.instrumentation.runtimemetrics.GarbageCollector;
import io.opentelemetry.instrumentation.runtimemetrics.MemoryPools;
import io.opentelemetry.instrumentation.runtimemetrics.Threads;
import io.opentelemetry.sdk.OpenTelemetrySdk;
import io.opentelemetry.sdk.autoconfigure.AutoConfiguredOpenTelemetrySdk;

@SpringBootApplication
public class KafkaConsumerApplication {

	private static volatile OpenTelemetry openTelemetry = OpenTelemetry.noop();

	public static void main(String[] args) {
		// Build the SDK auto-configuration extension module
		OpenTelemetrySdk openTelemetrySdk = AutoConfiguredOpenTelemetrySdk.builder()
				.setResultAsGlobal(false)
				.build()
				.getOpenTelemetrySdk();
		KafkaConsumerApplication.openTelemetry = openTelemetrySdk;

		// Set GlobalLoggerProvider, which is used by Log4j2 appender
		GlobalLoggerProvider.set(openTelemetrySdk.getSdkLoggerProvider());

		// Register runtime metrics instrumentation
		BufferPools.registerObservers(openTelemetrySdk);
		Classes.registerObservers(openTelemetrySdk);
		Cpu.registerObservers(openTelemetrySdk);
		GarbageCollector.registerObservers(openTelemetrySdk);
		MemoryPools.registerObservers(openTelemetrySdk);
		Threads.registerObservers(openTelemetrySdk);

		SpringApplication.run(KafkaConsumerApplication.class, args);
	}

	@Bean
	public OpenTelemetry openTelemetry() {
		return openTelemetry;
	}
}
