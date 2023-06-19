package com.newrelic.otelplayground.kafkaconsumer.repositories;

import org.springframework.data.jpa.repository.JpaRepository;

import com.newrelic.otelplayground.kafkaconsumer.entities.Name;


public interface NameRepository extends JpaRepository<Name, Long> {

}
