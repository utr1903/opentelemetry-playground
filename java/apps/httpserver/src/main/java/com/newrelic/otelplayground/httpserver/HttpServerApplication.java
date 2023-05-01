package com.newrelic.otelplayground.httpserver;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;

@SpringBootApplication
@EntityScan("com.newrelic.otelplayground.httpserver.entity")
public class HttpserverApplication {

	public static void main(String[] args) {
		SpringApplication.run(HttpserverApplication.class, args);
	}

}
